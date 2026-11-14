/*
 * Bookmunity reader runtime.
 *
 * Hosts epub.js inside the Flutter WebView and talks to Flutter through
 * `readerEvent` (JS -> Flutter) and `window.readerCommand` (Flutter -> JS).
 * See docs/reader_bridge.md for the message contract.
 *
 * Gestures are detected inside each chapter iframe because the WebView owns
 * all touches; Flutter never sees them.
 */
(function () {
  "use strict";

  var THEMES = {
    light: {bg: "#F7F4EE", fg: "#2B2B2B", link: "#4A6FA5", blend: "multiply"},
    sepia: {bg: "#F1E7D0", fg: "#4A3B2A", link: "#8A5A2B", blend: "multiply"},
    dark: {bg: "#1C1B19", fg: "#DAD5CB", link: "#9DB4D8", blend: "screen"}
  };
  var FONTS = {
    serif: "Georgia, 'Times New Roman', serif",
    sans: "system-ui, -apple-system, Roboto, 'Helvetica Neue', Arial, sans-serif"
  };
  var HIGHLIGHT_COLORS = ["#F2D16B", "#9CCB9E", "#9DB9E0", "#E8A9C4"];
  var INSET_TOP = 40;
  var INSET_BOTTOM = 36;
  var SWIPE_DISTANCE = 50;
  var TAP_MAX_MS = 350;
  var EDGE_ZONE = 0.25;

  var book = null;
  var rendition = null;
  var settings = {fontSize: 19, lineHeight: 1.6, margin: 20, theme: "light", flow: "paginated", font: "serif"};
  var locationsReady = false;
  var lastLocation = null;
  var tocItems = [];
  var tocByHref = {};
  var bookmarks = [];
  var highlights = {};
  var searchMark = null;
  var searchToken = 0;
  var turning = false;
  var lastHighlightTap = 0;
  var lastActivity = 0;
  var selectionOpen = false;

  function send(event, payload) {
    if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
      window.flutter_inappwebview.callHandler("readerEvent", {event: event, payload: payload || {}});
    }
  }

  // Non-fatal: logged by Flutter, the book stays open.
  window.addEventListener("error", function (e) {
    send("jsError", {message: String(e.message || e), source: String(e.filename || ""), line: e.lineno || 0});
  });
  window.addEventListener("resize", function () {
    if (typeof invalidateSnapshot === "function") invalidateSnapshot();
  });
  window.addEventListener("unhandledrejection", function (e) {
    send("jsError", {message: String(e.reason && e.reason.message || e.reason)});
  });

  function viewer() {
    return document.getElementById("viewer");
  }

  function isScrolled() {
    return settings.flow === "scrolled";
  }

  function theme() {
    return THEMES[settings.theme] || THEMES.light;
  }

  function activity() {
    var now = Date.now();
    if (now - lastActivity > 15000) {
      lastActivity = now;
      send("activity", {});
    }
  }

  // ---------------------------------------------------------------- layout

  function applyPageChrome() {
    var t = theme();
    document.documentElement.style.background = t.bg;
    document.body.style.background = t.bg;
    document.body.style.color = t.fg;
    document.body.className = "theme-" + settings.theme;
    pageEl().style.background = t.bg;
    var v = viewer();
    v.style.top = INSET_TOP + "px";
    v.style.bottom = INSET_BOTTOM + "px";
    // Paginated mode needs real container margins so epub.js computes column
    // widths correctly. Scrolled mode keeps the scroller full-width (so the
    // whole screen scrolls) and pads the chapter body instead.
    var side = isScrolled() ? 0 : settings.margin;
    v.style.left = side + "px";
    v.style.right = side + "px";
  }

  function contentCss() {
    var t = theme();
    var lines = [
      "html, body { background: transparent !important; color: " + t.fg + " !important; }",
      "body { font-family: " + (FONTS[settings.font] || FONTS.serif) + " !important;" +
        " line-height: " + settings.lineHeight + " !important;" +
        " -webkit-tap-highlight-color: transparent; -webkit-touch-callout: none;" +
        " text-rendering: optimizeLegibility; overflow-wrap: break-word; }",
      "p, li, blockquote, dd, dt, td { line-height: inherit !important; }",
      "a, a:visited { color: " + t.link + " !important; }",
      "::selection { background: rgba(242, 209, 107, 0.55); }"
    ];
    if (settings.theme !== "light") {
      // Many books hard-code black text; keep it readable on dark/sepia pages.
      lines.push("body * { color: inherit !important; background-color: transparent !important; }");
      lines.push("a, a * { color: " + t.link + " !important; }");
    }
    if (settings.theme === "dark") {
      lines.push("img { opacity: 0.88; }");
    }
    if (isScrolled()) {
      lines.push("body { padding-left: " + settings.margin + "px !important; padding-right: " +
        settings.margin + "px !important; box-sizing: border-box !important; }");
    }
    return lines.join("\n");
  }

  function injectStyle(doc) {
    if (!doc || !doc.head) return;
    var style = doc.getElementById("bookmunity-style");
    if (!style) {
      style = doc.createElement("style");
      style.id = "bookmunity-style";
      doc.head.appendChild(style);
    }
    style.textContent = contentCss();
  }

  function applyTypography() {
    if (!rendition) return;
    rendition.themes.fontSize(settings.fontSize + "px");
    rendition.getContents().forEach(function (contents) {
      injectStyle(contents.document);
    });
  }

  // ------------------------------------------------------------------- toc

  function basename(href) {
    var clean = String(href || "").split("#")[0];
    return clean.substring(clean.lastIndexOf("/") + 1);
  }

  function flattenToc(items, depth, out) {
    (items || []).forEach(function (item) {
      var label = String(item.label || "").replace(/\s+/g, " ").trim();
      out.push({label: label, href: item.href, depth: depth});
      var key = basename(item.href);
      if (label && key && !tocByHref[key]) tocByHref[key] = label;
      flattenToc(item.subitems, depth + 1, out);
    });
    return out;
  }

  function chapterTitleForIndex(index) {
    if (!book) return "";
    for (var i = index; i >= 0; i--) {
      var section = book.spine.get(i);
      if (!section) continue;
      var label = tocByHref[basename(section.href)];
      if (label) return label;
    }
    return "";
  }

  // When several TOC entries point into the same file (common in Gutenberg
  // books), pick the last one whose anchor sits at or before the position.
  function chapterTitleForLocation(start) {
    var index = start && typeof start.index === "number" ? start.index : 0;
    var section = book && book.spine.get(index);
    if (!section || !rendition || !start.cfi) return chapterTitleForIndex(index);
    var file = basename(section.href);
    var candidates = tocItems.filter(function (item) {
      return basename(item.href) === file;
    });
    if (candidates.length < 2) return chapterTitleForIndex(index);
    var contents = rendition.getContents().filter(function (c) {
      return c.sectionIndex === index;
    })[0];
    if (!contents) return chapterTitleForIndex(index);
    var best = null;
    candidates.forEach(function (item) {
      var fragment = String(item.href).split("#")[1];
      if (!fragment) {
        if (!best) best = item;
        return;
      }
      var element = contents.document.getElementById(decodeURIComponent(fragment));
      if (!element) return;
      try {
        if (compareCfi(contents.cfiFromNode(element), start.cfi) <= 0) best = item;
      } catch (e) { /* ignore unresolvable anchors */ }
    });
    if (best && best.label) return best.label;
    return index > 0 ? chapterTitleForIndex(index - 1) : candidates[0].label;
  }

  // ------------------------------------------------------------- reporting

  function compareCfi(a, b) {
    try {
      return new ePub.CFI().compare(a, b);
    } catch (e) {
      return NaN;
    }
  }

  function bookmarksOnPage(startCfi, endCfi) {
    if (!startCfi || !endCfi) return [];
    return bookmarks.filter(function (cfi) {
      return compareCfi(startCfi, cfi) <= 0 && compareCfi(cfi, endCfi) <= 0;
    });
  }

  // epub.js's own displayed.page is unreliable in paginated mode (it can
  // repeat or skip numbers), so derive the page from the scroll offset.
  function pageInfo(start) {
    if (isScrolled()) return {page: 0, total: 0};
    try {
      var manager = rendition.manager;
      var delta = manager.layout.delta;
      var view = manager.views.first();
      if (view && delta > 0) {
        var offset = manager.container.scrollLeft - (view.element.offsetLeft || 0);
        var total = Math.max(1, Math.round(view.width() / delta));
        return {page: Math.min(total, Math.max(1, Math.round(offset / delta) + 1)), total: total};
      }
    } catch (e) { /* fall through */ }
    return start.displayed ? {page: start.displayed.page, total: start.displayed.total} : {page: 0, total: 0};
  }

  function report() {
    var location = lastLocation;
    if (!location || !location.start) return;
    var start = location.start;
    var end = location.end || start;
    var percentage = null;
    var current = null;
    var total = null;
    var pages = pageInfo(start);
    if (locationsReady) {
      percentage = book.locations.percentageFromCfi(start.cfi);
      current = book.locations.locationFromCfi(start.cfi);
      total = book.locations.length();
    }
    send("relocated", {
      cfi: start.cfi || "",
      endCfi: end.cfi || "",
      href: start.href || "",
      index: typeof start.index === "number" ? start.index : -1,
      chapterTitle: chapterTitleForLocation(start),
      percentage: percentage,
      location: current,
      totalLocations: total,
      page: pages.page,
      totalPages: pages.total,
      atStart: !!location.atStart,
      atEnd: !!location.atEnd,
      bookmarkCfis: bookmarksOnPage(start.cfi, end.cfi)
    });
  }

  // ------------------------------------------------------------ highlights

  function highlightColor(index) {
    return HIGHLIGHT_COLORS[index] || HIGHLIGHT_COLORS[0];
  }

  function drawHighlight(item) {
    if (!rendition || !item || !item.cfiRange) return;
    try {
      rendition.annotations.remove(item.cfiRange, "highlight");
    } catch (e) { /* not drawn yet */ }
    highlights[item.cfiRange] = item;
    invalidateSnapshot();
    rendition.annotations.highlight(
      item.cfiRange,
      {id: item.id},
      function () {
        lastHighlightTap = Date.now();
        send("highlightTapped", {id: item.id, cfiRange: item.cfiRange});
      },
      "bookmunity-highlight",
      {"fill": highlightColor(item.color), "fill-opacity": "0.42", "mix-blend-mode": theme().blend}
    );
  }

  function removeHighlight(cfiRange) {
    delete highlights[cfiRange];
    if (!rendition) return;
    invalidateSnapshot();
    try {
      rendition.annotations.remove(cfiRange, "highlight");
    } catch (e) { /* already gone */ }
  }

  function redrawHighlights() {
    Object.keys(highlights).forEach(function (cfi) {
      drawHighlight(highlights[cfi]);
    });
  }

  function clearSearchMark() {
    if (searchMark && rendition) {
      try {
        rendition.annotations.remove(searchMark, "highlight");
      } catch (e) { /* ignore */ }
    }
    searchMark = null;
    invalidateSnapshot();
  }

  function markSearchResult(cfi) {
    clearSearchMark();
    searchMark = cfi;
    invalidateSnapshot();
    rendition.annotations.highlight(cfi, {}, null, "bookmunity-search",
      {"fill": "#5B7DB1", "fill-opacity": "0.35", "mix-blend-mode": theme().blend});
  }

  // -------------------------------------------------------------- gestures

  function hasSelection(win) {
    var selection = win && win.getSelection ? win.getSelection() : null;
    return !!(selection && !selection.isCollapsed && selection.toString().trim().length);
  }

  function clearSelection() {
    if (!rendition) return;
    rendition.getContents().forEach(function (contents) {
      var selection = contents.window.getSelection();
      if (selection) selection.removeAllRanges();
    });
    selectionOpen = false;
  }

  // ------------------------------------------------------------- page turn
  //
  // A paginated turn is drawn as a sheet of paper rotating about the spine
  // (the left edge). epub.js only shows one page at a time, so a turn needs
  // two pictures at once: the live #page and a frozen copy of it
  // (.flip-sheet) built from a clone of the chapter document. The copy holds
  // the whole chapter, so it is built once per chapter (ahead of time, after
  // each relocation) and re-aimed at any page of it by shifting it.
  //
  //   Forward:  the copy of the old page lies on top and lifts away toward the
  //             reader, revealing the live page, which has already moved on.
  //   Backward: the live page moves back, starts edge-on at the spine and
  //             folds down over the copy of the old page.
  //
  // Only transforms and opacity change per frame, so the compositor does the
  // work. Anything that fails falls back to a plain fade, never a stuck page.

  var PERSPECTIVE = 1800;
  var COMMIT_RATIO = 0.35;
  var FLING_MS = 320;
  var reduceMotion = !!(window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches);
  var snap = null;
  var snapVersion = 0;
  var snapTimer = null;
  var flip = null;

  function pageEl() {
    return document.getElementById("page");
  }

  function pageShade() {
    return document.getElementById("page-shade");
  }

  function castEl() {
    return document.getElementById("flip-cast");
  }

  function nextFrame() {
    return new Promise(function (resolve) {
      requestAnimationFrame(function () {
        requestAnimationFrame(resolve);
      });
    });
  }

  function delay(ms) {
    return new Promise(function (resolve) {
      setTimeout(resolve, ms);
    });
  }

  function atEdge(direction) {
    return !!(lastLocation && (direction > 0 ? lastLocation.atEnd : lastLocation.atStart));
  }

  // A turn that leaves the chapter replaces the chapter iframe, which would
  // orphan the touch that is dragging the page, so those turns are animated
  // after the finger lifts instead of following it.
  function crossesChapter(direction) {
    var pages = lastLocation && lastLocation.start ? pageInfo(lastLocation.start) : null;
    if (!pages || !pages.total) return true;
    return direction > 0 ? pages.page >= pages.total : pages.page <= 1;
  }

  function currentView() {
    try {
      var manager = rendition && rendition.manager;
      return manager && manager.views && manager.views.first ? manager.views.first() : null;
    } catch (e) {
      return null;
    }
  }

  function locationStamp() {
    var view = currentView();
    var container = rendition && rendition.manager && rendition.manager.container;
    return (view && view.section ? view.section.index : -1) + ":" +
      (container ? Math.round(container.scrollLeft) : 0);
  }

  function moveBy(direction) {
    var before = locationStamp();
    var move;
    try {
      move = direction > 0 ? rendition.next() : rendition.prev();
    } catch (e) {
      move = null;
    }
    return Promise.resolve(move).catch(function () {}).then(function () {
      return locationStamp() !== before;
    });
  }

  // ---- frozen copy of the chapter

  function snapshotKey(view) {
    if (!view || !view.element || !view.section) return null;
    var v = viewer();
    return [view.section.index, view.element.offsetWidth, view.element.offsetHeight,
      v.clientWidth, v.clientHeight, snapVersion].join("|");
  }

  function serializeDocument(doc) {
    var root = doc.documentElement.cloneNode(true);
    var head = root.querySelector("head");
    // Rules added through the CSSOM (insertRule) are not in the markup.
    var rules = [];
    Array.prototype.forEach.call(doc.styleSheets || [], function (sheet) {
      try {
        var owner = sheet.ownerNode;
        if (owner && String(owner.tagName).toLowerCase() === "style" && !String(owner.textContent || "").trim()) {
          Array.prototype.forEach.call(sheet.cssRules, function (rule) {
            rules.push(rule.cssText);
          });
        }
      } catch (e) { /* cross-origin sheet: already in the markup as a link */ }
    });
    Array.prototype.forEach.call(root.querySelectorAll("script"), function (node) {
      node.parentNode.removeChild(node);
    });
    if (head) {
      if (rules.length) {
        var style = doc.createElement("style");
        style.textContent = rules.join("\n");
        head.appendChild(style);
      }
      if (!head.querySelector("base") && /^https?:/.test(doc.baseURI || "")) {
        var base = doc.createElement("base");
        base.setAttribute("href", doc.baseURI);
        head.insertBefore(base, head.firstChild);
      }
    }
    if (/xml/.test(doc.contentType || "")) {
      return {type: "application/xhtml+xml", text: new XMLSerializer().serializeToString(root)};
    }
    return {type: "text/html", text: "<!DOCTYPE html>\n" + root.outerHTML};
  }

  function buildSnapshot(view) {
    var key = snapshotKey(view);
    var frame = view && (view.iframe || view.element.querySelector("iframe"));
    var doc = frame && frame.contentDocument;
    if (!key || !doc || !doc.documentElement) return null;
    var payload;
    try {
      payload = serializeDocument(doc);
    } catch (e) {
      return null;
    }
    var sheet = document.createElement("div");
    sheet.className = "flip-sheet";
    sheet.setAttribute("aria-hidden", "true");
    sheet.style.background = theme().bg;
    var clip = document.createElement("div");
    clip.className = "flip-clip";
    // The view clone keeps epub.js's highlight layer (an SVG beside the
    // iframe); only the iframe itself is swapped for a static copy.
    var clone = view.element.cloneNode(true);
    clone.removeAttribute("id");
    clone.style.position = "absolute";
    var copy = document.createElement("iframe");
    copy.setAttribute("sandbox", "allow-same-origin");
    copy.setAttribute("scrolling", "no");
    copy.setAttribute("tabindex", "-1");
    copy.style.cssText = frame.style.cssText;
    copy.style.border = "0";
    if (frame.getAttribute("width")) copy.setAttribute("width", frame.getAttribute("width"));
    if (frame.getAttribute("height")) copy.setAttribute("height", frame.getAttribute("height"));
    var old = clone.querySelector("iframe");
    if (old) {
      old.parentNode.replaceChild(copy, old);
    } else {
      clone.insertBefore(copy, clone.firstChild);
    }
    clip.appendChild(clone);
    var shade = document.createElement("div");
    shade.className = "flip-shade";
    sheet.appendChild(clip);
    sheet.appendChild(shade);
    document.body.appendChild(sheet);

    var url = URL.createObjectURL(new Blob([payload.text], {type: payload.type + ";charset=utf-8"}));
    var entry = {key: key, el: sheet, clip: clip, view: clone, shade: shade, url: url, loaded: false};
    entry.ready = new Promise(function (resolve) {
      copy.addEventListener("load", function () {
        nextFrame().then(function () {
          entry.loaded = true;
          resolve();
        });
      });
    });
    copy.src = url;
    return entry;
  }

  function destroySnapshot() {
    if (!snap) return;
    try {
      snap.el.parentNode.removeChild(snap.el);
    } catch (e) { /* already gone */ }
    try {
      URL.revokeObjectURL(snap.url);
    } catch (e) { /* ignore */ }
    snap = null;
  }

  function ensureSnapshot() {
    var view = currentView();
    var key = snapshotKey(view);
    if (!key) return null;
    if (snap && snap.key === key) return snap;
    destroySnapshot();
    snap = buildSnapshot(view);
    return snap;
  }

  // Highlights, search marks, settings and size all change what a page looks
  // like, so any of them retires the copy.
  function invalidateSnapshot() {
    snapVersion++;
    if (!flip) destroySnapshot();
    scheduleSnapshot();
  }

  function scheduleSnapshot() {
    clearTimeout(snapTimer);
    if (reduceMotion || isScrolled()) return;
    snapTimer = setTimeout(function () {
      if (!flip && !turning && rendition && !isScrolled()) ensureSnapshot();
    }, 500);
  }

  // Shift the chapter copy so it shows exactly the page on screen.
  function aimSnapshot(entry) {
    var container = rendition.manager.container;
    var view = currentView();
    // Rects, not offsets: they already account for the container's scroll.
    var pageRect = pageEl().getBoundingClientRect();
    var clipRect = container.getBoundingClientRect();
    var viewRect = view.element.getBoundingClientRect();
    entry.clip.style.left = (clipRect.left - pageRect.left) + "px";
    entry.clip.style.top = (clipRect.top - pageRect.top) + "px";
    entry.clip.style.width = container.clientWidth + "px";
    entry.clip.style.height = container.clientHeight + "px";
    entry.view.style.left = (viewRect.left - clipRect.left) + "px";
    entry.view.style.top = (viewRect.top - clipRect.top) + "px";
    entry.el.style.background = theme().bg;
  }

  // ---- drawing

  function setLayer(element, z) {
    element.style.zIndex = String(z);
  }

  // Horizontal position of the lifted edge on screen, after perspective.
  function projectedEdge(theta, width) {
    return width * Math.cos(theta) * PERSPECTIVE / (PERSPECTIVE - width * Math.sin(theta));
  }

  // x: where the free edge would be without perspective, 0 (at the spine)
  // to the screen width (lying flat).
  function renderFlip(f, x) {
    var width = Math.max(1, window.innerWidth);
    f.x = x;
    var cover = Math.max(0, Math.min(1, x / width));
    var theta = Math.acos(cover);
    var lift = Math.sin(theta);
    f.turner.style.transform = "perspective(" + PERSPECTIVE + "px) rotateY(" + (-theta * 180 / Math.PI).toFixed(3) + "deg)";
    f.turnShade.style.opacity = String(Math.min(1, lift * 1.2));
    f.underShade.style.opacity = String(0.55 * cover * Math.min(1, lift * 3));
    var cast = castEl();
    cast.style.transform = "translateX(" + projectedEdge(theta, width).toFixed(1) + "px)";
    cast.style.opacity = String(Math.min(1, lift * 3) * Math.min(1, cover * 4));
  }

  function setupLayers(f) {
    var page = pageEl();
    var entry = f.sheet;
    page.style.transition = "none";
    page.style.opacity = "1";
    if (f.dir > 0) {
      f.turner = entry.el;
      f.turnShade = entry.shade;
      f.under = page;
      f.underShade = pageShade();
      page.style.transform = "";
      setLayer(page, 1);
      setLayer(entry.el, 3);
    } else {
      f.turner = page;
      f.turnShade = pageShade();
      f.under = entry.el;
      f.underShade = entry.shade;
      page.style.transform = "perspective(" + PERSPECTIVE + "px) rotateY(-90deg)";
      setLayer(entry.el, 1);
      setLayer(page, 3);
    }
    f.turnShade.className = "flip-shade turning";
    f.underShade.className = "flip-shade under";
  }

  function easeOutCubic(t) {
    return 1 - Math.pow(1 - t, 3);
  }

  function easeInOutSine(t) {
    return -(Math.cos(Math.PI * t) - 1) / 2;
  }

  function animateFlip(f, target, duration, ease) {
    var from = f.x;
    var begin = null;
    return new Promise(function (resolve) {
      function frame(now) {
        if (f.dead) return resolve();
        if (begin === null) begin = now;
        var t = Math.min(1, (now - begin) / duration);
        renderFlip(f, from + (target - from) * ease(t));
        if (t < 1) {
          requestAnimationFrame(frame);
        } else {
          resolve();
        }
      }
      requestAnimationFrame(frame);
    });
  }

  // ---- lifecycle

  function beginFlip(direction, interactive) {
    var f = {
      dir: direction,
      interactive: interactive,
      x: direction > 0 ? window.innerWidth : 0,
      ready: false,
      release: null,
      dead: false,
      fallback: false,
      sheet: null
    };
    flip = f;
    turning = true;
    // A held drag may last as long as the reader likes; only an automatic
    // turn is on the clock until it is released.
    if (!interactive) armWatchdog(f, 8000);
    var entry = ensureSnapshot();
    if (!entry) {
      abortFlip(f);
      return f;
    }
    Promise.race([entry.ready, delay(interactive ? 450 : 700)]).then(function () {
      if (f.dead) return;
      if (!entry.loaded || snap !== entry) {
        abortFlip(f);
        return;
      }
      f.sheet = entry;
      aimSnapshot(entry);
      entry.el.style.transform = "";
      entry.shade.style.opacity = "0";
      // The copy now covers the live page pixel for pixel, so the live page
      // can move on underneath unseen.
      setLayer(entry.el, 3);
      return nextFrame().then(function () {
        if (f.dead) return false;
        return moveBy(direction);
      }).then(function (moved) {
        if (f.dead) return;
        if (!moved) {
          endFlip(f);
          send("edgeReached", {end: direction > 0});
          return;
        }
        setupLayers(f);
        f.ready = true;
        renderFlip(f, f.x);
        if (f.release !== null) settleFlip(f);
      });
    }).catch(function () {
      if (!f.dead) endFlip(f);
    });
    return f;
  }

  function dragFlip(f, dx) {
    if (!f || f.dead) return;
    var width = window.innerWidth;
    var x = f.dir > 0 ? width + dx : dx;
    f.x = Math.max(0, Math.min(width, x));
    if (f.ready) renderFlip(f, f.x);
  }

  function armWatchdog(f, ms) {
    clearTimeout(f.watchdog);
    f.watchdog = setTimeout(function () {
      endFlip(f);
    }, ms);
  }

  function releaseFlip(f, commit) {
    if (!f || f.release !== null) return;
    f.release = commit;
    if (!f.dead && f.interactive) armWatchdog(f, 4000);
    if (f.fallback) {
      if (commit) simpleTurn(f.dir);
      return;
    }
    if (f.ready && !f.dead) settleFlip(f);
  }

  function settleFlip(f) {
    var width = window.innerWidth;
    var commit = f.release;
    // Forward commits fold the page to the spine; backward commits lay it flat.
    var target = (f.dir > 0) === commit ? 0 : width;
    var distance = Math.abs(target - f.x) / Math.max(1, width);
    var duration = f.interactive ? Math.max(140, 360 * distance) : 520;
    animateFlip(f, target, duration, f.interactive ? easeOutCubic : easeInOutSine).then(function () {
      if (f.dead) return;
      // A cancelled turn steps the live page back while it is hidden: under
      // the flat copy (forward) or edge-on at the spine (backward).
      return (commit ? Promise.resolve() : moveBy(-f.dir)).then(nextFrame);
    }).then(function () {
      endFlip(f);
    });
  }

  function resetFlipLayers() {
    var page = pageEl();
    page.style.transition = "none";
    page.style.transform = "";
    page.style.opacity = "1";
    setLayer(page, 1);
    var shade = pageShade();
    shade.className = "flip-shade";
    shade.style.opacity = "0";
    castEl().style.opacity = "0";
  }

  function endFlip(f) {
    if (f.dead) return;
    f.dead = true;
    clearTimeout(f.watchdog);
    resetFlipLayers();
    if (f.sheet) {
      f.sheet.el.style.transform = "";
      f.sheet.shade.style.opacity = "0";
      f.sheet.shade.className = "flip-shade";
      setLayer(f.sheet.el, 0);
    }
    if (flip === f) flip = null;
    turning = false;
    if (snap && snap.key !== snapshotKey(currentView())) destroySnapshot();
    scheduleSnapshot();
  }

  // No copy available in time: drop the 3D turn for this gesture.
  function abortFlip(f) {
    endFlip(f);
    f.fallback = true;
    if (f.release === true) simpleTurn(f.dir);
  }

  function simpleTurn(direction) {
    if (!rendition || turning) return;
    turning = true;
    destroySnapshot();
    var page = pageEl();
    page.style.transform = "";
    page.style.transition = "opacity 120ms ease-in";
    page.style.opacity = "0.15";
    setTimeout(function () {
      moveBy(direction).then(function (moved) {
        page.style.transition = "opacity 160ms ease-out";
        page.style.opacity = "1";
        setTimeout(function () {
          page.style.transition = "none";
          turning = false;
        }, 170);
        if (!moved) send("edgeReached", {end: direction > 0});
      });
    }, 120);
  }

  // Rubber-band drag for swipes that cannot follow the finger.
  function setOffset(dx, animate) {
    var page = pageEl();
    // Opacity stays at 1: the chapter copy waits underneath #page and would
    // show through.
    page.style.transition = animate ? "transform 160ms ease-out" : "none";
    page.style.transform = dx ? "translateX(" + dx + "px)" : "";
    page.style.opacity = "1";
  }

  function turn(direction) {
    if (!rendition || turning) return;
    if (isScrolled()) {
      goToChapter(direction);
      return;
    }
    if (atEdge(direction)) {
      setOffset(0, true);
      send("edgeReached", {end: direction > 0});
      return;
    }
    if (reduceMotion) {
      simpleTurn(direction);
      return;
    }
    releaseFlip(beginFlip(direction, false), true);
  }

  function goToChapter(direction) {
    if (!rendition || turning || !lastLocation || !lastLocation.start) return;
    var target = book.spine.get((lastLocation.start.index || 0) + direction);
    if (!target) {
      send("edgeReached", {end: direction > 0});
      return;
    }
    destroySnapshot();
    var page = pageEl();
    page.style.transition = "opacity 140ms ease-in";
    page.style.opacity = "0";
    setTimeout(function () {
      Promise.resolve(rendition.display(target.href)).catch(function () {}).then(function () {
        page.style.transition = "opacity 180ms ease-out";
        page.style.opacity = "1";
      });
    }, 140);
  }

  // ---------------------------------------------------------------- gestures
  //
  // Distances use screen coordinates: during a backward turn the iframe's own
  // page is rotated, which would distort its client coordinates.

  function attachGestures(contents) {
    var doc = contents.document;
    var win = contents.window;
    var start = null;

    function abandon() {
      var s = start;
      start = null;
      if (!s) return;
      if (s.mode === "flip") releaseFlip(s.flip, false);
      else if (s.mode) setOffset(0, true);
    }

    doc.addEventListener("touchstart", function (e) {
      activity();
      if (e.touches.length !== 1) {
        abandon();
        return;
      }
      var t = e.touches[0];
      start = {
        x: t.screenX,
        y: t.screenY,
        time: Date.now(),
        hadSelection: hasSelection(win) || selectionOpen,
        moved: false,
        mode: null,
        dir: 0,
        flip: null
      };
    }, {passive: true});

    doc.addEventListener("touchmove", function (e) {
      if (!start || e.touches.length !== 1) return;
      var t = e.touches[0];
      var dx = t.screenX - start.x;
      var dy = t.screenY - start.y;
      if (Math.abs(dx) > 10 || Math.abs(dy) > 10) start.moved = true;
      if (!start.mode) {
        if (isScrolled() || start.hadSelection || hasSelection(win) || turning) return;
        if (Math.abs(dx) < 12 || Math.abs(dx) < Math.abs(dy) * 1.2) return;
        start.dir = dx < 0 ? 1 : -1;
        if (atEdge(start.dir)) {
          start.mode = "edge";
        } else if (reduceMotion || crossesChapter(start.dir)) {
          start.mode = "slide";
        } else {
          start.mode = "flip";
          start.flip = beginFlip(start.dir, true);
        }
      }
      if (start.mode === "flip") {
        if (start.flip.fallback) setOffset(dx * 0.3, false);
        else dragFlip(start.flip, dx);
      } else {
        setOffset(dx * (start.mode === "edge" ? 0.18 : 0.35), false);
      }
    }, {passive: true});

    doc.addEventListener("touchend", function (e) {
      if (!start) return;
      var s = start;
      start = null;
      var t = e.changedTouches[0];
      var dx = t.screenX - s.x;
      var dy = t.screenY - s.y;
      var elapsed = Date.now() - s.time;
      var travelled = s.dir > 0 ? -dx : dx;
      var swiped = travelled > SWIPE_DISTANCE;

      if (s.mode === "flip") {
        if (s.flip.fallback) setOffset(0, false);
        var commit = travelled > window.innerWidth * COMMIT_RATIO || (swiped && elapsed < FLING_MS);
        releaseFlip(s.flip, commit);
        return;
      }
      if (s.mode === "edge") {
        setOffset(0, true);
        if (swiped) send("edgeReached", {end: s.dir > 0});
        return;
      }
      if (s.mode === "slide") {
        setOffset(0, false);
        if (swiped) turn(s.dir);
        return;
      }

      if (s.hadSelection || hasSelection(win)) {
        if (s.hadSelection && !s.moved && elapsed < TAP_MAX_MS) {
          // Tapping away from an open selection dismisses it, like Kindle.
          setTimeout(function () {
            if (!hasSelection(win)) {
              selectionOpen = false;
              send("selectionCleared", {});
            }
          }, 60);
        }
        return;
      }
      // Scrolled mode: a clear horizontal swipe changes chapter.
      if (isScrolled() && Math.abs(dx) > SWIPE_DISTANCE && Math.abs(dx) > Math.abs(dy) * 2 && elapsed < 900) {
        turn(dx < 0 ? 1 : -1);
        return;
      }
      if (!s.moved && elapsed < TAP_MAX_MS) handleTap(t, win, e.target);
    }, {passive: true});

    doc.addEventListener("touchcancel", abandon, {passive: true});

    doc.addEventListener("selectionchange", function () {
      if (selectionOpen && !hasSelection(win)) {
        selectionOpen = false;
        send("selectionCleared", {});
      }
    });
  }

  function handleTap(touch, win, target) {
    if (target && target.closest && target.closest("a[href]")) return;
    var frame = win.frameElement;
    var offset = frame ? frame.getBoundingClientRect().left : 0;
    var x = offset + touch.clientX;
    var ratio = x / Math.max(1, window.innerWidth);
    var zone = ratio < EDGE_ZONE ? -1 : ratio > 1 - EDGE_ZONE ? 1 : 0;
    // Wait briefly so a highlight tap or a double-tap word selection wins.
    setTimeout(function () {
      if (Date.now() - lastHighlightTap < 500 || hasSelection(win)) return;
      if (zone !== 0 && !isScrolled()) {
        turn(zone);
      } else {
        send("tap", {zone: zone});
      }
    }, zone === 0 ? 300 : 120);
  }

  // --------------------------------------------------------------- content

  function onContent(contents) {
    injectStyle(contents.document);
    attachGestures(contents);
  }

  function onSelected(cfiRange, contents) {
    var range;
    try {
      range = contents.range(cfiRange);
    } catch (e) {
      return;
    }
    var text = range ? range.toString().replace(/\s+/g, " ").trim() : "";
    if (!text) return;
    var rect = range.getBoundingClientRect();
    var frame = contents.window.frameElement;
    var frameRect = frame ? frame.getBoundingClientRect() : {left: 0, top: 0};
    selectionOpen = true;
    send("selected", {
      cfiRange: cfiRange,
      text: text,
      chapterTitle: lastLocation && lastLocation.start ? chapterTitleForLocation(lastLocation.start) : "",
      rect: {
        left: rect.left + frameRect.left,
        top: rect.top + frameRect.top,
        width: rect.width,
        height: rect.height
      }
    });
  }

  function isCfi(target) {
    return typeof target === "string" && target.indexOf("epubcfi(") === 0;
  }

  // epub.js's continuous (scrolled) manager positions a CFI before the
  // surrounding chapters finish loading, so the target drifts as content is
  // inserted above it. Re-align a few times while layout settles, but stop as
  // soon as the reader scrolls on their own.
  var alignToken = 0;
  function alignScrolled(cfi) {
    if (!isScrolled() || !isCfi(cfi)) return;
    var token = ++alignToken;
    var expected = null;
    function align() {
      if (token !== alignToken || !rendition || !rendition.manager) return;
      var container = rendition.manager.container;
      if (expected !== null && Math.abs(container.scrollTop - expected) > 4) return;
      try {
        var section = book.spine.get(new ePub.CFI(cfi).spinePos);
        var view = section && rendition.manager.views.find(section);
        var position = view && view.locationOf(cfi);
        if (!position) return;
        var top = view.element.getBoundingClientRect().top - container.getBoundingClientRect().top +
          container.scrollTop + position.top - 8;
        container.scrollTop = Math.max(0, top);
        expected = container.scrollTop;
      } catch (e) { /* view not ready yet */ }
    }
    [0, 350, 900, 1800].forEach(function (delay) {
      setTimeout(align, delay);
    });
  }

  function go(target) {
    return Promise.resolve(rendition.display(target)).then(function () {
      alignScrolled(target);
    });
  }

  function createRendition(target) {
    var scrolled = isScrolled();
    applyPageChrome();
    rendition = book.renderTo(viewer(), {
      width: "100%",
      height: "100%",
      flow: scrolled ? "scrolled" : "paginated",
      manager: scrolled ? "continuous" : "default",
      spread: "none",
      minSpreadWidth: 100000,
      allowScriptedContent: false
    });
    rendition.hooks.content.register(onContent);
    rendition.on("relocated", function (location) {
      lastLocation = location;
      activity();
      report();
      scheduleSnapshot();
    });
    rendition.on("selected", onSelected);
    rendition.themes.fontSize(settings.fontSize + "px");
    redrawHighlights();
    return go(target || undefined).catch(function () {
      // A stale CFI (e.g. after the book file changed) must not strand the
      // reader on a blank screen.
      return rendition.display();
    });
  }

  function currentCfi() {
    return lastLocation && lastLocation.start ? lastLocation.start.cfi : undefined;
  }

  function rebuild(target) {
    if (rendition) {
      try {
        rendition.destroy();
      } catch (e) { /* ignore */ }
    }
    viewer().innerHTML = "";
    invalidateSnapshot();
    return createRendition(target);
  }

  function updateSettings(next) {
    var previous = settings;
    settings = Object.assign({}, settings, next || {});
    if (!rendition) return;
    invalidateSnapshot();
    var keep = currentCfi();
    if (previous.flow !== settings.flow) {
      clearSearchMark();
      rebuild(keep);
      return;
    }
    applyPageChrome();
    applyTypography();
    redrawHighlights();
    // Re-anchor on the pre-change position after epub.js re-flows, so a font
    // or margin change does not jump to a different page.
    setTimeout(function () {
      rendition.resize();
      if (keep) go(keep);
    }, 60);
  }

  // ---------------------------------------------------------------- search

  function search(query) {
    var token = ++searchToken;
    var needle = String(query || "").trim();
    if (needle.length < 2 || !book) {
      send("searchResults", {query: needle, results: [], done: true});
      return;
    }
    var results = [];
    var sections = book.spine.spineItems || [];
    var i = 0;
    function step() {
      if (token !== searchToken) return;
      if (i >= sections.length || results.length >= 300) {
        send("searchResults", {query: needle, results: results, done: true, truncated: results.length >= 300});
        return;
      }
      var section = sections[i++];
      Promise.resolve(section.load(book.load.bind(book))).then(function () {
        var found = section.find(needle) || [];
        var title = chapterTitleForIndex(section.index);
        found.forEach(function (match) {
          results.push({cfi: match.cfi, excerpt: String(match.excerpt || "").replace(/\s+/g, " ").trim(), chapterTitle: title});
        });
      }).catch(function () {}).then(function () {
        try {
          section.unload();
        } catch (e) { /* ignore */ }
        if (token === searchToken && i % 5 === 0) {
          send("searchProgress", {query: needle, scanned: i, total: sections.length, found: results.length});
        }
        step();
      });
    }
    step();
  }

  // --------------------------------------------------------------- startup

  function start(config) {
    if (typeof ePub !== "function") {
      send("error", {message: "The reading engine did not load."});
      return;
    }
    config = config || {};
    settings = Object.assign({}, settings, config.settings || {});
    bookmarks = config.bookmarks || [];
    (config.highlights || []).forEach(function (item) {
      highlights[item.cfiRange] = item;
    });
    applyPageChrome();

    book = ePub(config.url, {openAs: "epub"});
    book.opened.catch(function (error) {
      send("error", {message: "This book could not be opened: " + String(error && error.message || error)});
    });
    book.loaded.navigation.then(function (navigation) {
      tocByHref = {};
      tocItems = flattenToc(navigation.toc, 0, []);
      send("toc", {items: tocItems});
      report();
    }).catch(function () {
      send("toc", {items: []});
    });

    createRendition(config.cfi).then(function () {
      send("ready", {flow: settings.flow});
    });

    book.ready.then(function () {
      if (config.locations) {
        try {
          book.locations.load(config.locations);
          locationsReady = book.locations.length() > 0;
        } catch (e) {
          locationsReady = false;
        }
      }
      if (locationsReady) {
        send("locationsReady", {cached: true, total: book.locations.length()});
        report();
        return;
      }
      // Generated after first paint so opening a book stays fast.
      return book.locations.generate(1200).then(function () {
        locationsReady = true;
        send("locationsReady", {cached: false, total: book.locations.length(), locations: book.locations.save()});
        report();
      });
    }).catch(function (error) {
      send("jsError", {message: "Locations failed: " + String(error)});
    });
  }

  window.readerCommand = function (command) {
    var args = (command && command.args) || {};
    var name = command && command.name;
    if (!rendition || !book) return;
    switch (name) {
      case "next":
        turn(1);
        break;
      case "prev":
        turn(-1);
        break;
      case "nextChapter":
        goToChapter(1);
        break;
      case "prevChapter":
        goToChapter(-1);
        break;
      case "display":
        if (typeof args.percentage === "number" && locationsReady) {
          go(book.locations.cfiFromPercentage(Math.min(1, Math.max(0, args.percentage))));
        } else if (args.cfi || args.href) {
          go(args.cfi || args.href).then(function () {
            if (args.mark && args.cfi) markSearchResult(args.cfi);
          });
        }
        break;
      case "updateSettings":
        updateSettings(args.settings);
        break;
      case "addHighlight":
        drawHighlight(args);
        break;
      case "removeHighlight":
        removeHighlight(args.cfiRange);
        break;
      case "setBookmarks":
        bookmarks = args.cfis || [];
        report();
        break;
      case "clearSelection":
        clearSelection();
        break;
      case "search":
        search(args.query);
        break;
      case "clearSearch":
        searchToken++;
        clearSearchMark();
        break;
      default:
        send("jsError", {message: "Unknown reader command: " + name});
    }
  };

  window.startReader = start;
  send("bridgeReady", {});
}());

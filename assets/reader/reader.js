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
  }

  function markSearchResult(cfi) {
    clearSearchMark();
    searchMark = cfi;
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

  function setOffset(dx, animate) {
    var v = viewer();
    v.style.transition = animate ? "transform 160ms ease-out, opacity 160ms ease-out" : "none";
    v.style.transform = dx ? "translateX(" + dx + "px)" : "";
    v.style.opacity = dx ? String(Math.max(0.55, 1 - Math.abs(dx) / 500)) : "1";
  }

  function turn(direction) {
    if (!rendition || turning) return;
    if (isScrolled()) {
      goToChapter(direction);
      return;
    }
    if (lastLocation && ((direction > 0 && lastLocation.atEnd) || (direction < 0 && lastLocation.atStart))) {
      setOffset(0, true);
      send("edgeReached", {end: direction > 0});
      return;
    }
    turning = true;
    var v = viewer();
    var out = direction > 0 ? -1 : 1;
    v.style.transition = "transform 130ms ease-in, opacity 130ms ease-in";
    v.style.transform = "translateX(" + (out * 48) + "px)";
    v.style.opacity = "0.2";
    setTimeout(function () {
      var move = direction > 0 ? rendition.next() : rendition.prev();
      Promise.resolve(move).catch(function () {}).then(function () {
        v.style.transition = "none";
        v.style.transform = "translateX(" + (-out * 48) + "px)";
        void v.offsetWidth;
        v.style.transition = "transform 170ms ease-out, opacity 170ms ease-out";
        v.style.transform = "";
        v.style.opacity = "1";
        setTimeout(function () {
          turning = false;
        }, 180);
      });
    }, 130);
  }

  function goToChapter(direction) {
    if (!rendition || !lastLocation || !lastLocation.start) return;
    var target = book.spine.get((lastLocation.start.index || 0) + direction);
    if (!target) {
      send("edgeReached", {end: direction > 0});
      return;
    }
    var v = viewer();
    v.style.transition = "opacity 140ms ease-in";
    v.style.opacity = "0";
    setTimeout(function () {
      Promise.resolve(rendition.display(target.href)).catch(function () {}).then(function () {
        v.style.transition = "opacity 180ms ease-out";
        v.style.opacity = "1";
      });
    }, 140);
  }

  function attachGestures(contents) {
    var doc = contents.document;
    var win = contents.window;
    var start = null;

    doc.addEventListener("touchstart", function (e) {
      activity();
      if (e.touches.length !== 1) {
        start = null;
        return;
      }
      var t = e.touches[0];
      start = {x: t.clientX, y: t.clientY, time: Date.now(), hadSelection: hasSelection(win) || selectionOpen, moved: false};
    }, {passive: true});

    doc.addEventListener("touchmove", function (e) {
      if (!start || e.touches.length !== 1) return;
      var t = e.touches[0];
      var dx = t.clientX - start.x;
      var dy = t.clientY - start.y;
      if (Math.abs(dx) > 10 || Math.abs(dy) > 10) start.moved = true;
      if (!isScrolled() && !start.hadSelection && !turning && Math.abs(dx) > Math.abs(dy) && !hasSelection(win)) {
        setOffset(dx * 0.35, false);
      }
    }, {passive: true});

    doc.addEventListener("touchend", function (e) {
      if (!start) return;
      var s = start;
      start = null;
      var t = e.changedTouches[0];
      var dx = t.clientX - s.x;
      var dy = t.clientY - s.y;
      var elapsed = Date.now() - s.time;
      if (s.hadSelection || hasSelection(win)) {
        setOffset(0, true);
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
      var horizontal = Math.abs(dx) > Math.abs(dy) * (isScrolled() ? 2 : 1.2);
      if (Math.abs(dx) > SWIPE_DISTANCE && horizontal && elapsed < 900) {
        turn(dx < 0 ? 1 : -1);
        return;
      }
      if (!isScrolled()) setOffset(0, true);
      if (!s.moved && elapsed < TAP_MAX_MS) handleTap(t, win, e.target);
    }, {passive: true});

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
    return createRendition(target);
  }

  function updateSettings(next) {
    var previous = settings;
    settings = Object.assign({}, settings, next || {});
    if (!rendition) return;
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

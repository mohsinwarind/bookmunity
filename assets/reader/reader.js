(function () {
  let book;
  let rendition;

  function send(event, payload) {
    if (window.flutter_inappwebview) {
      window.flutter_inappwebview.callHandler("readerEvent", {
        event: event,
        payload: payload || {}
      });
    }
  }

  function start(url, cfi) {
    if (typeof ePub !== "function") {
      send("error", {message: "EPUB ENGINE DID NOT LOAD"});
      return;
    }
    const viewer = document.getElementById("viewer");
    if (viewer) {
      viewer.style.minHeight = "100vh";
      viewer.style.height = "100%";
    }

    book = ePub(url, {openAs: "epub"});
    rendition = book.renderTo(viewer, {
      width: "100%",
      height: "100%",
      flow: "scrolled-doc",
      manager: "continuous",
      spread: "none",
      allowScriptedContent: true
    });
    rendition.themes.default({
      body: {
        "font-family": "Georgia, serif !important",
        "line-height": "1.7 !important",
        "color": "#0a0a0a !important",
        "background": "transparent !important"
      }
    });
    rendition.on("relocated", function (location) {
      const start = location.start || {};
      send("relocated", {
        cfi: start.cfi || "",
        percentage: book.locations.percentageFromCfi(start.cfi || 0) || 0,
        chapterHref: start.href || "",
        chapterTitle: start.label || "",
        page: start.displayed ? start.displayed.page : 0,
        totalPages: start.displayed ? start.displayed.total : 0
      });
    });
    rendition.on("selected", function (cfiRange, contents) {
      const range = contents.range(cfiRange);
      const rect = range.getBoundingClientRect();
      send("selected", {
        cfiRange: cfiRange,
        text: range.toString(),
        rect: {left: rect.left, top: rect.top, width: rect.width, height: rect.height}
      });
    });
    book.ready.then(function () {
      send("ready", {});
      return book.locations.generate(1024);
    }).then(function () {
      send("locationsReady", {});
      return rendition.display(cfi || undefined);
    }).catch(function (error) {
      send("error", {message: String(error)});
    });
  }

  window.readerCommand = function (command) {
    const args = command.args || {};
    if (!rendition) return;
    if (command.name === "next") rendition.next();
    if (command.name === "prev") rendition.prev();
    if (command.name === "display") rendition.display(args.cfi || args.href);
    if (command.name === "setTheme") {
      document.body.className = args.theme || "";
      rendition.themes.override("color", args.theme === "dark" ? "#f4f0e6" : args.theme === "sepia" ? "#3b2a1a" : "#0a0a0a", true);
      rendition.themes.override("background", "transparent", true);
    }
    if (command.name === "setFontSize") rendition.themes.fontSize(String(args.size) + "px");
    if (command.name === "setLineHeight") rendition.themes.override("line-height", String(args.height), true);
    if (command.name === "setMargins") document.getElementById("viewer").style.padding = String(args.value) + "px";
  };

  window.startReader = start;
}());

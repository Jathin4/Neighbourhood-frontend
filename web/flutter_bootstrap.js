{{flutter_js}}
{{flutter_build_config}}
_flutter.loader.load({
  config: {
    // Flutter's web renderer is CanvasKit-only as of this SDK version (the old
    // "html" renderer was removed) — it fetches its runtime from gstatic.com
    // by default. This sandbox's browser can't reach that CDN, so point it at
    // the CanvasKit build already bundled locally under build/web/canvaskit/.
    canvasKitBaseUrl: "canvaskit/"
  }
});

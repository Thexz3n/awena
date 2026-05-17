{{flutter_js}}
{{flutter_build_config}}

// Only load the service worker if the browser context is secure (HTTPS or localhost)
if (window.isSecureContext) {
  _flutter.loader.load({
    serviceWorkerSettings: {
      serviceWorkerVersion: {{flutter_service_worker_version}},
    },
  });
} else {
  console.warn("Insecure context detected. Service Worker load bypassed to prevent crash.");
  _flutter.loader.load();
}

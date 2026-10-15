{{flutter_js}}
{{flutter_build_config}}

function showLoadError() {
  const boot = document.getElementById('boot');
  const caption = document.getElementById('boot-caption');
  const retry = document.getElementById('boot-retry');
  if (!boot || !caption || !retry) return;
  caption.textContent = 'No pudimos abrir la app. Revisa tu conexión e inténtalo de nuevo.';
  retry.hidden = false;
}

// Con onEntrypointLoaded el SDK no devuelve una promesa que rechace si el
// script de entrada falla; capturamos también ese error de recurso.
window.addEventListener('error', function (event) {
  const target = event.target;
  if (target?.tagName === 'SCRIPT' && target.src &&
      new URL(target.src, document.baseURI).pathname.endsWith('/main.dart.js')) {
    showLoadError();
  }
}, true);

(async function () {
  // Migración de la antigua caché offline de Flutter. Solo se retiran sus
  // recursos estáticos: las sesiones, preferencias y borradores se conservan.
  try {
    if ('serviceWorker' in navigator) {
      const scope = new URL('.', document.baseURI).href;
      const registrations = await navigator.serviceWorker.getRegistrations();
      const legacy = registrations.filter((registration) =>
        registration.scope === scope &&
        [registration.active, registration.waiting, registration.installing]
          .some((worker) => worker && new URL(worker.scriptURL).pathname.endsWith('/flutter_service_worker.js'))
      );
      for (const registration of legacy) await registration.unregister();
      if (legacy.length && typeof caches !== 'undefined') {
        for (const name of ['flutter-app-cache', 'flutter-temp-cache', 'flutter-app-manifest']) {
          await caches.delete(name);
        }
      }
    }
  } catch (_) {
    // Navegadores con almacenamiento restringido siguen pudiendo cargar.
  }

  // La caché HTTP normal del navegador revalida los archivos de cada release.
  // No se registra un nuevo worker offline para esta app de datos remotos.
  await _flutter.loader.load({
    onEntrypointLoaded: async function (initializer) {
      try {
        const runner = await initializer.initializeEngine();
        await runner.runApp();
      } catch (_) {
        showLoadError();
      }
    },
  });
})().catch(showLoadError);

import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import vm from 'node:vm';
import test from 'node:test';

const source = (await readFile(new URL('../../web/flutter_bootstrap.js', import.meta.url), 'utf8'))
  .replace('{{flutter_js}}', '').replace('{{flutter_build_config}}', '');

async function run({ storageDenied = false, loadFails = false, engineFails = false, hasLegacy = true, entrypointFails = false } = {}) {
  const actions = [];
  const caption = { textContent: '' };
  const retry = { hidden: true };
  const listeners = {};
  const boot = { appendChild: (button) => actions.push(button.textContent) };
  const context = {
    URL,
    window: { addEventListener: (name, callback) => { listeners[name] = callback; } },
    navigator: { serviceWorker: { getRegistrations: async () => {
      if (storageDenied) throw new Error('Denied');
      return [
        ...(hasLegacy ? [{ scope: 'https://gym.test/', active: { scriptURL: 'https://gym.test/flutter_service_worker.js' },
          unregister: async () => actions.push('unregister') }] : []),
        { scope: 'https://gym.test/', active: { scriptURL: 'https://gym.test/another-worker.js' },
          unregister: async () => actions.push('unrelated') },
      ];
    } } },
    caches: { delete: async (name) => actions.push(name) },
    document: { baseURI: 'https://gym.test/',
      getElementById: (id) => ({ boot, 'boot-caption': caption, 'boot-retry': retry })[id] ?? null,
      createElement: () => ({}),
    },
    location: { reload() {} },
    _flutter: { loader: { load: (options) => {
      actions.push('load');
      if (loadFails) return Promise.reject(new Error('Network'));
      if (entrypointFails) {
        listeners.error?.({ target: { tagName: 'SCRIPT', src: 'https://gym.test/main.dart.js' } });
        return undefined;
      }
      void options.onEntrypointLoaded({ initializeEngine: async () => {
        actions.push('engine');
        if (engineFails) throw new Error('Engine');
        return { runApp: async () => actions.push('runApp') };
      } });
    } } },
  };
  await vm.runInNewContext(source, context);
  await new Promise(setImmediate);
  return { actions, caption, retry };
}

test('retira solo la caché de Flutter antes de cargar la versión actual', async () => {
  const { actions } = await run();
  assert.deepEqual(actions, [
    'unregister', 'flutter-app-cache', 'flutter-temp-cache', 'flutter-app-manifest', 'load', 'engine', 'runApp',
  ]);
});

test('el almacenamiento bloqueado no impide abrir la app', async () => {
  const { actions } = await run({ storageDenied: true });
  assert.deepEqual(actions, ['load', 'engine', 'runApp']);
});

test('sin worker de Flutter no borra otras cachés ni registros', async () => {
  const { actions } = await run({ hasLegacy: false });
  assert.deepEqual(actions, ['load', 'engine', 'runApp']);
});

test('un fallo al iniciar el motor permite reintentar', async () => {
  const { actions, caption, retry } = await run({ engineFails: true });
  assert.equal(retry.hidden, false);
  assert.equal(actions.includes('runApp'), false);
  assert.equal(caption.textContent, 'No pudimos abrir la app. Revisa tu conexión e inténtalo de nuevo.');
});

test('un fallo de carga ofrece volver a intentar', async () => {
  const { caption, retry } = await run({ loadFails: true });
  assert.equal(retry.hidden, false);
  assert.equal(caption.textContent, 'No pudimos abrir la app. Revisa tu conexión e inténtalo de nuevo.');
});

test('un 404 de main.dart.js muestra el reintento aunque el SDK no retorne Promise', async () => {
  const { caption, retry } = await run({ entrypointFails: true });
  assert.equal(retry.hidden, false);
  assert.equal(caption.textContent, 'No pudimos abrir la app. Revisa tu conexión e inténtalo de nuevo.');
});

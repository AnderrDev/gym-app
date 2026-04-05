# gym_flutter

A new Flutter project for tracking gym workouts.

## Revisa la documentación

Para más detalles sobre el proyecto y su arquitectura, consulta la carpeta `docs`:

- [Contexto Maestro para Agentes IA](docs/AGENT_CONTEXT.md)
- [Documentación del Proyecto](docs/DOCUMENTACION.md)
- [Configuración de Supabase](docs/supabase.md)
- [Plan de Servicios Supabase](docs/SUPABASE_SERVICES_PLAN.md)
- [Edge Functions (implementadas)](docs/EDGE_FUNCTIONS.md)

## Ejecutar con Supabase

La app espera credenciales mediante `--dart-define`.

Ejemplo:

```bash
flutter run \
	--dart-define=SUPABASE_URL=https://your-project-ref.supabase.co \
	--dart-define=SUPABASE_ANON_KEY=your-anon-key
```

## Getting Started

This project is a starting point for a Flutter application.
...

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# Configuración de Supabase: Smart Gym Tracker

Este documento detalla la estructura de la base de datos y la configuración de Supabase utilizada en el proyecto.

## Esquema de Base de Datos

La base de datos utiliza PostgreSQL y está organizada para manejar usuarios, rutinas, ejercicios y sesiones de entrenamiento.

### Tablas Principales

1.  **`profiles`**: Extensión de la tabla `auth.users` de Supabase. Almacena información adicional del usuario.
    *   `id`: UUID (Referencia a `auth.users`).
    *   `full_name`: Nombre completo del usuario.

2.  **`routines`**: Plantillas de entrenamiento creadas por los usuarios.
    *   `id`: UUID (Generado automáticamente).
    *   `name`: Nombre de la rutina.
    *   `creator_id`: ID del perfil que creó la rutina.

3.  **`exercises`**: Catálogo maestro de ejercicios disponibles.
    *   `id`: UUID.
    *   `name`: Nombre del ejercicio.
    *   `description`: Descripción breve.

4.  **`user_routines`**: Tabla de relación que asigna rutinas a usuarios específicos.

5.  **`routine_exercises`**: Configuración de ejercicios dentro de una rutina (orden, series objetivo, repeticiones, peso).

6.  **`workout_sessions`**: Registro de una sesión de entrenamiento activa o completada.
    *   `started_at`: Fecha/hora de inicio.
    *   `completed_at`: Fecha/hora de finalización.
    *   `total_volume`: Volumen total levantado.

7.  **`set_logs`**: El registro detalle de cada serie realizada durante una sesión.
    *   `actual_weight`: Peso utilizado.
    *   `actual_reps`: Repeticiones logradas.

## Seguridad (Row Level Security - RLS)

Todas las tablas tienen habilitado RLS para garantizar que los usuarios solo puedan acceder y modificar sus propios datos.

*   **Profiles**: Solo el dueño del perfil puede insertarlo o actualizarlo. La lectura es pública (configurable).
*   **Sessions & Logs**: Solo el usuario propietario de la sesión puede ver, insertar o actualizar los registros relacionados.
*   **Routines**: Las rutinas son visibles para todos (lectura), pero solo el creador puede gestionarlas.

## Integración con Flutter

El proyecto utiliza el paquete `supabase_flutter` para la comunicación con el backend. La inicialización se encuentra en `lib/core/config/supabase_config.dart` (o similar) y utiliza inyección de dependencias para proveer el cliente de Supabase a los repositorios.

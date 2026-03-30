# Documentación del Proyecto: Smart Gym Tracker

## Índice
1. [Descripción General](#descripción-general)
2. [Objetivos del Proyecto](#objetivos-del-proyecto)
3. [Stack Tecnológico y Arquitectura](#stack-tecnológico-y-arquitectura)
4. [Avances Actuales](#avances-actuales)
5. [Próximos Pasos](#próximos-pasos)

---

## Descripción General
**Smart Gym Tracker** es una aplicación móvil desarrollada en Flutter diseñada para ayudar a los usuarios a registrar, gestionar y analizar sus entrenamientos en el gimnasio. La aplicación se enfoca en proporcionar una experiencia de usuario fluida y una arquitectura sólida que permita escalar la aplicación con nuevas funcionalidades en el futuro.

## Objetivos del Proyecto

### Objetivos Principales (MVP - Producto Mínimo Viable)
- **Autenticación Segura:** Permitir a los usuarios crear cuentas, iniciar sesión y mantener sus datos seguros y sincronizados.
- **Gestión de Entrenamientos:** Facilitar el inicio de sesiones de entrenamiento activas donde los usuarios pueden registrar los ejercicios, series (sets) y repeticiones.
- **Panel de Control (Dashboard):** Ofrecer una pantalla principal donde el usuario pueda acceder rápidamente a sus rutinas y ver un resumen de su actividad.
- **Arquitectura Escalable:** Implementar *Clean Architecture* para asegurar de que el código sea mantenible, testeable y fácilmente expansible.
- **Navegación Moderna:** Utilizar un sistema de enrutamiento robusto para manejar la navegación basada en estados de autenticación y transiciones fluidas.

## Stack Tecnológico y Arquitectura
- **Framework:** Flutter
- **Backend/BaaS:** Supabase (Autenticación y Base de Datos)
- **Gestor de Estado:** BLoC (Business Logic Component) mediante `flutter_bloc`
- **Enrutamiento:** `go_router` (Enrutamiento declarativo moderno)
- **Inyección de Dependencias:** `get_it` (Service Locator)
- **Patrón Arquitectónico:** Clean Architecture (Capas distribuidas en: Core, Domain, Data, Presentation).

## Avances Actuales

Hasta la fecha, se ha completado la configuración base del proyecto y se han implementado exitosamente las funcionalidades clave para el MVP:

### 1. Configuración del Proyecto y Arquitectura Inicial
- Inicialización del proyecto Flutter.
- Estructuración de directorios siguiendo los principios de *Clean Architecture*.
- Configuración de la inyección de dependencias centralizada (`injection_container.dart`).
- Integración e inicialización del cliente de Supabase (`supabase_config.dart`).
- Implementación de un sistema de navegación global mediante `go_router` (`app_router.dart`), incluyendo guardias de ruta para proteger vistas requeridas de inicio de sesión.
- Definición de estilos y paleta de colores global (`app_colors.dart`).

### 2. Módulo de Autenticación (`features/auth`)
- **Capa de Dominio y Datos:** Configuración de repositorios y conexión con Supabase Auth.
- **Gestión de Estado:** Implementación de `AuthBloc` para manejar los estados de sesión (Iniciado, Cerrado, Cargando, Error).
- **Presentación:** 
  - Desarrollo de la pantalla de Inicio de Sesión (`login_page.dart`).
  - Desarrollo de la pantalla de Registro (`register_page.dart`).

### 3. Módulo de Entrenamiento (`features/workout`)
- **Capa de Dominio y Datos:** Definición de entidades y modelos esenciales (ej. `set_log.dart`, `set_log_model.dart`).
- **Gestión de Estado:** Implementación de `WorkoutBloc` para manejar el progreso y las métricas de la actividad física actual.
- **Presentación:**
  - Desarrollo de la pantalla Principal / Dashboard (`dashboard_page.dart`).
  - Desarrollo de la pantalla de Entrenamiento Activo (`active_workout_page.dart`) para registrar series y ejercicios en tiempo real.
  - Creación de widgets reutilizables de UI (ej. `exercise_card.dart`).

## Próximos Pasos
*Esta sección se actualizará conforme avance el desarrollo de futuras iteraciones.*
- Optimización y refinamiento de la Interfaz de Usuario (UI) y Experiencia de Usuario (UX).
- Adición de historial detallado de entrenamientos.
- Visualización de gráficas y estadísticas de progreso personal.
- Pruebas unitarias e integrales para garantizar la resiliencia del código.

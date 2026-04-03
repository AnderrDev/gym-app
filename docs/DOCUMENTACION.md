# Documentación y Planificación del Proyecto: Smart Gym Tracker

## Índice
1. [Visión y Objetivo del Proyecto](#visión-y-objetivo-del-proyecto)
2. [Funcionalidades Principales (MVP)](#funcionalidades-principales-mvp)
3. [Stack Tecnológico y Arquitectura](#stack-tecnológico-y-arquitectura)
4. [Avances Actuales](#avances-actuales)
5. [Próximos Pasos en el Desarrollo](#próximos-pasos-en-el-desarrollo)

---

## Visión y Objetivo del Proyecto
**Smart Gym Tracker** es una aplicación móvil diseñada para ayudar a los usuarios a generar y seguir rutinas de entrenamiento, aplicando el concepto fundamental de la **sobrecarga progresiva**. 

El objetivo principal es responder a la necesidad de saber exactamente qué hacer cada día en el gimnasio y cómo mejorar. Si un usuario tiene una rutina de 4 días enfocada en distintos grupos musculares (ej. Lunes: Pecho), la aplicación debe indicarle qué ejercicios le tocan, permitirle registrar las series completadas (peso y repeticiones) y mostrarle inmediatamente qué hizo la semana pasada en ese mismo ejercicio para motivarlo a aumentar el peso o sacar una repetición más.

## Funcionalidades Principales (MVP)

### 1. Gestión de Rutinas y Días de Entrenamiento
- **Estructuración de Días:** Capacidad de crear rutinas divididas en múltiples días (ej. 3, 4 o 5 días por semana) enfocados en diferentes grupos musculares.
- **Asignación de Ejercicios:** Asignar una lista de ejercicios específicos para cada día de entrenamiento.

### 2. Entrenamiento Activo y Registro Libre
- **Acceso Inmediato e Ilimitado:** El usuario puede seleccionar y abrir cualquier día de su rutina (pasado, presente o futuro) y comenzar a interactuar de inmediato sin botones de "iniciar" o límites de tiempo.
- **Registro Interactivo:** Capacidad de ir marcando las series completadas de cada ejercicio, ingresando dinámicamente el **peso utilizado** y el **número de repeticiones**.
- **Temporizador de Descanso Automático:** Al marcar una serie como terminada, la app iniciará automáticamente un temporizador de descanso, ayudando al usuario a cronometrar sus tiempos de recuperación entre series.

### 3. Historial de Retroalimentación y Evolución
- **Comparación en Vivo:** Cada vez que el usuario va a hacer un ejercicio, la app le muestra el peso y repeticiones logrados en su sesión anterior para ese mismo ejercicio.
- **Motivación para Sobrecarga:** Ayudar al usuario a asegurar progreso, incitándolo a subir el peso o aumentar las repeticiones para superar su propia marca (Pre-llenado de datos de la sesión anterior).
- **Vista de Historial Semanal:** Pantalla dedicada a revisar el trabajo realizado en semanas anteriores, permitiendo al usuario observar su constancia y la evolución de sus pesos a lo largo del tiempo.

### 4. Base Técnica Sólida
- Autenticación Segura (creación de cuentas, login).
- Persistencia de datos en la nube y sincronización.
- Arquitectura limpia y escalable.

## Stack Tecnológico y Arquitectura
- **Framework:** Flutter
- **Backend/BaaS:** Supabase (Autenticación y Base de Datos PostreSQL)
- **Gestor de Estado:** BLoC (Business Logic Component) mediante `flutter_bloc`
- **Enrutamiento:** `go_router` (Enrutamiento declarativo moderno)
- **Inyección de Dependencias:** `get_it` (Service Locator)
- **Patrón Arquitectónico:** Clean Architecture (Capas distribuidas en: Core, Domain, Data, Presentation).

## 🚀 Avances Actuales (MVP Backend y Core Flow)

Hasta la fecha, se ha completado la infraestructura base y todo el núcleo lógico de entrenamiento (Épicas 2, 3 y 4 del MVP):
- **Arquitectura Base**: Mantenimiento estricto de *Clean Architecture* e inyección de dependencias mediante `get_it`.
- **Autenticación y Seguridad**: Sistema completo conectado a Supabase Auth y protegido por `go_router`.
- **Modelado de Datos Optimizado (Supabase + Flutter)**: Estructura interactiva y finalizada entre `Routines`, `RoutineDays`, `Exercises` y `SetLogs`. Se añadieron índices a las Claves Foráneas (FK) y políticas de seguridad RLS óptimas para alta concurrencia.
- **Flujo de Entrenamiento Activo (Registro Libre)**:
  - `ExerciseCard` interactivo y modular que renderiza visualmente los requerimientos, permitiendo al usuario ingresar datos al vuelo sin fricciones.
  - El sistema detecta cuando una serie es terminada y persiste la información automáticamente en tiempo de ejecución.
- **Núcleo de Sobrecarga Progresiva**:
  - Implementación de un `RPC` en Supabase (`get_last_exercise_performance`) que extrae instantáneamente los récords de la semana pasada y los envía al cliente mediante `WorkoutRemoteDataSource`.
  - El formulario se pre-llena automáticamente para que el usuario conozca sus últimos PR (Personal Records) y compita contra ellos sin requerir recordarlos.
- **Temporizadores Dinámicos**: Implementados en la tarjeta, toman y asumen el valor específico por defecto para el ejercicio directamente desde backend, gestionando vibraciones hápticas para finalizar el descanso.
- **Refinamiento UI/UX Premium**: Transiciones de micro-animaciones usando `AnimatedSize`, `AnimatedSwitcher`, y `AnimatedContainer` para los botones de las series y las tarjetas expansibles.
- **Vista de Historial Evolutivo**: `DashboardPage` adaptada para que el usuario navegue en el tiempo viéndolo distribuido por un calendario de semanas (`Paginación Semanal`). Las vistas de los días completados son interactivas.
- **Sistema de Integridad y Coaching (HU-5)**:
  - **Completado Estricto**: Validación en tiempo real de series completadas vs. objetivo en `GetWeeklyPlan` y `RoutineDayPage`.
  - **Inmutabilidad del Historial**: Bloqueo de escritura para semanas pasadas y futuras, garantizando la fidelidad de los datos.
  - **Coaching Inteligente y Persistente**: Motor de análisis de desempeño que evalúa si se alcanzaron las metas de peso y repeticiones, ofreciendo sugerencias de ajuste (coaching).
  - **Historial de Feedback**: Los resultados del coaching se guardan en formato **JSONB** en la base de datos, permitiendo al usuario revisar consejos de sesiones pasadas para aplicar en su entrenamiento actual.
  - **Feedback Premium**: Modal de resumen estilizado y sección persistente en la rutina que presenta los resultados y consejos de entrenamiento.

## ⏳ Próximos Pasos en el Desarrollo (Lo que falta)

A partir de este punto, el motor funcional de ejecución e historial de entrenamiento está finalizado. Las tareas pendientes se centran en el ecosistema alrededor del entrenamiento:

1. **Creación de Interfaz de Creación de Rutina (Admin / Planner):**
   - **Actualmente:** La app lee y procesa perfectamente rutinas asignadas al usuario desde base de datos (con nuestro mock de pruebas en PostgreSQL).
   - **Falta:** Desarrollar el flujo en la app para que un usuario pueda crear sus propias rutinas paso a paso. Interfaz para nombrar "Día 1, Día 2...", y mediante un catálogo visual agregar y programar cada ejercicio.
2. **Dashboard Gráfico de Analíticas (Opcional a Evaluar):**
   - Aunque la navegación de semanas está lograda, considerar incorporar un pequeño widget de gráficas `ui-ux-pro-max` (Líneas o Barras) donde se demuestre la tendencia de rendimiento o volumen total manejado durante los últimos días para generar mayor enganche visual de los resultados logrados.

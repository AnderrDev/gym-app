# Historias de Usuario: Smart Gym Tracker

Este documento consolida las Historias de Usuario (HUs) que conforman el alcance del proyecto. Desde la infraestructura base del MVP hasta las características premium de análisis predictivo.

## HU-1: Estructuración y Gestión de Rutinas
**Como** usuario de Smart Gym Tracker,  
**Quiero** poder visualizar y acceder a mis rutinas de entrenamiento divididas en múltiples días,  
**Para** saber con claridad qué grupo muscular o enfoque me toca entrenar cada día de la semana.

### Criterios de Aceptación:
- El sistema debe soportar un modelo de datos estructurado en Rutinas (ej. "Rutina Hipertrofia"), Días (ej. "Día 1: Pecho"), y Ejercicios específicos asignados a esos días.
- La pantalla principal (`DashboardPage`) debe presentar de manera clara la planificación de rutinas asignadas al usuario activo.

---

## HU-2: Entrenamiento Activo Diferido (Registro Libre)
**Como** usuario que está en el gimnasio,  
**Quiero** poder abrir directamente un día de mi rutina y empezar a registrar los pesos y repeticiones sin tener que darle a un botón de "iniciar",  
**Para** no perder tiempo configurando la app y enfocarme exclusivamente en mis levantamientos.

### Criterios de Aceptación:
- Ausencia de un botón global de iniciar/terminar para permitir acceso directo a las planillas diarias.
- El usuario podrá interactuar independientemente con las tarjetas (`ExerciseCard`) de cada ejercicio, ingresando peso y repeticiones.
- La aplicación persistirá automáticamente el progreso de las series a la base de datos de manera silente al confirmarlas (`SetLog`).

---

## HU-3: Temporizadores Dinámicos y Feedback Háptico
**Como** usuario que busca optimizar la hipertrofia,  
**Quiero** que la aplicación mida mis tiempos de descanso automáticamente después de cada serie,  
**Para** asegurar una recuperación óptima del músculo antes de mi próximo levantamiento.

### Criterios de Aceptación:
- Tras confirmar una serie en la `ExerciseCard`, iniciará un contador regresivo.
- El tiempo por defecto o asignado debe extraerse del backend por cada tipo de ejercicio.
- Se debe proveer al usuario un botón rápido de "Saltar descanso".
- El dispositivo utilizará vibraciones (haptic feedback) 3 segundos antes del final del descanso, seguido de una vibración pesada cuando el descanso haya culminado.

---

## HU-4: Retroalimentación y Sobrecarga Progresiva
**Como** usuario motivado,  
**Quiero** ver mis resultados anteriores mientras ejecuto mi entrenamiento,  
**Para** poder saber exactamente qué peso usar y tratar de sacar una repetición extra (sobrecarga progresiva).

### Criterios de Aceptación:
- Sistema `Offline-first` para cache y lectura rápida de resultados pasados.
- Cada formulario de repeticiones y peso deberá autocompletarse por defecto visualizando el "Récord Personal (PR)" o el último levantamiento válido registrado por el usuario en sesiones previas para el mismo ejercicio.
- Paginación semanal en un calendario interactivo en el `DashboardPage` que me permita verificar qué hice en semanas, meses, o años pasados.

---

## HU-5: Integridad de Datos y Coaching de Rendimiento
**Como** usuario comprometido con mi progreso físico,  
**Quiero** que la aplicación valide que he completado mis objetivos y me dé retroalimentación de "coach" sobre mi desempeño,  
**Para** asegurar que mis registros sean honestos y saber exactamente cómo ajustar mi entrenamiento la próxima vez.

### Criterios de Aceptación:
- **Validación de Completado Estricto**: Una sesión solo pasará de "En progreso" a "Completada" si las series ingresadas cumplen con el objetivo de la rutina (`completed_sets >= target_sets`).
- **Inmutabilidad del Historial**: Días pasados y semanas antiguas se vuelven de funcionalidad `sólo-lectura`.
- **Feedback Inteligente (Coaching)**: Un motor generará una recomendación sobre ajustar el peso basado en los repeticiones logradas, entregando consejos ("Sube el peso", "Mejora la técnica").
- Este análisis es guardado en formato JSON (`coaching_analysis`) para consultarlo históricamente en la base de datos `workout_sessions`.

---

## HU-6: Historial Estadístico Interactivo (Premium)
**Como** usuario analítico,  
**Quiero** acceder a gráficas e indicadores estadísticos del historial de cada ejercicio desde mi rutina activa,  
**Para** visualizar detalladamente mi tendencia de fuerza y progreso a lo largo de las semanas sin salir de la tarjeta del ejercicio.

### Criterios de Aceptación:
- **Badge de Tendencia Visual**: Sustituir iconos estáticos por indicadores gráficos en el "Cockpit del Coach" del `ExerciseCard` revelando sugerencias anticipadas de forma de flechas (↑, ↓, →).
- **Métricas Visibles Instantáneas**: Exhibición visual clara dentro de cada tarjeta sobre la meta total recomendada (ej. TARGET: 100kg x 6 repeticiones).
- **BottomSheet Interactivo (ExerciseStatsSheet)**: Al clicar en el icono de Insights, la aplicación levantará un modal visual renderizando gráficas estilo fitness.
- **Gráficos Integrados (`fl_chart`)**:
    - Líneas de tendencia para **Peso Máximo** logrado.
    - Proyección **Estimada de 1RM** (Repetición Máxima).
    - Gráficos de barra para visualizar la alteración de la carga de **Volumen Total** efectuada.

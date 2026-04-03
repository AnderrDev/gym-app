# Prompt de Diseño UI/UX para Smart Gym Tracker

Este documento contiene el contexto y las instrucciones necesarias para proporcionar a una herramienta de generación de UI/UX (como v0 by Vercel, Stitch, o un diseñador humano) para crear las interfaces de la aplicación "Smart Gym Tracker".

---

## 📋 Copia y pega el siguiente prompt en la herramienta de diseño:

**Contexto del Proyecto:**
Actúa como un diseñador UI/UX Senior experto en aplicaciones de fitness y salud de alto rendimiento. Necesito que diseñes las pantallas principales para "Smart Gym Tracker", una aplicación móvil orientada a la **sobrecarga progresiva** y el **coaching inteligente**. 

El objetivo principal de la app es que el usuario sepa exactamente qué hacer en el gimnasio, registre sus datos de manera extremadamente rápida ("sin fricción") entre series, y supere sus marcas de la semana pasada apoyado por un asistente virtual proactivo.

**Estilo Visual y UX (Vibe):**
*   **Tema:** Dark mode por defecto (ideal para el entorno del gimnasio). Fondos oscuros profundos (negros, grises muy oscuros) con acentos de color vibrantes (ej. verde neón, naranja eléctrico o azul cian) para indicar progreso o llamadas a la acción.
*   **Sensación:** Premium, moderna, rápida, profesional, limpia y minimalista pero con datos muy claros. Al estilo de aplicaciones de alto nivel deportivo.
*   **Tipografía:** Moderna, sans-serif (ej. Inter, Roboto, Outfit). Los números (pesos, repeticiones, tiempos) deben ser grandes y altamente legibles.
*   **Componentes:** Uso de "cards" (tarjetas) con sutiles sombras o bordes difuminados (glassmorphism suave o neomorfismo oscuro). 

**Pantallas Clave a Diseñar (Total: 7 Pantallas):**

Por favor, genera el diseño de exactamente **7 pantallas clave**, las cuales conforman el ecosistema completo de la aplicación. Las pantallas requeridas son:

**1. Pantalla de Login (Autenticación)**
*   Una vista de inicio de sesión minimalista pero impactante.
*   Campos para Correo Electrónico y Contraseña.
*   Botón principal claro para "Iniciar Sesión".
*   Opción para "Recuperar contraseña" y un enlace sutil para "Crear cuenta nueva".

**2. Pantalla de Registro (Crear Cuenta)**
*   Estilo coherente con el Login.
*   Campos para Nombre, Correo y Contraseña.
*   Botón principal para "Registrarse".

**3. Lista de Mis Rutinas (Home de Rutinas)**
*   Pantalla donde el usuario ve las rutinas que ha creado o que tiene asignadas.
*   Tarjetas (Cards) para cada rutina (ej. "Rutina Hipertrofia 4 Días").
*   Botón destacado flotante (FAB) o principal superior para "Añadir Nueva Rutina".

**4. Creador/Editor de Rutinas (Planner) y Días**
*   Una pantalla dividida o de flujo donde el usuario pueda nombrar un nuevo día o rutina.
*   Flujo visual interactivo para "Añadir Ejercicio" desde un catálogo.
*   Controles intuitivos para configurar "Series Objetivo", "Repeticiones Objetivo" y "Tiempo de Descanso" por defecto para cada ejercicio añadido.

**5. Dashboard Semanal (Historial de Entrenamiento)**
*   Una vista tipo calendario o carrusel horizontal en la parte superior para cambiar entre semanas pasadas, la actual y futuras.
*   Vista general de los días de la semana (L, M, X, J, V, S, D). Los días con rutinas planeadas deben destacar. 
*   Los días completados deben tener indicadores visuales de éxito (anillos cerrados, checkmarks verdes).
*   Un widget gráfico (gráfico de líneas o barras limpio) que muestre la tendencia general del volumen de peso levantado en las últimas semanas.

**6. Pantalla de Entrenamiento Activo (La vista principal durante el gimnasio)**
*   **Encabezado:** Nombre del día (ej. "Día 1: Pecho y Tríceps") y un indicador de progreso (ej. 3/5 ejercicios completados).
*   **Tarjetas de Ejercicio (Exercise Cards):** Esta es la pieza central. Cada tarjeta debe mostrar:
    *   Nombre del ejercicio e imagen/ícono sutil.
    *   **Contexto Histórico:** Un indicador visual muy claro de lo que el usuario hizo la semana pasada (ej. "Semana pasada: 4 series x 10 reps @ 80kg") para incitar a superarlo.
    *   **Filas de Registro:** Filas interactivas para cada serie (Set 1, Set 2...). Cada fila debe tener campos de *input* prominentes y fáciles de tocar para "Peso (kg)" y "Repeticiones".
    *   Un botón de "Completar Serie" (Checkmark) que al presionarlo visualmente confirme la acción e inicie un temporizador.
    *   **Temporizador de Descanso:** Un componente visual compacto e integrado en la tarjeta que muestre la cuenta regresiva del descanso tras completar una serie.

**7. Modal de Feedback y Coaching (Al finalizar la sesión)**
*   Un modal o pantalla de superposición (overlay) premium que aparece cuando el usuario termina su entrenamiento.
*   **Mensaje de Estado:** Éxito/Felicidades si superó sus marcas, o ánimos si estuvo por debajo.
*   **Resumen de Datos:** Volumen total levantado, PRs (Récords Personales) rotos.
*   **Caja de "Inteligencia Artificial" / Coaching:** Una alerta estilizada que contenga consejos basados en su rendimiento. Ej. "Notamos fatiga en el Press de Banca, sugerimos bajar el peso un 5% la próxima sesión" o "¡Excelente progreso! Intenta subir 2.5kg en tu próximo entrenamiento".

**Reglas de Diseño Adicionales:**
*   Asegúrate de que los botones principales ("Call to Action") estén en la zona inferior de la pantalla o sean fácilmente alcanzables con el pulgar.
*   Diseña pensando en que el usuario tiene las manos sudadas o cansadas: los *tap targets* (áreas de toque) para los inputs numéricos deben ser grandes.
*   Muestra estados: qué pasa cuando un input está activo, o cuando una serie está completada vs. pendiente.

---
*Fin del Prompt*

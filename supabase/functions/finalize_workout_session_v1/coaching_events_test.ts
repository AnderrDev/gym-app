import { toCoachingEvents } from "./coaching_events.ts";

const S = "11111111-1111-1111-1111-111111111111";
const U = "22222222-2222-2222-2222-222222222222";
const E = "33333333-3333-3333-3333-333333333333";

Deno.test("convierte cada item del motor en un evento", () => {
  const rows = toCoachingEvents(S, U, [{
    exercise_id: E,
    recommendation: "INCREASE_WEIGHT",
    performance_score: 1.05,
    completed_sets: 3,
    target_sets: 3,
    weight_met: true,
    reps_met: true,
    engine_version: "1.0",
  }]);
  if (rows.length !== 1) throw new Error("esperaba 1 fila");
  const r = rows[0];
  if (r.session_id !== S || r.user_id !== U || r.exercise_id !== E) throw new Error("ids");
  if (r.recommendation !== "INCREASE_WEIGHT" || r.performance_score !== 1.05) throw new Error("datos");
  if (r.suggested_weight !== null || r.reason_code !== null) throw new Error("opcionales a null");
  if (r.features.completed_sets !== 3) throw new Error("features");
});

Deno.test("descarta items sin id de ejercicio válido o sin recomendación", () => {
  const rows = toCoachingEvents(S, U, [
    { exercise_id: "no-uuid", recommendation: "MAINTAIN" },
    { exercise_id: E, recommendation: "" },
    null,
    "x",
  ]);
  if (rows.length !== 0) throw new Error(`esperaba 0, hay ${rows.length}`);
});

Deno.test("sin versión del motor asume la 1.0 y respeta los campos v2", () => {
  const [r] = toCoachingEvents(S, U, [{
    exercise_id: E,
    recommendation: "INCREASE_WEIGHT",
    suggested_weight: 42.5,
    suggested_reps: 8,
    reason_code: "DOUBLE_PROGRESSION_TOP",
  }]);
  if (r.engine_version !== "1.0") throw new Error("versión");
  if (r.suggested_weight !== 42.5 || r.suggested_reps !== 8) throw new Error("sugerencia");
  if (r.reason_code !== "DOUBLE_PROGRESSION_TOP") throw new Error("reason_code");
});

Deno.test("un análisis que no es array no produce eventos", () => {
  if (toCoachingEvents(S, U, null).length !== 0) throw new Error("null");
  if (toCoachingEvents(S, U, { a: 1 }).length !== 0) throw new Error("objeto");
});

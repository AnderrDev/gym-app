import { analyzeSessionV2, type CoachingInputsV2, type CoachingItemV2, formatKg, type HistoryRow } from "./engine_v2.ts";

const EX = "ex-1";

function sets(weight: number, reps: number[]) {
  return reps.map((r, i) => ({ exercise_id: EX, actual_weight: weight, actual_reps: r, set_index: i + 1, name: "Press banca" }));
}

function hist(date: string, top: number, minReps: number, opts: Partial<HistoryRow> = {}): HistoryRow {
  return {
    exercise_id: EX, session_date: date, top_weight: top, min_reps: minReps, sets_done: 3, sets_target: 3,
    target_reps: 8, best_e1rm: Math.round(top * (1 + minReps / 30) * 100) / 100, low_confidence: false,
    at_range_top: false, ...opts,
  };
}

function run(opts: {
  current: CoachingInputsV2["current_logs"];
  history?: HistoryRow[];
  target?: { sets?: number; min?: number; max?: number | null; weight?: number };
  catalog?: { movement_type: string | null; body_region?: string | null; load_increment_kg: number | null; name?: string };
  date?: string;
}): CoachingItemV2 {
  const t = opts.target ?? {};
  const items = analyzeSessionV2({
    session: { id: "s", user_id: "u", session_date: opts.date ?? "2026-10-20" },
    targets: [{
      exercise_id: EX, target_sets: t.sets ?? 3, target_reps: t.min ?? 8,
      target_reps_max: t.max === undefined ? 12 : t.max, target_weight: t.weight ?? 60,
    }],
    current_logs: opts.current,
    catalog: [{ exercise_id: EX, body_region: "upper", ...(opts.catalog ?? { movement_type: "compound", load_increment_kg: 2.5 }) }],
    history: opts.history ?? [],
  });
  if (items.length !== 1) throw new Error(`esperaba 1 item, hay ${items.length}`);
  return items[0];
}

function expect(item: CoachingItemV2, rec: string, reason: string, weight?: number | null, reps?: number | null) {
  const got = `${item.recommendation}/${item.reason_code}/${item.suggested_weight}/${item.suggested_reps}`;
  if (item.recommendation !== rec || item.reason_code !== reason) throw new Error(`esperaba ${rec}/${reason}, hay ${got}`);
  if (weight !== undefined && item.suggested_weight !== weight) throw new Error(`peso: ${got}`);
  if (reps !== undefined && item.suggested_reps !== reps) throw new Error(`reps: ${got}`);
  if (!item.feedback) throw new Error("feedback vacío");
  if (item.engine_version !== "2.0") throw new Error("versión");
}

const prev = [hist("2026-10-16", 60, 10)];

Deno.test("todas las series en el máximo del rango → sube un incremento y vuelve al mínimo", () => {
  expect(run({ current: sets(60, [12, 12, 12]), history: prev }), "INCREASE_WEIGHT", "DOUBLE_PROGRESSION_TOP", 62.5, 8);
});

Deno.test("dentro del rango → mismo peso, una rep más", () => {
  expect(run({ current: sets(60, [10, 9, 9]), history: prev }), "INCREASE_REPS", "IN_RANGE_ADD_REPS", 60, 10);
});

Deno.test("máximo alcanzado con caída fuerte entre series → confirmar antes de subir", () => {
  // 15-13-12: llega a 12 pero la primera serie tenía mucho margen; se exige confirmación.
  expect(run({ current: sets(60, [15, 13, 12]), history: prev }), "MAINTAIN", "CONFIRM_TOP", 60, 12);
});

Deno.test("máximo confirmado en la sesión anterior → sube aunque haya caída", () => {
  const confirmed = [hist("2026-10-16", 60, 12, { at_range_top: true })];
  expect(run({ current: sets(60, [15, 13, 12]), history: confirmed }), "INCREASE_WEIGHT", "DOUBLE_PROGRESSION_TOP", 62.5, 8);
});

Deno.test("primer fallo por debajo del mínimo → repetir peso", () => {
  expect(run({ current: sets(60, [8, 7, 7]), history: prev }), "MAINTAIN", "FIRST_MISS", 60, 8);
});

Deno.test("segundo fallo seguido al mismo peso → baja entre 5 y 10 % según la fuerza de hoy", () => {
  const missed = [hist("2026-10-16", 60, 7)];
  expect(run({ current: sets(60, [8, 7, 6]), history: missed }), "DECREASE_WEIGHT", "RESET_AFTER_MISSES", 57.5, 8);
});

Deno.test("reps muy por debajo del objetivo → baja a lo que permite el e1RM para el mínimo", () => {
  expect(run({ current: sets(60, [4, 3, 3]), history: [hist("2026-10-16", 57.5, 8)] }), "DECREASE_WEIGHT", "TOO_HEAVY", 52.5, 8);
});

Deno.test("arranque en frío: nunca sube carga", () => {
  expect(run({ current: sets(60, [12, 12, 12]) }), "MAINTAIN", "COLD_START_CONFIRM", 60, 12);
  expect(run({ current: sets(60, [9, 9, 8]) }), "INCREASE_REPS", "COLD_START_ADD_REPS", 60, 9);
  const cold = run({ current: sets(60, [9, 9, 8]) });
  if (cold.confidence !== "low") throw new Error("confianza baja sin historial");
});

Deno.test("series incompletas → mantener", () => {
  expect(run({ current: sets(60, [12, 12]), history: prev }), "MAINTAIN", "INCOMPLETE_SETS", 60, 8);
});

Deno.test("sin series → objetivo de la rutina, con el nombre del catálogo", () => {
  const item = run({ current: [], history: prev, catalog: { movement_type: "compound", load_increment_kg: 2.5, name: "Remo con barra" } });
  expect(item, "MAINTAIN", "NO_DATA", 60, 8);
  if (item.exercise_name !== "Remo con barra") throw new Error(`nombre ${item.exercise_name}`);
});

Deno.test("peso corporal o sin incremento → progresa solo por reps", () => {
  const plank = { movement_type: "isolation", load_increment_kg: null };
  expect(run({ current: sets(0, [12, 12, 12]), history: [hist("2026-10-16", 0, 10)], catalog: plank }),
    "INCREASE_REPS", "BODYWEIGHT_ADD_REPS", 0, 13);
});

Deno.test("salto grande para la carga (curl 10 kg, +2 kg = 20 %) → pide 2 reps extra antes de subir", () => {
  const db = { movement_type: "isolation", load_increment_kg: 2 };
  const h = [hist("2026-10-16", 10, 10)];
  expect(run({ current: sets(10, [12, 12, 12]), history: h, catalog: db }), "INCREASE_REPS", "IN_RANGE_ADD_REPS", 10, 13);
  expect(run({ current: sets(10, [14, 14, 14]), history: h, catalog: db }), "INCREASE_WEIGHT", "DOUBLE_PROGRESSION_TOP", 12, 8);
});

Deno.test("la subida nunca supera el 10 % ni baja del incremento mínimo", () => {
  const press = { movement_type: "compound", load_increment_kg: 5 };
  const item = run({ current: sets(200, [12, 12, 12]), history: [hist("2026-10-16", 200, 11)], catalog: press });
  expect(item, "INCREASE_WEIGHT", "DOUBLE_PROGRESSION_TOP", 205, 8);
});

Deno.test("regresión: falla dos sesiones seguidas y el e1RM cae ≥5 % bajo el pico → bajar", () => {
  const h = [hist("2026-10-16", 70, 7), hist("2026-10-12", 70, 10)];
  expect(run({ current: sets(60, [7, 6, 6]), history: h }), "DECREASE_WEIGHT", "REGRESSION", 57.5, 8);
});

Deno.test("estancamiento: e1RM plano varias sesiones → mantener con motivo PLATEAU", () => {
  const h = [hist("2026-10-16", 60, 9), hist("2026-10-12", 60, 9), hist("2026-10-08", 60, 9), hist("2026-10-04", 60, 9)];
  const item = run({ current: sets(60, [9, 9, 9]), history: h });
  if (item.reason_code !== "PLATEAU") throw new Error(`esperaba PLATEAU, hay ${item.reason_code}`);
  if (item.recommendation === "INCREASE_WEIGHT" || item.recommendation === "DECREASE_WEIGHT") throw new Error("sin cambio de carga");
});

Deno.test("sin rango (un solo objetivo): la primera vez que se cumple pide confirmarlo", () => {
  expect(run({ current: sets(60, [8, 8, 8]), history: prev, target: { max: null } }), "MAINTAIN", "CONFIRM_TOP", 60, 8);
});

Deno.test("sin rango: cumplido dos sesiones seguidas al mismo peso → sube", () => {
  const confirmed = [hist("2026-10-16", 60, 8, { at_range_top: true })];
  expect(run({ current: sets(60, [8, 8, 8]), history: confirmed, target: { max: null } }), "INCREASE_WEIGHT", "DOUBLE_PROGRESSION_TOP", 62.5, 8);
});

Deno.test("con la opción inmediata, sin rango sube al cumplir (comportamiento anterior)", () => {
  const items = analyzeSessionV2({
    session: { id: "s", user_id: "u", session_date: "2026-10-20" },
    targets: [{ exercise_id: EX, target_sets: 3, target_reps: 8, target_reps_max: null, target_weight: 60 }],
    current_logs: sets(60, [8, 8, 8]),
    catalog: [{ exercise_id: EX, movement_type: "compound", body_region: "upper", load_increment_kg: 2.5 }],
    history: prev,
  }, { singleTarget: "immediate" });
  if (items[0].recommendation !== "INCREASE_WEIGHT") throw new Error(items[0].reason_code);
});

Deno.test("no es estancamiento si la carga subió en las últimas sesiones aunque el e1RM esté plano", () => {
  // e1RM plano pero viene de 57,5 → 60: progresa por carga.
  const h = [hist("2026-10-16", 60, 9), hist("2026-10-12", 57.5, 10), hist("2026-10-08", 57.5, 10), hist("2026-10-04", 57.5, 10)];
  const item = run({ current: sets(60, [9, 9, 9]), history: h });
  if (item.reason_code === "PLATEAU") throw new Error("falsa alarma de estancamiento");
});

Deno.test("confianza y score", () => {
  const h = [hist("2026-10-16", 60, 10), hist("2026-10-12", 60, 9), hist("2026-10-08", 57.5, 10)];
  const item = run({ current: sets(60, [11, 10, 10]), history: h });
  if (item.confidence !== "high") throw new Error(`confianza ${item.confidence}`);
  if (!(item.performance_score > 1 && item.performance_score < 1.1)) throw new Error(`score ${item.performance_score}`);
  const stale = run({ current: sets(60, [11, 10, 10]), history: h, date: "2026-12-01" });
  if (stale.confidence !== "medium") throw new Error("pausa larga baja la confianza");
});

Deno.test("ejercicios sin series objetivo (sustituidos) no se analizan", () => {
  const items = analyzeSessionV2({ targets: [{ exercise_id: EX, target_sets: 0, target_reps: 8, target_reps_max: null, target_weight: 60 }] });
  if (items.length !== 0) throw new Error("esperaba []");
});

Deno.test("peso de trabajo: una serie suelta más pesada no es la referencia", () => {
  // Sesión real (2026-10-22): 100×6, 100×6, 110×3; antes 100×5 y 100×4. Suma reps → progresa.
  const current = [...sets(100, [6, 6]), { exercise_id: EX, actual_weight: 110, actual_reps: 3, set_index: 3, name: "Press banca" }];
  const h = [hist("2026-10-18", 100, 5), hist("2026-10-13", 100, 4)];
  const item = run({ current, history: h, target: { min: 8, max: null, weight: 95 } });
  expect(item, "INCREASE_REPS", "BUILDING_REPS", 100, 7);
  if (!item.weight_met) throw new Error("el objetivo de peso se cumple con la serie más pesada");
});

Deno.test("una sugerencia nunca supera lo que permite el e1RM de hoy", () => {
  // 90×4, 80×6, 80×6 con objetivo 8: peso de trabajo 80; e1RM ≈ 102 → para 8 reps da 80.
  const current = [{ exercise_id: EX, actual_weight: 90, actual_reps: 4, set_index: 1, name: "Press inclinado" },
    ...sets(80, [6, 6]).map((s, i) => ({ ...s, set_index: i + 2 }))];
  const item = run({ current, history: [hist("2026-10-20", 40, 8)], target: { min: 8, max: null, weight: 80 } });
  expect(item, "MAINTAIN", "FIRST_MISS", 80, 8);
});

Deno.test("sin mejora de reps tras un fallo al mismo peso sí hay reset", () => {
  const item = run({ current: sets(60, [7, 7, 7]), history: [hist("2026-10-16", 60, 7)] });
  expect(item, "DECREASE_WEIGHT", "RESET_AFTER_MISSES");
  if (item.suggested_weight !== 57.5) throw new Error(`peso ${item.suggested_weight}`);
});

Deno.test("con más de 12 reps objetivo no se acota por e1RM", () => {
  const item = run({ current: sets(70, [13, 12, 12]), history: [hist("2026-10-16", 65, 12, { target_reps: 15 })],
    target: { min: 15, max: null, weight: 70 } });
  if (item.suggested_weight !== 70) throw new Error(`peso ${item.suggested_weight}`);
});

Deno.test("empate de series entre dos pesos → manda el más pesado", () => {
  const current = [...sets(20, [10, 10]), ...sets(15, [12, 12]).map((s, i) => ({ ...s, set_index: i + 3 }))];
  const item = run({ current, history: prev, target: { sets: 4, min: 8, max: 12, weight: 20 } });
  if (item.suggested_weight !== 20) throw new Error(`peso ${item.suggested_weight}`);
});

// Casos encontrados con la simulación local (scripts/local_coach_sim, 2026-10-24).
Deno.test("simulación: llegar al máximo con menos peso no es regresión (el curl no cae a 0)", () => {
  const curl = { movement_type: "isolation", load_increment_kg: 2 };
  const h = [hist("2026-10-16", 14, 11), hist("2026-10-12", 14, 10)];
  const item = run({ current: sets(12, [12, 12, 12]), history: h, catalog: curl, target: { min: 10, max: 12, weight: 14 } });
  expect(item, "INCREASE_REPS", "IN_RANGE_ADD_REPS", 12, 13);
});

Deno.test("simulación: un mal día tras una sesión buena no es regresión", () => {
  const h = [hist("2026-10-16", 72.5, 8, { target_reps: 6 }), hist("2026-10-12", 80, 7, { target_reps: 6 })];
  const item = run({ current: sets(72.5, [7, 6, 5]), history: h, target: { min: 6, max: 8, weight: 72.5 } });
  expect(item, "MAINTAIN", "FIRST_MISS", 72.5, 6);
});

Deno.test("simulación: series topadas en el máximo no se diagnostican como estancamiento", () => {
  const h = [hist("2026-10-16", 95, 6, { target_reps: 5 }), hist("2026-10-12", 95, 6, { target_reps: 5 }),
    hist("2026-10-08", 95, 6, { target_reps: 5 }), hist("2026-10-04", 95, 6, { target_reps: 5 })];
  const item = run({ current: sets(95, [8, 8, 6]), history: h, target: { min: 5, max: 8, weight: 95 } });
  expect(item, "INCREASE_REPS", "IN_RANGE_ADD_REPS", 95, 7);
});

Deno.test("simulación: el reset tras dos fallos baja solo lo que pide la fuerza (−6 %, no −10 %)", () => {
  const h = [hist("2026-10-16", 80, 5, { target_reps: 6 })];
  const item = run({ current: sets(80, [7, 6, 5]), history: h, target: { min: 6, max: 8, weight: 80 } });
  expect(item, "DECREASE_WEIGHT", "RESET_AFTER_MISSES", 75, 6);
});

Deno.test("un ejercicio con carga nunca baja de su incremento mínimo", () => {
  const curl = { movement_type: "isolation", load_increment_kg: 2 };
  const item = run({ current: sets(2, [3, 3, 3]), history: [hist("2026-10-16", 2, 4)], catalog: curl, target: { min: 10, max: 12, weight: 2 } });
  if (item.suggested_weight !== 2 || item.recommendation === "DECREASE_WEIGHT") {
    throw new Error(`${item.recommendation} ${item.suggested_weight}`);
  }
});

Deno.test("formato de kg en español", () => {
  if (formatKg(42.5) !== "42,5 kg" || formatKg(60) !== "60 kg") throw new Error(`${formatKg(42.5)} / ${formatKg(60)}`);
});

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
  catalog?: { movement_type: string | null; body_region?: string | null; load_increment_kg: number | null };
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

Deno.test("segundo fallo seguido al mismo peso → baja ~10 % al incremento más cercano", () => {
  const missed = [hist("2026-10-16", 60, 7)];
  expect(run({ current: sets(60, [8, 7, 6]), history: missed }), "DECREASE_WEIGHT", "RESET_AFTER_MISSES", 55, 8);
});

Deno.test("reps muy por debajo del objetivo → carga demasiado alta (−5 %)", () => {
  expect(run({ current: sets(60, [4, 3, 3]), history: [hist("2026-10-16", 57.5, 8)] }), "DECREASE_WEIGHT", "TOO_HEAVY", 57.5, 8);
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

Deno.test("sin series → objetivo de la rutina", () => {
  expect(run({ current: [], history: prev }), "MAINTAIN", "NO_DATA", 60, 8);
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

Deno.test("regresión: e1RM ≥5 % bajo el pico reciente → bajar", () => {
  const h = [hist("2026-10-16", 70, 10), hist("2026-10-12", 70, 10)];
  expect(run({ current: sets(60, [9, 8, 8]), history: h }), "DECREASE_WEIGHT", "REGRESSION", 57.5, 8);
});

Deno.test("estancamiento: e1RM plano varias sesiones → mantener con motivo PLATEAU", () => {
  const h = [hist("2026-10-16", 60, 9), hist("2026-10-12", 60, 9), hist("2026-10-08", 60, 9), hist("2026-10-04", 60, 9)];
  const item = run({ current: sets(60, [9, 9, 9]), history: h });
  if (item.reason_code !== "PLATEAU") throw new Error(`esperaba PLATEAU, hay ${item.reason_code}`);
  if (item.recommendation === "INCREASE_WEIGHT" || item.recommendation === "DECREASE_WEIGHT") throw new Error("sin cambio de carga");
});

Deno.test("sin máximo de rango (rutinas de un solo valor) → sube al cumplir el objetivo", () => {
  expect(run({ current: sets(60, [8, 8, 8]), history: prev, target: { max: null } }), "INCREASE_WEIGHT", "DOUBLE_PROGRESSION_TOP", 62.5, 8);
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

Deno.test("formato de kg en español", () => {
  if (formatKg(42.5) !== "42,5 kg" || formatKg(60) !== "60 kg") throw new Error(`${formatKg(42.5)} / ${formatKg(60)}`);
});

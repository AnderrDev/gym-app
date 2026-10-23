import { analyzeSession, type CoachingInputs, type CoachingItem } from "./engine.ts";

const EX = "ex-1";

function sets(weight: number, reps: number[], withName = true) {
  return reps.map((r, i) => ({
    exercise_id: EX,
    actual_weight: weight,
    actual_reps: r,
    set_index: i + 1,
    ...(withName ? { name: "Press banca" } : {}),
  }));
}

function run(opts: {
  target?: { sets: number; reps: number; weight: number };
  current: CoachingInputs["current_logs"];
  previous?: CoachingInputs["previous_logs"];
}): CoachingItem {
  const t = opts.target ?? { sets: 3, reps: 8, weight: 40 };
  const items = analyzeSession({
    routine_exercises: [{
      exercise_id: EX,
      target_sets: t.sets,
      target_reps: t.reps,
      target_weight: t.weight,
    }],
    current_logs: opts.current,
    previous_logs: opts.previous ?? [],
  });
  if (items.length !== 1) throw new Error(`esperaba 1 item, hay ${items.length}`);
  return items[0];
}

function expect(item: CoachingItem, recommendation: string, score: number) {
  if (item.recommendation !== recommendation) {
    throw new Error(`recomendación ${item.recommendation}, esperaba ${recommendation}`);
  }
  if (item.performance_score !== score) {
    throw new Error(`score ${item.performance_score}, esperaba ${score}`);
  }
  if (!item.feedback) throw new Error("feedback vacío");
}

Deno.test("series incompletas mantienen la carga", () => {
  const item = run({ current: sets(40, [8, 8]) });
  expect(item, "MAINTAIN", 0.65);
  if (item.completed_sets !== 2 || item.target_sets !== 3) throw new Error("conteo de series");
});

Deno.test("primera sesión con reps cumplidas sube peso", () => {
  const item = run({ current: sets(40, [8, 8, 8]) });
  expect(item, "INCREASE_WEIGHT", 1.0);
  if (!item.weight_met || !item.reps_met) throw new Error("objetivos cumplidos");
});

Deno.test("primera sesión sin reps cumplidas sube repeticiones", () => {
  expect(run({ current: sets(40, [8, 7, 6]) }), "INCREASE_REPS", 0.85);
});

Deno.test("más peso que la vez anterior sin perder reps sube peso", () => {
  expect(
    run({ current: sets(42.5, [8, 8, 8]), previous: sets(40, [8, 8, 8]) }),
    "INCREASE_WEIGHT",
    1.05,
  );
});

Deno.test("mismo peso con reps por debajo del objetivo pide repeticiones", () => {
  expect(
    run({ current: sets(40, [8, 7, 7]), previous: sets(40, [7, 7, 6]) }),
    "INCREASE_REPS",
    0.88,
  );
});

Deno.test("menos peso que antes y reps muy bajas baja la carga", () => {
  expect(
    run({ current: sets(37.5, [4, 4, 3]), previous: sets(40, [8, 8, 8]) }),
    "DECREASE_WEIGHT",
    0.55,
  );
});

Deno.test("mismo rendimiento que la vez anterior mantiene", () => {
  expect(
    run({ current: sets(40, [8, 8, 8]), previous: sets(40, [8, 8, 8]) }),
    "MAINTAIN",
    0.9,
  );
});

Deno.test("superar el peso objetivo nunca recomienda bajar", () => {
  const item = run({
    target: { sets: 3, reps: 10, weight: 38 },
    current: sets(39, [5, 5, 5]),
    previous: sets(45, [5, 5, 5]),
  });
  if (item.recommendation === "DECREASE_WEIGHT") throw new Error("no debe bajar");
});

Deno.test("sin series registradas usa el nombre por defecto", () => {
  const item = run({ current: [] });
  expect(item, "MAINTAIN", 0.65);
  if (item.exercise_name !== "Ejercicio") throw new Error("nombre por defecto");
});

Deno.test("logs de otros ejercicios no contaminan el análisis", () => {
  const other = sets(100, [1, 1, 1]).map((l) => ({ ...l, exercise_id: "ex-2" }));
  expect(
    run({ current: [...sets(40, [8, 8, 8]), ...other], previous: other }),
    "INCREASE_WEIGHT",
    1.0,
  );
});

Deno.test("entradas vacías devuelven un análisis vacío", () => {
  if (analyzeSession({}).length !== 0) throw new Error("esperaba []");
});

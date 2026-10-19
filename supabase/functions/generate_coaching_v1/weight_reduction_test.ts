import { shouldReduceWeight } from './weight_reduction.ts';

Deno.test('superar el peso objetivo no recomienda bajar aunque el historial usara más carga', () => {
  if (shouldReduceWeight(40, 5, 38, 10)) throw new Error('No reducir por superar la carga objetivo');
});

Deno.test('peso dentro del objetivo y repeticiones muy bajas permite recomendar técnica', () => {
  if (!shouldReduceWeight(38, 5, 38, 10)) throw new Error('Detectar repeticiones bajas');
});

Deno.test('cumplir repeticiones no recomienda bajar', () => {
  if (shouldReduceWeight(38, 10, 38, 10)) throw new Error('Objetivo cumplido');
});

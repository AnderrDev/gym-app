export function shouldReduceWeight(weight: number, reps: number, targetWeight: number, targetReps: number): boolean {
  return weight <= targetWeight && reps < Math.max(4, targetReps * 0.6);
}

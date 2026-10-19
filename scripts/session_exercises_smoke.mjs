#!/usr/bin/env node
// Disposable HTTP contract test. Keys stay in memory; no existing user data is changed.
import { execFileSync } from 'node:child_process';
import { randomUUID, randomBytes } from 'node:crypto';
import assert from 'node:assert/strict';

const projectRef = 'benadgxgowycjxypyunc';
const base = `https://${projectRef}.supabase.co`;
let uid = randomUUID();
const routineId = randomUUID(), day1 = randomUUID(), day2 = randomUUID();
const currentId = randomUUID(), previousId = randomUUID();
let anon, service, token, userCreated = false, failed = false;
const check = (label) => console.log(`PASS ${label}`);
async function request(path, { method = 'GET', body, admin = false, expectError = false } = {}) {
  let response;
  try {
    response = await fetch(base + path, {
      method, signal: AbortSignal.timeout(30000),
      headers: { apikey: admin ? service : anon, Authorization: `Bearer ${admin ? service : token ?? anon}`,
        'Content-Type': 'application/json', Prefer: 'return=representation' },
      ...(body === undefined ? {} : { body: JSON.stringify(body) }),
    });
  } catch { throw new Error(`HTTP network failure: ${method} ${path.split('?')[0]}`); }
  const text = await response.text();
  let data; try { data = text ? JSON.parse(text) : null; } catch { data = null; }
  if (expectError) { assert(!response.ok, 'Expected rejected request'); return; }
  // Never include raw server bodies: auth endpoints may return sensitive values.
  if (!response.ok) {
    const detail = path.startsWith('/rest/') && /^[A-Z0-9]+$/.test(data?.code ?? '') ? ` [${data.code}] ${String(data.message ?? '').replace(/[\r\n]/g, ' ').slice(0, 180)}` : '';
    throw new Error(`HTTP ${response.status}: ${method} ${path.split('?')[0]}${detail}`);
  }
  return data;
}
const insert = (table, body) => request(`/rest/v1/${table}`, { method: 'POST', body });
const rpc = (name, body, expectError = false) => request(`/rest/v1/rpc/${name}`, { method: 'POST', body, expectError });
const edge = async (name, body) => {
  const data = await request(`/functions/v1/${name}`, { method: 'POST', body });
  assert.equal(data?.success, true, `${name} success`); return data;
};
try {
  let keys;
  try {
    keys = JSON.parse(execFileSync('supabase', ['projects', 'api-keys', '--project-ref', projectRef, '--output', 'json'],
      { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'], timeout: 30000 }));
  } catch { throw new Error('Supabase CLI API-key lookup failed (details withheld)'); }
  assert(Array.isArray(keys), 'CLI API-key array missing');
  anon = keys.find(k => k.name === 'anon')?.api_key;
  service = keys.find(k => k.name === 'service_role')?.api_key;
  assert(anon && service, 'Legacy anon/service_role keys unavailable');
  const password = randomBytes(32).toString('base64url') + 'aA1!';
  const email = `qa+${uid}@example.invalid`;
  const created = await request('/auth/v1/admin/users', { method: 'POST', admin: true,
    body: { id: uid, email, password, email_confirm: true, user_metadata: { full_name: 'Disposable session smoke' } } });
  assert(created?.id, 'Admin API created user id missing');
  uid = created.id;
  userCreated = true;
  const session = await request('/auth/v1/token?grant_type=password', { method: 'POST', body: { email, password } });
  token = session?.access_token;
  assert(token && session.user?.id === uid, 'Isolated QA sign-in');
  check('isolated QA authentication');
  const catalog = await request('/rest/v1/exercises?select=id&order=id&limit=3');
  assert.equal(catalog.length, 3, 'Need three catalog exercises');
  const [original, replacement, extra] = catalog.map(e => e.id);
  await insert('routines', { id: routineId, name: 'Disposable HTTP session smoke', creator_id: uid, is_public: false });
  await insert('user_routines', { user_id: uid, routine_id: routineId });
  await insert('routine_days', [{ id: day1, routine_id: routineId, day_of_week: 1, name: 'QA current' },
    { id: day2, routine_id: routineId, day_of_week: 2, name: 'QA history' }]);
  await insert('routine_exercises', { routine_day_id: day1, exercise_id: original, order: 1,
    target_sets: 3, target_reps: 10, target_weight: 38, rest_timer_seconds: 90 });
  const today = new Date().toISOString().slice(0, 10);
  const yesterday = new Date(Date.now() - 86400000).toISOString().slice(0, 10);
  await insert('workout_sessions', [{ id: previousId, user_id: uid, routine_day_id: day2, session_date: yesterday, completed_at: new Date().toISOString() },
    { id: currentId, user_id: uid, routine_day_id: day1, session_date: today, completed_at: null }]);
  await insert('set_logs', { session_id: previousId, exercise_id: original, set_index: 1, actual_weight: 42, actual_reps: 7 });
  let plan = await rpc('get_session_exercises_v1', { p_session_id: currentId });
  assert.equal(plan.length, 1);
  await insert('set_logs', { session_id: currentId, exercise_id: original, set_index: 1, actual_weight: 40, actual_reps: 5 });
  plan = await rpc('adapt_session_exercise_v1', { p_session_id: currentId, p_exercise_id: replacement,
    p_target_sets: 2, p_target_reps: 12, p_target_weight: 25, p_replace_exercise_id: original });
  plan = await rpc('adapt_session_exercise_v1', { p_session_id: currentId, p_exercise_id: extra,
    p_target_sets: 1, p_target_reps: 10, p_target_weight: 0 });
  assert.equal(plan.find(e => e.id === original).target_sets, 1);
  assert(plan.find(e => e.id === original).replaced_by_exercise_name);
  assert(plan.find(e => e.id === replacement).replaces_exercise_name);
  assert.equal(plan.find(e => e.id === extra).is_extra, true);
  assert.deepEqual(await rpc('get_session_exercises_v1', { p_session_id: currentId }), plan);
  // Overshooting the extra must not compensate for the pending replacement.
  await insert('set_logs', [1, 2, 3].map(i => ({ session_id: currentId, exercise_id: extra, set_index: i, actual_weight: 0, actual_reps: 10 })));
  let [summary] = await request(`/rest/v1/view_workout_sessions_summary?select=total_target_sets,total_completed_sets,is_strictly_completed&id=eq.${currentId}`);
  assert.equal(summary.total_target_sets, 4); assert.equal(summary.total_completed_sets, 2);
  // Keep one actual extra log in the final fixture.
  await request(`/rest/v1/set_logs?session_id=eq.${currentId}&exercise_id=eq.${extra}&set_index=gt.1`, { method: 'DELETE' });
  await insert('set_logs', [1, 2].map(i => ({ session_id: currentId, exercise_id: replacement, set_index: i, actual_weight: 25, actual_reps: 12 })));
  const originalLogs = await request(`/rest/v1/set_logs?select=actual_weight,actual_reps&session_id=eq.${currentId}&exercise_id=eq.${original}`);
  assert.equal(originalLogs.length, 1); assert.equal(originalLogs[0].actual_weight, 40); assert.equal(originalLogs[0].actual_reps, 5);
  check('snapshot lineage, original logs and per-exercise completion cap');
  const coaching = await edge('generate_coaching_v1', { session_id: currentId });
  const originalAnalysis = coaching.data?.analysis?.find(a => a.exercise_id === original);
  assert(originalAnalysis, 'Original coaching row');
  assert.notEqual(originalAnalysis.recommendation, 'DECREASE_WEIGHT', '40 kg above 38 kg target must not reduce weight');
  check('coaching uses snapshot targets and avoids false weight reduction');
  const finalized = await edge('finalize_workout_session_v1', { session_id: currentId });
  assert(!finalized.data?.warning_code, 'Automatic coaching must succeed');
  [summary] = await request(`/rest/v1/view_workout_sessions_summary?select=total_target_sets,total_completed_sets,is_strictly_completed&id=eq.${currentId}`);
  assert.equal(summary.total_target_sets, 4); assert.equal(summary.total_completed_sets, 4); assert.equal(summary.is_strictly_completed, true);
  await rpc('update_session_exercise_target_v1', { p_session_id: currentId, p_exercise_id: replacement, p_target_weight: 30, p_target_reps: 12 }, true);
  check('finalization, strict 4/4 completion and closed-session guard');
  await edge('get_weekly_insights_v1', { routine_id: routineId });
  check('weekly insights');
} catch (error) {
  failed = true;
  // Assertions contain only explicit safe labels; never serialize request/response objects.
  console.error(`FAIL ${error instanceof Error ? error.message : 'unknown error'}`);
} finally {
  if (userCreated) {
    let cleanupFailed = false;
    for (const path of [`/rest/v1/workout_sessions?user_id=eq.${uid}`, `/rest/v1/routines?id=eq.${routineId}`, `/auth/v1/admin/users/${uid}`]) {
      try { await request(path, { method: 'DELETE', admin: true }); }
      catch { cleanupFailed = true; }
    }
    if (cleanupFailed) { failed = true; console.error(`FAIL cleanup (isolated QA user ${uid}; inspect only this fixture)`); }
    else check('isolated QA cleanup');
  }
}
if (failed) process.exitCode = 1;

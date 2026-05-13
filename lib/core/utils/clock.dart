/// Reloj abstracto para que los blocs/use cases puedan testearse con una
/// implementación falsa. Producción usa [SystemClock] (registrado en DI);
/// los tests pueden inyectar un [FakeClock] con una hora fija.
abstract class Clock {
  DateTime now();
}

/// Implementación real basada en `DateTime.now()`.
class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

/// Reloj de prueba que devuelve siempre el mismo `DateTime`.
/// Útil para tests deterministas (p.ej. `weekStart` consistente).
class FakeClock implements Clock {
  FakeClock(this._fixed);

  DateTime _fixed;

  void set(DateTime value) => _fixed = value;

  @override
  DateTime now() => _fixed;
}

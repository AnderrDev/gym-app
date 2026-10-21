import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/core/observability/app_bloc_observer.dart';
import 'package:gym_flutter/core/observability/app_logger.dart';

class _CounterCubit extends Cubit<int> {
  _CounterCubit() : super(0);
  void inc() => emit(state + 1);
}

void main() {
  int logged() => AppLogger.instance.talker.history.length;

  test('verbose=false no registra cambios de estado', () async {
    final before = logged();
    Bloc.observer = AppBlocObserver(verbose: false);
    final cubit = _CounterCubit();
    cubit.inc();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(logged(), before);
    await cubit.close();
  });

  test('verbose=true registra cambios de estado', () async {
    final before = logged();
    Bloc.observer = AppBlocObserver(verbose: true);
    final cubit = _CounterCubit();
    cubit.inc();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(logged(), greaterThan(before));
    await cubit.close();
  });
}

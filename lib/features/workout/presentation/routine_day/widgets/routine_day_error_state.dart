import 'package:flutter/material.dart';

import 'package:gym_flutter/core/ui/molecules/app_error_state.dart';

class RoutineDayErrorState extends StatelessWidget {
  const RoutineDayErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppErrorState(message: message, onRetry: onRetry);
  }
}

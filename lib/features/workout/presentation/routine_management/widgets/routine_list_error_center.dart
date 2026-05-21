import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';

class RoutineListErrorCenter extends StatelessWidget {
  const RoutineListErrorCenter({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, color: context.colors.error, size: 48),
          const SizedBox(height: 12),
          Text(message, style: context.text.bodyMedium),
        ],
      ),
    );
  }
}

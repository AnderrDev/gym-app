// Este archivo se mantiene por compatibilidad pero la funcionalidad
// fue migrada a RoutineDayPage. Ver /routine-day route.
import 'package:flutter/material.dart';
import 'package:gym_flutter/core/constants/app_colors.dart';

class ActiveWorkoutPage extends StatelessWidget {
  final String userId;
  const ActiveWorkoutPage({super.key, required this.userId, dynamic routine});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: Text('Redirigiendo a RoutineDayPage...')),
    );
  }
}

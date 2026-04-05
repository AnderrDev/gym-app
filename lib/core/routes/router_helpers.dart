import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_routes.dart';

void goToLogin(BuildContext context) => context.go(AppRoutes.login);

void goToRegister(BuildContext context) => context.go(AppRoutes.register);

void goToDashboard(BuildContext context) => context.go(AppRoutes.dashboard);

// Push helpers removed; use context.push(AppRoutes.*) directly.

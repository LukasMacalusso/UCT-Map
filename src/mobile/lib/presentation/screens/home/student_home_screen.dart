import '../../../domain/entities/dashboard_academic_content.dart';

import 'package:flutter/material.dart';

import '../../../domain/entities/app_permission.dart';
import '../../../domain/repositories/schedule_repository.dart';
import 'role_dashboard_screen.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({
    super.key,
    this.repository,
    this.academicContent,
    this.embedded = false,
    this.active = true,
    this.onNavigateToTab,
  });
  final ScheduleRepository? repository;
  final DashboardAcademicContent? academicContent;
  final bool embedded;
  final bool active;
  final ValueChanged<int>? onNavigateToTab;
  @override
  Widget build(BuildContext context) => RoleDashboardScreen(
    permission: AppPermission.bookConsultation,
    repository: repository,
    academicContent: academicContent,
    embedded: embedded,
    active: active,
    onNavigateToTab: onNavigateToTab,
  );
}

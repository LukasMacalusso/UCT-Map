import '../../../domain/entities/dashboard_academic_content.dart';

import 'package:flutter/material.dart';

import '../../../core/network/api_client_provider.dart';
import '../../../domain/entities/app_permission.dart';
import 'student_home_screen.dart';
import 'admin_home_screen.dart';
import 'objects_officer_home_screen.dart';
import 'complaints_officer_home_screen.dart';
import 'guest_home_content.dart';
import 'teacher_home_screen.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/custom_drawer.dart';
import '../../widgets/app_navigation_bar.dart';

class HomeScreen extends StatelessWidget {
  final Function(int)? onNavigateToTab;

  const HomeScreen({
    super.key,
    this.onNavigateToTab,
    this.academicContent,
    this.embedded = false,
    this.active = true,
  });
  final DashboardAcademicContent? academicContent;
  final bool embedded;
  final bool active;

  void _goToTab(BuildContext context, int tabIndex) {
    if (onNavigateToTab != null) {
      onNavigateToTab!(tabIndex);
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context, tabIndex);
    } else {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.initial,
        arguments: tabIndex,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (AppPermission.bookConsultation.allows(
      ApiClientProvider.session.currentUser?.role,
    )) {
      return StudentHomeScreen(
        embedded: embedded,
        academicContent: academicContent,
        active: active,
        onNavigateToTab: onNavigateToTab,
      );
    }
    if (AppPermission.teacherSchedule.allows(
      ApiClientProvider.session.currentUser?.role,
    )) {
      return TeacherHomeScreen(
        embedded: embedded,
        academicContent: academicContent,
        active: active,
        onNavigateToTab: onNavigateToTab,
      );
    }
    final body =
        AppPermission.manageUsers.allows(
          ApiClientProvider.session.currentUser?.role,
        )
        ? AdminHomeScreen(active: active)
        : AppPermission.manageObjects.allows(
            ApiClientProvider.session.currentUser?.role,
          )
        ? ObjectsOfficerHomeScreen(active: active)
        : AppPermission.manageReports.allows(
            ApiClientProvider.session.currentUser?.role,
          )
        ? ComplaintsOfficerHomeScreen(active: active)
        : !ApiClientProvider.session.isAuthenticated
        ? const GuestHomeContent()
        : const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Bienvenido a UCT Map. Explora los espacios y servicios del campus.',
            ),
          );
    if (embedded) return body;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio - UCT Map'),
        backgroundColor: AppColors.uctBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Mi perfil',
            onPressed: () => _goToTab(context, 4),
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      drawer: CustomDrawer(
        currentIndex: -1,
        onSelectTab: (index) => _goToTab(context, index),
      ),
      body: body,
      bottomNavigationBar: AppNavigationBar(
        currentTab: 5,
        onSelectTab: (tab) {
          if (tab != 5) _goToTab(context, tab);
        },
      ),
    );
  }
}

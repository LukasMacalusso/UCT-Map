import 'package:flutter/material.dart';

import '../../domain/entities/lost_item.dart';
import '../../domain/entities/report.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../presentation/navigation/main_navigation_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/login/login_page.dart';
import '../../presentation/screens/login/session_required_view.dart';
import '../../presentation/screens/lost_found/lost_found_screen.dart';
import '../../presentation/screens/lost_found/lost_item_detail_screen.dart';
import '../../presentation/screens/lost_objects/create_lost_object_screen.dart';
import '../../presentation/screens/lost_objects/lost_objects_screen.dart';
import '../../data/repositories/lost_objects_repository_impl.dart';
import '../../presentation/screens/professors/professors_screen.dart';
import '../../presentation/screens/profile/my_lost_items_screen.dart';
import '../../presentation/screens/profile/my_reports_screen.dart';
import '../../presentation/screens/profile/profile_settings_screen.dart';
import '../../presentation/screens/profile/saved_places_screen.dart';
import '../../presentation/screens/reports/report_detail_screen.dart';
import '../../presentation/screens/reports/reports_screen.dart';

/// Centralized route definitions and generator for the UCT Map app.
class AppRoutes {
  AppRoutes._();

  static const String initial = '/';
  static const String main = '/main';
  static const String home = '/home';
  static const String professors = '/professors';
  static const String reports = '/reports';
  static const String reportDetail = '/reports/detail';
  static const String lostFound = '/lost-found';
  static const String lostObjects = '/lost-objects';
  static const String createLostObject = '/lost-objects/create';
  static const String lostItemDetail = '/lost-found/detail';
  static const String login = '/login';
  static const String profile = '/profile';
  static const String savedPlaces = '/saved-places';
  static const String myReports = '/my-reports';
  static const String myLostItems = '/my-lost-items';
  static const String profileSettings = '/profile-settings';

  /// Generates routes dynamically based on name and parameters.
  static Route<dynamic> onGenerateRoute(
    RouteSettings settings, {
    AuthRepository? authRepository,
  }) {
    final route = _generateRoute(
      settings,
      authRepository: authRepository,
    ) as MaterialPageRoute<dynamic>;
    const protected = {
      home,
      professors,
      reports,
      reportDetail,
      lostFound,
      lostObjects,
      createLostObject,
      lostItemDetail,
      savedPlaces,
      myReports,
      myLostItems,
      profileSettings,
    };
    if (!protected.contains(settings.name)) return route;
    return MaterialPageRoute<dynamic>(
      settings: settings,
      builder: (_) => SessionRequiredView(builder: route.builder),
    );
  }

  static Route<dynamic> _generateRoute(
    RouteSettings settings, {
    AuthRepository? authRepository,
  }) {
    switch (settings.name) {
      case initial:
      case main:
        int initialIndex = 0;
        final args = settings.arguments;
        if (args is int) {
          initialIndex = args;
        } else if (args is Map && args.containsKey('initialIndex')) {
          initialIndex = (args['initialIndex'] as int?) ?? 0;
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => MainNavigationScreen(initialIndex: initialIndex),
        );

      case home:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => HomeScreen(
            onNavigateToTab: (tabIndex) {
              if (Navigator.canPop(context)) {
                Navigator.pop(context, tabIndex);
              } else {
                Navigator.pushReplacementNamed(
                  context,
                  initial,
                  arguments: tabIndex,
                );
              }
            },
          ),
        );

      case professors:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => ProfessorsScreen(
            onNavigateToTab: (tabIndex) {
              if (Navigator.canPop(context)) {
                Navigator.pop(context, tabIndex);
              } else {
                Navigator.pushReplacementNamed(
                  context,
                  initial,
                  arguments: tabIndex,
                );
              }
            },
          ),
        );

      case reports:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => ReportsScreen(
            showAppBar: true,
            onNavigateToTab: (tabIndex) {
              if (Navigator.canPop(context)) {
                Navigator.pop(context, tabIndex);
              } else {
                Navigator.pushReplacementNamed(
                  context,
                  initial,
                  arguments: tabIndex,
                );
              }
            },
          ),
        );

      case reportDetail:
        final report = settings.arguments;
        if (report is Report) {
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => ReportDetailScreen(
              report: report,
              onNavigateToTab: (tabIndex) {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context, tabIndex);
                } else {
                  Navigator.pushReplacementNamed(
                    context,
                    initial,
                    arguments: tabIndex,
                  );
                }
              },
            ),
          );
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ReportsScreen(showAppBar: true),
        );

      case lostFound:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => LostFoundScreen(
            showAppBar: true,
            onNavigateToTab: (tabIndex) {
              if (Navigator.canPop(context)) {
                Navigator.pop(context, tabIndex);
              } else {
                Navigator.pushReplacementNamed(
                  context,
                  initial,
                  arguments: tabIndex,
                );
              }
            },
          ),
        );

      case lostItemDetail:
        final item = settings.arguments;
        if (item is LostItem) {
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => LostItemDetailScreen(
              item: item,
              onNavigateToTab: (tabIndex) {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context, tabIndex);
                } else {
                  Navigator.pushReplacementNamed(
                    context,
                    initial,
                    arguments: tabIndex,
                  );
                }
              },
            ),
          );
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LostFoundScreen(showAppBar: true),
        );

      case lostObjects:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => LostObjectsScreen(
            repository: LostObjectsRepositoryImpl(),
            showAppBar: true,
          ),
        );

      case createLostObject:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) =>
              CreateLostObjectScreen(repository: LostObjectsRepositoryImpl()),
        );

      case profile:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const MainNavigationScreen(initialIndex: 4),
        );

      case savedPlaces:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => SavedPlacesScreen(
            onNavigateToTab: (tabIndex) {
              if (Navigator.canPop(context)) {
                Navigator.pop(context, tabIndex);
              } else {
                Navigator.pushReplacementNamed(
                  context,
                  initial,
                  arguments: tabIndex,
                );
              }
            },
          ),
        );

      case myReports:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => MyReportsScreen(
            onNavigateToTab: (tabIndex) {
              if (Navigator.canPop(context)) {
                Navigator.pop(context, tabIndex);
              } else {
                Navigator.pushReplacementNamed(
                  context,
                  initial,
                  arguments: tabIndex,
                );
              }
            },
          ),
        );

      case myLostItems:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => MyLostItemsScreen(
            onNavigateToTab: (tabIndex) {
              if (Navigator.canPop(context)) {
                Navigator.pop(context, tabIndex);
              } else {
                Navigator.pushReplacementNamed(
                  context,
                  initial,
                  arguments: tabIndex,
                );
              }
            },
          ),
        );

      case profileSettings:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ProfileSettingsScreen(),
        );

      case login:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => LoginPage(authRepository: authRepository),
        );

      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const MainNavigationScreen(),
        );
    }
  }
}

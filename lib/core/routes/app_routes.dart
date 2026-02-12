import 'package:get/get.dart';
import 'package:health_connect_dashboard/core/constants/app_constants.dart';

import '../../presentation/views/screens/dashboard_screen.dart';
import '../../presentation/views/screens/debug_screen.dart';
import '../../presentation/views/screens/permission_screen.dart';

class AppRoutes {
  static final routes = [
    GetPage(name: Routes.dashboard, page: () => const DashboardScreen()),
    GetPage(name: Routes.permissions, page: () => const PermissionsScreen()),
    GetPage(name: Routes.debug, page: () => const DebugScreen()),
  ];
}

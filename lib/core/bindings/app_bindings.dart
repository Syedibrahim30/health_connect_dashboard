import 'package:get/get.dart';

import '../../data/repositories/health_repository.dart';
import '../../presentation/controllers/health_controller.dart';
import '../../presentation/controllers/performance_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Repository
    Get.lazyPut<HealthRepository>(() => HealthRepositoryImpl(), fenix: true);

    // Controllers
    Get.lazyPut(
      () => HealthController(Get.find<HealthRepository>()),
      fenix: true,
    );
    Get.lazyPut(() => PerformanceController(), fenix: true);
  }
}

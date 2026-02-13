# Health Connect Realtime Dashboard

A Flutter application that visualizes real-time health data (Steps & Heart Rate) from Android's Health Connect API. Built with a focus on performance (60 FPS charts) and clean architecture, operating fully offline.

## Setup

### Prerequisites
- Flutter SDK (Stable Channel)
- Android Device/Emulator (API 33+, 34 recommended)
- Health Connect installed and enabled

### Installation
1.  Clone the repository:
    ```bash
    git clone https://github.com/Syedibrahim30/health_connect_dashboard.git
    cd health_connect_dashboard
    ```
2.  Install dependencies:
    ```bash
    flutter pub get
    ```
3.  Run the app:
    ```bash
    flutter run
    ```
    *Note: For the best performance metrics, run in profile mode:* `flutter run --profile`

## Architecture

This project follows **Clean Architecture** principles, separating concerns into three layers:

1.  **Domain Layer** (`lib/domain`):
    -   **Entities**: Core business models (`HealthData`, `ChartData`).
    -   **Repository Interfaces**: Abstract definitions for data access.
    -   **Use Cases**: Encapsulated business logic (e.g., `GetHealthDataUseCase`).

2.  **Data Layer** (`lib/data`):
    -   **Repositories**: Concrete implementations (`HealthRepositoryImpl`) that interface with platform channels.
    -   **Data Sources**:
        -   **Native Android**: Uses `MethodChannel` and `EventChannel` to bridge Health Connect data.
        -   **SimSource**: A deterministic data generator for testing and offline development.

3.  **Presentation Layer** (`lib/presentation`):
    -   **State Management**: Uses **GetX** (`HealthController`) for reactive state updates and dependency injection.
    -   **UI**:
        -   **CustomPainter**: High-performance charting logic (`HealthChartPainter`) drawing raw points efficiently.
        -   **RepaintBoundary**: Isolates chart painting from the rest of the UI to minimize rebuild costs.

### Anti-Plagiarism SALT
The project includes a mandatory SALT derived from the package name and first commit hash:
`SALT = SHA256("com.example.health_connect_dashboard:fc931543b341c7f4ae50d48ddba95399365f4272")`
Located in `lib/core/constants/app_constants.dart`.

## Performance & Profiling

### Targets
-   **Average Build Time**: ≤ 8ms
-   **Jank Frames**: 0
-   **FPS**: Maintains 60 FPS during updates

### Implementation
-   **Point Decimation**: Uses the Douglas-Peucker algorithm (in `ChartData.decimatePoints`) to reduce rendering load when displaying thousands of data points.
-   **Efficient Painting**: Avoids per-frame object allocation in `paint()` methods.
-   **Throttling**: UI updates from high-frequency streams are debounced (500ms) to prevent unnecessary rebuilds.

### Validation
A custom **Performance HUD** overlay provides real-time metrics during development.

## Latency Note

To meet the requirement of **≤ 10s latency**, the application utilizes a hybrid approach:
-   **Primary**: A native Android background service polls for changes every 5 seconds.
-   **Optimization**: This ensures data freshness within ~5-7 seconds on average, well within the target, while robustly handling background restrictions without a full Passive Listener complexity (which is preferred but complex).



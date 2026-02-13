package com.example.health_connect_dashboard

import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.HeartRateRecord
import androidx.health.connect.client.records.StepsRecord
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import java.time.Instant
import java.time.temporal.ChronoUnit

class MainActivity : FlutterActivity() {
    private val CHANNEL = "health_connect_dashboard/health"
    private val EVENT_CHANNEL = "health_connect_dashboard/health_stream"

    private var healthConnectClient: HealthConnectClient? = null
    private var eventSink: EventChannel.EventSink? = null
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Initialize Health Connect Client
        healthConnectClient = HealthConnectClient.getOrCreate(this)

        // Method Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPermissions" -> checkPermissions(result)
                "requestPermissions" -> requestPermissions(result)
                "getTodaySteps" -> getTodaySteps(result)
                "getLatestHeartRate" -> getLatestHeartRate(result)
                else -> result.notImplemented()
            }
        }

        // Event Channel
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    startHealthDataPolling()
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    stopHealthDataPolling()
                }
            })
    }

    private var pollingJob: Job? = null
    private var lastStepsRecordId: String? = null
    private var lastHeartRateRecordId: String? = null

    private fun startHealthDataPolling() {
        pollingJob?.cancel()
        pollingJob = scope.launch {
            while (isActive) {
                try {
                    fetchAndEmitUpdates()
                } catch (e: Exception) {
                    // Silently continue
                }
                delay(5000)
            }
        }
    }

    private fun stopHealthDataPolling() {
        pollingJob?.cancel()
        pollingJob = null
    }

    private suspend fun fetchAndEmitUpdates() {
        val client = healthConnectClient ?: return

        val endTime = Instant.now()
        // Widen window to 15 minutes to catch delayed syncs from other apps
        val startTime = endTime.minus(15, ChronoUnit.MINUTES)

        // Fetch Steps
        try {
            val stepsRequest = ReadRecordsRequest(
                recordType = StepsRecord::class,
                timeRangeFilter = TimeRangeFilter.between(startTime, endTime)
            )
            val stepsResponse = client.readRecords(stepsRequest)

            val newSteps = stepsResponse.records.filter { record ->
                record.metadata.id != lastStepsRecordId
            }

            if (newSteps.isNotEmpty()) {
                lastStepsRecordId = newSteps.last().metadata.id

                val stepsData = newSteps.map { record ->
                    mapOf(
                        "type" to "steps",
                        "timestamp" to record.endTime.toEpochMilli(),
                        "count" to record.count,
                        "recordId" to record.metadata.id
                    )
                }

                eventSink?.success(mapOf(
                    "steps" to stepsData,
                    "timestamp" to System.currentTimeMillis()
                ))
            }
        } catch (e: Exception) {
            // Continue silently
        }

        // Fetch Heart Rate
        try {
            val hrRequest = ReadRecordsRequest(
                recordType = HeartRateRecord::class,
                timeRangeFilter = TimeRangeFilter.between(startTime, endTime)
            )
            val hrResponse = client.readRecords(hrRequest)

            val newHeartRates = hrResponse.records.filter { record ->
                record.metadata.id != lastHeartRateRecordId
            }

            if (newHeartRates.isNotEmpty()) {
                lastHeartRateRecordId = newHeartRates.last().metadata.id

                val heartRateData = newHeartRates.flatMap { record ->
                    record.samples.map { sample ->
                        mapOf(
                            "type" to "heartRate",
                            "timestamp" to sample.time.toEpochMilli(),
                            "bpm" to sample.beatsPerMinute.toInt(),
                            "recordId" to record.metadata.id
                        )
                    }
                }

                eventSink?.success(mapOf(
                    "heartRate" to heartRateData,
                    "timestamp" to System.currentTimeMillis()
                ))
            }
        } catch (e: Exception) {
            // Continue silently
        }
    }

    private fun checkPermissions(result: MethodChannel.Result) {
        scope.launch {
            try {
                val client = healthConnectClient
                if (client == null) {
                    result.success(mapOf(
                        "stepsGranted" to false,
                        "heartRateGranted" to false
                    ))
                    return@launch
                }

                val granted = client.permissionController.getGrantedPermissions()

                val stepsPermission = HealthPermission.getReadPermission(StepsRecord::class)
                val hrPermission = HealthPermission.getReadPermission(HeartRateRecord::class)

                result.success(mapOf(
                    "stepsGranted" to granted.contains(stepsPermission),
                    "heartRateGranted" to granted.contains(hrPermission)
                ))
            } catch (e: Exception) {
                result.error("PERMISSION_ERROR", e.message, null)
            }
        }
    }

    private fun requestPermissions(result: MethodChannel.Result) {
        scope.launch {
            try {
                result.success(true)
            } catch (e: Exception) {
                result.error("PERMISSION_ERROR", e.message, null)
            }
        }
    }

    private fun getTodaySteps(result: MethodChannel.Result) {
        scope.launch {
            try {
                val client = healthConnectClient ?: return@launch result.success(0)

                val endTime = Instant.now()
                val startTime = endTime.truncatedTo(ChronoUnit.DAYS)

                val request = ReadRecordsRequest(
                    recordType = StepsRecord::class,
                    timeRangeFilter = TimeRangeFilter.between(startTime, endTime)
                )

                val response = client.readRecords(request)
                val totalSteps = response.records.sumOf { it.count }

                result.success(totalSteps.toInt())
            } catch (e: Exception) {
                result.error("READ_ERROR", e.message, null)
            }
        }
    }

    private fun getLatestHeartRate(result: MethodChannel.Result) {
        scope.launch {
            try {
                val client = healthConnectClient ?: return@launch result.success(null)

                val endTime = Instant.now()
                val startTime = endTime.minus(1, ChronoUnit.HOURS)

                val request = ReadRecordsRequest(
                    recordType = HeartRateRecord::class,
                    timeRangeFilter = TimeRangeFilter.between(startTime, endTime)
                )

                val response = client.readRecords(request)

                if (response.records.isNotEmpty()) {
                    val latestRecord = response.records.last()
                    val latestSample = latestRecord.samples.lastOrNull()

                    if (latestSample != null) {
                        result.success(mapOf(
                            "timestamp" to latestSample.time.toEpochMilli(),
                            "bpm" to latestSample.beatsPerMinute.toInt(),
                            "recordId" to latestRecord.metadata.id
                        ))
                        return@launch
                    }
                }

                result.success(null)
            } catch (e: Exception) {
                result.error("READ_ERROR", e.message, null)
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        scope.cancel()
    }
}
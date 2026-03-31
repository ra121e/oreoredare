package com.example.oreoredare

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private lateinit var incomingCallMonitor: IncomingCallMonitor

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        incomingCallMonitor = IncomingCallMonitor(
            activity = this,
            applicationContext = applicationContext,
        )

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            IncomingCallMonitor.eventChannelName,
        ).setStreamHandler(IncomingCallEventDispatcher)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            IncomingCallMonitor.methodChannelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                IncomingCallMonitor.initializeMonitoringMethod -> {
                    result.success(incomingCallMonitor.initializeMonitoring())
                }
                IncomingCallMonitor.requestCallScreeningRoleMethod -> {
                    result.success(incomingCallMonitor.requestCallScreeningRoleIfNeeded())
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        if (::incomingCallMonitor.isInitialized) {
            incomingCallMonitor.dispose()
        }

        super.onDestroy()
    }
}

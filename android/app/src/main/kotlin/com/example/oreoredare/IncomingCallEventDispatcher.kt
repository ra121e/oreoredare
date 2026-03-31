package com.example.oreoredare

import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.EventChannel

/**
 * CallScreeningService と MainActivity から共通で使う着信イベント配信口。
 *
 * Flutter 側の EventChannel は Activity で初期化されるが、
 * 実際の着信検知は Service 側から先に発生することがある。
 * そのため、Flutter の購読がまだ始まっていない場合はイベントを一時保持し、
 * 購読開始後にまとめて流せるようにする。
 */
object IncomingCallEventDispatcher : EventChannel.StreamHandler {
    private const val tag = "IncomingCallDispatcher"
    private val mainHandler = Handler(Looper.getMainLooper())
    private val pendingEvents = mutableListOf<Map<String, Any?>>()
    private var eventSink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        mainHandler.post {
            eventSink = events
            Log.i(tag, "EventChannel listener attached. pending=${pendingEvents.size}")

            if (pendingEvents.isEmpty()) {
                return@post
            }

            pendingEvents.forEach(events::success)
            pendingEvents.clear()
            Log.i(tag, "Pending events flushed to Flutter.")
        }
    }

    override fun onCancel(arguments: Any?) {
        mainHandler.post {
            eventSink = null
            Log.i(tag, "EventChannel listener detached.")
        }
    }

    fun publish(event: Map<String, Any?>) {
        mainHandler.post {
            val sink = eventSink
            if (sink == null) {
                pendingEvents.add(event)
                Log.i(
                    tag,
                    "Event queued because Flutter listener is not attached yet. type=${event["eventType"]}",
                )
                return@post
            }

            sink.success(event)
            Log.i(tag, "Event delivered to Flutter. type=${event["eventType"]}")
        }
    }
}

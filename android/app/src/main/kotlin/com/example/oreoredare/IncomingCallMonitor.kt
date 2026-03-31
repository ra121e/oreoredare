package com.example.oreoredare

import android.Manifest
import android.app.role.RoleManager
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.telephony.PhoneStateListener
import android.telephony.TelephonyManager
import androidx.core.content.ContextCompat

class IncomingCallMonitor(
    private val activity: Activity,
    private val applicationContext: Context,
) {
    private val telephonyManager =
        applicationContext.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager

    private var hasStartedMonitoring = false
    private var lastCallState = TelephonyManager.CALL_STATE_IDLE
    private var lastPhoneNumber: String? = null

    companion object {
        const val eventChannelName = "oreoredare/incoming_call_events"
        const val methodChannelName = "oreoredare/incoming_call_bridge"
        const val initializeMonitoringMethod = "initializeMonitoring"
        const val requestCallScreeningRoleMethod = "requestCallScreeningRoleIfNeeded"
        private const val roleRequestCode = 42001
    }

    @Suppress("DEPRECATION", "OVERRIDE_DEPRECATION")
    private val phoneStateListener =
        object : PhoneStateListener() {
            override fun onCallStateChanged(state: Int, phoneNumber: String?) {
                super.onCallStateChanged(state, phoneNumber)
                handleCallStateChanged(state, phoneNumber)
            }
        }

    fun initializeMonitoring(): Map<String, Any?> {
        val hasPermission = hasReadPhoneStatePermission()
        val hasContactsPermission = hasReadContactsPermission()

        if (!hasPermission) {
            return mapOf(
                "permissionGranted" to false,
                "contactsPermissionGranted" to hasContactsPermission,
                "monitoringActive" to false,
                "source" to "call_screening_service",
                "callScreeningRoleGranted" to isCallScreeningRoleGranted(),
                "shouldRequestCallScreeningRole" to false,
                "message" to "READ_PHONE_STATE 権限が未許可のため、着信監視を開始できません。",
            )
        }

        if (!hasStartedMonitoring) {
            /*
             * CallScreeningService を incoming_call の主経路にしつつ、
             * PhoneStateListener は「通話が開始された」「通話が終わった」を
             * Flutter 側へ返す補助経路として使う。
             *
             * これにより、AQUOS sense8 のような実機で
             * 「着信時にオーバーレイを出す」最小構成を保ちながら、
             * 後続の画面クローズ処理も扱いやすくする。
             */
            @Suppress("DEPRECATION")
            telephonyManager.listen(
                phoneStateListener,
                PhoneStateListener.LISTEN_CALL_STATE,
            )
            hasStartedMonitoring = true
        }

        val roleGranted = isCallScreeningRoleGranted()

        return mapOf(
            "permissionGranted" to true,
            "contactsPermissionGranted" to hasContactsPermission,
            "monitoringActive" to true,
            "source" to if (roleGranted) "call_screening_service" else "phone_state_listener_fallback",
            "callScreeningRoleGranted" to roleGranted,
            "shouldRequestCallScreeningRole" to (!roleGranted && supportsCallScreeningRole()),
            "message" to if (roleGranted) {
                if (hasContactsPermission) {
                    "着信監視を開始しました。incoming_call は CallScreeningService から受け取り、連絡先登録済み番号も対象にします。"
                } else {
                    "着信監視を開始しました。incoming_call は CallScreeningService から受け取ります。連絡先登録済み番号も対象にするには連絡先権限が必要です。"
                }
            } else {
                buildString {
                    append("着信監視を開始しました。Call Screening role が未付与のため、まずは PhoneStateListener を暫定入口として使います。")
                    if (!hasContactsPermission) {
                        append(" 連絡先登録済み番号を含めた screening には、Call Screening role と連絡先権限の両方が必要です。")
                    }
                }
            },
        )
    }

    fun requestCallScreeningRoleIfNeeded(): Map<String, Any?> {
        if (!supportsCallScreeningRole()) {
            return mapOf(
                "roleRequestLaunched" to false,
                "message" to "この Android バージョンでは Call Screening role を要求できません。",
            )
        }

        val roleManager = activity.getSystemService(RoleManager::class.java)
        if (roleManager == null || !roleManager.isRoleAvailable(RoleManager.ROLE_CALL_SCREENING)) {
            return mapOf(
                "roleRequestLaunched" to false,
                "message" to "端末側で Call Screening role が利用できません。",
            )
        }

        if (roleManager.isRoleHeld(RoleManager.ROLE_CALL_SCREENING)) {
            return mapOf(
                "roleRequestLaunched" to false,
                "message" to "Call Screening role はすでに付与されています。",
            )
        }

        val intent = roleManager.createRequestRoleIntent(RoleManager.ROLE_CALL_SCREENING)
        @Suppress("DEPRECATION")
        activity.startActivityForResult(intent, roleRequestCode)

        return mapOf(
            "roleRequestLaunched" to true,
            "message" to "Call Screening role の許可画面を開きました。AQUOS sense8 側で本アプリを許可してください。",
        )
    }

    fun dispose() {
        if (!hasStartedMonitoring) {
            return
        }

        @Suppress("DEPRECATION")
        telephonyManager.listen(phoneStateListener, PhoneStateListener.LISTEN_NONE)
        hasStartedMonitoring = false
    }

    private fun hasReadPhoneStatePermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            activity,
            Manifest.permission.READ_PHONE_STATE,
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun hasReadContactsPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            activity,
            Manifest.permission.READ_CONTACTS,
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun handleCallStateChanged(state: Int, phoneNumber: String?) {
        val normalizedPhoneNumber = phoneNumber?.takeUnless { it.isBlank() }
        val previousPhoneNumber = lastPhoneNumber

        // 同じ状態が連続で飛んできても、不要なオーバーレイ再表示は避ける。
        if (state == lastCallState && normalizedPhoneNumber == lastPhoneNumber) {
            return
        }

        lastCallState = state
        lastPhoneNumber = normalizedPhoneNumber ?: previousPhoneNumber

        val eventPhoneNumber = normalizedPhoneNumber ?: previousPhoneNumber

        when (state) {
            TelephonyManager.CALL_STATE_RINGING -> {
                if (!isCallScreeningRoleGranted()) {
                    publishEvent(
                        eventType = "incoming_call",
                        phoneNumber = eventPhoneNumber,
                        source = "phone_state_listener_fallback",
                        callState = callStateName(state),
                    )
                }
            }
            TelephonyManager.CALL_STATE_OFFHOOK -> {
                publishEvent(
                    eventType = "call_connected",
                    phoneNumber = eventPhoneNumber,
                    source = "phone_state_listener",
                    callState = callStateName(state),
                )
            }
            TelephonyManager.CALL_STATE_IDLE -> {
                publishEvent(
                    eventType = "call_ended",
                    phoneNumber = eventPhoneNumber,
                    source = "phone_state_listener",
                    callState = callStateName(state),
                )

                lastPhoneNumber = null
            }
        }
    }

    private fun publishEvent(
        eventType: String,
        phoneNumber: String?,
        source: String,
        callState: String,
    ) {
        IncomingCallEventDispatcher.publish(
            mapOf(
                "eventType" to eventType,
                "timestamp" to System.currentTimeMillis(),
                "phoneNumber" to phoneNumber,
                "source" to source,
                "callState" to callState,
            ),
        )
    }

    private fun supportsCallScreeningRole(): Boolean {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q
    }

    private fun isCallScreeningRoleGranted(): Boolean {
        if (!supportsCallScreeningRole()) {
            return false
        }

        val roleManager = activity.getSystemService(RoleManager::class.java) ?: return false
        return roleManager.isRoleAvailable(RoleManager.ROLE_CALL_SCREENING) &&
            roleManager.isRoleHeld(RoleManager.ROLE_CALL_SCREENING)
    }

    private fun callStateName(state: Int): String {
        return when (state) {
            TelephonyManager.CALL_STATE_RINGING -> "CALL_STATE_RINGING"
            TelephonyManager.CALL_STATE_OFFHOOK -> "CALL_STATE_OFFHOOK"
            TelephonyManager.CALL_STATE_IDLE -> "CALL_STATE_IDLE"
            else -> "CALL_STATE_UNKNOWN"
        }
    }
}

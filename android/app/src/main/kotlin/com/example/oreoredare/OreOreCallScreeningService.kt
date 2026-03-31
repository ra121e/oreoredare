package com.example.oreoredare

import android.os.Build
import android.util.Log
import android.telecom.Call
import android.telecom.CallScreeningService
import androidx.annotation.RequiresApi

/**
 * 初回 MVP の着信入口。
 *
 * 今回は「実際の着信を Android ネイティブで検知し、
 * Flutter 側で既存オーバーレイを自動表示する」ことが目的なので、
 * Android 10 以降で caller ID / spam role と相性のよい
 * CallScreeningService を最初の入口として採用する。
 *
 * この Service 自体は通話をブロックしない。
 * 今は着信イベントを Flutter へ伝えるだけにとどめ、
 * 実際の通話制御や AI 応答は次のフェーズに回す。
 *
 * 注意:
 * - 実際にコールバックを受けるには、端末で本アプリに
 *   Call Screening role を付与する必要がある。
 * - バックグラウンドやロック画面では、Android の制約により
 *   Flutter 側オーバーレイを即時表示できない場合がある。
 *   初回 MVP では「アプリが前面にある状態」での成立を優先する。
 */
@RequiresApi(Build.VERSION_CODES.N)
class OreOreCallScreeningService : CallScreeningService() {
    companion object {
        private const val tag = "OreOreCallScreening"
    }

    override fun onScreenCall(callDetails: Call.Details) {
        val incomingPhoneNumber =
            callDetails.handle
                ?.schemeSpecificPart
                ?.takeUnless { it.isBlank() }

        Log.i(
            tag,
            "onScreenCall received. phone=${incomingPhoneNumber ?: "unknown"}",
        )

        IncomingCallEventDispatcher.publish(
            mapOf(
                "eventType" to "incoming_call",
                "timestamp" to System.currentTimeMillis(),
                "phoneNumber" to incomingPhoneNumber,
                "source" to "call_screening_service",
                "callState" to "CALL_STATE_RINGING",
            ),
        )

        Log.i(tag, "incoming_call event published to dispatcher.")

        // 初回 MVP ではブロックせず、通常の着信をそのまま継続させる。
        respondToCall(callDetails, CallResponse.Builder().build())
    }
}

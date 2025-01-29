package com.example.sms_listener_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.telephony.SmsMessage
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log

class SmsReceiver : BroadcastReceiver() {
    private var channel: MethodChannel? = null

    // This should be called from MainActivity to initialize the MethodChannel
    fun setChannel(flutterEngine: FlutterEngine) {
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.sms/sms")
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == "android.provider.Telephony.SMS_RECEIVED") {
            val bundle: Bundle? = intent.extras
            if (bundle != null) {
                val pdus = bundle["pdus"] as Array<*>
                for (pdu in pdus) {
                    val message = SmsMessage.createFromPdu(pdu as ByteArray)
                    val smsBody = message.messageBody

                    // Log received SMS for debugging
                    Log.d("SmsReceiver", "Received SMS: $smsBody")

                    // Check if the channel is initialized
                    channel?.invokeMethod("smsReceived", smsBody) ?: Log.e("SmsReceiver", "MethodChannel not initialized")
                }
            }
        }
    }
}
package com.example.sms_listener_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Bundle
import android.telephony.SmsMessage
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log

class MainActivity : FlutterActivity() {
    private val channelName = "com.example.sms/sms"
    private lateinit var smsReceiver: SmsReceiver

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        smsReceiver = SmsReceiver() // Initialize the SmsReceiver here
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            if (call.method == "startListening") {
                startListening(flutterEngine)
                result.success("Listening for SMS")
            } else {
                result.notImplemented()
            }
        }
    }

    private fun startListening(flutterEngine: FlutterEngine) {
        // Set the channel for the receiver
        smsReceiver.setChannel(flutterEngine)

        val filter = IntentFilter("android.provider.Telephony.SMS_RECEIVED")
        registerReceiver(smsReceiver, filter)
        Log.d("MainActivity", "SMS Receiver registered")

        // Start the foreground service
        val serviceIntent = Intent(this, SmsForegroundService::class.java)
        startForegroundService(serviceIntent)
    }

    override fun onDestroy() {
        super.onDestroy()
        // Unregister the receiver to prevent memory leaks
        unregisterReceiver(smsReceiver)
        Log.d("MainActivity", "SMS Receiver unregistered")
    }

    class SmsReceiver : BroadcastReceiver() {
        private var channel: MethodChannel? = null

        fun setChannel(flutterEngine: FlutterEngine) {
            channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.sms/sms")
        }

        override fun onReceive(context: Context, intent: Intent) {
            val bundle = intent.extras
            if (bundle != null) {
                val pdus = bundle["pdus"] as Array<*>?
                if (pdus != null) {
                    for (pdu in pdus) {
                        val smsMessage = SmsMessage.createFromPdu(pdu as ByteArray)
                        val messageBody = smsMessage.messageBody

                        // Log received SMS for debugging
                        Log.d("SmsReceiver", "Received SMS: $messageBody")

                        // Send SMS content to Dart
                        channel?.invokeMethod("smsReceived", messageBody) ?: run {
                            Log.e("SmsReceiver", "MethodChannel not initialized")
                        }
                    }
                } else {
                    Log.e("SmsReceiver", "Received null PDUs")
                }
            } else {
                Log.e("SmsReceiver", "Received null bundle")
            }
        }
    }
}
package com.example.final_project_doa

import android.app.AlarmManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  private val CHANNEL = "exact_alarm"

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
      .setMethodCallHandler { call, result ->
        when (call.method) {
          "canScheduleExact" -> {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
              val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
              result.success(am.canScheduleExactAlarms())
            } else {
              result.success(true)
            }
          }
          "requestPermission" -> {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
              val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
              }
              startActivity(intent)
            }
            result.success(null)
          }
          else -> result.notImplemented()
        }
      }
  }
}

package com.jftsensei.jftsensei_app

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Blocked until the app learns from the server that screenshots are allowed.
        setSecure(true)
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "jftsensei/secure").setMethodCallHandler { call, result ->
            if (call.method == "setSecure") {
                setSecure(call.arguments as? Boolean ?: true)
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }

    // FLAG_SECURE blocks screenshots and screen recording, and blanks the app in the recents screen.
    private fun setSecure(on: Boolean) {
        if (on) window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
        else window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }
}

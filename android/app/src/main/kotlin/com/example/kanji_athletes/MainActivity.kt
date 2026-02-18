package com.example.kanji_athletes

import android.media.MediaScannerConnection
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val CHANNEL = "kanji_athletes/saver"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
			if (call.method == "scanFile") {
				val filePath = call.argument<String>("path")
				if (filePath != null) {
					try {
						MediaScannerConnection.scanFile(this, arrayOf(filePath), null, null)
						result.success(true)
					} catch (e: Exception) {
						result.error("scan_failed", e.message, null)
					}
				} else {
					result.error("no_path", "No path provided", null)
				}
			} else {
				result.notImplemented()
			}
		}
	}
}

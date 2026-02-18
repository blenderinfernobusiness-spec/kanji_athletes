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
			when (call.method) {
				"scanFile" -> {
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
				}
				"insertImage" -> {
					try {
						val bytes = call.argument<ByteArray>("bytes")
						val filename = call.argument<String>("filename") ?: "screenshot.png"
						if (bytes == null) {
							result.error("no_bytes", "No image bytes provided", null)
						} else {
							val resolver = contentResolver
							val values = android.content.ContentValues().apply {
								put(android.provider.MediaStore.MediaColumns.DISPLAY_NAME, filename)
								put(android.provider.MediaStore.MediaColumns.MIME_TYPE, "image/png")
								if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
									put(android.provider.MediaStore.MediaColumns.RELATIVE_PATH, android.os.Environment.DIRECTORY_PICTURES + "/KanjiAthletes")
								}
							}
							val uri = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
								resolver.insert(android.provider.MediaStore.Images.Media.getContentUri(android.provider.MediaStore.VOLUME_EXTERNAL_PRIMARY), values)
							} else {
								resolver.insert(android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
							}
							if (uri != null) {
								resolver.openOutputStream(uri).use { out ->
									out?.write(bytes)
								}
								result.success(uri.toString())
							} else {
								result.error("insert_failed", "Could not insert image into MediaStore", null)
							}
						}
					} catch (e: Exception) {
						result.error("insert_error", e.message, null)
					}
				}
				else -> result.notImplemented()
			}
		}
	}
}

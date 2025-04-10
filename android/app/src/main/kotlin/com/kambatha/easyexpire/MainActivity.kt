package com.kambatha.easyexpire

import android.media.RingtoneManager
import android.net.Uri
import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.android.FlutterActivity
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "ringtone_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getRingtones") {
                val ringtoneList = getRingtones()
                result.success(ringtoneList)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getRingtones(): List<Map<String, String>> {
        val list = mutableListOf<Map<String, String>>()
        val ringtoneManager = RingtoneManager(applicationContext)
        ringtoneManager.setType(RingtoneManager.TYPE_RINGTONE)
        val cursor = ringtoneManager.cursor

        while (cursor.moveToNext()) {
            val title = cursor.getString(RingtoneManager.TITLE_COLUMN_INDEX)
            val uri = ringtoneManager.getRingtoneUri(cursor.position)
            val filePath = copyUriToFile(applicationContext, uri)
            if (filePath != null) {
                list.add(mapOf("title" to title, "path" to filePath))
            }
        }

        cursor.close()
        return list
    }

    private fun copyUriToFile(context: Context, uri: Uri): String? {
        return try {
            val inputStream = context.contentResolver.openInputStream(uri) ?: return null
            val tempFile = File.createTempFile("ringtone_", ".mp3", context.cacheDir)

            inputStream.use { input ->
                FileOutputStream(tempFile).use { output ->
                    input.copyTo(output)
                }
            }

            tempFile.absolutePath
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
}

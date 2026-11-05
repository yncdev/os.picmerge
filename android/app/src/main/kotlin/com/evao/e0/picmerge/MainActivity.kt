package com.evao.e0.picmerge

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.core.content.FileProvider
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec
import java.io.File

class MainActivity : FlutterActivity() {
    private var pendingFolderResult: MethodChannel.Result? = null
    private var pendingPdfResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        // 디코딩·인코딩·복사는 백그라운드 TaskQueue에서 실행한다 (DESIGN §3.1).
        MethodChannel(
            messenger,
            WORK_CHANNEL,
            StandardMethodCodec.INSTANCE,
            messenger.makeBackgroundTaskQueue(),
        ).setMethodCallHandler(NativeImageBridge(applicationContext))
        // 폴더·문서 선택기와 공유 시트는 Activity가 필요해 메인 스레드 채널로 둔다.
        MethodChannel(messenger, UI_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickFolder" -> pickFolder(result)
                "pickPdfs" -> pickPdfs(result)
                "shareFile" -> shareFile(
                    call.argument<String>("path")!!,
                    call.argument<String>("mimeType")!!,
                    call.argument<String>("name")!!,
                    result,
                )
                "appInfo" -> appInfo(result)
                "composeEmail" -> composeEmail(
                    call.argument<String>("to")!!,
                    call.argument<String>("subject")!!,
                    result,
                )
                else -> result.notImplemented()
            }
        }
    }

    /** 프로그램 정보 화면과 의견 보내기 제목에 쓴다 (DESIGN §2.2). */
    private fun appInfo(result: MethodChannel.Result) {
        try {
            val info = packageManager.getPackageInfo(packageName, 0)
            val buildNumber = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                info.longVersionCode
            } else {
                @Suppress("DEPRECATION")
                info.versionCode.toLong()
            }
            result.success(
                mapOf(
                    "versionName" to (info.versionName ?: ""),
                    "buildNumber" to buildNumber.toString(),
                    "manufacturer" to Build.MANUFACTURER,
                    "model" to Build.MODEL,
                    "osName" to "Android",
                    "osVersion" to Build.VERSION.RELEASE,
                ),
            )
        } catch (e: Exception) {
            result.error("unknown", e.message, null)
        }
    }

    /**
     * 메일 앱만 받는 ACTION_SENDTO로 받는 사람과 제목을 채워 연다. 보내는 것은 사용자가 한다 (DESIGN §2.2).
     * 패키지를 미리 조회하지 않아 `<queries>`와 권한이 필요 없다. 메일 앱이 없으면 false를 돌려준다.
     */
    private fun composeEmail(to: String, subject: String, result: MethodChannel.Result) {
        val intent = Intent(Intent.ACTION_SENDTO, Uri.parse(mailtoUri(to, subject)))
            .putExtra(Intent.EXTRA_EMAIL, arrayOf(to))
            .putExtra(Intent.EXTRA_SUBJECT, subject)
        try {
            startActivity(intent)
            result.success(true)
        } catch (e: ActivityNotFoundException) {
            result.success(false)
        } catch (e: Exception) {
            result.error("unknown", e.message, null)
        }
    }

    private fun pickFolder(result: MethodChannel.Result) {
        if (pendingFolderResult != null) {
            result.error("busy", "folder picker already open", null)
            return
        }
        pendingFolderResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).addFlags(
            Intent.FLAG_GRANT_READ_URI_PERMISSION or
                Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION,
        )
        try {
            startActivityForResult(intent, REQUEST_PICK_FOLDER)
        } catch (e: Exception) {
            pendingFolderResult = null
            result.error("unknown", e.message, null)
        }
    }

    /** 문서 선택기로 PDF를 고른다. 권한이 필요 없고, URI만 돌려준다. 복사는 작업 채널에서 한다. */
    private fun pickPdfs(result: MethodChannel.Result) {
        if (pendingPdfResult != null) {
            result.error("busy", "document picker already open", null)
            return
        }
        pendingPdfResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT)
            .addCategory(Intent.CATEGORY_OPENABLE)
            .setType("application/pdf")
            .putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
        try {
            startActivityForResult(intent, REQUEST_PICK_PDF)
        } catch (e: Exception) {
            pendingPdfResult = null
            result.error("unknown", e.message, null)
        }
    }

    /** 공유 시트를 연다. 받을 앱은 사용자가 고른다 (DESIGN §2.1.7). */
    private fun shareFile(path: String, mimeType: String, name: String, result: MethodChannel.Result) {
        try {
            val uri = FileProvider.getUriForFile(this, "$packageName.share", File(path))
            val send = Intent(Intent.ACTION_SEND)
                .setType(mimeType)
                .putExtra(Intent.EXTRA_STREAM, uri)
                .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            // 공유 시트 미리보기와 권한 전달에 필요하다.
            send.clipData = ClipData.newRawUri(name, uri)
            startActivity(Intent.createChooser(send, null))
            result.success(null)
        } catch (e: Exception) {
            result.error("unknown", e.message, null)
        }
    }

    @Deprecated("FlutterActivity는 ComponentActivity가 아니라 Activity Result API를 쓸 수 없다")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_PICK_PDF) {
            val result = pendingPdfResult ?: return
            pendingPdfResult = null
            val uris = mutableListOf<String>()
            if (resultCode == Activity.RESULT_OK && data != null) {
                val clip = data.clipData
                if (clip != null) {
                    for (i in 0 until clip.itemCount) uris.add(clip.getItemAt(i).uri.toString())
                } else {
                    data.data?.let { uris.add(it.toString()) }
                }
            }
            result.success(uris)
            return
        }
        if (requestCode != REQUEST_PICK_FOLDER) return
        val result = pendingFolderResult ?: return
        pendingFolderResult = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return
        }
        try {
            contentResolver.takePersistableUriPermission(uri, READ_WRITE)
            releaseOtherFolders(uri)
            val name = DocumentFile.fromTreeUri(this, uri)?.name ?: uri.lastPathSegment ?: ""
            result.success(mapOf("uri" to uri.toString(), "name" to name))
        } catch (e: SecurityException) {
            result.error("folder_unavailable", e.message, null)
        } catch (e: Exception) {
            // 다른 앱의 선택기가 트리 URI가 아닌 값을 돌려주면 IllegalArgumentException이 난다.
            result.error("folder_unavailable", e.message, null)
        }
    }

    /** 이전에 고른 폴더의 영구 권한을 돌려준다. 앱당 영구 권한 수에는 상한이 있다. */
    private fun releaseOtherFolders(keep: Uri) {
        for (permission in contentResolver.persistedUriPermissions) {
            if (permission.uri == keep) continue
            var flags = 0
            if (permission.isReadPermission) flags = flags or Intent.FLAG_GRANT_READ_URI_PERMISSION
            if (permission.isWritePermission) flags = flags or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            try {
                contentResolver.releasePersistableUriPermission(permission.uri, flags)
            } catch (_: SecurityException) {
            }
        }
    }

    companion object {
        private const val WORK_CHANNEL = "image_merger/work"
        private const val UI_CHANNEL = "image_merger/ui"
        private const val REQUEST_PICK_FOLDER = 4101
        private const val REQUEST_PICK_PDF = 4102
        private const val READ_WRITE =
            Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
    }
}

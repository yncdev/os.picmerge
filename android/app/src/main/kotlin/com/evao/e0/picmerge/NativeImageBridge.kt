package com.evao.e0.picmerge

import android.content.ContentValues
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.ColorSpace
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.pdf.PdfRenderer
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.ParcelFileDescriptor
import android.provider.DocumentsContract
import android.provider.MediaStore
import android.provider.OpenableColumns
import androidx.annotation.RequiresApi
import androidx.documentfile.provider.DocumentFile
import androidx.exifinterface.media.ExifInterface
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedOutputStream
import java.io.File
import java.io.FileInputStream
import java.io.FileNotFoundException
import java.io.FileOutputStream
import java.io.IOException
import kotlin.math.floor
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

/** [code]는 DESIGN §3.4 오류 코드 표의 코드와 같다. */
class BridgeException(val code: String, message: String) : Exception(message)

/**
 * 헤더 스캔, 다운샘플 디코딩(자르기·회색조), JPEG 인코딩, PDF 이미지화, 저장 폴더 파일 작업 (DESIGN §3.1).
 * 백그라운드 TaskQueue에서 호출되므로 무거운 작업을 해도 UI가 멈추지 않는다.
 */
class NativeImageBridge(private val context: Context) : MethodChannel.MethodCallHandler {

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            val value: Any? = when (call.method) {
                "cacheDir" -> context.cacheDir.absolutePath
                "scan" -> scan(call.arg("path"))
                "decodeRaw" -> decodeRaw(
                    call.arg("path"), call.arg("width"), call.arg("height"),
                    call.arg("channels"), call.arg("outPath"), call.cropArg(), call.grayscaleArg(),
                )
                "encodeJpeg" -> encodeJpeg(
                    call.arg("path"), call.arg("width"), call.arg("height"),
                    call.arg("quality"), call.arg("outPath"), call.cropArg(), call.grayscaleArg(),
                )
                "importDocument" -> importDocument(call.arg("uri"), call.arg("outPath"))
                "pdfPageCount" -> pdfPageCount(call.arg("path"))
                "renderPdfPage" -> renderPdfPage(
                    call.arg("path"), call.arg("pageIndex"), call.arg("dpi"),
                    call.arg("maxLongSide"), call.arg("quality"), call.arg("outPath"),
                )
                "defaultFolder" -> defaultFolder()
                "checkFolder" -> checkFolder(call.arg("uri"))
                "listNames" -> listNames(call.arg("uri"), call.arg("prefix"))
                "copyToFolder" -> copyToFolder(
                    call.arg("uri"), call.arg("sourcePath"), call.arg("name"), call.arg("mimeType"),
                )
                else -> {
                    result.notImplemented()
                    return
                }
            }
            result.success(value)
        } catch (e: BridgeException) {
            result.error(e.code, e.message, null)
        } catch (e: OutOfMemoryError) {
            result.error("out_of_memory", e.message, null)
        } catch (e: IOException) {
            result.error(if (isNoSpace(e)) "out_of_space" else "unknown", e.message, null)
        } catch (e: Exception) {
            result.error("unknown", e.message, null)
        }
    }

    // ---- 이미지 ----

    private fun scan(path: String): Map<String, Any> {
        val file = File(path)
        if (!file.isFile) throw BridgeException("source_unavailable", "missing: $path")
        val bounds = readBounds(path)
        val mime = bounds.outMimeType?.lowercase()
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0 || mime == null || mime !in SUPPORTED_MIME) {
            throw BridgeException("unsupported_format", "mime=$mime")
        }
        val swapped = isSwapped(readOrientation(path))
        return mapOf(
            "width" to if (swapped) bounds.outHeight else bounds.outWidth,
            "height" to if (swapped) bounds.outWidth else bounds.outHeight,
            "bytes" to file.length(),
            "mime" to mime,
        )
    }

    /** 축소·회전한 픽셀을 행 단위로 [outPath]에 쓴다. 형식: 8비트 RGB 또는 RGBA, 패딩 없음. */
    private fun decodeRaw(
        path: String, width: Int, height: Int, channels: Int, outPath: String,
        crop: CropBox?, grayscale: Boolean,
    ): Map<String, Any> {
        if (channels != 3 && channels != 4) throw BridgeException("unknown", "channels=$channels")
        val bitmap = finishBitmap(decodeOriented(path, width, height, crop), grayscale, flatten = channels == 3)
        try {
            writeRaw(bitmap, channels, File(outPath))
        } finally {
            bitmap.recycle()
        }
        return mapOf("width" to width, "height" to height)
    }

    /** 투명 영역은 흰색으로 채운 뒤 JPEG로 인코딩한다 (DESIGN §2.1.3). */
    private fun encodeJpeg(
        path: String, width: Int, height: Int, quality: Int, outPath: String,
        crop: CropBox?, grayscale: Boolean,
    ): Map<String, Any> {
        val bitmap = finishBitmap(decodeOriented(path, width, height, crop), grayscale, flatten = true)
        val out = File(outPath)
        writeJpeg(bitmap, quality, out)
        return mapOf("width" to width, "height" to height, "bytes" to out.length())
    }

    /** JPEG로 쓰고 [bitmap]을 해제한다. 실패하면 쓰다 만 파일을 지운다. */
    private fun writeJpeg(bitmap: Bitmap, quality: Int, out: File) {
        try {
            FileOutputStream(out).use { stream ->
                if (!bitmap.compress(Bitmap.CompressFormat.JPEG, quality, stream)) {
                    throw BridgeException("unknown", "JPEG encode failed")
                }
            }
        } catch (e: Throwable) {
            out.delete()
            throw e
        } finally {
            bitmap.recycle()
        }
    }

    /** 회색조를 적용하고, [flatten]이면 투명 영역을 흰색 위에 합친다. 할 일이 없으면 그대로 돌려준다. */
    private fun finishBitmap(bitmap: Bitmap, grayscale: Boolean, flatten: Boolean): Bitmap {
        val fill = flatten && bitmap.hasAlpha()
        if (!grayscale && !fill) return bitmap
        val out = Bitmap.createBitmap(bitmap.width, bitmap.height, Bitmap.Config.ARGB_8888)
        val paint = Paint().apply {
            if (grayscale) colorFilter = ColorMatrixColorFilter(ColorMatrix().apply { setSaturation(0f) })
        }
        Canvas(out).apply {
            if (fill) drawColor(Color.WHITE)
            drawBitmap(bitmap, 0f, 0f, paint)
        }
        bitmap.recycle()
        return out
    }

    // ---- PDF ----

    /** 문서 선택기가 준 URI를 앱 캐시로 복사한다. PdfRenderer는 탐색 가능한 파일이 필요하다. */
    private fun importDocument(uriString: String, outPath: String): Map<String, Any> {
        val uri = Uri.parse(uriString)
        val out = File(outPath)
        var name = uri.lastPathSegment?.substringAfterLast('/') ?: "document.pdf"
        try {
            context.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use {
                if (it.moveToFirst()) it.getString(0)?.let { value -> name = value }
            }
            val input = context.contentResolver.openInputStream(uri)
                ?: throw BridgeException("source_unavailable", "openInputStream returned null")
            input.use { source -> FileOutputStream(out).use { source.copyTo(it, 1 shl 16) } }
        } catch (e: SecurityException) {
            out.delete()
            throw BridgeException("source_unavailable", e.message ?: "security")
        } catch (e: FileNotFoundException) {
            out.delete()
            throw BridgeException("source_unavailable", e.message ?: "not found")
        } catch (e: Throwable) {
            out.delete()
            throw e
        }
        return mapOf("name" to name)
    }

    private fun <T> withPdf(path: String, block: (PdfRenderer) -> T): T {
        val descriptor = try {
            ParcelFileDescriptor.open(File(path), ParcelFileDescriptor.MODE_READ_ONLY)
        } catch (e: FileNotFoundException) {
            throw BridgeException("source_unavailable", "missing: $path")
        }
        val renderer = try {
            PdfRenderer(descriptor) // 성공하면 닫는 책임이 renderer로 넘어간다.
        } catch (e: SecurityException) {
            descriptor.close()
            throw BridgeException("unsupported_format", "password protected")
        } catch (e: IOException) {
            descriptor.close()
            throw BridgeException("corrupt_file", e.message ?: "not a PDF")
        }
        try {
            return block(renderer)
        } finally {
            renderer.close()
        }
    }

    private fun pdfPageCount(path: String): Int = withPdf(path) { it.pageCount }

    /** 한 페이지만 렌더링해 JPEG로 쓰고 바로 해제한다 (DESIGN §2.1.1). */
    private fun renderPdfPage(
        path: String, pageIndex: Int, dpi: Int, maxLongSide: Int, quality: Int, outPath: String,
    ): Map<String, Any> = withPdf(path) { renderer ->
        if (pageIndex !in 0 until renderer.pageCount) throw BridgeException("unknown", "page $pageIndex")
        val page = renderer.openPage(pageIndex)
        try {
            // PdfRenderer의 페이지 크기는 포인트(1/72인치) 단위다.
            val scale = min(dpi / 72.0, maxLongSide.toDouble() / max(page.width, page.height))
            val width = max(1, (page.width * scale).roundToInt())
            val height = max(1, (page.height * scale).roundToInt())
            val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            bitmap.eraseColor(Color.WHITE)
            // FOR_DISPLAY는 LCD 서브픽셀 글자라 색 번짐이 생긴다.
            page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_PRINT)
            writeJpeg(bitmap, quality, File(outPath))
            mapOf("width" to width, "height" to height)
        } finally {
            page.close()
        }
    }

    /**
     * [crop] 영역(EXIF 회전 반영 후 비율 좌표)을 [targetWidth]×[targetHeight]로 디코딩한다.
     * inSampleSize로 원본보다 작게 읽어 메모리를 아낀 뒤, 한 번의 변환으로 자르기·축소·회전을 함께 한다.
     */
    private fun decodeOriented(path: String, targetWidth: Int, targetHeight: Int, crop: CropBox?): Bitmap {
        if (targetWidth <= 0 || targetHeight <= 0) throw BridgeException("unknown", "bad target size")
        if (!File(path).isFile) throw BridgeException("source_unavailable", "missing: $path")
        val orientation = readOrientation(path)
        val swapped = isSwapped(orientation)
        val rawTargetW = if (swapped) targetHeight else targetWidth
        val rawTargetH = if (swapped) targetWidth else targetHeight

        val bounds = readBounds(path)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) throw BridgeException("corrupt_file", "bounds")
        val region = (crop ?: CropBox.FULL).toRaw(orientation)
        val regionW = bounds.outWidth * region.width
        val regionH = bounds.outHeight * region.height
        var sample = 1
        while (regionW / (sample * 2) >= rawTargetW && regionH / (sample * 2) >= rawTargetH) {
            sample *= 2
        }
        val options = BitmapFactory.Options().apply {
            inSampleSize = sample
            inPreferredConfig = Bitmap.Config.ARGB_8888
            // Display P3 사진을 sRGB로 받는다. JPEG(PDF)는 DeviceRGB로 들어가므로 P3 값이면 색이 바랜다.
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                inPreferredColorSpace = ColorSpace.get(ColorSpace.Named.SRGB)
            }
        }
        val decoded = BitmapFactory.decodeFile(path, options)
            // 헤더는 읽혔는데 디코딩이 안 되면 HEIF는 기기 디코더가 못 푸는 변형(예: 10비트)일 가능성이 크다.
            ?: throw if (bounds.outMimeType?.lowercase()?.let { it in HEIF_MIME } == true) {
                BridgeException("unsupported_format", "HEIF decode failed")
            } else {
                BridgeException("corrupt_file", "decode failed")
            }

        val srcX = floor(region.left * decoded.width).toInt().coerceIn(0, decoded.width - 1)
        val srcY = floor(region.top * decoded.height).toInt().coerceIn(0, decoded.height - 1)
        val srcW = (region.width * decoded.width).roundToInt().coerceIn(1, decoded.width - srcX)
        val srcH = (region.height * decoded.height).roundToInt().coerceIn(1, decoded.height - srcY)
        val matrix = Matrix().apply {
            setScale(rawTargetW.toFloat() / srcW, rawTargetH.toFloat() / srcH)
            postConcat(orientationMatrix(orientation))
        }
        var result = Bitmap.createBitmap(decoded, srcX, srcY, srcW, srcH, matrix, true)
        if (result !== decoded) decoded.recycle()
        if (result.width != targetWidth || result.height != targetHeight) {
            // 부동소수점 반올림으로 1px 어긋난 경우를 맞춘다.
            val fixed = Bitmap.createScaledBitmap(result, targetWidth, targetHeight, true)
            if (fixed !== result) result.recycle()
            result = fixed
        }
        return result
    }

    private fun writeRaw(bitmap: Bitmap, channels: Int, out: File) {
        val width = bitmap.width
        val row = IntArray(width)
        val buffer = ByteArray(width * channels)
        try {
            BufferedOutputStream(FileOutputStream(out), 1 shl 16).use { stream ->
                for (y in 0 until bitmap.height) {
                    // getPixels는 premultiply되지 않은 ARGB를 돌려준다.
                    bitmap.getPixels(row, 0, width, 0, y, width, 1)
                    var i = 0
                    for (color in row) {
                        buffer[i++] = (color shr 16).toByte()
                        buffer[i++] = (color shr 8).toByte()
                        buffer[i++] = color.toByte()
                        if (channels == 4) buffer[i++] = (color ushr 24).toByte()
                    }
                    stream.write(buffer)
                }
            }
        } catch (e: Throwable) {
            out.delete()
            throw e
        }
    }

    private fun readBounds(path: String): BitmapFactory.Options =
        BitmapFactory.Options().apply {
            inJustDecodeBounds = true
            BitmapFactory.decodeFile(path, this)
        }

    private fun readOrientation(path: String): Int =
        try {
            ExifInterface(path).getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL)
        } catch (e: Exception) {
            ExifInterface.ORIENTATION_NORMAL
        }

    private fun isSwapped(orientation: Int): Boolean = orientation in SWAPPED_ORIENTATIONS

    private fun orientationMatrix(orientation: Int): Matrix = Matrix().apply {
        when (orientation) {
            ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> postScale(-1f, 1f)
            ExifInterface.ORIENTATION_ROTATE_180 -> postRotate(180f)
            ExifInterface.ORIENTATION_FLIP_VERTICAL -> postScale(1f, -1f)
            ExifInterface.ORIENTATION_TRANSPOSE -> {
                postRotate(90f)
                postScale(-1f, 1f)
            }
            ExifInterface.ORIENTATION_ROTATE_90 -> postRotate(90f)
            ExifInterface.ORIENTATION_TRANSVERSE -> {
                postRotate(-90f)
                postScale(-1f, 1f)
            }
            ExifInterface.ORIENTATION_ROTATE_270 -> postRotate(-90f)
        }
    }

    // ---- 기본 저장 폴더 (MediaStore) ----

    /** API 29 미만은 권한 없이 Download에 쓸 수 없어 기본 폴더가 없다 (DESIGN §2.1.4). */
    private fun defaultFolder(): Map<String, Any>? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            mapOf("uri" to DEFAULT_FOLDER_URI, "name" to DEFAULT_FOLDER_NAME)
        } else {
            null
        }

    /** 앱이 만든 파일만 보인다. 다른 파일과 이름이 겹치면 시스템이 이름을 바꾼다. */
    @RequiresApi(Build.VERSION_CODES.Q)
    private fun listDownloads(prefix: String): List<String> {
        val escaped = prefix.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")
        val names = mutableListOf<String>()
        context.contentResolver.query(
            MediaStore.Downloads.EXTERNAL_CONTENT_URI,
            arrayOf(MediaStore.MediaColumns.DISPLAY_NAME),
            "${MediaStore.MediaColumns.DISPLAY_NAME} LIKE ? ESCAPE '\\'",
            arrayOf("$escaped%"),
            null,
        )?.use { cursor ->
            while (cursor.moveToNext()) {
                cursor.getString(0)?.let { names.add(it) }
            }
        } ?: throw BridgeException("folder_unavailable", "query returned null")
        return names
    }

    /**
     * 다 쓸 때까지 IS_PENDING=1로 숨겨 둔다. 실패하면 만든 행을 지워 쓰다 만 파일을 남기지 않는다 (DESIGN §3.4).
     * 시스템이 이름을 바꿀 수 있어 실제 이름을 읽어 돌려준다.
     */
    @RequiresApi(Build.VERSION_CODES.Q)
    private fun copyToDownloads(sourcePath: String, name: String, mimeType: String): Map<String, Any> {
        val resolver = context.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, name)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
            put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }
        val uri = try {
            resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
        } catch (e: Exception) {
            throw BridgeException(
                if (isNoSpace(e)) "out_of_space" else "folder_unavailable",
                e.message ?: "insert failed",
            )
        } ?: throw BridgeException("folder_unavailable", "insert returned null")
        try {
            val out = resolver.openOutputStream(uri)
                ?: throw BridgeException("folder_unavailable", "openOutputStream returned null")
            out.use { stream -> FileInputStream(sourcePath).use { it.copyTo(stream, 1 shl 16) } }
            val published = ContentValues().apply { put(MediaStore.MediaColumns.IS_PENDING, 0) }
            if (resolver.update(uri, published, null, null) == 0) throw IOException("could not publish $uri")
            val actualName = resolver.query(uri, arrayOf(MediaStore.MediaColumns.DISPLAY_NAME), null, null, null)
                ?.use { cursor -> if (cursor.moveToFirst()) cursor.getString(0) else null }
            return mapOf("name" to (actualName ?: name), "uri" to uri.toString())
        } catch (e: Throwable) {
            try {
                resolver.delete(uri, null, null)
            } catch (_: Exception) {
            }
            if (e is SecurityException) throw BridgeException("folder_unavailable", e.message ?: "security")
            throw e
        }
    }

    // ---- SAF ----

    private fun checkFolder(uriString: String): Map<String, Any> {
        if (uriString == DEFAULT_FOLDER_URI) {
            val ok = Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q
            return mapOf("ok" to ok, "name" to if (ok) DEFAULT_FOLDER_NAME else "")
        }
        return try {
            val treeUri = Uri.parse(uriString)
            val persisted = context.contentResolver.persistedUriPermissions
                .any { it.uri == treeUri && it.isWritePermission }
            val dir = DocumentFile.fromTreeUri(context, treeUri)
            val ok = persisted && dir != null && dir.isDirectory && dir.canWrite()
            mapOf("ok" to ok, "name" to (dir?.name ?: ""))
        } catch (e: Exception) {
            mapOf("ok" to false, "name" to "")
        }
    }

    /** 폴더 안에서 [prefix]로 시작하는 파일 이름. 이름 충돌 확인용 (DESIGN §2.1.4). */
    private fun listNames(uriString: String, prefix: String): List<String> {
        if (uriString == DEFAULT_FOLDER_URI) {
            return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) listDownloads(prefix) else emptyList()
        }
        val treeUri = Uri.parse(uriString)
        try {
            val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(
                treeUri, DocumentsContract.getTreeDocumentId(treeUri),
            )
            val names = mutableListOf<String>()
            context.contentResolver.query(
                childrenUri, arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME), null, null, null,
            )?.use { cursor ->
                while (cursor.moveToNext()) {
                    val name = cursor.getString(0)
                    if (name != null && name.startsWith(prefix)) names.add(name)
                }
            } ?: throw BridgeException("folder_unavailable", "query returned null")
            return names
        } catch (e: SecurityException) {
            throw BridgeException("folder_unavailable", e.message ?: "security")
        } catch (e: IllegalArgumentException) {
            throw BridgeException("folder_unavailable", e.message ?: "bad uri")
        }
    }

    /** 실패하면 폴더에 만든 파일을 지운다 (DESIGN §3.4). */
    private fun copyToFolder(uriString: String, sourcePath: String, name: String, mimeType: String): Map<String, Any> {
        if (uriString == DEFAULT_FOLDER_URI) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                throw BridgeException("folder_unavailable", "no default folder before API 29")
            }
            return copyToDownloads(sourcePath, name, mimeType)
        }
        val dir = try {
            DocumentFile.fromTreeUri(context, Uri.parse(uriString))
        } catch (e: Exception) {
            null
        } ?: throw BridgeException("folder_unavailable", "tree")
        val doc = try {
            dir.createFile(mimeType, name)
        } catch (e: SecurityException) {
            null
        } ?: throw BridgeException("folder_unavailable", "createFile failed")
        try {
            val out = context.contentResolver.openOutputStream(doc.uri, "w")
                ?: throw BridgeException("folder_unavailable", "openOutputStream returned null")
            out.use { stream -> FileInputStream(sourcePath).use { it.copyTo(stream, 1 shl 16) } }
        } catch (e: Throwable) {
            try {
                doc.delete()
            } catch (_: Exception) {
            }
            if (e is SecurityException) throw BridgeException("folder_unavailable", e.message ?: "security")
            throw e
        }
        return mapOf("name" to (doc.name ?: name), "uri" to doc.uri.toString())
    }

    private fun isNoSpace(e: Throwable): Boolean =
        generateSequence(e) { it.cause }.any {
            val message = it.message ?: ""
            message.contains("ENOSPC") || message.contains("No space left")
        }

    private fun <T> MethodCall.arg(key: String): T =
        argument<T>(key) ?: throw BridgeException("unknown", "missing argument: $key")

    private fun MethodCall.cropArg(): CropBox? =
        argument<List<Double>>("crop")?.let { CropBox(it[0], it[1], it[2], it[3]) }

    private fun MethodCall.grayscaleArg(): Boolean = argument<Boolean>("grayscale") ?: false

    companion object {
        /** 기본 저장 폴더의 표식. Dart와 Swift에서 같은 값이다. */
        private const val DEFAULT_FOLDER_URI = "default"
        private const val DEFAULT_FOLDER_NAME = "Download"
        private val HEIF_MIME = setOf("image/heif", "image/heic")
        private val SUPPORTED_MIME = setOf("image/jpeg", "image/png", "image/webp") + HEIF_MIME
        private val SWAPPED_ORIENTATIONS = setOf(
            ExifInterface.ORIENTATION_TRANSPOSE,
            ExifInterface.ORIENTATION_ROTATE_90,
            ExifInterface.ORIENTATION_TRANSVERSE,
            ExifInterface.ORIENTATION_ROTATE_270,
        )
    }
}

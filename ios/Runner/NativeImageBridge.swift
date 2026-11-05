import Flutter
import ImageIO
import UIKit
import UniformTypeIdentifiers

// iOS 플랫폼 채널. lib/core/platform/native_bridge.dart와 Android NativeImageBridge.kt와 같은 계약이다.
// 오류 코드는 DESIGN §3.4 표의 코드다. 메서드를 바꾸면 세 곳을 함께 고친다.

private struct BridgeError: Error {
  let code: String
  let message: String

  init(_ code: String, _ message: String) {
    self.code = code
    self.message = message
  }
}

/// 영역 편집 결과. EXIF 반영 후 가로·세로에 대한 0~1 비율 좌표다 (DESIGN §2.1.6).
private struct CropBox {
  let left: Double
  let top: Double
  let right: Double
  let bottom: Double

  init?(_ value: Any?) {
    guard let list = value as? [NSNumber], list.count == 4 else { return nil }
    left = list[0].doubleValue
    top = list[1].doubleValue
    right = list[2].doubleValue
    bottom = list[3].doubleValue
  }
}

/// 헤더 스캔, 다운샘플 디코딩(자르기·회색조), JPEG 인코딩, PDF 이미지화, 폴더 파일 작업.
/// 백그라운드 TaskQueue에서 호출되므로 무거운 작업을 해도 UI가 멈추지 않는다 (DESIGN §3.1).
final class NativeImageBridge {
  /// 기본 저장 폴더의 표식. Dart와 Kotlin에서 같은 값이다 (DESIGN §2.1.4).
  private static let defaultFolderUri = "default"
  private static let defaultFolderName = "Pic Merge"

  private static let supportedTypes: Set<String> = [
    "public.jpeg", "public.png", "org.webmproject.webp", "public.heic", "public.heif",
  ]

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    do {
      let args = call.arguments as? [String: Any] ?? [:]
      switch call.method {
      case "cacheDir":
        // image_picker가 임시 폴더에 복사본을 만들므로 같은 곳을 쓰면 시작 정리에서 함께 지워진다.
        result((NSTemporaryDirectory() as NSString).standardizingPath)
      case "scan":
        result(try scan(path: try string(args, "path")))
      case "decodeRaw":
        try decodeRaw(
          path: try string(args, "path"),
          width: try int(args, "width"),
          height: try int(args, "height"),
          channels: try int(args, "channels"),
          outPath: try string(args, "outPath"),
          crop: CropBox(args["crop"]),
          grayscale: args["grayscale"] as? Bool ?? false)
        result(nil)
      case "encodeJpeg":
        result(
          try encodeJpeg(
            path: try string(args, "path"),
            width: try int(args, "width"),
            height: try int(args, "height"),
            quality: try int(args, "quality"),
            outPath: try string(args, "outPath"),
            crop: CropBox(args["crop"]),
            grayscale: args["grayscale"] as? Bool ?? false))
      case "importDocument":
        result(try importDocument(uri: try string(args, "uri"), outPath: try string(args, "outPath")))
      case "pdfPageCount":
        result(try openPdf(path: try string(args, "path")).numberOfPages)
      case "renderPdfPage":
        try renderPdfPage(
          path: try string(args, "path"),
          pageIndex: try int(args, "pageIndex"),
          dpi: try int(args, "dpi"),
          maxLongSide: try int(args, "maxLongSide"),
          quality: try int(args, "quality"),
          outPath: try string(args, "outPath"))
        result(nil)
      case "defaultFolder":
        result(["uri": NativeImageBridge.defaultFolderUri, "name": NativeImageBridge.defaultFolderName])
      case "checkFolder":
        result(checkFolder(uri: try string(args, "uri")))
      case "listNames":
        result(try listNames(uri: try string(args, "uri"), prefix: try string(args, "prefix")))
      case "copyToFolder":
        result(
          try copyToFolder(
            uri: try string(args, "uri"),
            sourcePath: try string(args, "sourcePath"),
            name: try string(args, "name")))
      default:
        result(FlutterMethodNotImplemented)
      }
    } catch let error as BridgeError {
      result(FlutterError(code: error.code, message: error.message, details: nil))
    } catch {
      let nsError = error as NSError
      let noSpace =
        nsError.domain == NSCocoaErrorDomain && nsError.code == NSFileWriteOutOfSpaceError
        || nsError.domain == NSPOSIXErrorDomain && nsError.code == Int(ENOSPC)
      result(
        FlutterError(
          code: noSpace ? "out_of_space" : "unknown", message: error.localizedDescription,
          details: nil))
    }
  }

  // MARK: - 인자

  private func string(_ args: [String: Any], _ key: String) throws -> String {
    guard let value = args[key] as? String else {
      throw BridgeError("unknown", "missing argument: \(key)")
    }
    return value
  }

  private func int(_ args: [String: Any], _ key: String) throws -> Int {
    guard let value = args[key] as? NSNumber else {
      throw BridgeError("unknown", "missing argument: \(key)")
    }
    return value.intValue
  }

  // MARK: - 이미지

  private func openSource(_ path: String) throws -> CGImageSource {
    guard FileManager.default.fileExists(atPath: path) else {
      throw BridgeError("source_unavailable", "missing: \(path)")
    }
    let options = [kCGImageSourceShouldCache: false] as CFDictionary
    guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, options)
    else {
      throw BridgeError("corrupt_file", "cannot open")
    }
    return source
  }

  private func scan(path: String) throws -> [String: Any] {
    let source = try openSource(path)
    guard let type = CGImageSourceGetType(source) as String?,
      Self.supportedTypes.contains(type)
    else {
      throw BridgeError("unsupported_format", "type")
    }
    guard
      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
      let width = (properties[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue,
      let height = (properties[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue,
      width > 0, height > 0
    else {
      throw BridgeError("unsupported_format", "no size")
    }
    let orientation = (properties[kCGImagePropertyOrientation] as? NSNumber)?.intValue ?? 1
    let swapped = (5...8).contains(orientation)
    let attributes = try FileManager.default.attributesOfItem(atPath: path)
    return [
      "width": swapped ? height : width,
      "height": swapped ? width : height,
      "bytes": (attributes[.size] as? NSNumber)?.intValue ?? 0,
      "mime": mimeType(forUTI: type),
    ]
  }

  private func mimeType(forUTI type: String) -> String {
    switch type {
    case "public.jpeg": return "image/jpeg"
    case "public.png": return "image/png"
    case "org.webmproject.webp": return "image/webp"
    case "public.heif": return "image/heif"
    default: return "image/heic"
    }
  }

  /// [crop] 영역을 [width]×[height]로 그린 비트맵 컨텍스트를 만든다.
  /// ImageIO 썸네일로 작게 읽어 메모리를 아끼고(회전까지 반영됨), 그 위에서 잘라 그린다.
  private func render(
    path: String, width: Int, height: Int, crop: CropBox?, grayscale: Bool, flatten: Bool
  ) throws -> CGContext {
    guard width > 0, height > 0 else { throw BridgeError("unknown", "bad target size") }
    let source = try openSource(path)
    guard
      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
      let rawW = (properties[kCGImagePropertyPixelWidth] as? NSNumber)?.doubleValue,
      let rawH = (properties[kCGImagePropertyPixelHeight] as? NSNumber)?.doubleValue,
      rawW > 0, rawH > 0
    else {
      throw BridgeError("corrupt_file", "bounds")
    }

    // 목표 크기를 얻는 데 필요한 전체 이미지의 긴 변. 자르면 그만큼 크게 읽어야 한다.
    let cropW = crop.map { $0.right - $0.left } ?? 1
    let cropH = crop.map { $0.bottom - $0.top } ?? 1
    let fullW = Double(width) / cropW
    let fullH = Double(height) / cropH
    let neededLong = max(fullW, fullH)
    let sourceLong = max(rawW, rawH)
    // 줄이기만 한다. 목표가 원본보다 크면 원본 크기로 읽고 그릴 때 키운다.
    let maxPixel = min(sourceLong, ceil(neededLong))

    let options =
      [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceShouldCacheImmediately: true,
        kCGImageSourceThumbnailMaxPixelSize: maxPixel,
      ] as CFDictionary
    guard let oriented = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else {
      // 헤더는 읽혔는데 디코딩이 안 되면 기기가 못 푸는 변형일 가능성이 크다.
      let type = CGImageSourceGetType(source) as String?
      let isHeif = type == "public.heic" || type == "public.heif"
      throw BridgeError(isHeif ? "unsupported_format" : "corrupt_file", "decode failed")
    }

    let srgb = CGColorSpace(name: CGColorSpace.sRGB)!
    guard
      let context = CGContext(
        data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
        space: srgb, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    else {
      throw BridgeError("out_of_memory", "bitmap")
    }
    context.interpolationQuality = .high
    if flatten {
      context.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
      context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    }

    let drawn: CGImage
    if let crop = crop {
      let imageW = Double(oriented.width)
      let imageH = Double(oriented.height)
      let x = (crop.left * imageW).rounded(.down)
      let y = (crop.top * imageH).rounded(.down)
      let rect = CGRect(
        x: x, y: y,
        width: min(imageW - x, max(1, (cropW * imageW).rounded())),
        height: min(imageH - y, max(1, (cropH * imageH).rounded())))
      guard let cropped = oriented.cropping(to: rect) else {
        throw BridgeError("unknown", "crop")
      }
      drawn = cropped
    } else {
      drawn = oriented
    }
    context.draw(drawn, in: CGRect(x: 0, y: 0, width: width, height: height))
    if grayscale { applyGrayscale(context) }
    return context
  }

  /// Android의 setSaturation(0)과 같은 가중치로 회색조를 만든다. 알파는 그대로 둔다.
  private func applyGrayscale(_ context: CGContext) {
    guard let data = context.data else { return }
    let pixels = data.bindMemory(to: UInt8.self, capacity: context.bytesPerRow * context.height)
    for y in 0..<context.height {
      let row = pixels + y * context.bytesPerRow
      for x in 0..<context.width {
        let p = row + x * 4
        let gray = (0.213 * Double(p[0]) + 0.715 * Double(p[1]) + 0.072 * Double(p[2])).rounded()
        let value = UInt8(min(255, max(0, gray)))
        p[0] = value
        p[1] = value
        p[2] = value
      }
    }
  }

  /// 행 단위 raw 파일. 형식: 8비트 RGB 또는 RGBA, 패딩 없음, premultiply 안 됨.
  private func decodeRaw(
    path: String, width: Int, height: Int, channels: Int, outPath: String, crop: CropBox?,
    grayscale: Bool
  ) throws {
    guard channels == 3 || channels == 4 else {
      throw BridgeError("unknown", "channels=\(channels)")
    }
    let context = try render(
      path: path, width: width, height: height, crop: crop, grayscale: grayscale,
      flatten: channels == 3)
    guard let data = context.data else { throw BridgeError("out_of_memory", "bitmap") }
    let source = data.bindMemory(to: UInt8.self, capacity: context.bytesPerRow * height)
    let url = URL(fileURLWithPath: outPath)
    FileManager.default.createFile(atPath: outPath, contents: nil)
    do {
      let handle = try FileHandle(forWritingTo: url)
      defer { try? handle.close() }
      var buffer = [UInt8](repeating: 0, count: width * channels)
      for y in 0..<height {
        let row = source + y * context.bytesPerRow
        var i = 0
        for x in 0..<width {
          let p = row + x * 4
          let alpha = p[3]
          if alpha == 255 || alpha == 0 {
            buffer[i] = p[0]
            buffer[i + 1] = p[1]
            buffer[i + 2] = p[2]
          } else {
            // CGBitmapContext는 premultiplied만 지원하므로 되돌린다.
            let a = Double(alpha)
            buffer[i] = UInt8(min(255, (Double(p[0]) * 255 / a).rounded()))
            buffer[i + 1] = UInt8(min(255, (Double(p[1]) * 255 / a).rounded()))
            buffer[i + 2] = UInt8(min(255, (Double(p[2]) * 255 / a).rounded()))
          }
          if channels == 4 { buffer[i + 3] = alpha }
          i += channels
        }
        try handle.write(contentsOf: Data(buffer))
      }
    } catch {
      try? FileManager.default.removeItem(at: url)
      throw error
    }
  }

  private func encodeJpeg(
    path: String, width: Int, height: Int, quality: Int, outPath: String, crop: CropBox?,
    grayscale: Bool
  ) throws -> [String: Any] {
    let context = try render(
      path: path, width: width, height: height, crop: crop, grayscale: grayscale, flatten: true)
    guard let image = context.makeImage() else { throw BridgeError("unknown", "makeImage") }
    return try writeJpeg(image, quality: quality, outPath: outPath)
  }

  @discardableResult
  private func writeJpeg(_ image: CGImage, quality: Int, outPath: String) throws -> [String: Any] {
    let url = URL(fileURLWithPath: outPath)
    guard
      let destination = CGImageDestinationCreateWithURL(
        url as CFURL, "public.jpeg" as CFString, 1, nil)
    else {
      throw BridgeError("unknown", "JPEG destination")
    }
    let options =
      [kCGImageDestinationLossyCompressionQuality: Double(quality) / 100.0] as CFDictionary
    CGImageDestinationAddImage(destination, image, options)
    guard CGImageDestinationFinalize(destination) else {
      try? FileManager.default.removeItem(at: url)
      throw BridgeError("unknown", "JPEG encode failed")
    }
    let attributes = try FileManager.default.attributesOfItem(atPath: outPath)
    return [
      "width": image.width,
      "height": image.height,
      "bytes": (attributes[.size] as? NSNumber)?.intValue ?? 0,
    ]
  }

  // MARK: - PDF

  /// 문서 선택기가 준 파일을 앱 캐시로 복사한다.
  private func importDocument(uri: String, outPath: String) throws -> [String: Any] {
    guard let url = URL(string: uri) else { throw BridgeError("source_unavailable", "bad uri") }
    let scoped = url.startAccessingSecurityScopedResource()
    defer { if scoped { url.stopAccessingSecurityScopedResource() } }
    let target = URL(fileURLWithPath: outPath)
    do {
      try? FileManager.default.removeItem(at: target)
      try FileManager.default.copyItem(at: url, to: target)
      // asCopy로 받은 임시 복사본이다. 원본을 앱 안에 남기지 않는다.
      try? FileManager.default.removeItem(at: url)
    } catch {
      let nsError = error as NSError
      if nsError.domain == NSCocoaErrorDomain && nsError.code == NSFileWriteOutOfSpaceError {
        throw error
      }
      throw BridgeError("source_unavailable", error.localizedDescription)
    }
    return ["name": url.lastPathComponent]
  }

  private func openPdf(path: String) throws -> CGPDFDocument {
    guard FileManager.default.fileExists(atPath: path) else {
      throw BridgeError("source_unavailable", "missing: \(path)")
    }
    guard let document = CGPDFDocument(URL(fileURLWithPath: path) as CFURL) else {
      throw BridgeError("corrupt_file", "not a PDF")
    }
    // 암호 없이 열 수 있는 문서만 받는다 (빈 암호는 CGPDFDocument가 알아서 푼다).
    if document.isEncrypted && !document.isUnlocked {
      throw BridgeError("unsupported_format", "password protected")
    }
    return document
  }

  /// 한 페이지만 렌더링해 JPEG로 쓰고 바로 해제한다 (DESIGN §2.1.1).
  private func renderPdfPage(
    path: String, pageIndex: Int, dpi: Int, maxLongSide: Int, quality: Int, outPath: String
  ) throws {
    let document = try openPdf(path: path)
    // CGPDFDocument의 페이지 번호는 1부터다.
    guard let page = document.page(at: pageIndex + 1) else {
      throw BridgeError("unknown", "page \(pageIndex)")
    }
    let box = page.getBoxRect(.cropBox)
    let rotated = page.rotationAngle % 180 != 0
    let pageW = Double(rotated ? box.height : box.width)
    let pageH = Double(rotated ? box.width : box.height)
    guard pageW > 0, pageH > 0 else { throw BridgeError("corrupt_file", "empty page") }
    let scale = min(Double(dpi) / 72.0, Double(maxLongSide) / max(pageW, pageH))
    let width = max(1, Int((pageW * scale).rounded()))
    let height = max(1, Int((pageH * scale).rounded()))
    let srgb = CGColorSpace(name: CGColorSpace.sRGB)!
    guard
      let context = CGContext(
        data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
        space: srgb, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
    else {
      throw BridgeError("out_of_memory", "bitmap")
    }
    let target = CGRect(x: 0, y: 0, width: width, height: height)
    context.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
    context.fill(target)
    context.interpolationQuality = .high
    // getDrawingTransform은 축소만 하므로, 직접 키운 뒤 페이지 좌표계를 맞춘다.
    context.scaleBy(x: CGFloat(scale), y: CGFloat(scale))
    let unscaled = CGRect(x: 0, y: 0, width: pageW, height: pageH)
    context.concatenate(page.getDrawingTransform(.cropBox, rect: unscaled, rotate: 0, preserveAspectRatio: true))
    context.drawPDFPage(page)
    guard let image = context.makeImage() else { throw BridgeError("unknown", "makeImage") }
    try writeJpeg(image, quality: quality, outPath: outPath)
  }

  // MARK: - 저장 폴더 (security-scoped bookmark)

  /// [uri]는 Dart에는 불투명한 문자열이다. iOS에서는 bookmark 데이터의 base64다 (DESIGN §2.1.4).
  private func resolveFolder(_ uri: String) throws -> URL {
    guard let data = Data(base64Encoded: uri) else {
      throw BridgeError("folder_unavailable", "bad bookmark")
    }
    var stale = false
    do {
      return try URL(resolvingBookmarkData: data, bookmarkDataIsStale: &stale)
    } catch {
      throw BridgeError("folder_unavailable", error.localizedDescription)
    }
  }

  /// 앱의 Documents 폴더. 앱 샌드박스 안이라 security scope가 필요 없다. 없으면 만든다.
  private func defaultFolderURL() throws -> URL {
    do {
      return try FileManager.default.url(
        for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    } catch {
      throw BridgeError("folder_unavailable", error.localizedDescription)
    }
  }

  private func withFolder<T>(_ uri: String, _ body: (URL) throws -> T) throws -> T {
    if uri == NativeImageBridge.defaultFolderUri {
      return try body(try defaultFolderURL())
    }
    let url = try resolveFolder(uri)
    guard url.startAccessingSecurityScopedResource() else {
      throw BridgeError("folder_unavailable", "no access")
    }
    defer { url.stopAccessingSecurityScopedResource() }
    return try body(url)
  }

  private func checkFolder(uri: String) -> [String: Any] {
    do {
      return try withFolder(uri) { url in
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
        let writable = FileManager.default.isWritableFile(atPath: url.path)
        let name =
          uri == NativeImageBridge.defaultFolderUri
          ? NativeImageBridge.defaultFolderName : url.lastPathComponent
        return ["ok": exists && isDirectory.boolValue && writable, "name": name]
      }
    } catch {
      return ["ok": false, "name": ""]
    }
  }

  private func listNames(uri: String, prefix: String) throws -> [String] {
    try withFolder(uri) { url in
      do {
        return try FileManager.default.contentsOfDirectory(atPath: url.path)
          .filter { $0.hasPrefix(prefix) }
      } catch {
        throw BridgeError("folder_unavailable", error.localizedDescription)
      }
    }
  }

  /// 실패하면 폴더에 만든 파일을 지운다 (DESIGN §3.4).
  private func copyToFolder(uri: String, sourcePath: String, name: String) throws -> [String: Any] {
    try withFolder(uri) { folder in
      let target = folder.appendingPathComponent(name)
      do {
        try FileManager.default.copyItem(at: URL(fileURLWithPath: sourcePath), to: target)
      } catch {
        let nsError = error as NSError
        // 같은 이름이 이미 있으면 그 파일은 사용자 것이다. 지우면 안 된다.
        if nsError.domain == NSCocoaErrorDomain && nsError.code == NSFileWriteFileExistsError {
          throw BridgeError("unknown", "file exists: \(name)")
        }
        try? FileManager.default.removeItem(at: target)
        if nsError.domain == NSCocoaErrorDomain && nsError.code == NSFileWriteOutOfSpaceError {
          throw error
        }
        throw BridgeError("folder_unavailable", error.localizedDescription)
      }
      return ["name": name, "uri": target.absoluteString]
    }
  }
}

/// 폴더·문서 선택기와 공유 시트. 화면이 필요해 메인 스레드 채널에서 부른다.
final class NativeUiBridge: NSObject, UIDocumentPickerDelegate,
  UIAdaptivePresentationControllerDelegate
{
  private enum Pending {
    case folder(FlutterResult)
    case pdfs(FlutterResult)
  }

  private var pending: Pending?

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "pickFolder":
      present(picker: UIDocumentPickerViewController(forOpeningContentTypes: [.folder]), .folder(result), result)
    case "pickPdfs":
      // asCopy: 선택한 파일의 복사본을 앱 임시 폴더에 받아 권한 범위를 신경 쓰지 않는다.
      let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf], asCopy: true)
      picker.allowsMultipleSelection = true
      present(picker: picker, .pdfs(result), result)
    case "shareFile":
      guard let path = args["path"] as? String else {
        result(FlutterError(code: "unknown", message: "missing path", details: nil))
        return
      }
      shareFile(path: path, result: result)
    case "appInfo":
      result(appInfo())
    case "composeEmail":
      guard let to = args["to"] as? String, let subject = args["subject"] as? String else {
        result(FlutterError(code: "unknown", message: "missing to or subject", details: nil))
        return
      }
      composeEmail(to: to, subject: subject, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// 프로그램 정보 화면과 의견 보내기 제목에 쓴다 (DESIGN §2.2). UIDevice는 메인 스레드에서 읽는다.
  private func appInfo() -> [String: String] {
    let bundle = Bundle.main
    return [
      "versionName": bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "",
      "buildNumber": bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "",
      "manufacturer": "Apple",
      "model": NativeUiBridge.machineIdentifier(),
      "osName": "iOS",
      "osVersion": UIDevice.current.systemVersion,
    ]
  }

  /// `iPhone16,2` 같은 기기 식별자.
  private static func machineIdentifier() -> String {
    var info = utsname()
    uname(&info)
    return Mirror(reflecting: info.machine).children.reduce(into: "") { identifier, element in
      guard let value = element.value as? Int8, value != 0 else { return }
      identifier.append(Character(UnicodeScalar(UInt8(bitPattern: value))))
    }
  }

  /// 메일 앱을 받는 사람과 제목만 채워 연다. 보내는 것은 사용자가 한다 (DESIGN §2.2).
  /// 열지 못하면 false를 돌려준다.
  private func composeEmail(to: String, subject: String, result: @escaping FlutterResult) {
    guard let url = NativeUiBridge.mailtoURL(to: to, subject: subject) else {
      result(false)
      return
    }
    UIApplication.shared.open(url, options: [:]) { opened in
      result(opened)
    }
  }

  /// 제목은 RFC 3986의 비예약 문자만 남기고 퍼센트 인코딩한다. Kotlin의 mailtoUri와 같다.
  private static func mailtoURL(to: String, subject: String) -> URL? {
    let unreserved = CharacterSet(
      charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
    guard let encoded = subject.addingPercentEncoding(withAllowedCharacters: unreserved) else {
      return nil
    }
    return URL(string: "mailto:\(to)?subject=\(encoded)")
  }

  private func present(
    picker: UIDocumentPickerViewController, _ next: Pending, _ result: @escaping FlutterResult
  ) {
    guard pending == nil else {
      result(FlutterError(code: "busy", message: "picker already open", details: nil))
      return
    }
    guard let top = Self.topViewController() else {
      result(FlutterError(code: "unknown", message: "no view controller", details: nil))
      return
    }
    pending = next
    picker.delegate = self
    // 시트를 쓸어 닫으면 documentPickerWasCancelled가 불리지 않을 수 있다.
    // 결과를 돌려주지 않으면 Dart 쪽이 끝없이 기다려 화면 전체가 비활성으로 남는다.
    picker.presentationController?.delegate = self
    top.present(picker, animated: true)
  }

  func documentPicker(
    _ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]
  ) {
    let current = pending
    pending = nil
    switch current {
    case .folder(let result):
      guard let url = urls.first else {
        result(nil)
        return
      }
      let scoped = url.startAccessingSecurityScopedResource()
      defer { if scoped { url.stopAccessingSecurityScopedResource() } }
      do {
        let bookmark = try url.bookmarkData(
          options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
        result(["uri": bookmark.base64EncodedString(), "name": url.lastPathComponent])
      } catch {
        result(
          FlutterError(
            code: "folder_unavailable", message: error.localizedDescription, details: nil))
      }
    case .pdfs(let result):
      result(urls.map { $0.absoluteString })
    case nil:
      break
    }
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    finishCancelled()
  }

  func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
    finishCancelled()
  }

  /// [pending]을 먼저 비우므로 취소 경로가 둘 다 불려도 결과는 한 번만 돌아간다.
  private func finishCancelled() {
    let current = pending
    pending = nil
    switch current {
    case .folder(let result):
      result(nil)
    case .pdfs(let result):
      result([String]())
    case nil:
      break
    }
  }

  /// 공유 시트를 연다. 받을 앱은 사용자가 고른다 (DESIGN §2.1.7).
  private func shareFile(path: String, result: FlutterResult) {
    guard let top = Self.topViewController() else {
      result(FlutterError(code: "unknown", message: "no view controller", details: nil))
      return
    }
    let sheet = UIActivityViewController(
      activityItems: [URL(fileURLWithPath: path)], applicationActivities: nil)
    // iPad에서는 팝오버 기준을 주지 않으면 앱이 죽는다.
    if let popover = sheet.popoverPresentationController {
      popover.sourceView = top.view
      popover.sourceRect = CGRect(x: top.view.bounds.midX, y: top.view.bounds.maxY, width: 0, height: 0)
      popover.permittedArrowDirections = [.down]
    }
    top.present(sheet, animated: true)
    result(nil)
  }

  private static func topViewController() -> UIViewController? {
    let scene =
      UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first { $0.activationState == .foregroundActive }
      ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
    let window = scene?.windows.first { $0.isKeyWindow } ?? scene?.windows.first
    var top = window?.rootViewController
    while let presented = top?.presentedViewController {
      top = presented
    }
    return top
  }
}

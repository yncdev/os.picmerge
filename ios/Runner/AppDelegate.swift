import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let workBridge = NativeImageBridge()
  // 문서 선택기의 delegate는 약한 참조라 여기서 잡아 둔다.
  private let uiBridge = NativeUiBridge()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "NativeImageBridge")
    else { return }
    let messenger = registrar.messenger()
    let codec = FlutterStandardMethodCodec.sharedInstance()
    // 디코딩·인코딩·복사는 백그라운드 TaskQueue에서 실행한다 (DESIGN §3.1).
    let work = FlutterMethodChannel(
      name: "image_merger/work",
      binaryMessenger: messenger,
      codec: codec,
      taskQueue: messenger.makeBackgroundTaskQueue?())
    let workBridge = self.workBridge
    work.setMethodCallHandler { call, result in workBridge.handle(call, result: result) }
    // 선택기와 공유 시트는 화면이 필요해 메인 스레드 채널로 둔다.
    let ui = FlutterMethodChannel(
      name: "image_merger/ui", binaryMessenger: messenger, codec: codec)
    let uiBridge = self.uiBridge
    ui.setMethodCallHandler { call, result in uiBridge.handle(call, result: result) }
  }
}

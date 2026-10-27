import Flutter
import UIKit
import PhotosUI
import UniformTypeIdentifiers
import MessageUI
import Speech
import AVFoundation

/// iOS 原生通道实现（零第三方包），方法名与参数与安卓侧保持一致，
/// Dart 侧调用点不变：
///
/// gunsmap/prefs   getString {key} -> String? / setString {key, value}
/// gunsmap/system  openUrl {url} -> Bool / getCacheDir -> String?
///                 installApk {path} -> false（iOS 无 APK 安装）
///                 setIcon {icon} -> true（无操作；iOS 单主图标，
///                 多图标切换需弹系统确认框，本轮不做）
/// gunsmap/share   shareText {text} -> Bool / shareImage {bytes} -> Bool
/// gunsmap/pick_image pickImage -> Uint8List?（PHPicker，无需照片权限）
/// gunsmap/mailto  openMail {email, subject, body} -> Bool
/// gunsmap/voice   recognize -> String?（SFSpeechRecognizer，
///                 权限被拒或不支持时返回 FlutterError，Dart 侧 catch 后为 null）
enum GunsmapChannels {
  static func register(with messenger: FlutterBinaryMessenger) {
    let prefs = FlutterMethodChannel(name: "gunsmap/prefs", binaryMessenger: messenger)
    prefs.setMethodCallHandler { call, result in
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterMethodNotImplemented)
        return
      }
      switch call.method {
      case "getString":
        result(UserDefaults.standard.string(forKey: args["key"] as? String ?? ""))
      case "setString":
        if let key = args["key"] as? String, let value = args["value"] as? String {
          UserDefaults.standard.set(value, forKey: key)
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let system = FlutterMethodChannel(name: "gunsmap/system", binaryMessenger: messenger)
    system.setMethodCallHandler { call, result in
      switch call.method {
      case "openUrl":
        guard let urlString = (call.arguments as? [String: Any])?["url"] as? String,
              let url = URL(string: urlString)
        else {
          result(false)
          return
        }
        UIApplication.shared.open(url, options: [:]) { result($0) }
      case "getCacheDir":
        result(FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.path)
      case "installApk":
        // iOS 没有 APK 安装：返回 false，Dart 侧按失败处理（见设置页 iOS 门控）。
        result(false)
      case "setIcon":
        // iOS 只用单主图标，不做多图标切换。
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let share = FlutterMethodChannel(name: "gunsmap/share", binaryMessenger: messenger)
    share.setMethodCallHandler { call, result in
      guard let args = call.arguments as? [String: Any] else {
        result(false)
        return
      }
      switch call.method {
      case "shareText":
        guard let text = args["text"] as? String else {
          result(false)
          return
        }
        presentShare(items: [text], result: result)
      case "shareImage":
        guard let typed = args["bytes"] as? FlutterStandardTypedData,
              let image = UIImage(data: typed.data)
        else {
          result(false)
          return
        }
        presentShare(items: [image], result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let pickImage = FlutterMethodChannel(name: "gunsmap/pick_image", binaryMessenger: messenger)
    pickImage.setMethodCallHandler { call, result in
      guard call.method == "pickImage" else {
        result(FlutterMethodNotImplemented)
        return
      }
      ImagePicker.shared.pick(result: result)
    }

    let mailto = FlutterMethodChannel(name: "gunsmap/mailto", binaryMessenger: messenger)
    mailto.setMethodCallHandler { call, result in
      guard call.method == "openMail",
            let args = call.arguments as? [String: Any],
            let email = args["email"] as? String
      else {
        result(FlutterMethodNotImplemented)
        return
      }
      MailSender.shared.openMail(
        email: email,
        subject: args["subject"] as? String ?? "",
        body: args["body"] as? String ?? "",
        result: result)
    }

    let voice = FlutterMethodChannel(name: "gunsmap/voice", binaryMessenger: messenger)
    voice.setMethodCallHandler { call, result in
      guard call.method == "recognize" else {
        result(FlutterMethodNotImplemented)
        return
      }
      SpeechHelper.shared.recognize(result)
    }
  }

  /// 最上层控制器；iPad 上分享与选图需用它挂 popover，否则会闪退。
  static func topViewController() -> UIViewController? {
    let windows = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
    guard var top = windows.first(where: { $0.isKeyWindow })?.rootViewController else {
      return nil
    }
    while let presented = top.presentedViewController {
      top = presented
    }
    return top
  }

  static func presentShare(items: [Any], result: @escaping FlutterResult) {
    guard let top = topViewController() else {
      result(false)
      return
    }
    let sheet = UIActivityViewController(activityItems: items, applicationActivities: nil)
    if let pop = sheet.popoverPresentationController {
      pop.sourceView = top.view
      pop.sourceRect = CGRect(
        x: top.view.bounds.midX, y: top.view.bounds.midY, width: 0, height: 0)
      pop.permittedArrowDirections = []
    }
    top.present(sheet, animated: true) {
      result(true)
    }
  }
}

/// 选图：PHPicker（系统选图器，无需照片权限）。取消返回 null。
final class ImagePicker: NSObject, PHPickerViewControllerDelegate {
  static let shared = ImagePicker()
  private var pendingResult: FlutterResult?
  private var delegateRetainer: ImagePicker?

  func pick(result: @escaping FlutterResult) {
    guard let top = GunsmapChannels.topViewController() else {
      result(nil)
      return
    }
    // 自持有 delegate，直到本次选择结束，避免回调前被释放。
    delegateRetainer = self
    var config = PHPickerConfiguration()
    config.filter = .images
    config.selectionLimit = 1
    let picker = PHPickerViewController(configuration: config)
    picker.delegate = self
    if let pop = picker.popoverPresentationController {
      pop.sourceView = top.view
      pop.sourceRect = CGRect(
        x: top.view.bounds.midX, y: top.view.bounds.midY, width: 0, height: 0)
      pop.permittedArrowDirections = []
    }
    pendingResult = result
    top.present(picker, animated: true)
  }

  func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    picker.dismiss(animated: true)
    let finish = pendingResult
    pendingResult = nil
    delegateRetainer = nil
    guard let item = results.first else {
      finish?(nil)
      return
    }
    let provider = item.itemProvider
    if provider.canLoadObject(ofClass: UIImage.self) {
      provider.loadObject(ofClass: UIImage.self) { object, _ in
        let data = (object as? UIImage)?.pngData()
        DispatchQueue.main.async {
          finish?(data.map { FlutterStandardTypedData(bytes: $0) })
        }
      }
    } else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
      provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
        DispatchQueue.main.async {
          finish?(data.map { FlutterStandardTypedData(bytes: $0) })
        }
      }
    } else {
      finish?(nil)
    }
  }
}

/// 邮件：优先系统邮件撰写框，不可用时退回 mailto: 链接。
final class MailSender: NSObject, MFMailComposeViewControllerDelegate {
  static let shared = MailSender()
  private var pendingResult: FlutterResult?

  func openMail(email: String, subject: String, body: String, result: @escaping FlutterResult) {
    guard let top = GunsmapChannels.topViewController() else {
      result(false)
      return
    }
    if MFMailComposeViewController.canSendMail() {
      let composer = MFMailComposeViewController()
      composer.mailComposeDelegate = self
      composer.setToRecipients([email])
      composer.setSubject(subject)
      composer.setMessageBody(body, isHTML: false)
      pendingResult = result
      top.present(composer, animated: true)
      return
    }
    var components = URLComponents()
    components.scheme = "mailto"
    components.path = email
    components.queryItems = [
      URLQueryItem(name: "subject", value: subject),
      URLQueryItem(name: "body", value: body),
    ]
    guard let url = components.url else {
      result(false)
      return
    }
    UIApplication.shared.open(url, options: [:]) { result($0) }
  }

  func mailComposeController(
    _ controller: MFMailComposeViewController,
    didFinishWith result: MFMailComposeResult,
    error: Error?
  ) {
    controller.dismiss(animated: true) { [weak self] in
      // 撰写框能打开即算成功（含用户取消），Dart 侧只在打不开时才走复制邮箱兜底。
      self?.pendingResult?(true)
      self?.pendingResult = nil
    }
  }
}

/// 语音：SFSpeechRecognizer + 麦克风实时识别，首句最终结果即返回。
/// 权限被拒、不支持或失败时返回 FlutterError，Dart 侧 catch 后为 null，
/// 调用方只作提示，不闪退。
final class SpeechHelper: NSObject {
  static let shared = SpeechHelper()
  private let recognizer: SFSpeechRecognizer? = SFSpeechRecognizer(locale: Locale.current)
  private let audioEngine = AVAudioEngine()
  private var request: SFSpeechAudioBufferRecognitionRequest?
  private var task: SFSpeechRecognitionTask?
  private var pendingResult: FlutterResult?
  private var finished = false

  func recognize(_ result: @escaping FlutterResult) {
    guard let recognizer = recognizer, recognizer.isAvailable else {
      result(FlutterError(
        code: "unavailable",
        message: "Speech recognition is not available on this device",
        details: nil))
      return
    }
    pendingResult = result
    finished = false
    SFSpeechRecognizer.requestAuthorization { [weak self] status in
      DispatchQueue.main.async {
        guard let self = self else { return }
        guard status == .authorized else {
          self.fail(FlutterError(
            code: "denied",
            message: "Speech recognition permission was not granted",
            details: nil))
          return
        }
        self.start()
      }
    }
  }

  private func start() {
    let session = AVAudioSession.sharedInstance()
    do {
      try session.setCategory(.record, mode: .measurement, options: .duckOthers)
      try session.setActive(true, options: .notifyOthersOnDeactivation)
    } catch {
      fail(FlutterError(code: "audio", message: error.localizedDescription, details: nil))
      return
    }
    let request = SFSpeechAudioBufferRecognitionRequest()
    request.shouldReportPartialResults = false
    self.request = request
    let input = audioEngine.inputNode
    let format = input.outputFormat(forBus: 0)
    input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
      self?.request?.append(buffer)
    }
    audioEngine.prepare()
    do {
      try audioEngine.start()
    } catch {
      fail(FlutterError(code: "audio", message: error.localizedDescription, details: nil))
      return
    }
    task = recognizer?.recognitionTask(with: request) { [weak self] response, error in
      guard let self = self else { return }
      if let error = error {
        self.fail(FlutterError(
          code: "recognition", message: error.localizedDescription, details: nil))
        return
      }
      if let response = response, response.isFinal {
        self.finish(response.bestTranscription.formattedString)
      }
    }
  }

  private func finish(_ text: String) {
    guard !finished else { return }
    finished = true
    stopAudio()
    pendingResult?(text)
    pendingResult = nil
  }

  private func fail(_ error: FlutterError) {
    guard !finished else { return }
    finished = true
    stopAudio()
    pendingResult?(error)
    pendingResult = nil
  }

  private func stopAudio() {
    audioEngine.stop()
    audioEngine.inputNode.removeTap(onBus: 0)
    request?.endAudio()
    request = nil
    task = nil
    try? AVAudioSession.sharedInstance().setActive(
      false, options: .notifyOthersOnDeactivation)
  }
}

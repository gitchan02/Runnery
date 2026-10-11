import AVFoundation
import Flutter

/// 러닝 음성 안내. 아이폰 기본 한국어 음성으로 읽고, 읽는 동안만 음악 소리를 줄였다가 되돌립니다.
final class VoiceGuideChannel: NSObject, AVSpeechSynthesizerDelegate {
  private static let shared = VoiceGuideChannel()
  private let synthesizer = AVSpeechSynthesizer()

  private override init() {
    super.init()
    synthesizer.delegate = self
  }

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "runnery/voice", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "speak", let text = call.arguments as? String else {
        return result(FlutterMethodNotImplemented)
      }
      shared.speak(text)
      result(nil)
    }
  }

  private func speak(_ text: String) {
    let session = AVAudioSession.sharedInstance()
    // 다른 앱 음악은 끄지 않고 잠깐 작게 줄입니다. 화면이 꺼져 있어도 들리도록 재생 모드를 씁니다.
    try? session.setCategory(.playback, mode: .voicePrompt, options: [.duckOthers, .mixWithOthers])
    try? session.setActive(true)
    let utterance = AVSpeechUtterance(string: text)
    utterance.voice = AVSpeechSynthesisVoice(language: "ko-KR")
    utterance.rate = AVSpeechUtteranceDefaultSpeechRate
    synthesizer.speak(utterance)
  }

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    guard !synthesizer.isSpeaking else { return }
    // 다 읽으면 줄였던 음악 소리를 되돌립니다.
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
  }
}

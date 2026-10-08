import ActivityKit
import Foundation

/// 앱(Runner)과 라이브 액티비티 위젯이 함께 쓰는 러닝 상태. 두 타깃에 모두 들어갑니다.
@available(iOS 16.2, *)
struct RunningActivityAttributes: ActivityAttributes {
  struct ContentState: Codable, Hashable {
    var distanceKm: Double
    var pace: String
    /// 일시정지 중 표시할 운동 시간(초).
    var elapsedSeconds: Int
    /// 달리는 중 시간이 저절로 흐르도록 기준이 되는 시각(지금 - 운동 시간).
    var timerStart: Date
    var paused: Bool
    /// 목표 문구. 자유 러닝이면 nil.
    var goal: String?
  }
}

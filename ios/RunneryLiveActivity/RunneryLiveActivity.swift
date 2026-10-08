import ActivityKit
import SwiftUI
import WidgetKit

@main
struct RunneryLiveActivityBundle: WidgetBundle {
  var body: some Widget {
    RunningLiveActivity()
  }
}

/// 앱 밖에서 보이는 러닝 진행 상황: 다이내믹 아일랜드와 잠금 화면.
struct RunningLiveActivity: Widget {
  private static let orange = Color(red: 1, green: 0.48, blue: 0)

  var body: some WidgetConfiguration {
    ActivityConfiguration(for: RunningActivityAttributes.self) { context in
      LockScreenView(state: context.state)
        .activityBackgroundTint(Color.black.opacity(0.85))
        .activitySystemActionForegroundColor(.white)
    } dynamicIsland: { context in
      let state = context.state
      return DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Label {
            Text(state.paused ? "일시정지" : "러닝 중")
          } icon: {
            Image(systemName: state.paused ? "pause.fill" : "figure.run")
              .foregroundStyle(Self.orange)
          }
          .font(.caption)
          .foregroundStyle(.secondary)
        }
        DynamicIslandExpandedRegion(.trailing) {
          ElapsedText(state: state).font(.caption).foregroundStyle(.secondary)
        }
        DynamicIslandExpandedRegion(.bottom) {
          HStack(alignment: .firstTextBaseline) {
            DistanceText(km: state.distanceKm, size: 34)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
              Text("\(state.pace) /km").font(.callout.monospacedDigit())
              if let goal = state.goal {
                Text(goal).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
              }
            }
          }
        }
      } compactLeading: {
        Image(systemName: state.paused ? "pause.fill" : "figure.run")
          .foregroundStyle(Self.orange)
      } compactTrailing: {
        Text(String(format: "%.2fkm", state.distanceKm))
          .font(.caption.monospacedDigit())
          .foregroundStyle(.white)
      } minimal: {
        Image(systemName: "figure.run").foregroundStyle(Self.orange)
      }
    }
  }
}

private struct LockScreenView: View {
  let state: RunningActivityAttributes.ContentState

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text("RUNNERY").font(.caption.weight(.heavy)).tracking(2)
        Spacer()
        Text(state.paused ? "일시정지" : "러닝 중").font(.caption).foregroundStyle(.secondary)
      }
      HStack(alignment: .firstTextBaseline) {
        DistanceText(km: state.distanceKm, size: 40)
        Spacer()
        VStack(alignment: .trailing, spacing: 2) {
          ElapsedText(state: state).font(.title3.monospacedDigit())
          Text("\(state.pace) /km").font(.caption.monospacedDigit()).foregroundStyle(.secondary)
        }
      }
      if let goal = state.goal {
        Text(goal).font(.caption).foregroundStyle(.secondary)
      }
    }
    .foregroundStyle(.white)
    .padding(16)
  }
}

private struct DistanceText: View {
  let km: Double
  let size: CGFloat

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 4) {
      Text(String(format: "%.2f", km)).font(.system(size: size, weight: .bold).monospacedDigit())
      Text("km").font(.callout).foregroundStyle(.secondary)
    }
  }
}

/// 달리는 중에는 앱이 매초 보내지 않아도 시간이 저절로 흐릅니다.
private struct ElapsedText: View {
  let state: RunningActivityAttributes.ContentState

  var body: some View {
    if state.paused {
      let s = state.elapsedSeconds
      Text(s >= 3600
        ? String(format: "%d:%02d:%02d", s / 3600, s / 60 % 60, s % 60)
        : String(format: "%d:%02d", s / 60, s % 60))
        .monospacedDigit()
    } else {
      Text(timerInterval: state.timerStart...Date.distantFuture, countsDown: false)
        .monospacedDigit()
        .multilineTextAlignment(.trailing)
    }
  }
}

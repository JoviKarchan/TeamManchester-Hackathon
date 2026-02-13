import ActivityKit
import WidgetKit
import SwiftUI

@available(iOS 16.1, *)
struct SearchActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SearchActivityAttributes.self) { context in
            SearchActivityLockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    if let imageData = context.attributes.imageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 44, height: 44)
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    SearchStatusView(status: context.state.status, progress: context.state.progress)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.status == .searching {
                        Text("Searching item......")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 16)
                    } else if context.state.status == .found {
                        Text("Item found")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 16)
                    } else {
                        Text("Nothing found")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 16)
                    }
                }
            } compactLeading: {
                if let imageData = context.attributes.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 20, height: 20)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 20, height: 20)
                }
            } compactTrailing: {
                SearchStatusView(status: context.state.status, progress: context.state.progress, isCompact: true)
            } minimal: {
                if let imageData = context.attributes.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 16, height: 16)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 16, height: 16)
                }
            }
        }
    }
}

struct SearchActivityLockScreenView: View {
    let context: ActivityViewContext<SearchActivityAttributes>
    
    var body: some View {
        HStack(spacing: 12) {
            if let imageData = context.attributes.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 44, height: 44)
            }
            
            if context.state.status == .searching {
                Text("Searching item......")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            } else if context.state.status == .found {
                Text("Item found")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            } else {
                Text("Nothing found")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            SearchStatusView(status: context.state.status, progress: context.state.progress)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black)
    }
}

struct SearchStatusView: View {
    let status: SearchStatus
    let progress: Double
    var isCompact: Bool = false
    
    @State private var animationPhase: Int = 0
    
    var body: some View {
        Group {
            switch status {
            case .searching:
                if isCompact {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            .frame(width: 20, height: 20)
                        
                        if animationPhase == 0 {
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 4, height: 4)
                        } else if animationPhase == 1 {
                            HStack(spacing: 2) {
                                Circle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(width: 2, height: 2)
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(width: 2, height: 2)
                            }
                        } else {
                            HStack(spacing: 2) {
                                Circle()
                                    .fill(Color.white.opacity(0.4))
                                    .frame(width: 2, height: 2)
                                Circle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(width: 2, height: 2)
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(width: 2, height: 2)
                            }
                        }
                    }
                    .frame(width: 20, height: 20)
                } else {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2.5)
                            .frame(width: 32, height: 32)
                        
                        if animationPhase == 0 {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 6, height: 6)
                        } else if animationPhase == 1 {
                            HStack(spacing: 3) {
                                Circle()
                                    .fill(Color.white.opacity(0.4))
                                    .frame(width: 3, height: 3)
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 3, height: 3)
                            }
                        } else {
                            HStack(spacing: 3) {
                                Circle()
                                    .fill(Color.white.opacity(0.5))
                                    .frame(width: 3, height: 3)
                                Circle()
                                    .fill(Color.white.opacity(0.4))
                                    .frame(width: 3, height: 3)
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 3, height: 3)
                            }
                        }
                    }
                    .frame(width: 32, height: 32)
                }
            case .found:
                Circle()
                    .fill(Color.green)
                    .frame(width: isCompact ? 20 : 32, height: isCompact ? 20 : 32)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: isCompact ? 10 : 16, weight: .bold))
                            .foregroundColor(.white)
                    )
            case .nothingFound:
                Circle()
                    .fill(Color.red)
                    .frame(width: isCompact ? 20 : 32, height: isCompact ? 20 : 32)
                    .overlay(
                        Image(systemName: "xmark")
                            .font(.system(size: isCompact ? 10 : 16, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
        }
        .onAppear {
            if status == .searching {
                startAnimation()
            }
        }
        .onChange(of: status) { newStatus in
            if newStatus == .searching {
                startAnimation()
            } else {
                animationPhase = 0
            }
        }
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { timer in
            withAnimation(.easeInOut(duration: 0.3)) {
                animationPhase = (animationPhase + 1) % 3
            }
            if status != .searching {
                timer.invalidate()
            }
        }
    }
}

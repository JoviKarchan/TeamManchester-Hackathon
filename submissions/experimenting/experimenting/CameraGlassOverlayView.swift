import SwiftUI

struct CameraGlassOverlayView: View {
    var onBack: () -> Void

    var bottomPanelHeight: CGFloat = 158

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Full-screen clear layer that does NOT capture touches (so shutter/flip/flash work)
            Color.clear
                .contentShape(Rectangle())
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)

            // Only the back button receives touches (fixed 44×44); hint is non-interactive so shutter works
            backButton
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .padding(.leading, 16)
                .padding(.top, 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            hintView
                .allowsHitTesting(false)
                .padding(.horizontal, 24)
                .padding(.bottom, bottomPanelHeight)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .background(Color.clear)
    }

    private var backButton: some View {
        Button(action: onBack) {
            Image(systemName: "chevron.left")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .glassEffect(in: .circle)
    }

    private var hintView: some View {
        Text("Take a photo to search")
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(.primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .glassEffect(in: .rect(cornerRadius: 12))
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
        CameraGlassOverlayView(onBack: {})
    }
}

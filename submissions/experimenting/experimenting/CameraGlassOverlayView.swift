import SwiftUI

struct CameraGlassOverlayView: View {
    var onBack: () -> Void

    var bottomPanelHeight: CGFloat = 158

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
                .contentShape(Rectangle())
                .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 0) {
                    backButton
                        .padding(.leading, 16)
                        .padding(.top, 8)
                    Spacer(minLength: 0)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            VStack {
                Spacer()
                hintView
                    .padding(.horizontal, 24)
                    .padding(.bottom, bottomPanelHeight)
            }
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

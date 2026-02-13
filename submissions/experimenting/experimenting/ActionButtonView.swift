import SwiftUI
import UIKit

func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
    let generator = UIImpactFeedbackGenerator(style: style)
    generator.prepare()
    generator.impactOccurred()
}

struct PressScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(
                .spring(response: 0.25, dampingFraction: 0.8),
                value: configuration.isPressed
            )
    }
}

struct ActionButtonsView: View {
    var onCameraTapped: (() -> Void)?
    var onUploadTapped: (() -> Void)?

    var body: some View {
        HStack(spacing: 14) {
            actionButton(
                icon: "camera.fill",
                title: "Use Camera"
            ) {
                haptic(.light)
                onCameraTapped?()
            }

            actionButton(
                icon: "photo.on.rectangle",
                title: "Upload Photo"
            ) {
                haptic(.light)
                onUploadTapped?()
            }
        }
        .padding(.horizontal, 24)
    }

    private func actionButton(
        icon: String,
        title: String,
        action: @escaping () -> Void
    ) -> some View {
    Button(action: action) {
            VStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 26))
                    .foregroundColor(Color("All"))
                    .padding(20)
                    .background(
                        Circle()
                            .fill(Color(.systemGray5)) // w neutrality
                    )

                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color("All"))
            }
            .frame(width: 170, height: 200)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color("CardColor"))
                    .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
            )
        }
        .buttonStyle(PressScaleStyle())
    }
}

#Preview {
    ActionButtonsView()
}

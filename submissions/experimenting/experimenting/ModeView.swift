import SwiftUI

struct ModeView: View {
    @ObservedObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("Background")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        ModeRow(title: "System", isSelected: authManager.theme == .system, colorScheme: colorScheme) {
                            authManager.updateTheme(.system)
                        }
                        
                        Divider()
                            .padding(.leading, 16)
                        
                        ModeRow(title: "Light", isSelected: authManager.theme == .light, colorScheme: colorScheme) {
                            authManager.updateTheme(.light)
                        }
                        
                        Divider()
                            .padding(.leading, 16)
                        
                        ModeRow(title: "Dark", isSelected: authManager.theme == .dark, colorScheme: colorScheme) {
                            authManager.updateTheme(.dark)
                        }
                    }
                    .background(Color.white.opacity(colorScheme == .dark ? 0.1 : 1.0))
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                    .padding(.top, 30)
                    
                    Spacer()
                }
            }
            .navigationTitle("Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color("All"))
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(colorScheme == .dark ? 0.1 : 1.0))
                            .clipShape(Circle())
                    }
                }
            }
            .foregroundStyle(Color("All"))
        }
    }
}

struct ModeRow: View {
    let title: String
    let isSelected: Bool
    let colorScheme: ColorScheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 17))
                    .foregroundColor(Color("All"))
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }
}

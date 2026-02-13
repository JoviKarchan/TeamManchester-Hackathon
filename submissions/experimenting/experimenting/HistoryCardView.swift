import SwiftUI

struct HistoryCardView: View {
    let imageURL: URL
    let name: String
    let dateText: String
    
    var body: some View {
        HStack(spacing: 14) {
            thumbnail
            
            VStack(alignment: .leading, spacing: 6) {
                Text(name)
                    .font(.system(size: 22, weight: .regular))
                    .foregroundColor(Color("All"))
                    .fontWeight(.bold)
                
                Text(dateText)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(Color("All"))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color("All"))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color("CardColor"))
                .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 8)
        )
        .frame(maxWidth: 370)
        .padding(.leading, 10)

    }
    
    private var thumbnail: some View {
        Group {
            if imageURL.isFileURL,
               let uiImage = UIImage(contentsOfFile: imageURL.path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        fallbackThumb
                    }
                }
            }
        }
        .frame(width: 64, height: 64)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var fallbackThumb: some View {
        ZStack {
            Color(.systemGray5)
            Image(systemName: "photo")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(Color("All"))
        }
    }
}

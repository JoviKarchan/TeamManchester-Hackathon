import SwiftUI
import UIKit


private struct SearchableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct HomeView: View {
    @EnvironmentObject private var historyStore: HistoryStore
    @Binding var selectedTab: Int
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var searchableImage: SearchableImage?
    @State private var searchState: ImageSearchState = .searching
    @State private var searchMatches: [LensMatch] = []

    var body: some View {
        NavigationStack {
            ZStack {
                Color("Background")
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack(spacing: 8) {
                        Text("Findly")
                            .font(.system(size: 30, weight: .bold))

                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(Color("All"))

                        Spacer()
                    }
                    .padding(.top, 30)
                    .padding(.horizontal, 75)

                    Text("Add a photo to start searching")
                        .font(.system(size: 25))
                        .padding(.top, 80)
                        .frame(maxWidth: .infinity, alignment: .center)

                    Text("Find your dream outfit in seconds")
                        .font(.system(size: 16))
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .center)

                    ActionButtonsView(
                        onCameraTapped: { showCamera = true },
                        onUploadTapped: { showPhotoLibrary = true }
                    )
                    .padding(40)

                    HStack {
                        Text("Recent Searches")
                            .font(.system(size: 24))
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 70)
                        
                        Button {
                            selectedTab = 2
                        } label: {
                            Text("See All")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color("All"))
                                .padding(.trailing, 55)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    ForEach(Array(historyStore.items.prefix(2)).enumerated(), id: \.element.id) { index, item in
                        HistoryCardView(
                            imageURL: item.imageURL,
                            name: item.title,
                            dateText: HistoryItem.dateText(for: item.date)
                        )
                        .frame(width: 380)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, index == 0 ? 16 : 12)
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .foregroundStyle(Color("All"))
        }
        .fullScreenCover(isPresented: $showCamera) {
            CustomCameraView(isPresented: $showCamera, onCapture: handleImageForSearch)
        }
        .fullScreenCover(isPresented: $showPhotoLibrary) {
            PhotoLibraryPicker(
                isPresented: $showPhotoLibrary,
                onImagePicked: handleImageForSearch,
                onCancel: { showPhotoLibrary = false }
            )
        }
        .fullScreenCover(item: $searchableImage) { item in
            ImageSearchResultView(
                image: item.image,
                state: searchState,
                onTryAgain: {
                    searchableImage = nil
                },
                onDismiss: {
                    searchableImage = nil
                }
            )
        }
    }

    private func handleImageForSearch(_ image: UIImage) {
        showCamera = false
        showPhotoLibrary = false
        searchState = .searching
        searchMatches = []
        searchableImage = SearchableImage(image: image)

        if #available(iOS 16.1, *) {
            let searchId = UUID().uuidString
            LiveActivityManager.shared.startSearch(image: image, searchId: searchId)
        }

        Task {
            do {
                if #available(iOS 16.1, *) {
                    LiveActivityManager.shared.updateSearch(progress: 0.3)
                }
                
                let url = try await UploadService.uploadImage(image)
                
                if #available(iOS 16.1, *) {
                    LiveActivityManager.shared.updateSearch(progress: 0.6)
                }
                
                let matches = try await SerpApiClient.searchWithImageURLAllMatches(url)
                
                if #available(iOS 16.1, *) {
                    LiveActivityManager.shared.updateSearch(progress: 0.9)
                }
                
                await MainActor.run {
                    let matchesWithPrices = matches.filter { $0.priceLabel != nil && !$0.priceLabel!.isEmpty }
                    let title = matchesWithPrices.first?.title ?? matches.first?.title ?? "Image search"
                    historyStore.add(title: title, date: Date(), imageURL: url)
                    
                    if #available(iOS 16.1, *) {
                        LiveActivityManager.shared.completeSearch(found: !matchesWithPrices.isEmpty)
                    }
                    
                    if matchesWithPrices.isEmpty {
                        searchState = .noMatch
                    } else {
                        // Show matches immediately, then fetch trust scores
                        searchState = .found(matchesWithPrices)
                        searchMatches = matchesWithPrices
                        
                        // Fetch trust scores for all matches with prices
                        Task {
                            var matchesWithTrustScores: [LensMatch] = []
                            for match in matchesWithPrices {
                                var updatedMatch = match
                                if let trustScore = try? await TrustScoreClient.getTrustScore(from: match.link) {
                                    updatedMatch.trustScore = trustScore
                                }
                                matchesWithTrustScores.append(updatedMatch)
                            }
                            await MainActor.run {
                                searchState = .found(matchesWithTrustScores)
                                searchMatches = matchesWithTrustScores
                            }
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    if #available(iOS 16.1, *) {
                        LiveActivityManager.shared.completeSearch(found: false)
                    }
                    searchState = .noMatch
                }
            }
        }
    }
}

#Preview {
    HomeView(selectedTab: .constant(0))
        .environmentObject(HistoryStore())
}

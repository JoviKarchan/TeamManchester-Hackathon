import ActivityKit
import Foundation
import UIKit

@available(iOS 16.1, *)
class LiveActivityManager {
    static let shared = LiveActivityManager()
    
    private var currentActivity: Activity<SearchActivityAttributes>?
    
    private init() {}
    
    func startSearch(image: UIImage, searchId: String) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return
        }
        
        let imageData = image.jpegData(compressionQuality: 0.3)
        
        let attributes = SearchActivityAttributes(
            imageData: imageData,
            searchId: searchId
        )
        
        let contentState = SearchActivityAttributes.ContentState(
            status: .searching,
            progress: 0.0
        )
        
        do {
            let activity = try Activity<SearchActivityAttributes>.request(
                attributes: attributes,
                contentState: contentState,
                pushType: nil
            )
            currentActivity = activity
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }
    
    func updateSearch(progress: Double) {
        guard let activity = currentActivity else { return }
        
        let contentState = SearchActivityAttributes.ContentState(
            status: .searching,
            progress: progress
        )
        
        Task {
            await activity.update(using: contentState)
        }
    }
    
    func completeSearch(found: Bool) {
        guard let activity = currentActivity else { return }
        
        let contentState = SearchActivityAttributes.ContentState(
            status: found ? .found : .nothingFound,
            progress: 1.0
        )
        
        Task {
            await activity.update(using: contentState)
            
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            
            await activity.end(dismissalPolicy: .immediate)
            currentActivity = nil
        }
    }
    
    func endActivity() {
        guard let activity = currentActivity else { return }
        
        Task {
            await activity.end(dismissalPolicy: .immediate)
            currentActivity = nil
        }
    }
}

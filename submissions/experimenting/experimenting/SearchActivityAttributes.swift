import ActivityKit
import WidgetKit
import SwiftUI

struct SearchActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var status: SearchStatus
        var progress: Double
    }
    
    var imageData: Data?
    var searchId: String
}

enum SearchStatus: String, Codable {
    case searching
    case found
    case nothingFound
}

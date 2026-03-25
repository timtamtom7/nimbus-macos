import SwiftUI
import AppKit

extension View {
    func accessibilityFileLabel(name: String) -> some View {
        self.accessibilityLabel("File \(name)")
    }
}

import SwiftUI

// MARK: - Color Extensions
extension Color {
    // System Colors
    static let systemBackground = Color(UIColor.systemBackground)
    static let secondarySystemBackground = Color(UIColor.secondarySystemBackground)
    static let tertiarySystemBackground = Color(UIColor.tertiarySystemBackground)
    static let groupedBackground = Color(UIColor.systemGroupedBackground)
    static let secondaryGroupedBackground = Color(UIColor.secondarySystemGroupedBackground)
    
    // Custom App Colors
    static let primaryAccent = Color("PrimaryAccent") // 从 Assets 中读取
    static let secondaryAccent = Color("SecondaryAccent")
    
    // Semantic Colors
    static let safetyGreen = Color(UIColor.systemGreen)
    static let warningYellow = Color(UIColor.systemYellow)
    static let dangerRed = Color(UIColor.systemRed)
    static let infoBlue = Color(UIColor.systemBlue)
}

// MARK: - View Extensions
extension View {
    func cardBackground() -> some View {
        self.background(Color.secondarySystemBackground)
            .cornerRadius(12)
            .shadow(radius: 2)
    }
    
    func primaryBackground() -> some View {
        self.background(Color.groupedBackground)
    }
}

// MARK: - Theme Constants
enum Theme {
    static let padding: CGFloat = 16
    static let cornerRadius: CGFloat = 12
    static let shadowRadius: CGFloat = 2
    
    enum FontSize {
        static let small: CGFloat = 12
        static let regular: CGFloat = 16
        static let large: CGFloat = 20
        static let title: CGFloat = 24
    }
    
    enum Spacing {
        static let small: CGFloat = 8
        static let regular: CGFloat = 16
        static let large: CGFloat = 24
    }
} 
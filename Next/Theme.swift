import SwiftUI

// MARK: - App Theme
/// Centralized theme configuration for the Next app
/// Following the design philosophy: Minimal, Dark, Calm, No distractions
enum Theme {
    
    // MARK: - Colors
    enum Colors {
        /// Background color: #1C1C1E
        static let background = Color(hex: "1C1C1E")
        
        /// Primary text color: #FFFFFF
        static let primaryText = Color.white
        
        /// Secondary text color (dimmed)
        static let secondaryText = Color.white.opacity(0.7)
        
        /// Accent color (sage green): #8FAF9A
        static let accent = Color(hex: "8FAF9A")
        
        /// Muted background for buttons/cards
        static let cardBackground = Color(hex: "2C2C2E")
        
        /// Subtle divider color
        static let divider = Color.white.opacity(0.1)
    }
    
    // MARK: - Typography
    enum Typography {
        static let title = Font.system(size: 32, weight: .bold, design: .rounded)
        static let headline = Font.system(size: 24, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 18, weight: .regular, design: .rounded)
        static let caption = Font.system(size: 14, weight: .regular, design: .rounded)
        static let button = Font.system(size: 18, weight: .semibold, design: .rounded)
    }
    
    // MARK: - Spacing
    enum Spacing {
        static let xxSmall: CGFloat = 4
        static let xSmall: CGFloat = 8
        static let small: CGFloat = 12
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xLarge: CGFloat = 32
        static let xxLarge: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let pill: CGFloat = 50
    }
}

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers
extension View {
    func primaryButton() -> some View {
        self
            .font(Theme.Typography.button)
            .foregroundColor(Theme.Colors.background)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.medium)
            .background(Theme.Colors.accent)
            .cornerRadius(Theme.CornerRadius.medium)
    }
    
    func secondaryButton() -> some View {
        self
            .font(Theme.Typography.button)
            .foregroundColor(Theme.Colors.primaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.medium)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.medium)
    }
    
    func tertiaryButton() -> some View {
        self
            .font(Theme.Typography.button)
            .foregroundColor(Theme.Colors.secondaryText)
            .padding(.vertical, Theme.Spacing.small)
    }
}

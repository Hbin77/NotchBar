//
//  DesignSystem.swift
//  NotchBar
//
//  디자인 토큰 시스템
//

import SwiftUI

enum NotchDesign {

    // MARK: - Corner Radius

    enum CornerRadius {
        static let notch: CGFloat = 20
        static let card: CGFloat = 14
        static let button: CGFloat = 10
        static let pill: CGFloat = 20
        static let progress: CGFloat = 3
    }

    // MARK: - Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
    }

    // MARK: - Animation

    enum Anim {
        static let expand = Animation.spring(response: 0.4, dampingFraction: 0.85)
        static let contentAppear = Animation.spring(response: 0.35, dampingFraction: 0.8)
        static let hover = Animation.easeInOut(duration: 0.15)
        static let quick = Animation.easeOut(duration: 0.2)

        static func stagger(index: Int) -> Animation {
            .spring(response: 0.4, dampingFraction: 0.82).delay(Double(index) * 0.05)
        }
    }

    // MARK: - Shadow

    enum Shadow {
        static func popup() -> some ViewModifier { ShadowModifier(radius: 30, opacity: 0.4, y: 10) }
        static func card() -> some ViewModifier { ShadowModifier(radius: 8, opacity: 0.15, y: 2) }
        static func subtle() -> some ViewModifier { ShadowModifier(radius: 4, opacity: 0.1, y: 1) }
    }

    // MARK: - Typography

    enum Font {
        static let largeTitle = SwiftUI.Font.system(size: 28, weight: .light, design: .rounded)
        static let title = SwiftUI.Font.system(size: 14, weight: .semibold)
        static let body = SwiftUI.Font.system(size: 12, weight: .regular)
        static let caption = SwiftUI.Font.system(size: 11, weight: .medium)
        static let captionSecondary = SwiftUI.Font.system(size: 10, weight: .regular)
        static let tiny = SwiftUI.Font.system(size: 9, weight: .medium)
        static let mono = SwiftUI.Font.system(size: 11, weight: .medium, design: .monospaced)
        static let monoRounded = SwiftUI.Font.system(size: 11, weight: .medium, design: .rounded)
    }
}

// MARK: - Shadow Modifier

private struct ShadowModifier: ViewModifier {
    let radius: CGFloat
    let opacity: Double
    let y: CGFloat

    func body(content: Content) -> some View {
        content.shadow(color: .black.opacity(opacity), radius: radius, y: y)
    }
}

// MARK: - Widget Card Modifier

struct WidgetCardModifier: ViewModifier {
    @State private var isHovering = false

    func body(content: Content) -> some View {
        content
            .padding(NotchDesign.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: NotchDesign.CornerRadius.card)
                    .fill(Color.white.opacity(isHovering ? 0.08 : 0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: NotchDesign.CornerRadius.card)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.12), .white.opacity(0.03)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.5
                    )
            )
            .scaleEffect(isHovering ? 1.015 : 1.0)
            .animation(NotchDesign.Anim.hover, value: isHovering)
            .onHover { hovering in
                isHovering = hovering
            }
    }
}

extension View {
    func widgetCard() -> some View {
        modifier(WidgetCardModifier())
    }
}

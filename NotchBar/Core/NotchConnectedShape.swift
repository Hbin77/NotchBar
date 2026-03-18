//
//  NotchConnectedShape.swift
//  NotchBar
//
//  노치에서 자연스럽게 확장되는 커스텀 Shape
//
//  구조:
//       ╭──────╮        ← notchWidth, 메뉴바 바로 아래
//       │ stem │
//    ╭──╯      ╰──╮    ← S-커브 전환
//    │            │
//    │  본체      │    ← 전체 너비
//    │            │
//    ╰────────────╯
//

import SwiftUI

struct NotchConnectedShape: Shape {

    var notchWidth: CGFloat
    var stemHeight: CGFloat    // stem 높이 (보이는 부분)
    var cornerRadius: CGFloat = 22
    var curveSize: CGFloat = 24

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(notchWidth, stemHeight) }
        set {
            notchWidth = newValue.first
            stemHeight = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        let midX = rect.midX
        let halfNotch = notchWidth / 2
        let bodyTop = stemHeight

        var p = Path()

        // 1. stem 상단 좌측 (노치 하단과 맞닿는 지점)
        p.move(to: CGPoint(x: midX - halfNotch, y: 0))

        // 2. 상단 가장자리 (노치 너비)
        p.addLine(to: CGPoint(x: midX + halfNotch, y: 0))

        // 3. 우측 stem 하단까지
        p.addLine(to: CGPoint(x: midX + halfNotch, y: bodyTop))

        // 4. S-커브: stem 우측 → 본체 우측
        p.addCurve(
            to: CGPoint(x: rect.maxX, y: bodyTop + curveSize),
            control1: CGPoint(x: midX + halfNotch, y: bodyTop + curveSize * 0.7),
            control2: CGPoint(x: rect.maxX, y: bodyTop + curveSize * 0.3)
        )

        // 5. 우측 변 → 하단 우측 모서리
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius))

        // 6. 하단 우측 둥근 모서리
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )

        // 7. 하단 가장자리
        p.addLine(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY))

        // 8. 하단 좌측 둥근 모서리
        p.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - cornerRadius),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )

        // 9. 좌측 변 → 커브 시작점
        p.addLine(to: CGPoint(x: rect.minX, y: bodyTop + curveSize))

        // 10. S-커브: 본체 좌측 → stem 좌측
        p.addCurve(
            to: CGPoint(x: midX - halfNotch, y: bodyTop),
            control1: CGPoint(x: rect.minX, y: bodyTop + curveSize * 0.3),
            control2: CGPoint(x: midX - halfNotch, y: bodyTop + curveSize * 0.7)
        )

        // 11. 좌측 stem 상단까지
        p.addLine(to: CGPoint(x: midX - halfNotch, y: 0))

        p.closeSubpath()
        return p
    }
}

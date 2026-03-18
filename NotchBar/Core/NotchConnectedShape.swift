//
//  NotchConnectedShape.swift
//  NotchBar
//
//  노치에서 자연스럽게 확장되는 커스텀 Shape
//

import SwiftUI

struct NotchConnectedShape: Shape {

    var notchWidth: CGFloat
    var notchHeight: CGFloat   // 메뉴바/노치 높이 (stem 영역)
    var cornerRadius: CGFloat = 22
    var curveSize: CGFloat = 22 // 노치→패널 전환 곡선 크기

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(notchWidth, notchHeight) }
        set {
            notchWidth = newValue.first
            notchHeight = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        let midX = rect.midX
        let halfNotch = notchWidth / 2
        let notchR: CGFloat = min(12, halfNotch)
        let bodyTop = notchHeight

        var p = Path()

        // 1. 노치 stem 상단 좌측 모서리 (둥근)
        p.move(to: CGPoint(x: midX - halfNotch + notchR, y: 0))

        // 2. 상단 가장자리
        p.addLine(to: CGPoint(x: midX + halfNotch - notchR, y: 0))

        // 3. 상단 우측 둥근 모서리
        p.addQuadCurve(
            to: CGPoint(x: midX + halfNotch, y: notchR),
            control: CGPoint(x: midX + halfNotch, y: 0)
        )

        // 4. 우측 stem 하단까지
        p.addLine(to: CGPoint(x: midX + halfNotch, y: bodyTop))

        // 5. S-커브: stem 우측 → 패널 본체 우측
        p.addCurve(
            to: CGPoint(x: rect.maxX, y: bodyTop + curveSize),
            control1: CGPoint(x: midX + halfNotch, y: bodyTop + curveSize * 0.65),
            control2: CGPoint(x: rect.maxX, y: bodyTop + curveSize * 0.35)
        )

        // 6. 우측 변 → 하단 우측 모서리
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius))

        // 7. 하단 우측 둥근 모서리
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )

        // 8. 하단 가장자리
        p.addLine(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY))

        // 9. 하단 좌측 둥근 모서리
        p.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - cornerRadius),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )

        // 10. 좌측 변 → 커브 시작점
        p.addLine(to: CGPoint(x: rect.minX, y: bodyTop + curveSize))

        // 11. S-커브: 패널 본체 좌측 → stem 좌측
        p.addCurve(
            to: CGPoint(x: midX - halfNotch, y: bodyTop),
            control1: CGPoint(x: rect.minX, y: bodyTop + curveSize * 0.35),
            control2: CGPoint(x: midX - halfNotch, y: bodyTop + curveSize * 0.65)
        )

        // 12. 좌측 stem 상단까지
        p.addLine(to: CGPoint(x: midX - halfNotch, y: notchR))

        // 13. 상단 좌측 둥근 모서리
        p.addQuadCurve(
            to: CGPoint(x: midX - halfNotch + notchR, y: 0),
            control: CGPoint(x: midX - halfNotch, y: 0)
        )

        p.closeSubpath()
        return p
    }
}

//
//  CircularProgressRing.swift
//  FastFlow
//
//  通用圆环进度组件，用于断食计时主界面与喝水进度。
//

import SwiftUI

struct CircularProgressRing<Center: View>: View {
    /// 进度 0...1。
    let progress: Double
    /// 圆环渐变色。
    var gradient: Gradient = Gradient(colors: [.accentColor, Color.goalReached])
    /// 线宽。
    var lineWidth: CGFloat = 18
    /// 中心内容。
    @ViewBuilder var center: () -> Center

    var body: some View {
        ZStack {
            // 背景轨道。
            Circle()
                .stroke(
                    Color.secondary.opacity(0.15),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )

            // 进度弧。
            Circle()
                .trim(from: 0, to: max(0.0001, min(1, progress)))
                .stroke(
                    AngularGradient(
                        gradient: gradient,
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(DS.Motion.smooth, value: progress)

            center()
                .padding(lineWidth * 2)
        }
        // 圆环本身为装饰，进度信息由中心内容朗读；避免 VoiceOver 重复读取轨道。
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    CircularProgressRing(progress: 0.65) {
        VStack {
            Text("16:8").font(.headline)
            Text("10:24:00").font(.system(.largeTitle, design: .rounded).weight(.bold))
        }
    }
    .frame(width: 280, height: 280)
    .padding()
}

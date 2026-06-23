//
//  FastFlowWidgetBundle.swift
//  FastFlowWidget
//
//  Widget Extension 入口。聚合主屏 Widget 与断食 Live Activity。
//  ⚠️ 此文件属于「Widget Extension」Target（由 Xcode 新建 Widget Extension 时生成入口，
//     将本 Bundle 设为 @main）。
//

import SwiftUI
import WidgetKit

@main
struct FastFlowWidgetBundle: WidgetBundle {
    var body: some Widget {
        FastingProgressWidget()
        FastingLiveActivity()
    }
}

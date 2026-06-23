//
//  String+Localized.swift
//  LumenPuzzle
//
//  把运行时的本地化键（String）转换为可被 Text 本地化的 LocalizedStringKey，
//  以及直接取本地化字符串值的便捷方法。
//

import SwiftUI

extension String {

    /// 将本字符串视为本地化键，返回 LocalizedStringKey（供 Text 渲染时查表）。
    var asLocalizedKey: LocalizedStringKey {
        LocalizedStringKey(self)
    }

    /// 直接返回本地化后的字符串值。
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
}

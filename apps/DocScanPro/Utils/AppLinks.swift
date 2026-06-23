//
//  AppLinks.swift
//  DocScanPro
//
//  集中管理 App 内引用的外部链接。隐私政策在 App 内以原生页面呈现
//  （见 PrivacyView），无需依赖外部网站；使用条款采用 Apple 官方标准
//  EULA，确保上架审核时链接始终有效。
//

import Foundation

enum AppLinks {

    /// 使用条款：Apple 官方标准最终用户许可协议（EULA）。
    /// 当未提供自定义条款页时，App Store 允许并推荐使用此标准链接。
    static let termsOfUse = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    /// 支持邮箱（mailto，无需架设网站即可联系）。
    /// 上架前请替换为真实的支持邮箱地址。
    static let support = URL(string: "mailto:support@docscanpro.app")!
}

//
//  AppLinks.swift
//  CleanAlbum
//
//  对外法务链接集中管理，便于上架前替换为正式托管地址。
//

import Foundation

enum AppLinks {
    /// 使用条款：采用 Apple 标准 EULA（无自定义条款时的官方推荐做法）。
    static let termsOfUse = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    /// 隐私政策。
    ///
    /// 仓库内已附 `PRIVACY.html`（声明"零收集"），可直接托管到 GitHub Pages 等静态站点。
    /// 上架前请将此 URL 替换为你实际托管的地址，并与 App Store Connect 中填写的隐私政策 URL 保持一致。
    static let privacyPolicy = URL(string: "https://zhangshicheng3d.github.io/cleanalbum/privacy.html")!
}

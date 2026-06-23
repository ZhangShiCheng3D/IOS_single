//
//  PrivacyPolicyView.swift
//  SeniorHelper
//
//  应用内隐私政策。本应用纯本地运行、不联网、不收集任何数据，
//  因此隐私政策直接内置于 App 中，无需外部网页（避免失效链接）。
//

import SwiftUI

struct PrivacyPolicyView: View {

    /// 一条政策条目：标题 + 说明。
    private let sections: [(title: LocalizedStringKey, body: LocalizedStringKey)] = [
        ("不收集个人信息", "本应用完全在您的设备上运行，不收集、不上传、也不共享任何个人信息。"),
        ("数据存储", "用药计划、紧急联系人与药盒照片仅保存在您的设备本地，永不上传到任何服务器。"),
        ("相机与相册", "相机仅用于放大镜和拍摄药盒照片；相册仅用于选取药盒照片。照片只保存在本机。"),
        ("通知", "用药提醒通过系统本地通知发送，不经过任何网络服务。"),
        ("购买", "内购由 Apple App Store 处理，我们不会接触到您的支付信息。"),
        ("联系我们", "如有任何疑问，请通过「设置 › 联系与帮助」与我们联系。")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.largePadding) {
                VStack(alignment: .leading, spacing: Theme.smallPadding) {
                    Text("我们重视您的隐私")
                        .font(.title.weight(.bold))
                    Text("一句话总结：所有数据只留在您的手机里。")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                ForEach(sections.indices, id: \.self) { index in
                    let section = sections[index]
                    VStack(alignment: .leading, spacing: 6) {
                        Text(section.title)
                            .font(.title3.weight(.bold))
                        Text(section.body)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Text(verbatim: String(localized: "最近更新") + "：2025-12")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                    .padding(.top, Theme.smallPadding)
            }
            .padding(Theme.padding)
        }
        .background(Theme.pageBackground)
        .navigationTitle(Text("隐私政策"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}

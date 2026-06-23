//
//  HomeView.swift
//  CollageKit
//
//  首页：工程作品库。新建工程、继续编辑、删除，入口到设置与 Pro。
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var store: PurchaseManager
    @Query(sort: \CollageProject.updatedAt, order: .reverse) private var projects: [CollageProject]

    @State private var path: [CollageProject] = []
    @State private var showNewTemplatePicker = false
    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var projectToDelete: CollageProject?

    private let columns = [GridItem(.flexible(), spacing: 16),
                           GridItem(.flexible(), spacing: 16)]

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if projects.isEmpty {
                    emptyState
                } else {
                    gallery
                }
            }
            .navigationTitle("app_name")
            .toolbar { toolbarContent }
            .navigationDestination(for: CollageProject.self) { project in
                EditorView(project: project).environmentObject(store)
            }
            .sheet(isPresented: $showNewTemplatePicker) {
                TemplatePickerView(isPro: store.isPro,
                                   onSelect: createProject,
                                   onNeedPro: { showNewTemplatePicker = false; showPaywall = true })
            }
            .sheet(isPresented: $showSettings) {
                SettingsView().environmentObject(store)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView().environmentObject(store)
            }
            .confirmationDialog("delete_confirm_title",
                                isPresented: Binding(get: { projectToDelete != nil },
                                                     set: { if !$0 { projectToDelete = nil } }),
                                titleVisibility: .visible) {
                Button("delete", role: .destructive) {
                    if let project = projectToDelete { delete(project) }
                }
                Button("cancel", role: .cancel) { projectToDelete = nil }
            } message: {
                Text("delete_confirm_message")
            }
            .safeAreaInset(edge: .bottom) { newButton }
        }
    }

    // MARK: - 顶部栏

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if !store.isPro {
                Button {
                    showPaywall = true
                } label: {
                    Label("pro_badge", systemImage: "crown.fill")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Color.accentColor.opacity(0.15))
                        .foregroundStyle(Color.accentColor)
                        .clipShape(Capsule())
                }
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
            }
            .accessibilityLabel(Text("settings_title"))
        }
    }

    // MARK: - 作品库

    private var gallery: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(projects) { project in
                    Button {
                        path.append(project)
                    } label: {
                        projectCard(project)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            projectToDelete = project
                        } label: {
                            Label("delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    private func projectCard(_ project: CollageProject) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            MiniCollageView(project: project)
                .frame(height: 160)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(.separator), lineWidth: 0.5)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(project.title.isEmpty ? String(localized: "untitled_project") : project.title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Text(project.updatedAt, format: .relative(presentation: .named))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - 空状态

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("home_empty_title").font(.title3.weight(.semibold))
            Text("home_empty_sub")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 新建按钮

    private var newButton: some View {
        Button {
            showNewTemplatePicker = true
        } label: {
            Label("home_new", systemImage: "plus")
        }
        .buttonStyle(PrimaryButtonStyle())
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - 行为

    private func createProject(_ template: CollageTemplate) {
        let project = CollageProject(template: template)
        context.insert(project)
        showNewTemplatePicker = false
        path.append(project)
    }

    private func delete(_ project: CollageProject) {
        DesignSystem.Haptics.impact(.medium)
        withAnimation(.easeInOut(duration: 0.25)) {
            context.delete(project)
        }
        projectToDelete = nil
    }
}

#Preview {
    HomeView()
        .environmentObject(PurchaseManager())
        .modelContainer(for: [CollageProject.self, CollagePhoto.self,
                              CollageText.self, UserPreset.self], inMemory: true)
}

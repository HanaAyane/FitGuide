import SwiftUI

struct FavoritePickerSheet: View {
    let exerciseId: String
    @EnvironmentObject var library: LibraryStore
    @EnvironmentObject var store: ExerciseStore
    @Environment(\.dismiss) private var dismiss
    @State private var showCreate = false
    @State private var newName = ""

    var body: some View {
        NavigationStack {
            ZStack {
                SpaceBackground()
                List {
                    if let df = library.defaultFavorites {
                        row(list: df)
                    }
                    if !library.customLists.isEmpty {
                        Section {
                            ForEach(library.customLists) { row(list: $0) }
                        } header: {
                            HStack {
                                Text("自定义列表")
                                Spacer()
                                Text("My Lists".uppercased())
                                    .font(.caption2.smallCaps())
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }
                    Section {
                        Button {
                            showCreate.toggle()
                        } label: {
                            Label("新建列表  New List", systemImage: "plus.circle")
                                .foregroundColor(Color.accentColor)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
            .navigationTitle("收藏到  Save to")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("完成", action: { dismiss() })
                        .foregroundColor(.textPrimary)
                }
            }
            .alert("新建列表 New List", isPresented: $showCreate) {
                TextField("列表名称 List name", text: $newName)
                Button("取消", role: .cancel) { newName = "" }
                Button("创建", action: {
                    let name = newName.trimmingCharacters(in: .whitespaces)
                    if !name.isEmpty {
                        library.addList(named: name)
                        newName = ""
                    }
                })
            }
        }
    }

    @ViewBuilder
    private func row(list: FavoriteList) -> some View {
        let isFav = library.isFavorited(exerciseId: exerciseId, in: list)
        Button {
            library.toggleFavorite(exerciseId: exerciseId, in: list)
        } label: {
            HStack {
                Text(list.name)
                    .foregroundColor(.textPrimary)
                Spacer()
                if let count = list.items.count as Int? {
                    Text("\(count)")
                        .font(.subheadline.monospacedDigit())
                        .foregroundColor(.textSecondary)
                }
                Image(systemName: isFav ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isFav ? Color.accentColor : .textSecondary)
            }
        }
        .listRowBackground(Color.clear)
    }
}
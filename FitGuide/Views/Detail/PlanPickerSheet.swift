import SwiftUI

struct PlanPickerSheet: View {
    let exerciseId: String
    @EnvironmentObject var library: LibraryStore
    @Environment(\.dismiss) private var dismiss
    @State private var showCreate = false
    @State private var newName = ""

    var body: some View {
        NavigationStack {
            ZStack {
                SpaceBackground()
                List {
                    Section {
                        Button {
                            showCreate.toggle()
                        } label: {
                            Label("新建计划 New Plan", systemImage: "plus.circle")
                                .foregroundColor(Color.accentColor)
                        }
                    }
                    if !library.trainingPlans.isEmpty {
                        Section {
                            ForEach(library.trainingPlans) { plan in
                                let already = library.containsInPlan(plan, exerciseId: exerciseId)
                                Button {
                                    guard !already else { return }
                                    library.addToPlan(plan, exerciseId: exerciseId)
                                    dismiss()
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(plan.name)
                                                .foregroundColor(.textPrimary)
                                            if already {
                                                Text("已添加 · Added")
                                                    .font(.caption2.smallCaps())
                                                    .foregroundColor(Color.accentColor)
                                            } else {
                                                Text("\(plan.items.count) 个动作 · Items")
                                                    .font(.caption.smallCaps())
                                                    .foregroundColor(.textSecondary)
                                            }
                                        }
                                        Spacer()
                                        Image(systemName: already ? "checkmark.circle.fill" : "plus.circle")
                                            .foregroundColor(already ? Color.accentColor : Color.accentColor)
                                    }
                                    .opacity(already ? 0.5 : 1.0)
                                }
                                .disabled(already)
                            }
                        } header: {
                            Text("已有计划 Plans")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("加入计划  Add to Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消", action: { dismiss() })
                        .foregroundColor(.textSecondary)
                }
            }
            .alert("新建计划 New Plan", isPresented: $showCreate) {
                TextField("名称", text: $newName)
                Button("取消", role: .cancel) { newName = "" }
                Button("创建并加入", action: {
                    let name = newName.trimmingCharacters(in: .whitespaces)
                    if !name.isEmpty {
                        let plan = library.addPlan(named: name)
                        library.addToPlan(plan, exerciseId: exerciseId)
                        newName = ""
                        dismiss()
                    }
                })
            }
        }
    }
}
import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject var library: LibraryStore
    @EnvironmentObject var store: ExerciseStore
    @EnvironmentObject var workoutStore: ActiveWorkoutStore

    var body: some View {
        ZStack {
            SpaceBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l.rawValue) {
                    languageSection
                    workoutSection
                    dataSection
                    attributionSection
                    aboutSection
                }
                .padding(Spacing.m.rawValue)
            }
        }
        .navigationTitle("设置 Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var workoutSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.s.rawValue) {
                Text("训练 Workout")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                Toggle(
                    isOn: $workoutStore.autoStartRestTimerEnabled
                ) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("自动开始休息计时")
                            .font(.subheadline)
                            .foregroundColor(.textPrimary)
                        Text("AUTO-START REST TIMER")
                            .font(.caption2.smallCaps())
                            .foregroundColor(.textSecondary)
                    }
                }
                .tint(Color.accentColor)

                Text("关闭后，完成训练组不会自动弹出计时器；暂停、延长和跳过操作不受影响。")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                Text("When off, completing a set will not start the rest timer automatically.")
                    .font(.caption2.smallCaps())
                    .foregroundColor(.textSecondary)

                Divider()
                    .overlay(Color.white.opacity(0.08))

                Toggle(
                    isOn: $workoutStore.restTimerSoundEnabled
                ) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("休息结束声音")
                            .font(.subheadline)
                            .foregroundColor(.textPrimary)
                        Text("REST-END SOUND")
                            .font(.caption2.smallCaps())
                            .foregroundColor(.textSecondary)
                    }
                }
                .tint(Color.accentColor)

                Text("默认关闭；开启后仅在 App 活跃时播放系统提示音，并遵循设备音量与静音设置。")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                Text("Off by default. When enabled, an in-app system sound follows device audio settings.")
                    .font(.caption2.smallCaps())
                    .foregroundColor(.textSecondary)
            }
        }
    }

    private var languageSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.s.rawValue) {
                Text("语言 Language")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                Text("始终显示中英双语")
                    .font(.subheadline)
                    .foregroundColor(.textPrimary)
                Text("Chinese–English bilingual is always on")
                    .font(.caption.smallCaps())
                    .foregroundColor(.textSecondary)
                Text("本应用遵循\"中英共生\"设计原则，不提供单语切换。")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .padding(.top, Spacing.xs.rawValue)
            }
        }
    }

    private var dataSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.s.rawValue) {
                Text("数据 Data")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                row(zh: "动作库总数", en: "Total exercises", value: "\(store.exercises.count)")
                row(zh: "计划个数", en: "Training plans", value: "\(library.trainingPlans.count)")
                row(
                    zh: "已完成训练",
                    en: "Completed workouts",
                    value: "\(workoutStore.completedSessionCount())"
                )
                row(zh: "最近看过", en: "Recents", value: "\(library.recentViews.count)")
                Text("计划、逐组重量与次数、训练历史均仅保存在本机，不通过云端同步。")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .padding(.top, Spacing.xs.rawValue)
                Text("Plans, set logs and workout history are local-only; no cloud sync.")
                    .font(.caption2.smallCaps())
                    .foregroundColor(.textSecondary)
            }
        }
    }

    private var attributionSection: some View {
        VStack(spacing: Spacing.s.rawValue) {
            GlassCard {
                VStack(alignment: .leading, spacing: Spacing.s.rawValue) {
                    Text("媒体致谢 Media Attribution")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    Text("动作示范图与动画 GIF 来源：")
                        .font(.subheadline)
                        .foregroundColor(.textPrimary)
                    Text("Exercise demo images and GIFs are from:")
                        .font(.caption.smallCaps())
                        .foregroundColor(.textSecondary)
                    Link(destination: URL(string: "https://gymvisual.com/")!) {
                        HStack(spacing: Spacing.xs.rawValue) {
                            Image(systemName: "safari")
                            Text("Gym visual — gymvisual.com")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color.accentColor)
                    }
                }
            }
            AttributionFooter()
        }
    }

    private var aboutSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.xs.rawValue) {
                Text("关于 About")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                Text("FitGuide · 健身动作指导")
                    .font(.subheadline)
                    .foregroundColor(.textPrimary)
                Text("仅个人学习/作品集用途，不上架 App Store。")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                Text("Personal / portfolio use only. Not for App Store distribution.")
                    .font(.caption2.smallCaps())
                    .foregroundColor(.textSecondary)
            }
        }
    }

    private func row(zh: String, en: String, value: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(zh)
                    .font(.subheadline)
                    .foregroundColor(.textPrimary)
                Text(en.uppercased())
                    .font(.caption2.smallCaps())
                    .foregroundColor(.textSecondary)
            }
            Spacer()
            Text(value)
                .font(.subheadline.monospacedDigit())
                .foregroundColor(Color.accentColor)
        }
    }
}

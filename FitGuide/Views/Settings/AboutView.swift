import SwiftUI

struct AboutView: View {
    var body: some View {
        ZStack {
            SpaceBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l.rawValue) {
                    VStack(spacing: Spacing.s.rawValue) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 72, weight: .light))
                            .foregroundColor(Color.accentColor)
                        Text("HanaAyane")
                            .font(.title2.weight(.semibold))
                            .foregroundColor(.textPrimary)
                        Text("HanaAyane")
                            .font(.subheadline.smallCaps())
                            .foregroundColor(.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.m.rawValue)

                    GlassCard {
                        VStack(alignment: .leading, spacing: Spacing.s.rawValue) {
                            Text("开发者 Developer")
                                .font(.headline)
                                .foregroundColor(.textPrimary)
                            Text("本应用由 HanaAyane 设计与开发。\nDesigned and developed by HanaAyane.")
                                .font(.subheadline)
                                .foregroundColor(.textPrimary)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: Spacing.s.rawValue) {
                            Text("GitHub")
                                .font(.headline)
                                .foregroundColor(.textPrimary)
                            Link(destination: URL(string: "https://github.com/HanaAyane")!) {
                                HStack(spacing: Spacing.s.rawValue) {
                                    Image(systemName: "safari")
                                        .foregroundColor(Color.accentColor)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("HanaAyane")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(Color.accentColor)
                                        Text("github.com/HanaAyane")
                                            .font(.caption2.smallCaps())
                                            .foregroundColor(.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.up.right.square")
                                        .foregroundColor(Color.accentColor)
                                }
                            }
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: Spacing.s.rawValue) {
                            Text("FitGuide · 健身动作指导")
                                .font(.headline)
                                .foregroundColor(.textPrimary)
                            Text("Version 2.0")
                                .font(.subheadline.monospacedDigit())
                                .foregroundColor(Color.accentColor)
                            Text("1324 个动作 · 离线训练记录 · 中英双语")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                            Text("1324 exercises · Offline workout tracking · Bilingual")
                                .font(.caption2.smallCaps())
                                .foregroundColor(.textSecondary)
                        }
                    }

                    AttributionFooter()
                }
                .padding(Spacing.m.rawValue)
            }
        }
        .navigationTitle("关于 About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

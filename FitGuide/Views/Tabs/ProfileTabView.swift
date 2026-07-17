import SwiftUI

struct ProfileTabView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                SpaceBackground()
                VStack(spacing: Spacing.m.rawValue) {
                    VStack(spacing: Spacing.s.rawValue) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 56, weight: .light))
                            .foregroundColor(.textSecondary)
                        Text("我的")
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.textPrimary)
                        Text("Profile")
                            .font(.subheadline.smallCaps())
                            .foregroundColor(.textSecondary)
                    }
                    Spacer()
                    GlassCard(padding: Spacing.m.rawValue) {
                        NavigationLink {
                            SettingsView()
                        } label: {
                            HStack {
                                Image(systemName: "gearshape")
                                    .foregroundColor(Color.accentColor)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("设置")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.textPrimary)
                                    Text("Settings")
                                        .font(.caption2.smallCaps())
                                        .foregroundColor(.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, Spacing.m.rawValue)
                    GlassCard(padding: Spacing.m.rawValue) {
                        NavigationLink {
                            AboutView()
                        } label: {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(Color.accentColor)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("关于")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.textPrimary)
                                    Text("About")
                                        .font(.caption2.smallCaps())
                                        .foregroundColor(.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, Spacing.m.rawValue)
                    Spacer()
                }
                .padding(Spacing.m.rawValue)
            }
            .navigationTitle("我的")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
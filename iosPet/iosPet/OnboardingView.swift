//
//  OnboardingView.swift
//  iosPet
//
//  首次 / 功能更新时展示的全屏引导页
//

import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let emoji: String
}

struct OnboardingView: View {
    @Binding var hasFinishedOnboarding: Bool
    @State private var currentIndex: Int = 0

    private let pages: [OnboardingPage] = [
        .init(
            title: "你的桌宠来了",
            subtitle: "它会在桌面和小组件里陪着你，一起提醒休息、运动和专注学习。",
            emoji: "😺"
        ),
        .init(
            title: "添加桌面小组件",
            subtitle: "长按桌面空白处 → 点击左上角“+” → 搜索“桌宠” → 选择喜欢的尺寸添加。",
            emoji: "📱"
        ),
        .init(
            title: "表情跟随状态变化",
            subtitle: "在应用里切换“摸摸它 / 去运动 / 学习模式”等操作时，小组件和 App 图标的表情会一起变化。",
            emoji: "🎭"
        )
    ]

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack {
                TabView(selection: $currentIndex) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        VStack(spacing: 24) {
                            Spacer()

                            Text(page.emoji)
                                .font(.system(size: 80))

                            VStack(spacing: 12) {
                                Text(page.title)
                                    .font(.title.bold())
                                Text(page.subtitle)
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 32)
                            }

                            Spacer()

                            if index == pages.count - 1 {
                                Button {
                                    withAnimation(.spring()) {
                                        print("[OnboardingView] ✅ 用户完成 onboarding，开始体验主界面")
                                        hasFinishedOnboarding = true
                                    }
                                } label: {
                                    Text("开始体验")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.accentColor)
                                        .foregroundColor(.white)
                                        .cornerRadius(14)
                                        .padding(.horizontal, 32)
                                }
                                .padding(.bottom, 40)
                            } else {
                                // 保持底部留白，让用户自然通过滑动进入下一页
                                Spacer().frame(height: 80)
                            }
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
            }
        }
    }
}

#Preview {
    OnboardingView(hasFinishedOnboarding: .constant(false))
}



//
//  iosPetApp.swift
//  iosPet
//
//  Created by admin on 2025/12/9.
//

import SwiftUI
import WidgetKit
import BackgroundTasks
import UIKit

@main
struct iosPetApp: App {
    /// 首次 / 功能更新引导标记
    /// 如有大版本功能更新，可以改成 hasSeenOnboarding_v2 之类重新引导一次
    @AppStorage("hasSeenOnboarding_v1") private var hasSeenOnboarding: Bool = false

    init() {
        print("[iosPetApp] 📱 应用启动 - Onboarding 状态: \(hasSeenOnboarding)")

        // 注册后台刷新任务
        registerBackgroundTasks()
        
        // 监听应用进入前台，立即刷新Widget
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            print("[iosPetApp] 📱 应用进入前台，立即刷新Widget")
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasSeenOnboarding {
                    ContentView()
                } else {
                    OnboardingView(hasFinishedOnboarding: $hasSeenOnboarding)
                }
            }
            .task {
                print("[iosPetApp] 🚀 应用启动，开始初始化...")

                // 请求通知权限（首次启动时即可提示）
                let permissionGranted = await NotificationManager.shared.requestPermission()
                print("[iosPetApp] 🔐 通知权限请求结果: \(permissionGranted ? "已授权" : "已拒绝")")

                // 初始化 Widget 状态（如果 App Group 中没有数据，设置为 idle）
                initializeWidgetState()

                // 启动使用习惯提醒（无论权限如何，都启动用于测试）
                print("[iosPetApp] 📊 启动使用习惯提醒...")
                UsageReminderManager.shared.startMonitoring()

                if !permissionGranted {
                    print("[iosPetApp] ⚠️ 通知权限被拒绝，但监测仍会启动（用于测试和日志）")
                }

                print("[iosPetApp] ✅ 应用初始化完成")

                // 在DEBUG模式下运行测试
                #if DEBUG
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    print("[iosPetApp] 🧪 运行测试套件...")
                    TestModeManager.runTestSuite()
                    UsageReminderManager.shared.validateTestModeThresholds()
                }
                #endif
            }
        }
    }
    
    /// 初始化 Widget 状态，确保 App Group 中有初始值
    private func initializeWidgetState() {
        guard let defaults = UserDefaults(suiteName: AppGroupKeys.suiteName) else {
            print("[iosPetApp] ⚠️ 无法访问 App Group，Widget 可能无法正常工作")
            return
        }
        
        // 如果 App Group 中没有情绪数据，设置为 idle
        if defaults.string(forKey: AppGroupKeys.sharedEmotionKey) == nil {
            defaults.set(PetEmotion.idle.rawValue, forKey: AppGroupKeys.sharedEmotionKey)
            defaults.synchronize()
            print("[iosPetApp] ✅ 初始化 Widget 状态为 idle")
            
            // 刷新 Widget 以显示初始状态
            WidgetCenter.shared.reloadAllTimelines()
        } else {
            print("[iosPetApp] ✅ Widget 状态已存在，无需初始化")
        }

        // 调度后台刷新任务
        scheduleBackgroundRefresh()
    }

    /// 注册后台刷新任务
    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.example.iosPet.inactivityCheck", using: nil) { task in
            self.handleInactivityCheck(task: task as! BGAppRefreshTask)
        }
        print("[iosPetApp] 📋 已注册后台刷新任务")
    }

    /// 处理后台久未使用检查任务
    private func handleInactivityCheck(task: BGAppRefreshTask) {
        print("[iosPetApp] 🔄 执行后台久未使用检查")

        // 执行完整的检查逻辑
        UsageReminderManager.shared.manualCheck()

        // 强制刷新Widget以反映最新状态
        WidgetCenter.shared.reloadAllTimelines()

        // 调度下一次任务
        scheduleBackgroundRefresh()

        // 标记任务完成
        task.setTaskCompleted(success: true)
    }

    /// 调度后台刷新任务
    private func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.example.iosPet.inactivityCheck")

        // 考虑测试模式的时间缩放，但确保最小间隔
        let normalInterval: TimeInterval = 60 * 60  // 1小时
        let scaledInterval = TestModeManager.shared.scaledTimeInterval(normalInterval)

        // iOS后台任务最小间隔限制，确保至少15分钟
        let minInterval: TimeInterval = 15 * 60  // 15分钟
        let actualInterval = max(scaledInterval, minInterval)

        request.earliestBeginDate = Date(timeIntervalSinceNow: actualInterval)

        print("[iosPetApp] ⏱️ 后台任务调度间隔: \(actualInterval) 秒 (\(TestModeManager.shared.isTestModeEnabled ? "测试模式" : "正常模式"))")

        do {
            try BGTaskScheduler.shared.submit(request)
            print("[iosPetApp] ✅ 已调度后台刷新任务")
        } catch {
            print("[iosPetApp] ❌ 调度后台任务失败: \(error)")
        }
    }
}


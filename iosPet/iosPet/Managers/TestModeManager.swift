//
//  TestModeManager.swift
//  iosPet
//
//  测试模式管理器 - 控制演示时缩短时间阈值
//

import Foundation
import SwiftUI
#if os(iOS)
import WidgetKit
#endif

// MARK: - 调试扩展（仅在DEBUG模式下可用）
#if DEBUG
extension TestModeManager {
    /// 运行完整的功能测试
    static func runTestSuite() {
        print("\n" + String(repeating: "=", count: 50))
        print("🧪 TestModeManager 功能测试开始")
        print(String(repeating: "=", count: 50))

        let manager = TestModeManager.shared

        // 测试1: 验证初始状态
        print("\n📋 测试1: 初始状态检查")
        print("   当前测试模式: \(manager.isTestModeEnabled ? "开启" : "关闭")")
        print("   时间缩放因子: \(manager.timeScaleFactor)倍")

        // 测试2: 验证正常模式
        print("\n📋 测试2: 正常模式验证")
        manager.isTestModeEnabled = false
        manager.validateTimeScaling()

        // 测试3: 验证测试模式
        print("\n📋 测试3: 测试模式验证")
        manager.isTestModeEnabled = true
        manager.validateTimeScaling()

        print("\n" + String(repeating: "=", count: 50))
        print("✅ TestModeManager 功能测试完成")
        print("💡 在应用设置中切换测试模式开关来控制时间缩放")
        print(String(repeating: "=", count: 50) + "\n")
    }
}
#endif

final class TestModeManager: ObservableObject {
    static let shared = TestModeManager()

    @Published var isTestModeEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(isTestModeEnabled, forKey: "isTestModeEnabled")
            UserDefaults.standard.synchronize()

            // 同时保存到 App Group，让 Widget 也能读取
            if let appGroupDefaults = UserDefaults(suiteName: "group.com.example.iosPet") {
                appGroupDefaults.set(isTestModeEnabled, forKey: "isTestModeEnabled")
                appGroupDefaults.synchronize()
                print("[TestMode] 💾 测试模式状态已保存到App Group: \(isTestModeEnabled)")
            }

            // 立即刷新Widget，确保显示最新的测试模式状态
            #if os(iOS)
            refreshWidgetImmediately()
            #endif

            // 当测试模式改变时，通知所有相关管理器重启
            NotificationCenter.default.post(name: .testModeDidChange, object: nil)
        }
    }

    private init() {
        // 从 UserDefaults 加载测试模式状态
        isTestModeEnabled = UserDefaults.standard.bool(forKey: "isTestModeEnabled")
    }

    // 测试模式时间缩放因子（用于演示）
    var timeScaleFactor: Double {
        return isTestModeEnabled ? 120.0 : 1.0  // 测试模式下时间加快120倍
    }

    // 获取实际时间阈值（考虑测试模式）
    func scaledTimeInterval(_ normalInterval: TimeInterval) -> TimeInterval {
        return normalInterval / timeScaleFactor
    }

    // MARK: - 测试验证方法

    /// 验证时间缩放是否正常工作
    func validateTimeScaling() {
        let modeText = isTestModeEnabled ? "🔥 测试模式" : "📱 正常模式"
        print("[TestMode] 🎭 当前模式: \(modeText)")
        print("[TestMode] ⚡ 时间缩放因子: \(timeScaleFactor)倍")

        if isTestModeEnabled {
            print("[TestMode] 🚀 演示加速: 时间加快 \(timeScaleFactor) 倍，方便快速测试功能！")
        } else {
            print("[TestMode] 📊 正常速度: 使用实际时间阈值")
        }

        // 关键时间阈值验证
        let keyThresholds: [(String, Double)] = [
            ("久未使用警告", 2 * 60 * 60),      // 2小时
            ("久未使用限制", 6 * 60 * 60),      // 6小时
            ("检查间隔", 1 * 60 * 60),          // 1小时
        ]

        print("[TestMode] 📊 关键阈值验证:")
        for (description, normalInterval) in keyThresholds {
            let scaled = scaledTimeInterval(normalInterval)
            let normalHours = Int(normalInterval / 3600)
            let normalMins = Int((normalInterval.truncatingRemainder(dividingBy: 3600)) / 60)
            let scaledMins = Int(scaled / 60)

            if normalHours > 0 {
                print("[TestMode]   \(description): \(normalHours)小时 → \(scaledMins)分钟")
            } else {
                print("[TestMode]   \(description): \(normalMins)分钟 → \(Int(scaled))秒")
            }
        }
    }

    /// 切换测试模式（用于手动测试）
    func toggleTestMode() {
        isTestModeEnabled.toggle()
        print("[TestMode] 🔄 测试模式已\(isTestModeEnabled ? "开启" : "关闭")")

        // 强制刷新Widget以应用新的测试模式设置
        refreshWidgetTimeline()
    }

    /// 强制刷新Widget时间线
    private func refreshWidgetTimeline() {
        #if os(iOS)
        WidgetCenter.shared.reloadAllTimelines()
        print("[TestMode] 🔄 已刷新Widget时间线")
        #endif
    }

    /// 立即强制刷新Widget（多次刷新确保生效）
    private func refreshWidgetImmediately() {
        #if os(iOS)
        // 立即刷新
        WidgetCenter.shared.reloadAllTimelines()
        print("[TestMode] 🔄 立即刷新Widget（第1次）")
        
        // 短暂延迟后再次刷新，确保Widget读取到最新数据
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            WidgetCenter.shared.reloadAllTimelines()
            print("[TestMode] 🔄 延迟刷新Widget（第2次）")
        }
        
        // 再延迟一次，确保Widget完全更新
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            WidgetCenter.shared.reloadAllTimelines()
            print("[TestMode] 🔄 最终刷新Widget（第3次）")
        }
        #endif
    }
}

extension Notification.Name {
    static let testModeDidChange = Notification.Name("testModeDidChange")
}

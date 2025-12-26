//
//  UsageReminderManager.swift
//  iosPet
//
//  使用习惯提醒管理器 - 久未使用提醒和前台连续使用提醒
//

import Foundation
import UIKit
import UserNotifications
#if os(iOS)
import WidgetKit
#endif

final class UsageReminderManager: ObservableObject {
    static let shared = UsageReminderManager()
    private init() {
        setupNotifications()
        loadLastActiveTime()

        // 监听测试模式变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(testModeDidChange),
            name: .testModeDidChange,
            object: nil
        )
    }

    // 配置键名
    private let inactivityWarningHoursKey = "inactivityWarningHours"
    private let inactivityLimitHoursKey = "inactivityLimitHours"
    private let checkIntervalHoursKey = "checkIntervalHours"
    private let continuousWarningHoursKey = "continuousWarningHours"
    
    // 默认配置 - 久未使用提醒（小时）
    private var inactivityWarningHours: Double {
        get {
            let value = UserDefaults.standard.double(forKey: inactivityWarningHoursKey)
            return value > 0 ? value : 2.0  // 默认2小时
        }
        set {
            UserDefaults.standard.set(newValue, forKey: inactivityWarningHoursKey)
        }
    }
    
    private var inactivityLimitHours: Double {
        get {
            let value = UserDefaults.standard.double(forKey: inactivityLimitHoursKey)
            return value > 0 ? value : 6.0  // 默认6小时
        }
        set {
            UserDefaults.standard.set(newValue, forKey: inactivityLimitHoursKey)
        }
    }
    
    private var checkIntervalHours: Double {
        get {
            let value = UserDefaults.standard.double(forKey: checkIntervalHoursKey)
            return value > 0 ? value : 1.0  // 默认1小时
        }
        set {
            UserDefaults.standard.set(newValue, forKey: checkIntervalHoursKey)
        }
    }
    
    // 默认配置 - 手机连续使用提醒（小时）
    private var continuousWarningHours: Double {
        get {
            let value = UserDefaults.standard.double(forKey: continuousWarningHoursKey)
            return value > 0 ? value : 1.5  // 默认1.5小时
        }
        set {
            UserDefaults.standard.set(newValue, forKey: continuousWarningHoursKey)
        }
    }
    
    // 计算属性 - 转换为TimeInterval（秒）
    private var inactivityWarningThreshold: TimeInterval {
        inactivityWarningHours * 60 * 60
    }
    
    private var inactivityLimitThreshold: TimeInterval {
        inactivityLimitHours * 60 * 60
    }
    
    private var checkInterval: TimeInterval {
        checkIntervalHours * 60 * 60
    }
    
    private var continuousWarningThreshold: TimeInterval {
        continuousWarningHours * 60 * 60
    }
    
    // 公共方法：更新配置
    func updateInactivityWarning(hours: Double) {
        inactivityWarningHours = hours
        print("[UsageReminder] ⚙️ 更新久未使用警告阈值: \(hours)小时")
    }
    
    func updateInactivityLimit(hours: Double) {
        inactivityLimitHours = hours
        print("[UsageReminder] ⚙️ 更新久未使用限制阈值: \(hours)小时")
    }
    
    func updateCheckInterval(hours: Double) {
        checkIntervalHours = hours
        print("[UsageReminder] ⚙️ 更新检查间隔: \(hours)小时")
        // 如果正在监测，需要重启以应用新间隔
        if isMonitoring {
            stopMonitoring()
            startMonitoring()
        }
    }
    
    func updateContinuousWarning(hours: Double) {
        continuousWarningHours = hours
        print("[UsageReminder] ⚙️ 更新手机连续使用警告阈值: \(hours)小时")
    }
    
    // 公共方法：获取当前配置
    func getInactivityWarningHours() -> Double { inactivityWarningHours }
    func getInactivityLimitHours() -> Double { inactivityLimitHours }
    func getCheckIntervalHours() -> Double { checkIntervalHours }
    func getContinuousWarningHours() -> Double { continuousWarningHours }


    // 状态
    private var lastActiveTime: Date = Date()
    private var backgroundEntryTime: Date?  // 进入后台的时间
    private var isMonitoring = false
    private var inactivityWarningSent = false
    private var inactivityLimitSent = false
    private var continuousWarningSent = false
    private var checkTimer: Timer?

    private let lastActiveKey = AppGroupKeys.sharedLastActiveKey

    // MARK: - 公共方法

    func startMonitoring() {
        guard !isMonitoring else { return }

        isMonitoring = true
        updateLastActiveTime()  // 记录开始时间
        resetFlags()

        print("[UsageReminder] 🚀 开始使用习惯监测")

        // 使用测试模式支持的方法
        let actualCheckInterval = getCurrentCheckInterval()

        print("[UsageReminder] ⏱️ 检查间隔: \(actualCheckInterval) 秒")

        // 定期检查
        checkTimer = Timer.scheduledTimer(
            timeInterval: actualCheckInterval,
            target: self,
            selector: #selector(performCheck),
            userInfo: nil,
            repeats: true
        )

        // 确保定时器在主线程运行
        RunLoop.main.add(checkTimer!, forMode: .common)

        // 监听应用状态变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    func stopMonitoring() {
        isMonitoring = false
        checkTimer?.invalidate()
        checkTimer = nil
        NotificationCenter.default.removeObserver(self)
        print("[UsageReminder] 🛑 停止使用习惯监测")
    }

    // MARK: - 私有方法

    @objc private func appDidBecomeActive() {
        let currentTime = Date()

        // 先检查久未使用状态（在重置之前，用于日志）
        let inactiveDuration = currentTime.timeIntervalSince(lastActiveTime)
        let hours = Int(inactiveDuration / 3600)
        if hours >= 2 {
            print("[UsageReminder] 💝 用户回来了！之前不活跃了 \(hours) 小时")
        }

        // 处理应用状态变化
        if let backgroundTime = backgroundEntryTime {
            // 从后台恢复
            let backgroundDuration = currentTime.timeIntervalSince(backgroundTime)
            backgroundEntryTime = nil

            print("[UsageReminder] 📱 从后台恢复")
            print("[UsageReminder] ⏱️ 本次后台持续时间: \(formatDuration(backgroundDuration))")
            
            // 无论后台时间长短，用户打开应用就应该重置久未使用时间
            // 因为用户主动打开了应用，说明在使用
            updateLastActiveTime()
            print("[UsageReminder] ✅ 从后台恢复，重置久未使用时间")
        } else {
            // 冷启动或从其他状态激活 - 这是用户主动打开应用
            print("[UsageReminder] 📱 应用冷启动/主动激活")
            
            // 立即重置久未使用状态（用户主动打开应用）
            updateLastActiveTime()
            resetFlags()
        }
        
        // 更新宠物状态为开心（用户主动使用）
        SyncManager.shared.updateAllCarriers(to: .happy)
        
        // 立即强制刷新Widget，确保显示正常状态
        // 使用多次刷新确保Widget立即更新
        #if os(iOS)
        // 立即刷新（在主线程）
        WidgetCenter.shared.reloadAllTimelines()
        print("[UsageReminder] 🔄 立即刷新Widget（第1次）")
        
        // 短暂延迟后再次刷新
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            WidgetCenter.shared.reloadAllTimelines()
            print("[UsageReminder] 🔄 延迟刷新Widget（第2次）")
        }
        
        // 再延迟一次，确保Widget完全更新
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            WidgetCenter.shared.reloadAllTimelines()
            print("[UsageReminder] ✅ 最终刷新Widget（第3次），应该显示正常状态")
        }
        #endif

        // 重置连续使用警告标志（应用打开时重置）
        continuousWarningSent = false
        
        // 更新应用启动时间（用于检测手机使用时长）
        // 如果应用关闭后重新打开，且间隔超过1小时，重置计时
        let appLaunchTimeKey = "appLaunchTime"
        if let lastLaunchTime = UserDefaults.standard.object(forKey: appLaunchTimeKey) as? Date {
            let timeSinceLastLaunch = currentTime.timeIntervalSince(lastLaunchTime)
            // 如果距离上次启动超过1小时，重置计时（可能是新的一天或长时间未使用）
            if timeSinceLastLaunch > 3600 {
                UserDefaults.standard.set(currentTime, forKey: appLaunchTimeKey)
                print("[UsageReminder] 📱 应用重新启动，重置手机使用时长计时")
            }
        } else {
            // 第一次启动，记录启动时间
            UserDefaults.standard.set(currentTime, forKey: appLaunchTimeKey)
            print("[UsageReminder] 📱 首次启动，记录应用启动时间（用于估算手机使用时长）")
        }

        // 检查久未使用（用于 Widget 显示）
        checkInactivityForWidget()
    }

    @objc private func appDidEnterBackground() {
        backgroundEntryTime = Date()
        print("[UsageReminder] 📱 应用进入后台")
    }

    @objc private func performCheck() {
        checkInactivityReminders()
        checkContinuousUsage()
    }

    private func checkInactivityForWidget() {
        // 这个方法现在不需要做什么特别的事情
        // Widget 会通过 getInactiveHours() 方法自动获取久未使用时间并显示相应状态
        let inactiveDuration = Date().timeIntervalSince(lastActiveTime)
        print("[UsageReminder] 📊 Widget 检查久未使用 - 不活跃时间: \(formatDuration(inactiveDuration))")

        // 可以在这里添加一些逻辑来决定是否需要特殊处理
        // 但主要的显示逻辑在 Widget 中实现
    }

    private func checkInactivityReminders() {
        // 这个方法在定时器触发时调用，用于检查是否需要发送久未使用的提醒
        // 注意：iOS 后台执行限制，这个方法可能不会定期执行
        print("[UsageReminder] 🔍 定时检查久未使用状态")

        let inactiveDuration = Date().timeIntervalSince(lastActiveTime)
        let warningThreshold = getCurrentInactivityWarningThreshold()
        let limitThreshold = getCurrentInactivityLimitThreshold()

        print("[UsageReminder] ⏱️ 当前不活跃时间: \(formatDuration(inactiveDuration))")
        print("[UsageReminder] 🎯 警告阈值: \(formatDuration(warningThreshold)), 限制阈值: \(formatDuration(limitThreshold))")

        // 检查是否需要发送久未使用提醒
        if inactiveDuration >= limitThreshold && !inactivityLimitSent {
            print("[UsageReminder] 🚨 触发强烈久未使用提醒")
            sendWelcomeBackMessage(inactiveDuration: inactiveDuration)
            inactivityLimitSent = true
            inactivityWarningSent = true  // 同时标记警告也已发送
        } else if inactiveDuration >= warningThreshold && !inactivityWarningSent {
            print("[UsageReminder] 💝 触发轻微久未使用提醒")
            sendGentleReminder(inactiveDuration: inactiveDuration)
            inactivityWarningSent = true
        }
    }

    private func checkContinuousUsage() {
        // 检测手机总使用时长（而不是应用使用时长）
        // 使用简化的检测方法：基于应用启动时间估算手机使用时长
        // 注意：这是简化实现，理想情况下应该使用ScreenTime API获取准确的手机使用时长
        checkContinuousUsageSimplified()
    }
    
    // 简化的连续使用检测（基于应用启动时间）
    // 注意：这是简化实现，实际应该使用ScreenTime API检测手机总使用时长
    private func checkContinuousUsageSimplified() {
        // 记录应用启动时间（第一次打开应用时）
        let appLaunchTimeKey = "appLaunchTime"
        let currentTime = Date()
        
        if let launchTime = UserDefaults.standard.object(forKey: appLaunchTimeKey) as? Date {
            let elapsed = currentTime.timeIntervalSince(launchTime)
            let warningThreshold = getCurrentContinuousWarningThreshold()
            
            print("[UsageReminder] 📊 手机使用时长检测 - 从启动到现在: \(formatDuration(elapsed))")
            
            if elapsed >= warningThreshold && !continuousWarningSent {
                sendContinuousUsageWarning(currentUsage: elapsed)
                continuousWarningSent = true
            }
        } else {
            // 第一次启动，记录启动时间
            UserDefaults.standard.set(currentTime, forKey: appLaunchTimeKey)
            print("[UsageReminder] 📱 记录应用启动时间（用于估算手机使用时长）: \(currentTime)")
        }
    }

    private func sendWelcomeBackMessage(inactiveDuration: TimeInterval) {
        // 不再发送推送通知，而是更新 Widget 显示状态
        // Widget 会根据 inactiveHours 自动显示相应的状态
        print("[UsageReminder] 🎉 检测到久未使用，Widget 将显示欢迎状态")

        // 更新宠物状态为开心（欢迎回来）
        SyncManager.shared.updateAllCarriers(to: .happy)
    }

    private func sendGentleReminder(inactiveDuration: TimeInterval) {
        // 不再发送推送通知，Widget 会显示久未使用状态
        print("[UsageReminder] 💝 检测到一段时间未使用，Widget 将显示想念状态")

        // 根据久未使用时长更新不同的宠物状态
        let hours = Int(inactiveDuration / 3600)
        switch hours {
        case 2..<6:
            // 轻微想念 - 设置为happy状态表示宠物在想念主人
            SyncManager.shared.updateAllCarriers(to: .happy)
        case 6..<24:
            // 比较想念 - 设置为bored状态表示无聊/想念
            SyncManager.shared.updateAllCarriers(to: .bored)
        default:
            // 非常想念 - 设置为sleepy状态表示疲惫/想念
            SyncManager.shared.updateAllCarriers(to: .sleepy)
        }
    }

    private func sendContinuousUsageWarning(currentUsage: TimeInterval) {
        // 更新宠物状态为过度使用警告（检测到手机连续使用时间过长）
        SyncManager.shared.updateAllCarriers(to: .overuseWarning)
        print("[UsageReminder] ⚠️ 手机连续使用警告：检测到使用时长 \(formatDuration(currentUsage))，更新宠物状态")
    }

    private func updateLastActiveTime() {
        lastActiveTime = Date()
        if let defaults = UserDefaults(suiteName: AppGroupKeys.suiteName) {
            defaults.set(lastActiveTime, forKey: lastActiveKey)
            defaults.synchronize()
            print("[UsageReminder] 💾 保存活跃时间到 App Group: \(lastActiveTime)")
        }
    }

    private func loadLastActiveTime() {
        if let defaults = UserDefaults(suiteName: AppGroupKeys.suiteName),
           let savedTime = defaults.object(forKey: lastActiveKey) as? Date {
            lastActiveTime = savedTime
            print("[UsageReminder] 📖 从 App Group 加载上次活跃时间: \(lastActiveTime)")
        } else {
            lastActiveTime = Date()
            updateLastActiveTime()
        }
    }

    private func resetFlags() {
        inactivityWarningSent = false
        inactivityLimitSent = false
        continuousWarningSent = false
    }

    private func setupNotifications() {
        Task {
            await NotificationManager.shared.requestPermission()
        }
    }

    // MARK: - 测试模式支持

    @objc private func testModeDidChange() {
        print("[UsageReminder] 🎭 测试模式状态改变")

        // 如果正在监测，先停止
        if isMonitoring {
            stopMonitoring()
        }

        // 重新启动以应用新的时间阈值
        startMonitoring()
    }

    // 获取当前生效的时间阈值（考虑测试模式）
    private func getCurrentInactivityWarningThreshold() -> TimeInterval {
        if TestModeManager.shared.isTestModeEnabled {
            return TestModeManager.shared.scaledTimeInterval(inactivityWarningThreshold)
        }
        return inactivityWarningThreshold
    }

    private func getCurrentInactivityLimitThreshold() -> TimeInterval {
        if TestModeManager.shared.isTestModeEnabled {
            return TestModeManager.shared.scaledTimeInterval(inactivityLimitThreshold)
        }
        return inactivityLimitThreshold
    }

    private func getCurrentCheckInterval() -> TimeInterval {
        if TestModeManager.shared.isTestModeEnabled {
            return TestModeManager.shared.scaledTimeInterval(checkInterval)
        }
        return checkInterval
    }

    private func getCurrentContinuousWarningThreshold() -> TimeInterval {
        if TestModeManager.shared.isTestModeEnabled {
            return TestModeManager.shared.scaledTimeInterval(continuousWarningThreshold)
        }
        return continuousWarningThreshold
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)

        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }


    // MARK: - 测试方法

    func manualCheck() {
        print("[UsageReminder] 🔧 手动触发检查")
        performCheck()
    }

    func simulateInactivity(hours: Double) {
        print("[UsageReminder] 🎭 模拟久未使用: \(hours)小时")
        // 临时修改最后活跃时间用于测试
        let simulatedTime = Date().addingTimeInterval(-hours * 3600)
        let originalTime = lastActiveTime

        lastActiveTime = simulatedTime
        manualCheck()

        // 延迟恢复真实时间，给用户时间看到Widget变化
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.lastActiveTime = originalTime
            print("[UsageReminder] 🎭 模拟结束，恢复真实时间")
            // 刷新Widget显示真实状态
            #if os(iOS)
            WidgetCenter.shared.reloadAllTimelines()
            #endif
        }
    }

    /// 重置久未使用状态（手动恢复）
    func resetInactivityState() {
        print("[UsageReminder] 🔄 手动重置久未使用状态")
        updateLastActiveTime()
        resetFlags()
        // 更新宠物状态为开心
        SyncManager.shared.updateAllCarriers(to: .happy)
        // 刷新Widget
        #if os(iOS)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    func simulateContinuousUsage(minutes: Double) {
        print("[UsageReminder] 🎭 模拟手机连续使用: \(minutes)分钟")
        // 模拟手机使用时长：设置应用启动时间为指定时间前
        let appLaunchTimeKey = "appLaunchTime"
        let simulatedLaunchTime = Date().addingTimeInterval(-minutes * 60)
        UserDefaults.standard.set(simulatedLaunchTime, forKey: appLaunchTimeKey)
        print("[UsageReminder] 🎭 设置模拟启动时间: \(simulatedLaunchTime)")
        
        // 触发检查
        manualCheck()
        
        // 延迟恢复真实时间
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            UserDefaults.standard.removeObject(forKey: appLaunchTimeKey)
            print("[UsageReminder] 🎭 模拟结束，恢复真实时间")
        }
    }

    /// 验证测试模式下的时间阈值
    func validateTestModeThresholds() {
        print("[UsageReminder] 🎭 测试模式阈值验证:")

        let warningThreshold = getCurrentInactivityWarningThreshold()
        let limitThreshold = getCurrentInactivityLimitThreshold()
        let checkInterval = getCurrentCheckInterval()
        let continuousWarning = getCurrentContinuousWarningThreshold()

        print("[UsageReminder]   久未使用警告阈值: \(formatDuration(warningThreshold))")
        print("[UsageReminder]   久未使用限制阈值: \(formatDuration(limitThreshold))")
        print("[UsageReminder]   检查间隔: \(formatDuration(checkInterval))")
        print("[UsageReminder]   手机连续使用警告阈值: \(formatDuration(continuousWarning))")

        print("[UsageReminder] 📊 当前测试模式: \(TestModeManager.shared.isTestModeEnabled ? "开启" : "关闭")")
        print("[UsageReminder] ⚡ 时间缩放因子: \(TestModeManager.shared.timeScaleFactor)倍")
    }
}

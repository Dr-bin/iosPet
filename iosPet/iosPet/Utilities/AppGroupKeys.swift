//
//  AppGroupKeys.swift
//  iosPet
//

import Foundation

enum AppGroupKeys {
    static let suiteName = "group.com.example.iosPet"
    /// 共享的原始状态（可选保留）
    static let sharedStateKey = "pet.shared.state"
    /// 共享情绪（Widget / 图标 使用）
    static let sharedEmotionKey = "pet.shared.emotion"
    /// 共享 Todo 列表（Widget 使用）
    static let sharedTodosKey = "pet.shared.todos"
    /// 共享最后活跃时间（Widget 显示久未使用状态）
    static let sharedLastActiveKey = "pet.shared.lastActiveTime"
    /// 共享状态消息（Widget 显示当前状态的消息）
    static let sharedStateMessageKey = "pet.shared.stateMessage"
    /// 共享图标（Widget 显示当前状态的图标）
    static let sharedIconKey = "pet.shared.icon"
    /// 共享测试模式状态（Widget 使用）
    static let sharedTestModeKey = "pet.shared.testMode"
}


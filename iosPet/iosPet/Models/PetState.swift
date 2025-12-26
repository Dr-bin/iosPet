//
//  PetState.swift
//  iosPet
//
//  基础状态定义与载体枚举
//

import Foundation

enum PetStateCategory: String, Codable, CaseIterable {
    case fatigue      // 疲惫/头晕/困倦
    case sport        // 运动/出汗/活力
    case focus        // 学习/专注/无聊
    case healthy      // 开心/正常/鼓励
    case alert        // 过度使用提醒/警告
}

enum PetState: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }

    // 疲惫
    case dizzy, sleepy, tiredEyes
    // 运动
    case running, jumping, workout
    // 学习/专注
    case reading, thinking, bored
    // 健康/鼓励
    case happy, cheering, celebrating
    // 警告
    case overuseWarning, restNeeded

    var category: PetStateCategory {
        switch self {
        case .dizzy, .sleepy, .tiredEyes:
            return .fatigue
        case .running, .jumping, .workout:
            return .sport
        case .reading, .thinking, .bored:
            return .focus
        case .happy, .cheering, .celebrating:
            return .healthy
        case .overuseWarning, .restNeeded:
            return .alert
        }
    }
}


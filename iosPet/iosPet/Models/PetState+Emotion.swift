//
//  PetState+Emotion.swift
//  iosPet
//
//  将应用内部的 PetState 映射到跨载体统一的 PetEmotion
//

import Foundation

extension PetState {
    /// 将细粒度的 PetState 映射为 Widget / 词库 等使用的情绪枚举
    var emotion: PetEmotion {
        switch self {
        case .dizzy, .tiredEyes:
            return .dizzy
        case .overuseWarning:
            return .longUsage  // 长时间使用警告应该映射到 longUsage
        case .sleepy, .restNeeded:
            return .sleepy
        case .running, .jumping, .workout:
            return .workout
        case .reading, .thinking:
            return .awayFocus
        case .bored:
            return .bored
        case .happy, .cheering, .celebrating:
            return .happy
        }
    }
}



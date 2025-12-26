//
//  HealthKitService.swift
//  iosPet
//
//  占位：未来接入 HealthKit
//

import Foundation

final class HealthKitService {
    func estimateState() async -> UserStatusSnapshot? {
        // TODO: 调用 HealthKit 获取运动数据
        return UserStatusSnapshot(
            id: UUID(),
            detectedState: .running,
            confidence: 0.6,
            source: .healthKit,
            timestamp: .init(),
            context: ["reason": "simulated"]
        )
    }
}


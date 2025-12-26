//
//  ScreenTimeService.swift
//  iosPet
//
//  占位：未来接入 Screen Time API
//

import Foundation

final class ScreenTimeService {
    func estimateState() async -> UserStatusSnapshot? {
        // TODO: 使用 Screen Time API 获取实际数据
        return UserStatusSnapshot(
            id: UUID(),
            detectedState: .overuseWarning,
            confidence: 0.7,
            source: .screenTime,
            timestamp: .init(),
            context: ["reason": "simulated"]
        )
    }
}


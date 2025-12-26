//
//  StateDetector.swift
//  iosPet
//
//  汇总多来源状态检测
//

import Foundation

final class StateDetector {
    static let shared = StateDetector()
    private init() {}

    private let screenTimeService = ScreenTimeService()
    private let healthKitService = HealthKitService()

    func detect(completion: @escaping (UserStatusSnapshot) -> Void) {
        // 简化：并行收集后合并
        Task {
            async let screenState = screenTimeService.estimateState()
            async let healthState = healthKitService.estimateState()
            let states = await [screenState, healthState].compactMap { $0 }
            let result = fuse(states: states) ?? fallbackSnapshot()
            completion(result)
        }
    }

    private func fuse(states: [UserStatusSnapshot]) -> UserStatusSnapshot? {
        guard let top = states.max(by: { $0.confidence < $1.confidence }) else { return nil }
        return top
    }

    private func fallbackSnapshot() -> UserStatusSnapshot {
        UserStatusSnapshot(
            id: UUID(),
            detectedState: .happy,
            confidence: 0.2,
            source: .manualOverride,
            timestamp: .init(),
            context: [:]
        )
    }
}


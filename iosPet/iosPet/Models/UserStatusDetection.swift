//
//  UserStatusDetection.swift
//  iosPet
//
//  用户状态检测记录
//

import Foundation

struct UserStatusSnapshot: Codable, Identifiable {
    let id: UUID
    let detectedState: PetState
    let confidence: Double
    let source: DetectionSource
    let timestamp: Date
    let context: [String: String]
}

enum DetectionSource: String, Codable {
    case screenTime
    case healthKit
    case idleInference
    case habitModel
    case manualOverride
}


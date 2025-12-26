//
//  PetConfiguration.swift
//  iosPet
//
//  用户可配置项
//

import Foundation

struct PetAppearance: Codable, Hashable {
    var colorHex: String
    var accessory: String
    var baseForm: String
}

struct BehaviorThresholds: Codable, Hashable {
    var screenTimeLimitMinutes: Int
    var restReminderMinutes: Int
    var focusDetectionIdleMinutes: Int
}

struct NotificationPreference: Codable, Hashable {
    var enableNotifications: Bool
    var dailyGreetingTimes: [String]   // "08:30"
    var quietHours: ClosedRange<Int>?  // 0-23
}

struct PetConfiguration: Codable, Identifiable {
    let id: UUID
    var name: String
    var appearance: PetAppearance
    var thresholds: BehaviorThresholds
    var notificationPreference: NotificationPreference
    var sensitivity: Double
    var lastUpdated: Date
}


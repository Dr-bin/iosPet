//
//  ConfigurationManager.swift
//  iosPet
//

import Foundation

final class ConfigurationManager: ObservableObject {
    static let shared = ConfigurationManager()
    private init() {}

    @Published private(set) var current: PetConfiguration = ConfigurationManager.defaultConfiguration()

    func update(_ config: PetConfiguration) {
        current = config
        NotificationCenter.default.post(name: .petConfigurationDidChange, object: config)
    }

    func applyTemplate(_ template: PetConfiguration) {
        update(template)
    }

    private static func defaultConfiguration() -> PetConfiguration {
        PetConfiguration(
            id: UUID(),
            name: "默认配置",
            appearance: PetAppearance(colorHex: "#FFD166", accessory: "🎀", baseForm: "猫猫"),
            thresholds: BehaviorThresholds(screenTimeLimitMinutes: 90, restReminderMinutes: 30, focusDetectionIdleMinutes: 20),
            notificationPreference: NotificationPreference(enableNotifications: true, dailyGreetingTimes: ["08:00", "22:00"], quietHours: nil),
            sensitivity: 0.6,
            lastUpdated: .init()
        )
    }
}

extension Notification.Name {
    static let petConfigurationDidChange = Notification.Name("petConfigurationDidChange")
}


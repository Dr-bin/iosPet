//
//  NotificationManager.swift
//  iosPet
//

import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            print("[NotificationManager] 通知权限请求结果: \(granted ? "已授权" : "已拒绝")")
            return granted
        } catch {
            print("[NotificationManager] 通知权限请求失败: \(error.localizedDescription)")
            return false
        }
    }

    func checkPermissionStatus() async -> UNAuthorizationStatus {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus)
            }
        }
    }

    func schedule(message: String, category: MessageCategory, in seconds: TimeInterval) {
        Task {
            let status = await checkPermissionStatus()

            guard status == .authorized else {
                print("[NotificationManager] 通知权限未授权，无法发送通知")
                print("[NotificationManager] 请在设置 > 通知 > iosPet 中开启通知权限")
                return
            }

            let content = UNMutableNotificationContent()
            content.title = title(for: category)
            content.body = message
            content.sound = .default

            // UNTimeIntervalNotificationTrigger 需要 timeInterval > 0
            let trigger: UNNotificationTrigger
            if seconds <= 0 {
                // 立即发送，使用最小延迟 0.1 秒
                trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
            } else {
                trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
            }

            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

            do {
                try await UNUserNotificationCenter.current().add(request)
                print("[NotificationManager] 通知已安排: \(message)")
            } catch {
                print("[NotificationManager] 发送通知失败: \(error.localizedDescription)")
            }
        }
    }

    private func title(for category: MessageCategory) -> String {
        switch category {
        case .healthReminder: return "健康提醒"
        case .sportEncourage: return "运动加油"
        case .studyPraise: return "学习认可"
        case .achievement: return "成就解锁"
        case .dailyCare: return "日常关怀"
        }
    }
}


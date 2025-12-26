import Foundation

enum PetEmotion: String, CaseIterable, Identifiable, Codable {
    case idle
    case longUsage        // 长时间刷手机
    case awayFocus        // 离机专注/学习
    case workout          // 运动
    case sleepy           // 疲惫/想睡
    case dizzy            // 头晕
    case bored            // 无聊
    case happy            // 愉悦

    var id: String { rawValue }
}


//
//  PetWidget.swift
//  PetWidget
//
//  Created by admin on 2025/12/23.
//

import WidgetKit
import SwiftUI
import Foundation
import OSLog

// MARK: - 共享类型定义（Widget 独立使用）

enum PetEmotion: String, CaseIterable {
    case idle
    case longUsage        // 长时间刷手机
    case awayFocus        // 离机专注/学习
    case workout          // 运动
    case sleepy           // 疲惫/想睡
    case dizzy            // 头晕
    case bored            // 无聊
    case happy            // 愉悦
}

enum AppGroupKeys {
    static let suiteName = "group.com.example.iosPet"
    static let sharedEmotionKey = "pet.shared.emotion"
    static let sharedTodosKey = "pet.shared.todos"
    static let sharedLastActiveKey = "pet.shared.lastActiveTime"
    static let sharedTestModeKey = "isTestModeEnabled"
    static let sharedStateMessageKey = "pet.shared.stateMessage"
    static let sharedIconKey = "pet.shared.icon"
}

// MARK: - Widget 数据模型

struct TodoItem: Codable, Identifiable {
    let id: UUID
    var text: String
    var isCompleted: Bool
    var createdAt: Date

    init(id: UUID = UUID(), text: String, isCompleted: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.text = text
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }
}

struct PetEntry: TimelineEntry {
    let date: Date
    let emotion: PetEmotion
    let emoji: String
    let phrase: String
    let todos: [TodoItem]  // 添加 Todo 列表
    let inactiveHours: Int  // 久未使用的时长（小时）
    let inactiveSeconds: Int  // 久未使用的时长（秒，用于测试模式显示）
}

// MARK: - Widget Provider

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> PetEntry {
        .init(
            date: Date(),
            emotion: .idle,
            emoji: "🧪",
            phrase: "测试默认值 - 这是 placeholder",
            todos: [
                TodoItem(id: UUID(), text: "示例 Todo 1", isCompleted: false, createdAt: Date()),
                TodoItem(id: UUID(), text: "示例 Todo 2", isCompleted: true, createdAt: Date())
            ],
            inactiveHours: 0,
            inactiveSeconds: 0
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (PetEntry) -> ()) {
        let entry = getCurrentEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PetEntry>) -> ()) {
        let entry = getCurrentEntry()
        let now = Date()

        // 检查是否在测试模式
        let testModeEnabled = (UserDefaults(suiteName: AppGroupKeys.suiteName)?.bool(forKey: AppGroupKeys.sharedTestModeKey)) ?? false
        
        // 如果显示久未使用状态，更频繁地刷新以便及时响应应用打开
        // 如果显示正常状态，可以稍微慢一点刷新
        // 测试模式下需要实时显示秒数和时钟，所以刷新更频繁
        let refreshInterval: TimeInterval
        if testModeEnabled {
            // 测试模式下，每1秒刷新一次以便实时显示秒数和时钟
            // 虽然系统可能不会严格执行，但Text(Date(), style: .time)会触发更频繁的更新
            refreshInterval = 1
        } else if entry.inactiveHours >= 2 {
            // 显示久未使用状态时，每30秒刷新
            refreshInterval = 30
        } else {
            // 显示正常状态时，每60秒刷新
            refreshInterval = 60
        }
        
        // 在测试模式下，创建多个时间点的entries以便实时更新
        var entries: [PetEntry] = []
        if testModeEnabled {
            // 测试模式下，创建未来60秒内的多个entries，每秒一个
            for i in 0..<60 {
                if let futureDate = Calendar.current.date(byAdding: .second, value: i, to: now) {
                    // 计算未来时间点的不活跃秒数
                    let futureInactiveSeconds = entry.inactiveSeconds + i
                    let futureInactiveHours = Int((Double(futureInactiveSeconds) * (testModeEnabled ? 120.0 : 1.0)) / 3600)
                    
                    entries.append(PetEntry(
                        date: futureDate,
                        emotion: entry.emotion,
                        emoji: entry.emoji,
                        phrase: entry.phrase,
                        todos: entry.todos,
                        inactiveHours: futureInactiveHours,
                        inactiveSeconds: futureInactiveSeconds
                    ))
                }
            }
        } else {
            // 正常模式下，只创建一个entry
            entries = [
                PetEntry(date: now, emotion: entry.emotion, emoji: entry.emoji, phrase: entry.phrase, todos: entry.todos, inactiveHours: entry.inactiveHours, inactiveSeconds: entry.inactiveSeconds)
            ]
        }

        let nextRefresh = Calendar.current.date(byAdding: .second, value: Int(refreshInterval), to: now)!
        
        // 使用 .after 策略，确保Widget会定期刷新
        let timeline = Timeline(entries: entries, policy: .after(nextRefresh))

        let statusText = entry.inactiveHours >= 2 ? "久未使用" : "正常状态"
        print("[Widget] 📅 Timeline刷新 - 状态: \(statusText), 下次刷新: \(nextRefresh), 测试模式: \(testModeEnabled), 不活跃小时: \(entry.inactiveHours)")

        completion(timeline)
    }
    
    private func getCurrentEntry() -> PetEntry {
        // 强制同步UserDefaults，确保读取最新数据
        if let defaults = UserDefaults(suiteName: AppGroupKeys.suiteName) {
            defaults.synchronize()
        }
        
        // 从 App Group 读取情绪
        let emotion: PetEmotion = {
            guard let defaults = UserDefaults(suiteName: AppGroupKeys.suiteName),
                  let raw = defaults.string(forKey: AppGroupKeys.sharedEmotionKey),
                  let emo = PetEmotion(rawValue: raw) else {
                return .idle
            }
            return emo
        }()

        // 从 App Group 读取图标和消息，如果没有则使用默认
        let (emoji, phrase): (String, String) = {
            if let defaults = UserDefaults(suiteName: AppGroupKeys.suiteName) {
                // 优先使用保存的图标
                let savedIcon = defaults.string(forKey: AppGroupKeys.sharedIconKey)
                let savedMessage = defaults.string(forKey: AppGroupKeys.sharedStateMessageKey)
                
                if let icon = savedIcon, !icon.isEmpty,
                   let message = savedMessage, !message.isEmpty {
                    // 使用保存的图标和消息
                    return (icon, message)
                } else if let message = savedMessage, !message.isEmpty {
                    // 只有消息，使用默认图标
                    let defaultEmoji = getEmojiAndPhrase(for: emotion).0
                    return (defaultEmoji, message)
                }
            }
            // 使用默认消息
            return getEmojiAndPhrase(for: emotion)
        }()

        // 读取 Todo 列表
        let todos = loadTodos()

        // 计算久未使用时间
        let inactiveHours = getInactiveHours()
        let inactiveSeconds = getInactiveSeconds()

        return PetEntry(date: Date(), emotion: emotion, emoji: emoji, phrase: phrase, todos: todos, inactiveHours: inactiveHours, inactiveSeconds: inactiveSeconds)
    }

    }
    
    // MARK: - 读取 Todo 列表
    private func loadTodos() -> [TodoItem] {
        guard let defaults = UserDefaults(suiteName: AppGroupKeys.suiteName),
              let data = defaults.data(forKey: AppGroupKeys.sharedTodosKey),
              let todos = try? JSONDecoder().decode([TodoItem].self, from: data) else {
            return []
        }
        return todos
    }

    // MARK: - 计算久未使用时间
    private func getInactiveHours() -> Int {
        guard let defaults = UserDefaults(suiteName: AppGroupKeys.suiteName),
              let lastActiveTime = defaults.object(forKey: AppGroupKeys.sharedLastActiveKey) as? Date else {
            print("[Widget] ⚠️ 无法读取lastActiveTime，返回0小时")
            return 0
        }

        let currentTime = Date()
        let inactiveDuration = currentTime.timeIntervalSince(lastActiveTime)

        // 如果时间太短（小于1分钟），认为是刚打开应用，返回0
        if inactiveDuration < 60 {
            print("[Widget] ✅ 应用刚打开，显示正常状态")
            return 0
        }

        // 在测试模式下，缩放不活跃时间以便快速看到效果
        // 测试模式：120倍加速，所以1分钟 = 2小时
        let testModeEnabled = defaults.bool(forKey: AppGroupKeys.sharedTestModeKey)
        let effectiveDuration = testModeEnabled ? inactiveDuration * 120.0 : inactiveDuration

        let hours = Int(effectiveDuration / 3600)
        
        print("[Widget] ⏱️ 久未使用计算 - 当前时间: \(currentTime), 最后活跃: \(lastActiveTime)")
        print("[Widget] ⏱️ 实际不活跃: \(Int(inactiveDuration))秒, 测试模式: \(testModeEnabled), 有效不活跃: \(Int(effectiveDuration))秒, 小时数: \(hours)")

        return hours
    }

    // MARK: - 计算久未使用时间（精确到秒，用于测试模式显示）
    private func getInactiveSeconds() -> Int {
        guard let defaults = UserDefaults(suiteName: AppGroupKeys.suiteName) else {
            return 0
        }
        
        // 强制同步，确保读取最新数据
        defaults.synchronize()
        
        guard let lastActiveTime = defaults.object(forKey: AppGroupKeys.sharedLastActiveKey) as? Date else {
            print("[Widget] ⚠️ 无法读取lastActiveTime，返回0秒")
            return 0
        }

        let currentTime = Date()
        let inactiveDuration = currentTime.timeIntervalSince(lastActiveTime)
        let seconds = Int(inactiveDuration)
        
        print("[Widget] ⏱️ 计算不活跃秒数 - 当前: \(currentTime), 最后活跃: \(lastActiveTime), 秒数: \(seconds)")
        
        return seconds
    }

    // MARK: - 久未使用显示
    private func getInactiveEmoji(for hours: Int) -> String {
        switch hours {
        case 2..<6:
            return "💭"  // 轻微想念
        case 6..<24:
            return "😢"  // 比较想念
        case 24..<72:
            return "😭"  // 很想念
        default:
            return "💔"  // 非常想念
        }
    }

    private func getInactiveMessage(for hours: Int) -> String {
        switch hours {
        case 2..<6:
            return "有段时间没见到你了..."
        case 6..<24:
            return "我开始想你了，快来看看我吧！"
        case 24..<72:
            return "\(hours / 24)天没见了，好想你！"
        default:
            return "太久没见了，我很想你..."
        }
    }
    
    private func getEmojiAndPhrase(for emotion: PetEmotion) -> (String, String) {
        switch emotion {
        case .idle:
            return ("🧪", "测试默认值 - 这是 idle 状态")
        case .happy:
            return ("😺", "今天也要开心呀~")
        case .dizzy:
            return ("😵‍💫", "看手机有点久了…要不要休息一下？")
        case .sleepy:
            return ("😴", "有点困了，要不要先休息一下？")
        case .workout:
            return ("🏃‍♂️", "一起去运动一下，缓解久坐吧！")
        case .awayFocus:
            return ("📖", "我帮你看着手机，你专心学习")
        case .bored:
            return ("🥱", "有点无聊，要不做点有意义的事？")
        case .longUsage:
            return ("⚠️", "使用时间有点长了，休息一下吧")
        }
    }

// MARK: - Widget View

struct PetWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    // 检查是否在测试模式
    private var isTestMode: Bool {
        UserDefaults(suiteName: AppGroupKeys.suiteName)?.bool(forKey: AppGroupKeys.sharedTestModeKey) ?? false
    }
    
    // 根据Widget尺寸调整显示数量
    private var maxTodoCount: Int {
        switch family {
        case .systemSmall:
            return entry.todos.isEmpty ? 0 : 2
        case .systemMedium:
            return 3
        default:
            return 2
        }
    }
    
    // 格式化时间显示（精确到秒）
    private func formatTime(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
    
    // 获取久未使用emoji
    private func getInactiveEmoji(for hours: Int) -> String {
        switch hours {
        case 2..<6:
            return "💭"  // 轻微想念
        case 6..<24:
            return "😢"  // 比较想念
        case 24..<72:
            return "😭"  // 很想念
        default:
            return "💔"  // 非常想念
        }
    }
    
    // 获取久未使用消息
    private func getInactiveMessage(for hours: Int) -> String {
        switch hours {
        case 2..<6:
            return "有段时间没见到你了..."
        case 6..<24:
            return "我开始想你了，快来看看我吧！"
        case 24..<72:
            return "\(hours / 24)天没见了，好想你！"
        default:
            return "太久没见了，我很想你..."
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            // 测试模式下显示实时时间和时钟（紧凑布局）
            if isTestMode {
                HStack(spacing: family == .systemSmall ? 4 : 6) {
                    // 显示当前时间（实时时钟）
                    HStack(spacing: 2) {
                        Text("🕐")
                            .font(.system(size: 7))
                        Text(entry.date, style: .time)
                            .font(.system(size: family == .systemSmall ? 8 : 9, design: .monospaced))
                            .foregroundColor(.blue)
                            .contentTransition(.numericText())
                    }
                    
                    // 显示不活跃时间
                    HStack(spacing: 2) {
                        Text("⏱️")
                            .font(.system(size: 7))
                        Text("\(formatTime(seconds: entry.inactiveSeconds))")
                            .font(.system(size: family == .systemSmall ? 8 : 9, design: .monospaced))
                            .foregroundColor(.orange)
                            .contentTransition(.numericText())
                    }
                }
                .font(.caption2)
                .padding(.horizontal, 3)
                .padding(.vertical, 1)
                .background(Color.blue.opacity(0.05))
                .cornerRadius(3)
            }
            
            // Medium Widget: 左右布局（左边状态，右边TodoList）
            if family == .systemMedium {
                HStack(spacing: 8) {
                    // 左边：状态显示
                    VStack(spacing: 3) {
                        if entry.inactiveHours >= 2 {
                            // 久未使用状态
                            Text(getInactiveEmoji(for: entry.inactiveHours))
                                .font(.system(size: 32))
                            Text(getInactiveMessage(for: entry.inactiveHours))
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .minimumScaleFactor(0.7)
                                .foregroundColor(.primary)
                        } else {
                            // 正常状态
                            Text(entry.emoji)
                                .font(.system(size: 28))
                            Text(entry.phrase)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .minimumScaleFactor(0.7)
                                .foregroundColor(.primary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // 右边：TodoList（如果有）
                    if !entry.todos.isEmpty && maxTodoCount > 0 {
                        Divider()
                            .frame(height: .infinity)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("📝 Todo")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            ForEach(entry.todos.prefix(maxTodoCount)) { todo in
                                HStack(spacing: 3) {
                                    Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(todo.isCompleted ? .green : .gray)
                                        .font(.system(size: 8))
                                        .frame(width: 10)
                                    
                                    Text(todo.text)
                                        .font(.caption2)
                                        .strikethrough(todo.isCompleted)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                        .foregroundColor(todo.isCompleted ? .secondary : .primary)
                                }
                            }
                            
                            if entry.todos.count > maxTodoCount {
                                Text("还有 \(entry.todos.count - maxTodoCount) 个...")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            } else {
                // Small Widget: 垂直布局
                if entry.inactiveHours >= 2 {
                    // 久未使用状态
                    Spacer()
                    VStack(spacing: 2) {
                        Text(getInactiveEmoji(for: entry.inactiveHours))
                            .font(.system(size: 28))
                        Text(getInactiveMessage(for: entry.inactiveHours))
                            .font(.caption2)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                            .foregroundColor(.primary)
                    }
                    Spacer()
                } else {
                    // 正常状态：显示宠物情绪 + Todo
                    VStack(spacing: 3) {
                        // 宠物情绪显示
                        Text(entry.emoji)
                            .font(.system(size: 24))
                        
                        Text(entry.phrase)
                            .font(.caption2)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                            .foregroundColor(.primary)
                    }
                    .frame(maxHeight: .infinity, alignment: .top)

                    // 如果有 Todo，显示 Todo 列表
                    if !entry.todos.isEmpty && maxTodoCount > 0 {
                        Divider()
                            .padding(.vertical, 1)

                        VStack(alignment: .leading, spacing: 1) {
                            ForEach(entry.todos.prefix(maxTodoCount)) { todo in
                                HStack(spacing: 3) {
                                    Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(todo.isCompleted ? .green : .gray)
                                        .font(.system(size: 8))
                                        .frame(width: 10)

                                    Text(todo.text)
                                        .font(.caption2)
                                        .strikethrough(todo.isCompleted)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                        .foregroundColor(todo.isCompleted ? .secondary : .primary)
                                }
                            }

                            if entry.todos.count > maxTodoCount {
                                Text("还有 \(entry.todos.count - maxTodoCount) 个...")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .padding(family == .systemSmall ? 6 : 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Widget Configuration

struct PetWidget: Widget {
    let kind: String = "PetWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            PetWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("桌宠")
        .description("显示与主应用一致的桌宠情绪。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    PetWidget()
} timeline: {
    PetEntry(
        date: Date(),
        emotion: .happy,
        emoji: "😺",
        phrase: "今天也要开心呀~",
        todos: [
            TodoItem(text: "买菜", isCompleted: false),
            TodoItem(text: "洗衣服", isCompleted: true)
        ],
        inactiveHours: 0,
        inactiveSeconds: 0
    )
    PetEntry(
        date: Date(),
        emotion: .dizzy,
        emoji: "😵‍💫",
        phrase: "看手机有点久了…要不要休息一下？",
        todos: [],
        inactiveHours: 0,
        inactiveSeconds: 0
    )
    PetEntry(
        date: Date(),
        emotion: .workout,
        emoji: "🏃‍♂️",
        phrase: "一起去运动一下，缓解久坐吧！",
        todos: [
            TodoItem(text: "去跑步", isCompleted: false)
        ],
        inactiveHours: 0,
        inactiveSeconds: 0
    )
}

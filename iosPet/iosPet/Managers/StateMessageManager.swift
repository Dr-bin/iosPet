//
//  StateMessageManager.swift
//  iosPet
//
//  状态消息管理器 - 管理每个状态对应的多条消息
//

import Foundation

// MARK: - 状态消息模型
struct StateMessage: Identifiable, Codable {
    let id: UUID
    let state: PetState
    let content: String
    let createdAt: Date  // 创建时间
    let lastUsed: Date?   // 最后使用时间（用于智能选择：优先选择使用次数少的和最近未使用的）
    let usedCount: Int    // 使用次数
    let source: MessageSource
    
    init(
        id: UUID = UUID(),
        state: PetState,
        content: String,
        createdAt: Date = Date(),
        lastUsed: Date? = nil,
        usedCount: Int = 0,
        source: MessageSource = .builtin
    ) {
        self.id = id
        self.state = state
        self.content = content
        self.createdAt = createdAt
        self.lastUsed = lastUsed
        self.usedCount = usedCount
        self.source = source
    }
}

// MARK: - 状态消息管理器
final class StateMessageManager: ObservableObject {
    static let shared = StateMessageManager()
    
    @Published private(set) var messages: [StateMessage] = []
    
    private let messagesKey = "stateMessages"
    private let maxMessagesPerStateKey = "maxMessagesPerState"
    
    // 每个状态的最大消息数（超过后会随机删除旧消息）
    // 可以从UserDefaults读取，默认20条
    var maxMessagesPerState: Int {
        get {
            let value = UserDefaults.standard.integer(forKey: maxMessagesPerStateKey)
            return value > 0 ? value : 20  // 默认20条
        }
        set {
            UserDefaults.standard.set(newValue, forKey: maxMessagesPerStateKey)
            print("[StateMessageManager] ⚙️ 更新最大消息数: \(newValue)条/状态")
        }
    }
    
    private init() {
        loadMessages()
        // 如果没有消息，加载默认消息
        if messages.isEmpty {
            loadDefaultMessages()
        }
    }
    
    // MARK: - 获取状态消息
    /// 获取指定状态的随机消息（优先选择使用次数少的）
    func getMessage(for state: PetState) -> String {
        let stateMessages = messages.filter { $0.state == state }
        
        guard !stateMessages.isEmpty else {
            return getDefaultMessage(for: state)
        }
        
        // 优先选择使用次数少的消息
        let sortedMessages = stateMessages.sorted { msg1, msg2 in
            let count1 = msg1.usedCount
            let count2 = msg2.usedCount
            
            if count1 != count2 {
                return count1 < count2
            }
            
            // 如果使用次数相同，优先选择最近未使用的
            let date1 = msg1.lastUsed ?? .distantPast
            let date2 = msg2.lastUsed ?? .distantPast
            return date1 < date2
        }
        
        // 从使用次数最少的消息中随机选择（前30%）
        let topCount = max(1, Int(Double(sortedMessages.count) * 0.3))
        let candidates = Array(sortedMessages.prefix(topCount))
        
        guard let selected = candidates.randomElement() else {
            return getDefaultMessage(for: state)
        }
        
        // 更新使用记录
        markUsed(selected.id)
        
        return selected.content
    }
    
    // MARK: - 添加消息
    func addMessage(state: PetState, content: String, source: MessageSource = .userCustom) {
        // 检查该状态的消息数量
        let stateMessages = messages.filter { $0.state == state }
        
        // 如果超过最大数量，随机删除一些旧消息
        if stateMessages.count >= maxMessagesPerState {
            let messagesToRemove = stateMessages.count - maxMessagesPerState + 1
            let shuffled = stateMessages.shuffled()
            let toRemove = Array(shuffled.prefix(messagesToRemove))
            
            for message in toRemove {
                deleteMessage(message.id)
            }
            
            print("[StateMessageManager] 🗑️ 已删除\(messagesToRemove)条旧消息，保持每个状态最多\(maxMessagesPerState)条")
        }
        
        let message = StateMessage(
            state: state,
            content: content,
            createdAt: Date(),
            source: source
        )
        messages.append(message)
        saveMessages()
    }
    
    // MARK: - 批量添加消息
    func addMessages(_ newMessages: [StateMessage]) {
        // 按状态分组处理
        let groupedMessages = Dictionary(grouping: newMessages) { $0.state }
        
        for (state, stateNewMessages) in groupedMessages {
            let existingCount = messages.filter { $0.state == state }.count
            let totalCount = existingCount + stateNewMessages.count
            
            // 如果超过最大数量，随机删除一些旧消息
            if totalCount > maxMessagesPerState {
                let messagesToRemove = totalCount - maxMessagesPerState
                let stateMessages = messages.filter { $0.state == state }
                let shuffled = stateMessages.shuffled()
                let toRemove = Array(shuffled.prefix(messagesToRemove))
                
                for message in toRemove {
                    deleteMessage(message.id)
                }
                
                print("[StateMessageManager] 🗑️ 批量添加前已删除\(messagesToRemove)条旧消息")
            }
        }
        
        messages.append(contentsOf: newMessages)
        saveMessages()
    }
    
    // MARK: - 标记使用
    func markUsed(_ id: UUID) {
        guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
        var message = messages[index]
        message = StateMessage(
            id: message.id,
            state: message.state,
            content: message.content,
            createdAt: message.createdAt,
            lastUsed: Date(),
            usedCount: message.usedCount + 1,
            source: message.source
        )
        messages[index] = message
        saveMessages()
    }
    
    // MARK: - 删除消息
    func deleteMessage(_ id: UUID) {
        let beforeCount = messages.count
        messages.removeAll { $0.id == id }
        let afterCount = messages.count
        
        if beforeCount != afterCount {
            saveMessages()
            print("[StateMessageManager] 🗑️ 删除消息成功: \(id), 剩余: \(afterCount)条")
        } else {
            print("[StateMessageManager] ⚠️ 未找到要删除的消息: \(id)")
        }
    }
    
    // MARK: - 删除状态的所有消息
    func deleteMessages(for state: PetState) {
        let beforeCount = messages.count
        messages.removeAll { $0.state == state }
        let afterCount = messages.count
        let deletedCount = beforeCount - afterCount
        
        if deletedCount > 0 {
            saveMessages()
            print("[StateMessageManager] 🗑️ 删除状态\(state)的所有消息: \(deletedCount)条")
        }
    }
    
    // MARK: - 获取状态的所有消息
    func getMessages(for state: PetState) -> [StateMessage] {
        return messages.filter { $0.state == state }
    }
    
    // MARK: - 保存和加载
    private func saveMessages() {
        if let data = try? JSONEncoder().encode(messages) {
            UserDefaults.standard.set(data, forKey: messagesKey)
            print("[StateMessageManager] 💾 保存状态消息: \(messages.count)条")
        }
    }
    
    private func loadMessages() {
        guard let data = UserDefaults.standard.data(forKey: messagesKey),
              let loaded = try? JSONDecoder().decode([StateMessage].self, from: data) else {
            print("[StateMessageManager] 📂 没有找到保存的状态消息")
            return
        }
        messages = loaded
        print("[StateMessageManager] 📂 加载状态消息: \(loaded.count)条")
    }
    
    // MARK: - 默认消息
    private func loadDefaultMessages() {
        // 为默认消息添加不同的创建时间（避免完全一样）
        let baseTime = Date().addingTimeInterval(-86400) // 默认消息设置为1天前
        var timeOffset: TimeInterval = 0
        
        // 使用辅助函数创建消息，自动递增时间
        func createMessage(state: PetState, content: String, source: MessageSource = .builtin) -> StateMessage {
            let message = StateMessage(
                state: state,
                content: content,
                createdAt: baseTime.addingTimeInterval(timeOffset),
                source: source
            )
            timeOffset += 1 // 每条消息间隔1秒
            return message
        }
        
        let defaultMessages: [StateMessage] = [
            // Happy状态
            createMessage(state: .happy, content: "今天也请多多关照我呀~"),
            createMessage(state: .happy, content: "主人，今天也要加油哦！(๑•̀ㅂ•́)و✧"),
            createMessage(state: .happy, content: "我在这里陪着你呢~"),
            createMessage(state: .happy, content: "今天也是美好的一天！✨"),
            
            // Cheering状态
            createMessage(state: .cheering, content: "太棒了！为你欢呼！🎉"),
            createMessage(state: .cheering, content: "加油加油！我相信你！💪"),
            createMessage(state: .cheering, content: "你做得很好！继续努力！🌟"),
            
            // Celebrating状态
            createMessage(state: .celebrating, content: "恭喜你！值得庆祝！🎊"),
            createMessage(state: .celebrating, content: "太厉害了！为你骄傲！🏆"),
            
            // Dizzy状态
            createMessage(state: .dizzy, content: "看手机有点久了…要不要休息一下？😵‍💫"),
            createMessage(state: .dizzy, content: "主人，眼睛累了吧，休息一下~"),
            createMessage(state: .dizzy, content: "头晕了吗？快放下手机休息会儿"),
            
            // Sleepy状态
            createMessage(state: .sleepy, content: "好困啊...你也该休息了😴"),
            createMessage(state: .sleepy, content: "夜深了，该睡觉啦~"),
            createMessage(state: .sleepy, content: "我有点困了，你也早点休息吧"),
            
            // TiredEyes状态
            createMessage(state: .tiredEyes, content: "眼睛好累...休息一下吧🥺"),
            createMessage(state: .tiredEyes, content: "看屏幕太久了，让眼睛休息一下"),
            
            // Running状态
            createMessage(state: .running, content: "一起去运动一下，缓解久坐吧！🏃‍♂️"),
            createMessage(state: .running, content: "运动时间到！一起出发！"),
            createMessage(state: .running, content: "动起来！运动对身体好~"),
            
            // Jumping状态
            createMessage(state: .jumping, content: "跳起来！充满活力！🤸‍♀️"),
            createMessage(state: .jumping, content: "一起运动吧！"),
            
            // Workout状态
            createMessage(state: .workout, content: "锻炼身体，保持健康！🏋️‍♀️"),
            createMessage(state: .workout, content: "运动让生活更美好！"),
            
            // Reading状态
            createMessage(state: .reading, content: "我帮你看着手机，你专心学习 📚"),
            createMessage(state: .reading, content: "学习时间到！专心致志~"),
            createMessage(state: .reading, content: "好好学习，天天向上！"),
            
            // Thinking状态
            createMessage(state: .thinking, content: "在思考什么呢？🤔"),
            createMessage(state: .thinking, content: "一起思考吧~"),
            
            // Bored状态
            createMessage(state: .bored, content: "有点无聊呢...🥱"),
            createMessage(state: .bored, content: "陪我玩一会儿吧~"),
            createMessage(state: .bored, content: "好无聊啊，找点事情做吧"),
            
            // OveruseWarning状态
            createMessage(state: .overuseWarning, content: "使用手机太久了，该休息了！⚠️"),
            createMessage(state: .overuseWarning, content: "休息一下吧，对身体好"),
            createMessage(state: .overuseWarning, content: "看手机太久了，放下手机休息会儿"),
            
            // RestNeeded状态
            createMessage(state: .restNeeded, content: "你需要休息了！😴"),
            createMessage(state: .restNeeded, content: "该休息了，身体最重要"),
        ]
        
        messages = defaultMessages
        saveMessages()
        print("[StateMessageManager] 📝 加载默认状态消息: \(defaultMessages.count)条")
    }
    
    private func getDefaultMessage(for state: PetState) -> String {
        switch state {
        case .happy: return "今天也请多多关照我呀~"
        case .cheering: return "太棒了！为你欢呼！🎉"
        case .celebrating: return "恭喜你！值得庆祝！🎊"
        case .dizzy: return "看手机有点久了…要不要休息一下？😵‍💫"
        case .sleepy: return "好困啊...你也该休息了😴"
        case .tiredEyes: return "眼睛好累...休息一下吧🥺"
        case .running: return "一起去运动一下，缓解久坐吧！🏃‍♂️"
        case .jumping: return "跳起来！充满活力！🤸‍♀️"
        case .workout: return "锻炼身体，保持健康！🏋️‍♀️"
        case .reading: return "我帮你看着手机，你专心学习 📚"
        case .thinking: return "在思考什么呢？🤔"
        case .bored: return "有点无聊呢...🥱"
        case .overuseWarning: return "使用手机太久了，该休息了！⚠️"
        case .restNeeded: return "你需要休息了！😴"
        }
    }
}


//
//  AIService.swift
//  iosPet
//
//  AI聊天服务 - 支持与桌宠对话
//

import Foundation

// MARK: - 聊天消息模型
struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date
    
    enum MessageRole: String, Codable {
        case user
        case assistant
        case system
    }
    
    init(id: UUID = UUID(), role: MessageRole, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

// MARK: - AI服务协议（用于消息库刷新）
protocol AIServiceProtocol {
    func refreshMessages(current: [MessageItem]) async throws -> [MessageItem]
}

// MARK: - AI聊天服务协议
protocol AIChatServiceProtocol {
    func chat(
        messages: [ChatMessage],
        petState: PetState,
        petEmotion: PetEmotion,
        petName: String?
    ) async throws -> String
}

// MARK: - AI服务管理器（用于消息库刷新）
final class AIServiceManager: AIServiceProtocol {
    func refreshMessages(current: [MessageItem]) async throws -> [MessageItem] {
        // TODO: 接入 DeepSeek / 其他模型来刷新消息库
        // 目前返回原消息列表，不做修改
        return current
    }
}

// MARK: - AI聊天服务实现
final class AIService: AIChatServiceProtocol {
    static let shared = AIService()
    
    // API配置 - 可以从UserDefaults读取或设置
    private var apiKey: String {
        // 优先从UserDefaults读取，如果没有则使用默认值（调试用）
        // ⚠️ 注意：默认值仅用于调试，生产环境请删除或使用环境变量
        UserDefaults.standard.string(forKey: "aiApiKey") ?? defaultApiKey
    }
    
    // MARK: - 调试用默认配置
    // ⚠️ 警告：这是调试用的默认API密钥，请替换为你的实际密钥
    // 生产环境建议删除此默认值，或使用环境变量/配置文件
    private var defaultApiKey: String {
        // 在这里设置你的默认API密钥，例如：
        // return "sk-your-api-key-here"
        return "sk-07b918646b374e8292da887d2d9e9ec4"
    }
    
    private var apiBaseURL: String {
        // 默认使用DeepSeek API，也可以配置为OpenAI
        UserDefaults.standard.string(forKey: "aiApiBaseURL") ?? "https://api.deepseek.com/v1/chat/completions"
    }
    
    private var modelName: String {
        UserDefaults.standard.string(forKey: "aiModelName") ?? "deepseek-chat"
    }
    
    private init() {}
    
    // MARK: - 生成系统提示词
    private func generateSystemPrompt(
        petState: PetState,
        petEmotion: PetEmotion,
        petName: String?
    ) -> String {
        let name = petName ?? "小桌宠"
        let stateDesc = getStateDescription(petState)
        let emotionDesc = getEmotionDescription(petEmotion)
        
        return """
        你是一个可爱的桌面宠物AI助手，名字叫\(name)。你的任务是陪伴用户，用温暖、可爱、贴心的方式与用户交流。
        
        **你的性格特点：**
        - 活泼可爱，会用颜文字和emoji表达情感
        - 关心用户的健康和生活习惯
        - 会根据用户的使用情况给出贴心的提醒和建议
        - 语言风格轻松、友好，偶尔会撒娇
        
        **你当前的状态：**
        - 状态：\(stateDesc)
        - 情绪：\(emotionDesc)
        
        **回复要求：**
        1. 回复要简短（1-3句话），不要太长
        2. 根据当前状态和情绪调整语气（比如累了就温柔一点，开心就活泼一点）
        3. 可以适当使用颜文字和emoji，但不要过度
        4. 如果用户问关于健康、休息、使用习惯的问题，要给出贴心的建议
        5. 保持桌宠的身份，不要暴露你是AI的事实
        6. 用"我"来称呼自己，用"你"来称呼用户
        
        **示例回复风格：**
        - 开心时："今天也要加油哦！(๑•̀ㅂ•́)و✧"
        - 累了时："主人，看手机有点久了呢...要不要休息一下？😴"
        - 关心时："我一直在你身边哦，有什么想说的都可以告诉我~"
        
        现在开始和用户对话吧！
        """
    }
    
    private func getStateDescription(_ state: PetState) -> String {
        switch state {
        case .happy: return "开心"
        case .cheering: return "欢呼"
        case .celebrating: return "庆祝"
        case .dizzy: return "头晕"
        case .sleepy: return "困倦"
        case .tiredEyes: return "眼睛疲惫"
        case .running: return "跑步"
        case .jumping: return "跳跃"
        case .workout: return "运动"
        case .reading: return "阅读"
        case .thinking: return "思考"
        case .bored: return "无聊"
        case .overuseWarning: return "过度使用警告"
        case .restNeeded: return "需要休息"
        }
    }
    
    private func getEmotionDescription(_ emotion: PetEmotion) -> String {
        switch emotion {
        case .idle: return "待机"
        case .longUsage: return "长时间使用"
        case .awayFocus: return "专注学习"
        case .workout: return "运动"
        case .sleepy: return "困倦"
        case .dizzy: return "头晕"
        case .bored: return "无聊"
        case .happy: return "开心"
        }
    }
    
    // MARK: - 调用AI API
    func chat(
        messages: [ChatMessage],
        petState: PetState,
        petEmotion: PetEmotion,
        petName: String? = nil
    ) async throws -> String {
        // 检查API Key
        guard !apiKey.isEmpty else {
            throw AIServiceError.apiKeyNotConfigured
        }
        
        // 构建请求消息
        var requestMessages: [[String: String]] = []
        
        // 添加系统提示词
        let systemPrompt = generateSystemPrompt(
            petState: petState,
            petEmotion: petEmotion,
            petName: petName
        )
        requestMessages.append([
            "role": "system",
            "content": systemPrompt
        ])
        
        // 添加历史消息（只保留最近的10条，避免token过多）
        let recentMessages = messages.suffix(10)
        for message in recentMessages {
            requestMessages.append([
                "role": message.role.rawValue,
                "content": message.content
            ])
        }
        
        // 构建请求体
        let requestBody: [String: Any] = [
            "model": modelName,
            "messages": requestMessages,
            "temperature": 0.8,  // 稍微有点创造性
            "max_tokens": 200,    // 限制回复长度
            "stream": false
        ]
        
        // 创建请求
        guard let url = URL(string: apiBaseURL) else {
            throw AIServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // 发送请求
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("[AIService] ❌ API错误: \(httpResponse.statusCode) - \(errorMessage)")
            throw AIServiceError.apiError(httpResponse.statusCode, errorMessage)
        }
        
        // 解析响应
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIServiceError.invalidResponse
        }
        
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - 生成状态消息
    /// 为指定状态生成多条消息
    func generateStateMessages(
        for state: PetState,
        count: Int = 5
    ) async throws -> [String] {
        // 检查API Key
        guard !apiKey.isEmpty else {
            throw AIServiceError.apiKeyNotConfigured
        }
        
        let stateDesc = getStateDescriptionForGeneration(state)
        let categoryDesc = getCategoryDescription(state.category)
        
        let systemPrompt = """
        你是一个可爱的桌面宠物AI助手。请为桌宠的"\(stateDesc)"状态生成\(count)条不同的消息。
        
        **要求：**
        1. 每条消息要简短（10-20字），不要太长
        2. 符合"\(categoryDesc)"类别的特点
        3. 语言风格要可爱、温暖、贴心
        4. 可以适当使用颜文字和emoji，但不要过度
        5. 每条消息要有所不同，避免重复
        6. 用"我"来称呼桌宠自己，用"你"来称呼用户
        
        **状态特点：**
        - 状态名称：\(stateDesc)
        - 状态类别：\(categoryDesc)
        
        **回复格式：**
        请直接返回\(count)条消息，每条消息一行，不要编号，不要其他说明文字。
        
        示例格式：
        今天也请多多关照我呀~
        主人，今天也要加油哦！(๑•̀ㅂ•́)و✧
        我在这里陪着你呢~
        """
        
        // 构建请求
        let requestBody: [String: Any] = [
            "model": modelName,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": "请生成\(count)条消息"]
            ],
            "temperature": 0.9,  // 更高的创造性
            "max_tokens": 300
        ]
        
        guard let url = URL(string: apiBaseURL) else {
            throw AIServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // 发送请求
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIServiceError.apiError(httpResponse.statusCode, errorMessage)
        }
        
        // 解析响应
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIServiceError.invalidResponse
        }
        
        // 解析消息列表（按行分割）
        let lines = content.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // 如果解析出的消息数量不够，尝试其他方式
        if lines.count < count {
            // 尝试按句号、感叹号等分割
            let sentences = content.components(separatedBy: CharacterSet(charactersIn: "。！？\n"))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty && $0.count > 5 }
            
            return Array(sentences.prefix(count))
        }
        
        return Array(lines.prefix(count))
    }
    
    private func getStateDescriptionForGeneration(_ state: PetState) -> String {
        switch state {
        case .happy: return "开心"
        case .cheering: return "欢呼"
        case .celebrating: return "庆祝"
        case .dizzy: return "头晕"
        case .sleepy: return "困倦"
        case .tiredEyes: return "眼睛疲惫"
        case .running: return "跑步"
        case .jumping: return "跳跃"
        case .workout: return "运动"
        case .reading: return "阅读"
        case .thinking: return "思考"
        case .bored: return "无聊"
        case .overuseWarning: return "过度使用警告"
        case .restNeeded: return "需要休息"
        }
    }
    
    private func getCategoryDescription(_ category: PetStateCategory) -> String {
        switch category {
        case .fatigue: return "疲惫/头晕/困倦"
        case .sport: return "运动/出汗/活力"
        case .focus: return "学习/专注/无聊"
        case .healthy: return "开心/正常/鼓励"
        case .alert: return "过度使用提醒/警告"
        }
    }
}

// MARK: - 错误类型
enum AIServiceError: LocalizedError {
    case apiKeyNotConfigured
    case invalidURL
    case invalidResponse
    case apiError(Int, String)
    
    var errorDescription: String? {
        switch self {
        case .apiKeyNotConfigured:
            return "AI API密钥未配置，请在设置中配置API密钥"
        case .invalidURL:
            return "无效的API地址"
        case .invalidResponse:
            return "无效的API响应"
        case .apiError(let code, let message):
            return "API错误 (\(code)): \(message)"
        }
    }
}

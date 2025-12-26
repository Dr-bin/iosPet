//
//  PetChatView.swift
//  iosPet
//
//  桌宠聊天界面
//

import SwiftUI

struct PetChatView: View {
    @StateObject private var chatManager = ChatManager.shared
    @State private var inputText: String = ""
    @State private var isSending: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    let petState: PetState
    let petEmotion: PetEmotion
    let petName: String?
    
    // 缓存图标，避免每次渲染都重新选择
    @State private var cachedIcon: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // 消息列表
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // 欢迎消息（始终显示在顶部）
                        welcomeMessage
                            .id("welcome")
                        
                        // 聊天消息
                        ForEach(chatManager.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        // 加载指示器
                        if isSending {
                            HStack {
                                ProgressView()
                                    .scaleEffect(max(0.1, min(2.0, 0.8)))
                                Text("桌宠正在思考...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .id("loading")
                        }
                    }
                    .padding()
                }
                .onChange(of: chatManager.messages.count) { oldCount, newCount in
                    // 滚动到底部
                    guard newCount > 0 else { return }
                    // 使用主线程异步执行，避免阻塞输入
                    DispatchQueue.main.async {
                        if let lastMessage = chatManager.messages.last {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                .onChange(of: isSending) { oldValue, newValue in
                    guard newValue else { return }
                    // 使用主线程异步执行
                    DispatchQueue.main.async {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo("loading", anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // 输入区域
            HStack(spacing: 12) {
                TextField("和桌宠说点什么...", text: $inputText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                    .submitLabel(.send)
                    .onSubmit {
                        if !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending {
                            sendMessage()
                        }
                    }
                    .disabled(isSending)
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(inputText.isEmpty || isSending ? .gray : .blue)
                }
                .disabled(inputText.isEmpty || isSending)
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .navigationTitle("和桌宠聊天")
        .navigationBarTitleDisplayMode(.inline)
        .alert("错误", isPresented: $showError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            // 加载聊天历史
            chatManager.loadChatHistory()
            // 初始化图标（只设置一次）
            if cachedIcon.isEmpty {
                cachedIcon = IconManager.shared.getIcon(for: petState)
            }
        }
        .onChange(of: petState) { oldState, newState in
            // 状态改变时更新图标（带动画）
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                cachedIcon = IconManager.shared.getIcon(for: newState)
            }
        }
    }
    
    // MARK: - 欢迎消息
    private var welcomeMessage: some View {
        VStack(spacing: 12) {
            // 宠物图标（带动画）
            Text(cachedIcon.isEmpty ? IconManager.shared.getIcon(for: petState) : cachedIcon)
                .font(.system(size: 60))
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: cachedIcon)
            
            if chatManager.messages.isEmpty {
                VStack(spacing: 4) {
                    Text("你好！我是你的桌宠")
                        .font(.headline)
                    
                    Text("有什么想和我说的吗？")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .transition(.opacity)
            } else {
                Text("继续聊天...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .transition(.opacity)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.3), value: chatManager.messages.isEmpty)
    }
    
    // MARK: - 发送消息
    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        inputText = ""
        
        // 添加用户消息
        chatManager.addMessage(role: .user, content: userMessage)
        
        // 发送到AI
        isSending = true
        Task {
            do {
                let response = try await AIService.shared.chat(
                    messages: chatManager.messages,
                    petState: petState,
                    petEmotion: petEmotion,
                    petName: petName
                )
                
                await MainActor.run {
                    chatManager.addMessage(role: .assistant, content: response)
                    isSending = false
                    chatManager.saveChatHistory()
                }
            } catch {
                await MainActor.run {
                    isSending = false
                    errorMessage = error.localizedDescription
                    showError = true
                    print("[PetChatView] ❌ 发送消息失败: \(error)")
                }
            }
        }
    }
}

// MARK: - 消息气泡
struct MessageBubble: View {
    let message: ChatMessage
    
    // 计算最大宽度，避免 NaN
    private var maxBubbleWidth: CGFloat {
        // 使用 GeometryReader 更安全，但这里用固定值更稳定
        // 避免在输入时频繁计算导致 NaN
        return 300
    }
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(12)
                    .background(
                        message.role == .user
                            ? Color.blue.opacity(max(0, min(1, 0.1)))
                            : Color.gray.opacity(max(0, min(1, 0.1)))
                    )
                    .foregroundColor(.primary)
                    .cornerRadius(max(0, min(50, 16)))
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: maxBubbleWidth, alignment: message.role == .user ? .trailing : .leading)
            
            if message.role == .assistant {
                Spacer()
            }
        }
    }
}

// MARK: - 聊天管理器
final class ChatManager: ObservableObject {
    static let shared = ChatManager()
    
    @Published var messages: [ChatMessage] = []
    
    private let chatHistoryKey = "petChatHistory"
    
    private init() {}
    
    func addMessage(role: ChatMessage.MessageRole, content: String) {
        let message = ChatMessage(role: role, content: content)
        messages.append(message)
    }
    
    func saveChatHistory() {
        // 只保存最近的50条消息
        let recentMessages = Array(messages.suffix(50))
        
        if let data = try? JSONEncoder().encode(recentMessages) {
            UserDefaults.standard.set(data, forKey: chatHistoryKey)
            print("[ChatManager] 💾 保存聊天历史: \(recentMessages.count)条消息")
        }
    }
    
    func loadChatHistory() {
        guard let data = UserDefaults.standard.data(forKey: chatHistoryKey),
              let history = try? JSONDecoder().decode([ChatMessage].self, from: data) else {
            print("[ChatManager] 📂 没有找到聊天历史")
            return
        }
        
        messages = history
        print("[ChatManager] 📂 加载聊天历史: \(history.count)条消息")
    }
    
    func clearChatHistory() {
        messages = []
        UserDefaults.standard.removeObject(forKey: chatHistoryKey)
        print("[ChatManager] 🗑️ 清空聊天历史")
    }
}


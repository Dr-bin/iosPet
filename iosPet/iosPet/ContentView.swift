//
//  ContentView.swift
//  iosPet
//
//  Created by admin on 2025/12/9.
//

import SwiftUI
import WidgetKit

struct ContentView: View {
    @ObservedObject private var configManager = ConfigurationManager.shared
    @ObservedObject private var messageManager = MessageLibraryManager.shared
    @ObservedObject private var testModeManager = TestModeManager.shared

    var body: some View {
        TabView {
            PetHomeView()
                .tabItem {
                    Label("宠物", systemImage: "pawprint.fill")
                }

            PetConfigView()
                .tabItem {
                    Label("配置", systemImage: "slider.horizontal.3")
                }
        }
        .onAppear {
            print("[ContentView] 🎯 主界面已显示，开始初始化...")
            bootstrap()
            print("[ContentView] ✅ 主界面初始化完成")
        }
    }

    /// 加载本地表情资源与词库
    private func bootstrap() {
        if messageManager.messages.isEmpty {
            if let url = Bundle.main.url(forResource: "DefaultMessages", withExtension: "json"),
               let data = try? Data(contentsOf: url) {
                try? messageManager.load(from: data)
            }
        }
        if ResourceManager.shared.resources(for: .happy, carrier: .widget).isEmpty {
            if let url = Bundle.main.url(forResource: "ExpressionResources", withExtension: "json"),
               let data = try? Data(contentsOf: url) {
                try? ResourceManager.shared.load(from: data)
            }
        }
    }
}

// MARK: - 宠物主交互页

struct PetHomeView: View {
    @StateObject private var messageManager = StateMessageManager.shared
    @State private var currentState: PetState = .happy
    @State private var currentIcon: String = "😸"
    @State private var lastMessage: String? = "今天也请多多关照我呀~"
    @State private var showChatView = false
    @State private var iconScale: CGFloat = 1.0
    @State private var iconRotation: Double = 0

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景渐变
                LinearGradient(
                    colors: [
                        colorTheme.background,
                        colorTheme.background.opacity(0.5),
                        Color(.systemBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Spacer()
                    
                    // 宠物主体形象区域
                    VStack(spacing: 16) {
                        // 宠物图标（带动画）
                        Text(currentIcon)
                            .font(.system(size: 100))
                            .scaleEffect(max(0.1, min(2.0, iconScale.isNaN ? 1.0 : iconScale)))
                            .rotationEffect(.degrees(iconRotation.isNaN ? 0 : iconRotation))
                            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: iconScale)
                            .animation(.easeInOut(duration: 0.3), value: iconRotation)
                            .padding(30)
                            .background(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                colorTheme.primary.opacity(0.2),
                                                colorTheme.secondary.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: colorTheme.primary.opacity(0.3), radius: 20, x: 0, y: 10)
                            )
                        
                        // 状态文案（简化）
                        Text(stateDescription(for: currentState))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)

                    // 气泡对话（优化样式）
                    if let lastMessage {
                        HStack {
                            Text(lastMessage)
                                .font(.body)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(.ultraThinMaterial)
                                        .shadow(color: .black.opacity(max(0, min(1, 0.1))), radius: max(0, min(20, 10)), x: 0, y: max(0, min(10, 5)))
                                )
                        }
                        .padding(.horizontal, 24)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: lastMessage)
                    }

                    Spacer()

                    // 交互按钮区域（优化布局）
                    VStack(spacing: 12) {
                        // 第一行按钮
                        HStack(spacing: 12) {
                            ActionButton(
                                title: "摸摸它",
                                icon: "🤲",
                                color: .yellow,
                                action: {
                                    changeState(to: .happy)
                                }
                            )
                            
                            ActionButton(
                                title: "去运动",
                                icon: "🏃‍♂️",
                                color: .green,
                                action: {
                                    changeState(to: .running)
                                }
                            )
                        }
                        
                        // 第二行按钮
                        HStack(spacing: 12) {
                            ActionButton(
                                title: "学习",
                                icon: "📖",
                                color: .cyan,
                                action: {
                                    changeState(to: .reading)
                                }
                            )
                            
                            ActionButton(
                                title: "休息",
                                icon: "😴",
                                color: .blue,
                                action: {
                                    changeState(to: .dizzy)
                                }
                            )
                        }
                        
                        // 聊天按钮（优化样式）
                        Button {
                            showChatView = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "message.fill")
                                Text("和桌宠聊天")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(14)
                            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("桌宠")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showChatView = true
                    } label: {
                        Image(systemName: "message.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showChatView) {
                PetChatView(
                    petState: currentState,
                    petEmotion: currentState.emotion,
                    petName: nil
                )
            }
            .onAppear {
                // 视图出现时同步当前状态到 Widget
                updateState(to: currentState, animated: false)
            }
        }
    }
    
    // MARK: - 计算属性
    private var colorTheme: (primary: Color, secondary: Color, background: Color) {
        IconManager.shared.getColorTheme(for: currentState)
    }
    
    // MARK: - 方法
    private func changeState(to newState: PetState) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            updateState(to: newState, animated: true)
        }
    }
    
    private func updateState(to newState: PetState, animated: Bool) {
        currentState = newState
        currentIcon = IconManager.shared.getIcon(for: newState)
        lastMessage = messageManager.getMessage(for: newState)
        SyncManager.shared.updateAllCarriers(to: newState)
        
        if animated {
            // 图标动画（确保数值有效）
            let targetScale: CGFloat = 1.2
            let targetRotation = Double.random(in: -10...10)
            
            // 确保数值不是 NaN 或无效值
            let safeScale = (targetScale.isNaN || targetScale.isInfinite) ? 1.0 : max(0.1, min(2.0, targetScale))
            let safeRotation = (targetRotation.isNaN || targetRotation.isInfinite) ? 0 : max(-360, min(360, targetRotation))
            
            // 设置动画值
            iconScale = safeScale
            iconRotation = safeRotation
            
            // 延迟后恢复
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    iconScale = 1.0
                    iconRotation = 0
                }
            }
        }
    }

    private func stateDescription(for state: PetState) -> String {
        switch state {
        case .happy: return "很开心"
        case .cheering: return "在加油"
        case .celebrating: return "在庆祝"
        case .dizzy: return "有点头晕"
        case .sleepy: return "有点困"
        case .tiredEyes: return "眼睛累"
        case .running: return "在运动"
        case .jumping: return "精力满满"
        case .workout: return "在锻炼"
        case .reading: return "在学习"
        case .thinking: return "在思考"
        case .bored: return "有点无聊"
        case .overuseWarning: return "提醒休息"
        case .restNeeded: return "需要休息"
        }
    }
}

// MARK: - 交互按钮组件
struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    isPressed = false
                }
            }
            action()
        }) {
            VStack(spacing: 6) {
                Text(icon)
                    .font(.system(size: 28))
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(color.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
            .scaleEffect(max(0.5, min(1.5, isPressed ? 0.95 : 1.0)))
            .shadow(color: color.opacity(0.2), radius: max(0, min(20, isPressed ? 4 : 8)), x: 0, y: max(0, min(10, isPressed ? 2 : 4)))
        }
        .buttonStyle(.plain)
    }
    
    // 测试 App Group 数据
    private func testAppGroup() {
        if let defaults = UserDefaults(suiteName: AppGroupKeys.suiteName) {
            defaults.synchronize()
            let allKeys = defaults.dictionaryRepresentation().keys
            let emotion = defaults.string(forKey: AppGroupKeys.sharedEmotionKey) ?? "未找到"
            
            print("========== App Group 测试 ==========")
            print("Suite Name: \(AppGroupKeys.suiteName)")
            print("所有 Keys: \(Array(allKeys))")
            print("当前情绪值: \(emotion)")
            print("====================================")
            
            // 强制刷新 Widget
            WidgetCenter.shared.reloadTimelines(ofKind: "PetWidget")
            WidgetCenter.shared.reloadAllTimelines()
        } else {
            print("❌ 无法访问 App Group: \(AppGroupKeys.suiteName)")
        }
    }
}

// MARK: - 配置与资源预览页

struct PetConfigView: View {
    @ObservedObject private var testModeManager = TestModeManager.shared
    @ObservedObject private var usageReminder = UsageReminderManager.shared
    
    @State private var inactivityWarningHours: Double = 2.0
    @State private var inactivityLimitHours: Double = 6.0
    @State private var checkIntervalHours: Double = 1.0
    @State private var continuousWarningHours: Double = 1.5

    var body: some View {
        NavigationStack {
            Form {
                // 测试模式开关
                Section("演示设置") {
                    Toggle("启用测试模式", isOn: $testModeManager.isTestModeEnabled)
                        .tint(.orange)
                        .onChange(of: testModeManager.isTestModeEnabled) { oldValue, newValue in
                            if newValue {
                                print("[TestMode] 🧪 测试模式已启用 - 时间阈值将大幅缩短")
                            } else {
                                print("[TestMode] 📱 测试模式已关闭 - 使用正常时间阈值")
                            }
                        }

                    if testModeManager.isTestModeEnabled {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("🎭 测试模式说明：")
                                .font(.caption)
                                .fontWeight(.medium)
                            Text("• 久未使用提醒：1分钟/3分钟（正常：2h/6h）")
                                .font(.caption2)
                            Text("• 手机连续使用提醒：45秒（正常：1.5h）")
                                .font(.caption2)
                            Text("• 检查间隔：30秒（正常：1小时）")
                                .font(.caption2)
                            Text("• 时间缩放：120倍加速，方便快速演示")
                                .font(.caption2)
                        }
                        .foregroundColor(.orange)
                        .padding(.vertical, 4)
                    }
                }

                // 实际使用的参数配置（可编辑）
                Section {
                    // 久未使用警告
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("久未使用警告")
                            Spacer()
                            Text("\(inactivityWarningHours, specifier: "%.1f") 小时")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        Stepper("", value: $inactivityWarningHours, in: 0.5...24, step: 0.5)
                            .onChange(of: inactivityWarningHours) { oldValue, newValue in
                                usageReminder.updateInactivityWarning(hours: newValue)
                            }
                        Text("应用长时间未打开时，Widget显示想念状态的时间")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    // 久未使用限制
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("久未使用限制")
                            Spacer()
                            Text("\(inactivityLimitHours, specifier: "%.1f") 小时")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        Stepper("", value: $inactivityLimitHours, in: 1...72, step: 1)
                            .onChange(of: inactivityLimitHours) { oldValue, newValue in
                                usageReminder.updateInactivityLimit(hours: newValue)
                            }
                        Text("应用长时间未打开时，触发强烈提醒的时间")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    // 检查间隔
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("检查间隔")
                            Spacer()
                            Text("\(checkIntervalHours, specifier: "%.1f") 小时")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        Stepper("", value: $checkIntervalHours, in: 0.5...6, step: 0.5)
                            .onChange(of: checkIntervalHours) { oldValue, newValue in
                                usageReminder.updateCheckInterval(hours: newValue)
                            }
                        Text("系统检查久未使用状态的频率")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    // 手机连续使用警告
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("手机连续使用警告")
                            Spacer()
                            Text("\(continuousWarningHours, specifier: "%.1f") 小时")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        Stepper("", value: $continuousWarningHours, in: 0.5...8, step: 0.5)
                            .onChange(of: continuousWarningHours) { oldValue, newValue in
                                usageReminder.updateContinuousWarning(hours: newValue)
                            }
                        Text("检测到手机连续使用达到此时间时，开始提醒休息")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    if testModeManager.isTestModeEnabled {
                        Divider()
                            .padding(.vertical, 2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("⚠️ 测试模式已启用")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                            
                            Text("所有时间阈值已缩短120倍")
                                .font(.caption2)
                                .foregroundColor(.orange.opacity(0.8))
                        }
                    }
                } header: {
                    Text("时间阈值配置")
                } footer: {
                    Text("手机连续使用警告：检测用户连续使用手机（所有应用）的时长。当达到设定时间时，宠物会显示过度使用警告状态，提醒用户休息。")
                        .font(.caption2)
                }
                
                // AI聊天配置
                AIConfigSection()
                
                // 状态消息管理
                StateMessageSection()
                
                // Todo List 测试区域
                TodoListSection()

                // 通知权限状态区域
                NotificationPermissionSection()

                // 使用习惯提醒测试区域
                UsageReminderTestSection()
            }
            .navigationTitle("桌宠配置")
            .onAppear {
                // 加载当前配置值
                inactivityWarningHours = usageReminder.getInactivityWarningHours()
                inactivityLimitHours = usageReminder.getInactivityLimitHours()
                checkIntervalHours = usageReminder.getCheckIntervalHours()
                continuousWarningHours = usageReminder.getContinuousWarningHours()
            }
        }
    }
}

// MARK: - Todo List 区域

struct TodoListSection: View {
    @ObservedObject private var todoManager = TodoManager.shared
    @State private var newTodoText = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        Section("Todo List (测试 Widget 同步)") {
            // 输入框
            HStack {
                TextField("输入新的 Todo...", text: $newTodoText)
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        addTodo()
                    }
                
                Button(action: addTodo) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
                .disabled(newTodoText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            
            // Todo 列表
            if todoManager.todos.isEmpty {
                Text("暂无 Todo，添加一个试试吧！")
                    .foregroundColor(.secondary)
                    .font(.caption)
            } else {
                ForEach(todoManager.todos) { todo in
                    TodoRowView(todo: todo)
                }
                .onDelete(perform: deleteTodos)
            }
            
        }
    }
    
    private func addTodo() {
        guard !newTodoText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        todoManager.addTodo(newTodoText)
        newTodoText = ""
        isTextFieldFocused = false
    }
    
    private func deleteTodos(at offsets: IndexSet) {
        todoManager.deleteTodo(at: offsets)
    }

}

// MARK: - 通知权限状态区域

struct NotificationPermissionSection: View {
    @State private var permissionStatus: String = "检查中..."
    @State private var isLoading = false

    var body: some View {
        Section("通知权限状态") {
            HStack {
                Text("权限状态：\(permissionStatus)")
                    .font(.caption)

                Spacer()

                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Button {
                        checkPermission()
                    } label: {
                        Text("检查")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(6)
                    }
                }
            }

            if permissionStatus.contains("未授权") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("⚠️ 需要通知权限才能接收健康提醒")
                        .font(.caption)
                        .foregroundColor(.orange)

                    Text("开启方法：设置 > 通知 > iosPet > 允许通知")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Button {
                        openNotificationSettings()
                    } label: {
                        Text("前往设置")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .onAppear {
            checkPermission()
        }
    }

    private func checkPermission() {
        isLoading = true

        Task {
            let status = await NotificationManager.shared.checkPermissionStatus()

            await MainActor.run {
                switch status {
                case .authorized:
                    permissionStatus = "✅ 已授权"
                case .denied:
                    permissionStatus = "❌ 已拒绝"
                case .notDetermined:
                    permissionStatus = "❓ 未请求"
                case .provisional:
                    permissionStatus = "⚠️ 临时授权"
                case .ephemeral:
                    permissionStatus = "⚠️ 临时会话"
                @unknown default:
                    permissionStatus = "❓ 未知状态"
                }

                isLoading = false
            }
        }
    }

    private func openNotificationSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - 使用习惯提醒测试区域

struct UsageReminderTestSection: View {
    @State private var monitorStatus = "监测中..."
    @State private var isSimulating = false
    @State private var currentAction: String? = nil

    var body: some View {
        Section("使用习惯提醒测试") {
            Text("当前状态：\(monitorStatus)")
                .font(.caption)
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                // 久未使用测试
                HStack(spacing: 12) {
                    Button(action: {
                        print("[BUTTON] 🟠 按钮被点击: 模拟2小时未用")
                        Task {
                            await simulateInactivity2Hours()
                        }
                    }) {
                        Text("模拟2小时未用")
                            .font(.caption)
                            .padding(8)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .disabled(isSimulating)
                    .buttonStyle(.plain)

                    Button(action: {
                        print("[BUTTON] 🔴 按钮被点击: 模拟6小时未用")
                        Task {
                            await simulateInactivity6Hours()
                        }
                    }) {
                        Text("模拟6小时未用")
                            .font(.caption)
                            .padding(8)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .disabled(isSimulating)
                    .buttonStyle(.plain)
                }

                // 连续使用测试
                HStack(spacing: 12) {
                    Button(action: {
                        print("[BUTTON] 🟡 按钮被点击: 模拟手机连续使用1.5小时")
                        Task {
                            await simulateContinuousUsage90Min()
                        }
                    }) {
                        Text("模拟手机使用1.5h")
                            .font(.caption)
                            .padding(8)
                            .background(Color.yellow.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .disabled(isSimulating)
                    .buttonStyle(.plain)

                    Button(action: {
                        print("[BUTTON] 🟣 按钮被点击: 模拟手机连续使用2小时")
                        Task {
                            await simulateContinuousUsage120Min()
                        }
                    }) {
                        Text("模拟手机使用2h")
                            .font(.caption)
                            .padding(8)
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .disabled(isSimulating)
                    .buttonStyle(.plain)
                }

                // 手动检查和重置
                HStack(spacing: 12) {
                    Button(action: {
                        print("[BUTTON] 🔵 按钮被点击: 手动检查状态")
                        Task {
                            await manualCheckAsync()
                        }
                    }) {
                        Text("手动检查状态")
                            .font(.caption)
                            .padding(8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .disabled(isSimulating)
                    .buttonStyle(.plain)

                    Button(action: {
                        print("[BUTTON] 🟢 按钮被点击: 重置状态")
                        Task {
                            await resetInactivityStateAsync()
                        }
                    }) {
                        Text("重置状态")
                            .font(.caption)
                            .padding(8)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .disabled(isSimulating)
                    .buttonStyle(.plain)
                }
            }

                VStack(alignment: .leading, spacing: 2) {
                    Text("🎯 功能说明：")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    Text("• 久未使用：2小时发提醒，6小时发欢迎消息")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("• 连续使用：1.5小时警告，2小时强烈提醒")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("• 模拟器：时间阈值大幅缩短便于测试")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
        }
    }

    private func simulateInactivity2Hours() async {
        guard !isSimulating else {
            print("[METHOD] 🚫 simulateInactivity2Hours: 已在执行中，忽略")
            return
        }
        print("[METHOD] 🟠 simulateInactivity2Hours: 开始执行")
        await simulateInactivityAsync(hours: 2)
    }

    private func simulateInactivity6Hours() async {
        guard !isSimulating else {
            print("[METHOD] 🚫 simulateInactivity6Hours: 已在执行中，忽略")
            return
        }
        print("[METHOD] 🔴 simulateInactivity6Hours: 开始执行")
        await simulateInactivityAsync(hours: 6)
    }

    private func simulateContinuousUsage90Min() async {
        guard !isSimulating else {
            print("[METHOD] 🚫 simulateContinuousUsage90Min: 已在执行中，忽略")
            return
        }
        print("[METHOD] 🟡 simulateContinuousUsage90Min: 开始执行")
        await simulateContinuousUsageAsync(minutes: 90)
    }

    private func simulateContinuousUsage120Min() async {
        guard !isSimulating else {
            print("[METHOD] 🚫 simulateContinuousUsage120Min: 已在执行中，忽略")
            return
        }
        print("[METHOD] 🟣 simulateContinuousUsage120Min: 开始执行")
        await simulateContinuousUsageAsync(minutes: 120)
    }

    private func simulateInactivityAsync(hours: Double) async {
        guard !isSimulating else {
            print("[UsageReminderTest] 🚫 simulateInactivityAsync: 已在执行中，忽略")
            return
        }
        isSimulating = true
        monitorStatus = "模拟中..."

        print("[UsageReminderTest] 🎭 执行模拟久未使用: \(hours)小时")
        UsageReminderManager.shared.simulateInactivity(hours: hours)
        monitorStatus = "已模拟\(hours)小时未用"

        // 短暂延迟确保操作完成
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
        monitorStatus = "监测中..."
        isSimulating = false
        print("[UsageReminderTest] ✅ 模拟完成")
    }

    private func simulateInactivity(hours: Double) {
        print("[UsageReminderTest] 🎭 模拟久未使用: \(hours)小时")
        UsageReminderManager.shared.simulateInactivity(hours: hours)
        monitorStatus = "已模拟\(hours)小时未用"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            monitorStatus = "监测中..."
        }
    }

    private func simulateContinuousUsageAsync(minutes: Double) async {
        guard !isSimulating else {
            print("[UsageReminderTest] 🚫 simulateContinuousUsageAsync: 已在执行中，忽略")
            return
        }
        isSimulating = true
        monitorStatus = "模拟中..."

        print("[UsageReminderTest] 🎭 执行模拟手机连续使用: \(minutes)分钟")
        UsageReminderManager.shared.simulateContinuousUsage(minutes: minutes)
        monitorStatus = "已模拟手机使用\(minutes)分钟"

        // 短暂延迟确保操作完成
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
        monitorStatus = "监测中..."
        isSimulating = false
        print("[UsageReminderTest] ✅ 模拟完成")
    }

    private func simulateContinuousUsage(minutes: Double) {
        print("[UsageReminderTest] 🎭 模拟手机连续使用: \(minutes)分钟")
        UsageReminderManager.shared.simulateContinuousUsage(minutes: minutes)
        monitorStatus = "已模拟手机使用\(minutes)分钟"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            monitorStatus = "监测中..."
        }
    }

    private func manualCheckAsync() async {
        guard !isSimulating else {
            print("[METHOD] 🚫 manualCheckAsync: 已在执行中，忽略")
            return
        }
        print("[METHOD] 🔵 manualCheckAsync: 开始执行")
        isSimulating = true
        monitorStatus = "检查中..."

        print("[UsageReminderTest] 🔧 执行手动触发检查")
        UsageReminderManager.shared.manualCheck()
        monitorStatus = "已手动触发检查"

        // 短暂延迟确保操作完成
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
        monitorStatus = "监测中..."
        isSimulating = false
        print("[UsageReminderTest] ✅ 检查完成")
    }

    private func resetInactivityStateAsync() async {
        guard !isSimulating else {
            print("[METHOD] 🚫 resetInactivityStateAsync: 已在执行中，忽略")
            return
        }
        print("[METHOD] 🟢 resetInactivityStateAsync: 开始执行")
        isSimulating = true
        monitorStatus = "重置中..."

        print("[UsageReminderTest] 🔄 执行手动重置久未使用状态")
        UsageReminderManager.shared.resetInactivityState()
        monitorStatus = "已重置状态"

        // 短暂延迟确保操作完成
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
        monitorStatus = "监测中..."
        isSimulating = false
        print("[UsageReminderTest] ✅ 重置完成")
    }

    private func manualCheck() {
        print("[UsageReminderTest] 🔧 手动触发检查")
        UsageReminderManager.shared.manualCheck()
        monitorStatus = "已手动触发检查"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            monitorStatus = "监测中..."
        }
    }
}

struct TodoRowView: View {
    let todo: TodoItem
    @ObservedObject private var todoManager = TodoManager.shared

    var body: some View {
        HStack {
            Button(action: {
                todoManager.toggleTodo(todo)
            }) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(todo.isCompleted ? .green : .gray)
            }

            Text(todo.text)
                .strikethrough(todo.isCompleted)
                .foregroundColor(todo.isCompleted ? .secondary : .primary)
        }
        .contextMenu {
            Button(role: .destructive) {
                print("[TodoRowView] 🗑️ 长按删除Todo: \(todo.id)")
                todoManager.deleteTodo(by: todo.id)
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                print("[TodoRowView] 🗑️ 滑动删除Todo: \(todo.id)")
                todoManager.deleteTodo(by: todo.id)
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
    }
}

// MARK: - AI配置区域
struct AIConfigSection: View {
    @State private var apiKey: String = ""
    @State private var apiBaseURL: String = "https://api.deepseek.com/v1/chat/completions"
    @State private var modelName: String = "deepseek-chat"
    @State private var showAPIKey: Bool = false
    
    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                // API密钥
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("API密钥")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Button {
                            showAPIKey.toggle()
                        } label: {
                            Image(systemName: showAPIKey ? "eye.slash.fill" : "eye.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if showAPIKey {
                        TextField("输入API密钥", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onChange(of: apiKey) { oldValue, newValue in
                                UserDefaults.standard.set(newValue, forKey: "aiApiKey")
                            }
                    } else {
                        SecureField("输入API密钥", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onChange(of: apiKey) { oldValue, newValue in
                                UserDefaults.standard.set(newValue, forKey: "aiApiKey")
                            }
                    }
                    
                    Text("支持DeepSeek、OpenAI等API")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // API地址
                VStack(alignment: .leading, spacing: 4) {
                    Text("API地址")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField("API地址", text: $apiBaseURL)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onChange(of: apiBaseURL) { oldValue, newValue in
                            UserDefaults.standard.set(newValue, forKey: "aiApiBaseURL")
                        }
                    
                    Text("DeepSeek: https://api.deepseek.com/v1/chat/completions")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("OpenAI: https://api.openai.com/v1/chat/completions")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // 模型名称
                VStack(alignment: .leading, spacing: 4) {
                    Text("模型名称")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField("模型名称", text: $modelName)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onChange(of: modelName) { oldValue, newValue in
                            UserDefaults.standard.set(newValue, forKey: "aiModelName")
                        }
                    
                    Text("DeepSeek: deepseek-chat")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("OpenAI: gpt-3.5-turbo 或 gpt-4")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("AI聊天配置")
        } footer: {
            Text("配置AI API后，可以在主页与桌宠进行对话。桌宠会根据当前状态和情绪，用可爱的口吻回复你。")
                .font(.caption2)
        }
        .onAppear {
            // 加载已保存的配置
            apiKey = UserDefaults.standard.string(forKey: "aiApiKey") ?? ""
            apiBaseURL = UserDefaults.standard.string(forKey: "aiApiBaseURL") ?? "https://api.deepseek.com/v1/chat/completions"
            modelName = UserDefaults.standard.string(forKey: "aiModelName") ?? "deepseek-chat"
        }
    }
}

// MARK: - 状态消息管理区域
struct StateMessageSection: View {
    @StateObject private var messageManager = StateMessageManager.shared
    @State private var selectedState: PetState = .happy
    @State private var isGenerating = false
    @State private var generateCount: Int = 5
    @State private var showMessages = false
    @State private var maxMessagesPerState: Int = 20
    
    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                // 状态选择
                VStack(alignment: .leading, spacing: 4) {
                    Text("选择状态")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("状态", selection: $selectedState) {
                        ForEach(PetState.allCases) { state in
                            Text(stateDescription(state)).tag(state)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                // 生成数量
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("生成数量")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text("\(generateCount)条")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Stepper("", value: $generateCount, in: 3...10)
                }
                
                // 最大消息数设置
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("每个状态最大消息数")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text("\(maxMessagesPerState)条")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Stepper("", value: $maxMessagesPerState, in: 5...50, step: 5)
                        .onChange(of: maxMessagesPerState) { oldValue, newValue in
                            messageManager.maxMessagesPerState = newValue
                        }
                    
                    Text("超过此数量时，生成新消息会自动删除旧消息")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // 生成按钮
                Button(action: {
                    print("[StateMessageSection] 🎯 点击生成按钮")
                    generateMessages()
                }) {
                    HStack {
                        if isGenerating {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text(isGenerating ? "正在生成..." : "AI生成消息")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isGenerating ? Color.gray.opacity(0.3) : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isGenerating)
                .buttonStyle(.plain)
                
                // 查看消息按钮
                Button(action: {
                    print("[StateMessageSection] 📋 点击查看消息按钮")
                    // 确保在主线程且sheet未显示时打开
                    if !showMessages {
                        DispatchQueue.main.async {
                            showMessages = true
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "list.bullet")
                        Text("查看当前状态的消息")
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(messageManager.getMessages(for: selectedState).count)条")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("最多\(maxMessagesPerState)条")
                                .font(.caption2)
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 4)
        } header: {
            Text("状态消息管理")
        } footer: {
            VStack(alignment: .leading, spacing: 4) {
                Text("使用AI为每个状态生成多条不同的消息，让桌宠的回复更加生动多样。每次切换状态时，会从对应状态的消息中随机选择一条显示。")
                    .font(.caption2)
                
                Text("每个状态最多保存\(maxMessagesPerState)条消息，超过后会自动删除最旧的。可以在上方调整最大消息数（5-50条）。")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $showMessages) {
            StateMessageListView(state: selectedState)
                .presentationDetents([.large])
        }
        .onAppear {
            // 加载当前的最大消息数设置
            maxMessagesPerState = messageManager.maxMessagesPerState
        }
    }
    
    private func stateDescription(_ state: PetState) -> String {
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
    
    private func generateMessages() {
        guard !isGenerating else {
            print("[StateMessageSection] ⚠️ 已在生成中，忽略重复调用")
            return
        }
        
        print("[StateMessageSection] 🚀 开始生成消息，状态: \(selectedState), 数量: \(generateCount)")
        isGenerating = true
        Task {
            do {
                let messages = try await AIService.shared.generateStateMessages(
                    for: selectedState,
                    count: generateCount
                )
                
                await MainActor.run {
                    // 创建 StateMessage 对象，为每条消息添加稍微不同的时间戳
                    var baseTime = Date()
                    let stateMessages = messages.enumerated().map { index, content in
                        // 每条消息间隔0.1秒，这样时间戳会略有不同
                        let messageTime = baseTime.addingTimeInterval(Double(index) * 0.1)
                        return StateMessage(
                            state: selectedState,
                            content: content,
                            createdAt: messageTime,
                            source: .aiGenerated
                        )
                    }
                    
                    // 批量添加消息（会自动处理最大数量限制）
                    messageManager.addMessages(stateMessages)
                    isGenerating = false
                    print("[StateMessageSection] ✅ 成功生成\(messages.count)条消息")
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    print("[StateMessageSection] ❌ 生成消息失败: \(error)")
                }
            }
        }
    }
}

// MARK: - 状态消息列表视图
struct StateMessageListView: View {
    @ObservedObject private var messageManager = StateMessageManager.shared
    let state: PetState
    @Environment(\.dismiss) private var dismiss
    
    var messages: [StateMessage] {
        // 按创建时间排序（最新的在前）
        messageManager.getMessages(for: state).sorted { $0.createdAt > $1.createdAt }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(messages) { message in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(message.content)
                            .font(.body)
                        
                        HStack(spacing: 6) {
                            // 来源
                            Text(message.source.rawValue)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            // 创建时间
                            Text("· 创建: \(formatDate(message.createdAt))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            // 使用统计
                            if message.usedCount > 0 {
                                Text("· 使用\(message.usedCount)次")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                if let lastUsed = message.lastUsed {
                                    Text("· 最后: \(formatDate(lastUsed))")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text("· 未使用")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .contextMenu {
                        Button(role: .destructive) {
                            print("[StateMessageListView] 🗑️ 长按删除消息: \(message.id)")
                            messageManager.deleteMessage(message.id)
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            print("[StateMessageListView] 🗑️ 滑动删除消息: \(message.id)")
                            messageManager.deleteMessage(message.id)
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("\(stateDescription(state))状态消息")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !messages.isEmpty {
                        Menu {
                            Button(role: .destructive) {
                                // 删除该状态的所有消息
                                for message in messages {
                                    messageManager.deleteMessage(message.id)
                                }
                            } label: {
                                Label("删除全部", systemImage: "trash.fill")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func stateDescription(_ state: PetState) -> String {
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "昨天 \(formatter.string(from: date))"
        } else {
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}

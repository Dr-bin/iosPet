//
//  TodoManager.swift
//  iosPet
//
//  Todo 列表管理器
//

import Foundation
import WidgetKit

final class TodoManager: ObservableObject {
    static let shared = TodoManager()
    private init() {
        loadTodos()
    }
    
    @Published var todos: [TodoItem] = []
    
    private let todosKey = AppGroupKeys.sharedTodosKey
    
    // MARK: - 添加 Todo
    func addTodo(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let newTodo = TodoItem(text: text)
        todos.append(newTodo)
        saveTodos()
        syncToWidget()
    }
    
    // MARK: - 删除 Todo
    func deleteTodo(at offsets: IndexSet) {
        todos.remove(atOffsets: offsets)
        saveTodos()
        syncToWidget()
    }
    
    // MARK: - 通过ID删除 Todo
    func deleteTodo(by id: UUID) {
        todos.removeAll { $0.id == id }
        saveTodos()
        syncToWidget()
        print("[TodoManager] 🗑️ 删除Todo: \(id)")
    }
    
    // MARK: - 切换完成状态
    func toggleTodo(_ todo: TodoItem) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            todos[index].isCompleted.toggle()
            saveTodos()
            syncToWidget()
        }
    }
    
    // MARK: - 保存到 App Group
    private func saveTodos() {
        guard let defaults = UserDefaults(suiteName: AppGroupKeys.suiteName) else {
            print("[TodoManager] ❌ 无法访问 App Group")
            return
        }

        if let encoded = try? JSONEncoder().encode(todos) {
            defaults.set(encoded, forKey: todosKey)
            defaults.synchronize()
        } else {
            print("[TodoManager] ❌ 保存 Todo 数据失败")
        }
    }
    
    // MARK: - 从 App Group 加载
    private func loadTodos() {
        guard let defaults = UserDefaults(suiteName: AppGroupKeys.suiteName) else {
            print("[TodoManager] ❌ 无法访问 App Group")
            todos = []
            return
        }

        if let data = defaults.data(forKey: todosKey),
           let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) {
            todos = decoded
        } else {
            todos = []
        }
    }
    
    // MARK: - 同步到 Widget
    private func syncToWidget() {
        DispatchQueue.main.async {
            WidgetCenter.shared.reloadTimelines(ofKind: "PetWidget")
            WidgetCenter.shared.reloadAllTimelines()

            // 延迟再刷新一次确保更新
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                WidgetCenter.shared.reloadTimelines(ofKind: "PetWidget")
            }
        }
    }
}


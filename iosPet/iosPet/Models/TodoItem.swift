//
//  TodoItem.swift
//  iosPet
//
//  Todo 列表项模型
//

import Foundation

struct TodoItem: Codable, Identifiable, Hashable {
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



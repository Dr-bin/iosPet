//
//  MessageLibrary.swift
//  iosPet
//

import Foundation

enum MessageCategory: String, Codable, CaseIterable {
    case healthReminder
    case sportEncourage
    case studyPraise
    case achievement
    case dailyCare
}

struct MessageItem: Identifiable, Codable {
    let id: UUID
    let category: MessageCategory
    let content: String
    let lastUsed: Date?
    let usedCount: Int
    let source: MessageSource
}

enum MessageSource: String, Codable {
    case builtin
    case aiGenerated
    case userCustom
}


//
//  MessageLibraryManager.swift
//  iosPet
//

import Foundation

final class MessageLibraryManager: ObservableObject {
    static let shared = MessageLibraryManager()
    private init() {}

    @Published private(set) var messages: [MessageItem] = []
    private let aiService: AIServiceProtocol = AIServiceManager()

    func load(from data: Data) throws {
        messages = try JSONDecoder().decode([MessageItem].self, from: data)
    }

    func randomMessage(for category: MessageCategory) -> MessageItem? {
        messages
            .filter { $0.category == category }
            .sorted { ($0.lastUsed ?? .distantPast) < ($1.lastUsed ?? .distantPast) }
            .randomElement()
    }

    func markUsed(_ id: UUID) {
        guard let idx = messages.firstIndex(where: { $0.id == id }) else { return }
        var item = messages[idx]
        item = MessageItem(
            id: item.id,
            category: item.category,
            content: item.content,
            lastUsed: Date(),
            usedCount: item.usedCount + 1,
            source: item.source
        )
        messages[idx] = item
    }

    func refreshViaAI() async {
        do {
            let updated = try await aiService.refreshMessages(current: messages)
            await MainActor.run { [weak self] in
                self?.messages = updated
            }
        } catch {
            print("AI refresh failed: \(error)")
        }
    }
}


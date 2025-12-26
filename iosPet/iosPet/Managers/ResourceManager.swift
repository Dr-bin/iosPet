//
//  ResourceManager.swift
//  iosPet
//
//  统一加载与查询表情资源
//

import Foundation

final class ResourceManager {
    static let shared = ResourceManager()
    private init() {}

    private var resources: [ExpressionResource] = []

    func load(from data: Data) throws {
        let decoder = JSONDecoder()
        self.resources = try decoder.decode([ExpressionResource].self, from: data)
    }

    func resources(for state: PetState, carrier: PetCarrier) -> [ExpressionResource] {
        resources
            .filter { $0.state == state && $0.carrier == carrier }
            .sorted { $0.priority < $1.priority }
    }

    func randomResource(for state: PetState, carrier: PetCarrier) -> ExpressionResource? {
        resources(for: state, carrier: carrier).randomElement()
    }
}


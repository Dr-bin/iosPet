//
//  ExpressionResource.swift
//  iosPet
//
//  表情资源模型：统一描述不同载体的资源
//

import Foundation

enum PetCarrier: String, Codable, CaseIterable {
    case widget
    case appIcon
    case inApp
    case notification
}

struct ExpressionResource: Identifiable, Codable {
    let id: String                     // 唯一资源ID
    let state: PetState                // 对应宠物状态
    let carrier: PetCarrier            // 载体类型
    let display: String                // 临时资源（Emoji/颜文字）
    let priority: Int                  // 同状态下的优先级
    let triggers: [ResourceTrigger]    // 触发条件

    // 预留真实素材字段
    let imageName: String?
    let animationName: String?
    let soundName: String?
}

struct ResourceTrigger: Codable, Hashable {
    let context: String          // 如 "screenTimeHigh"、"workout" 等
    let timeRange: ClosedRange<Int>? // 可选的时间范围（分钟）
}


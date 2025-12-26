//
//  IconManager.swift
//  iosPet
//
//  图标管理器 - 为每个状态提供多个图标选项
//

import Foundation
import SwiftUI

final class IconManager {
    static let shared = IconManager()
    
    private init() {}
    
    // MARK: - 获取状态的随机图标
    func getIcon(for state: PetState) -> String {
        let icons = getIcons(for: state)
        return icons.randomElement() ?? icons.first ?? "😺"
    }
    
    // MARK: - 获取状态的所有图标
    func getIcons(for state: PetState) -> [String] {
        switch state {
        case .happy:
            return ["😸", "😺", "😊", "😄", "😃", "🥰", "😍", "🤗", "😻", "😽"]
        case .cheering:
            return ["😺", "🎉", "🎊", "👏", "🙌", "🤗", "😄", "😃", "✨", "🌟"]
        case .celebrating:
            return ["🎉😺", "🎊😸", "🎈😄", "🎁😊", "🏆😃", "🥳", "🎊", "🎉", "✨", "🌟"]
        case .dizzy:
            return ["😵‍💫", "😵", "😰", "😨", "😧", "🤯", "😱", "😓", "😥", "😪"]
        case .sleepy:
            return ["😴", "😪", "😵", "🥱", "😑", "😌", "😛", "😜", "😝", "😋"]
        case .tiredEyes:
            return ["🥺", "😢", "😭", "😰", "😨", "😧", "😓", "😥", "😪", "😵"]
        case .running:
            return ["🏃‍♂️", "🏃‍♀️", "🏃", "💨", "⚡", "🔥", "🌪️", "🚀", "🏃‍♂️💨", "🏃‍♀️💨"]
        case .jumping:
            return ["🤸‍♀️", "🤸‍♂️", "🤸", "🦘", "🐰", "⚡", "💫", "✨", "🌟", "⭐"]
        case .workout:
            return ["🏋️‍♀️", "🏋️‍♂️", "🏋️", "💪", "🔥", "⚡", "🎯", "🏆", "🥇", "💯"]
        case .reading:
            return ["📖😺", "📚😸", "📖", "📚", "📝", "✍️", "🤓", "👓", "📖✨", "📚🌟"]
        case .thinking:
            return ["🤔", "💭", "🧠", "💡", "🔍", "🔎", "🤓", "👓", "💭✨", "🧠💡"]
        case .bored:
            return ["🥱", "😑", "😐", "😶", "😒", "🙄", "😏", "😌", "😪", "😴"]
        case .overuseWarning:
            return ["⚠️😵", "⚠️", "🚨", "⛔", "🛑", "🔴", "⚠️😰", "⚠️😨", "⚠️😓", "⚠️😥"]
        case .restNeeded:
            return ["😪", "😴", "😵", "😌", "😑", "😐", "😶", "😒", "😓", "😥"]
        }
    }
    
    // MARK: - 获取状态的颜色主题
    func getColorTheme(for state: PetState) -> (primary: Color, secondary: Color, background: Color) {
        switch state {
        case .happy, .cheering, .celebrating:
            return (.yellow, .orange, Color.yellow.opacity(0.15))
        case .dizzy, .tiredEyes:
            return (.purple, .pink, Color.purple.opacity(0.15))
        case .sleepy, .restNeeded:
            return (.blue, .indigo, Color.blue.opacity(0.15))
        case .running, .jumping, .workout:
            return (.green, .mint, Color.green.opacity(0.15))
        case .reading, .thinking:
            return (.cyan, .teal, Color.cyan.opacity(0.15))
        case .bored:
            return (.gray, .secondary, Color.gray.opacity(0.15))
        case .overuseWarning:
            return (.red, .orange, Color.red.opacity(0.15))
        }
    }
}


//
//  SyncManager.swift
//  iosPet
//

import Foundation
import WidgetKit
import SwiftUI

final class SyncManager: ObservableObject {
    static let shared = SyncManager()
    private init() {}

    @Published private(set) var carrierStates: [CarrierSyncState] = []

    func updateAllCarriers(to state: PetState) {
        // 同步到 App Group，供 Widget 读取
        let emotion = state.emotion

        // 保存情绪到 App Group
        guard let defaults = UserDefaults(suiteName: AppGroupKeys.suiteName) else {
            print("[SyncManager] ❌ 无法访问 App Group: \(AppGroupKeys.suiteName)")
            return
        }

        // 写入新值
        defaults.set(emotion.rawValue, forKey: AppGroupKeys.sharedEmotionKey)
        
        // 保存当前状态的消息
        let message = StateMessageManager.shared.getMessage(for: state)
        defaults.set(message, forKey: AppGroupKeys.sharedStateMessageKey)
        
        // 保存当前状态的图标
        let icon = IconManager.shared.getIcon(for: state)
        defaults.set(icon, forKey: AppGroupKeys.sharedIconKey)
        
        defaults.synchronize()

        // 立即刷新 Widget
        updateWidget(state: state)

        record(state: state)
    }

    private func updateWidget(state: PetState) {
        // 在主线程上刷新 Widget
        DispatchQueue.main.async {
            WidgetCenter.shared.reloadTimelines(ofKind: "PetWidget")
            WidgetCenter.shared.reloadAllTimelines()

            // 延迟再刷新一次确保更新
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                WidgetCenter.shared.reloadTimelines(ofKind: "PetWidget")
            }
        }
    }


    private func record(state: PetState) {
        let entry = CarrierSyncState(id: UUID(), carrier: .widget, lastState: state, lastUpdated: .init(), lastSuccess: true)
        carrierStates.append(entry)
    }
}



//
//  PetWidgetBundle.swift
//  PetWidget
//
//  Created by admin on 2025/12/23.
//

import WidgetKit
import SwiftUI

@main
struct PetWidgetBundle: WidgetBundle {
    var body: some Widget {
        PetWidget()
        // 如果需要 Control Widget 和 Live Activity，可以取消下面的注释
        // PetWidgetControl()
        // PetWidgetLiveActivity()
    }
}

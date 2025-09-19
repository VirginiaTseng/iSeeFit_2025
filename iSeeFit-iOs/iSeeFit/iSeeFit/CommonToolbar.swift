//
//  CommonToolbar.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-02-21.
//

import SwiftUI

struct CommonToolbar: ToolbarContent {
    var notificationAction: () -> Void
    var darkModeAction: () -> Void
    var voiceAction: () -> Void
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 15) {
                Button(action: notificationAction) {
                    Image(systemName: "bell.fill")
                        .foregroundColor(.purple)
                }
                
                Button(action: darkModeAction) {
                    Image(systemName: "moon.fill")
                        .foregroundColor(.purple)
                }
                
                Button(action: voiceAction) {
                    Image(systemName: "mic.fill")
                        .foregroundColor(.purple)
                }
            }
        }
    }
}

// 创建一个视图修饰符
extension View {
    func commonToolbar(
        notificationAction: @escaping () -> Void = {},
        darkModeAction: @escaping () -> Void = {},
        voiceAction: @escaping () -> Void = {}
    ) -> some View {
        self.toolbar {
            CommonToolbar(
                notificationAction: notificationAction,
                darkModeAction: darkModeAction,
                voiceAction: voiceAction
            )
        }
    }
}

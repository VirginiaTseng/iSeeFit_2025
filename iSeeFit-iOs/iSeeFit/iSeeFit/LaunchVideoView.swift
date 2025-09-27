//
//  LaunchVideoView.swift
//  iSeeFit
//
//  Created by VirginiaZheng on 2025-09-25.
//

import SwiftUI
import AVKit

struct LaunchVideoView: View {
    let onFinish: () -> Void
    @State private var player: AVPlayer? = {
        guard let url = Bundle.main.url(forResource: "output_vertical", withExtension: "mp4") else { return nil }
        let p = AVPlayer(url: url)
        p.isMuted = true            // 引导视频默认静音，体验和过审更友好
        return p
    }()
    @Environment(\.scenePhase) private var scenePhase
    @State private var isReady = false

    var body: some View {
        ZStack {
            if let player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .aspectRatio(contentMode: .fill)  // 铺满（会“居中裁切”少量画面）
                    //.clipped()
                    .onAppear {
                        // 循环播放
                        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                                               object: player.currentItem, queue: .main) { _ in
                            player.seek(to: .zero)
                            player.play()
                        }
                        player.play()
                        isReady = true
                    }
                    .onDisappear {
                        player.pause()
                    }
                    // App 切前后台时自动暂停/恢复
                    .onChange(of: scenePhase) { phase in
                        if phase == .active { player.play() } else { player.pause() }
                    }
            } else {
                Color.black.ignoresSafeArea()
                Text("Loading…").foregroundStyle(.white)
            }

            // 顶部右侧：跳过
            VStack {
                HStack {
                    Spacer()
                    Button("Skip") { onFinish() }
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.top, 12).padding(.trailing, 12)
                }
                Spacer()
                // 底部：开始体验
                Button {
                    onFinish()
                } label: {
                    Text("Start")
                        .font(.headline)
                        .padding(.horizontal, 24).padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                .padding(.bottom, 36)
            }
            .opacity(isReady ? 1 : 0) // 视频就绪再显示按钮
        }
        .statusBarHidden(true) // 可选：沉浸式
    }
}

//
//struct LaunchVideoView_Previews: PreviewProvider {
//    static var previews: some View {
//        LaunchVideoView(onFinish: { hasSeenIntro = true })
//    }
//}

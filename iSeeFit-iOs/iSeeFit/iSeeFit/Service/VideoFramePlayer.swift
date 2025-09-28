//
//  VideoFramePlayer.swift
//  iSeeFit
//
//  Created by VirginiaZheng on 2025-09-27.
//

import SwiftUI
import Combine

class VideoFramePlayer: ObservableObject {
    @Published var frames: [UIImage] = []
    @Published var currentFrame: UIImage?
    @Published var isPlaying = false
    @Published var currentIndex = 0
    @Published var progress: Double = 0.0
    
    private var timer: Timer?
    private let fps: Double = 30.0
    
    func loadFrames(_ frames: [UIImage]) {
        self.frames = frames
        currentIndex = 0
        currentFrame = frames.first
        progress = 0.0
    }
    
    func play() {
        guard !frames.isEmpty else { return }
        
        isPlaying = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0/fps, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            self.currentIndex = (self.currentIndex + 1) % self.frames.count
            self.currentFrame = self.frames[self.currentIndex]
            self.progress = Double(self.currentIndex) / Double(self.frames.count)
        }
    }
    
    func pause() {
        isPlaying = false
        timer?.invalidate()
        timer = nil
    }
    
    func stop() {
        pause()
        currentIndex = 0
        currentFrame = frames.first
        progress = 0.0
    }
    
    func seek(to index: Int) {
        guard index >= 0 && index < frames.count else { return }
        
        currentIndex = index
        currentFrame = frames[index]
        progress = Double(index) / Double(frames.count)
    }
}

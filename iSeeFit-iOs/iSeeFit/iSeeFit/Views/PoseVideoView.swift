//
//  PoseVideoView.swift
//  iSeeFit
//
//  Created by VirginiaZheng on 2025-09-27.
//

import SwiftUI
import PhotosUI

struct PoseVideoView: View {
    // Pose detection
    @StateObject private var api = VideoFrameAPI()
    @StateObject private var player = VideoFramePlayer()
    @State private var isProcessing = false
    @State private var selectedVideo: URL?
    @State private var showVideoPicker = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                  

                  // Video display area
                  if let frame = player.currentFrame {
                      Image(uiImage: frame)
                          .resizable()
                          .aspectRatio(contentMode: .fit)
                          .frame(
                              maxWidth: player.isPortraitVideo ? 300 : .infinity,
                              maxHeight: player.isPortraitVideo ? 500 : 300
                          )
                          .cornerRadius(12)
                          .shadow(radius: 8)
                          .onTapGesture {
                              if player.isPlaying {
                                  player.pause()
                              } else {
                                  player.play()
                              }
                          }
                } else if isProcessing {
                    VStack {
                        ProgressView("Processing...")
                            .scaleEffect(1.2)
                        Text("Analyzing poses in video")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(height: 300)
                } else {
                    VStack {
                        Image(systemName: "video.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Select video to start pose detection")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(height: 300)
                }
                
              // Control buttons
                if !player.frames.isEmpty {
                    VStack(spacing: 16) {
                        // Progress bar
                        VStack {
                            HStack {
                                Text("Progress")
                                Spacer()
                                Text("\(player.currentIndex + 1) / \(player.frames.count)")
                            }
                            .font(.caption)
                            
                            ProgressView(value: player.progress)
                                .progressViewStyle(LinearProgressViewStyle())
                        }
                        
                        // Playback controls
                        HStack(spacing: 20) {
                            Button(action: { player.stop() }) {
                                Image(systemName: "stop.fill")
                                    .font(.title2)
                            }
                            
                            Button(action: {
                                if player.isPlaying {
                                    player.pause()
                                } else {
                                    player.play()
                                }
                            }) {
                                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.title)
                            }
                            
                            Button(action: { showVideoPicker = true }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                            }
                            
                            Button(action: { clearVideo() }) {
                                Image(systemName: "trash.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)
                } else {
                    // Select video button
                    Button(action: { showVideoPicker = true }) {
                        HStack {
                            Image(systemName: "video.badge.plus")
                            Text("Select Video")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                }
                
                // Error message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
            //.navigationTitle("Pose Detection")
            .sheet(isPresented: $showVideoPicker) {
                VideoPicker(selectedVideo: $selectedVideo)
            }
            .onChange(of: selectedVideo) { video in
                if let video = video {
                    processVideo(video)
                }
            }
        }
    }
    
    private func processVideo(_ videoURL: URL) {
        isProcessing = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await api.processVideoToFrames(videoURL)
                
                // Decode frames
                let frames: [UIImage] = response.frames?.compactMap { base64String in
                    guard let data = Data(base64Encoded: base64String) else { return nil }
                    return UIImage(data: data)
                } ?? []
                
                await MainActor.run {
                    player.loadFrames(frames)
                    isProcessing = false
                }
                
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isProcessing = false
                }
            }
        }
    }
    
    private func clearVideo() {
        // Stop playback
        player.stop()
        
        // Clear frame data
        player.frames = []
        player.currentFrame = nil
        
        // Reset video properties
        player.videoAspectRatio = 1.0
        player.isPortraitVideo = false
        
        // Clear selected video
        selectedVideo = nil
        
        // Clear error message
        errorMessage = nil
        
        print("DEBUG: PoseVideoView - Video cleared successfully")
    }
}

// Video picker
struct VideoPicker: UIViewControllerRepresentable {
    @Binding var selectedVideo: URL?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.mediaTypes = ["public.movie"]
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: VideoPicker
        
        init(_ parent: VideoPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let videoURL = info[.mediaURL] as? URL {
                parent.selectedVideo = videoURL
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

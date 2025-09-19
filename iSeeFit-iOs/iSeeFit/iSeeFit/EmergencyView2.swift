//
//  EmergencyView2.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-02-21.
//



import SwiftUI
import AVFoundation
import CoreMotion
import LocalAuthentication

struct EmergencyView2: View {
    @StateObject private var emergencyManager = EmergencyManager() //waiting for
    @State private var isRecording = false
    @State private var timeRemaining: Int = 60
    @State private var timer: Timer?
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                if isRecording {
                    ZStack {
                        Circle()
                            .stroke(Color.red.opacity(0.2), lineWidth: 6)
                            .frame(width: 160, height: 160)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(timeRemaining) / 60.0)
                            .stroke(Color.red, lineWidth: 6)
                            .frame(width: 160, height: 160)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: timeRemaining)
                        
                        VStack {
                            Text("\(timeRemaining)")
                                .font(.system(size: 40, weight: .bold))
                            Text("seconds")
                                .font(.caption)
                        }
                        .foregroundColor(.red)
                    }
                    .padding(.bottom, 30)
                }
                
                // 紧急按钮
                EmergencyButton(
                    isRecording: $isRecording,
                    onLongPressStart: {
                        startEmergencyMode()
                    },
                    onLongPressEnd: {
                        // 用户释放按钮，但不停止记录
                        // 只有验证成功才停止
                    }
                )
                
                Spacer()
                
                if isRecording {
                    // 验证按钮
                    Button(action: {
                        authenticateUser()
                    }) {
                        Text("Verify to Cancel")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                
                // 说明文字
                VStack(spacing: 16) {
                    Text("Emergency Button")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Press and hold to activate emergency mode.\nVerify your identity within 1 minute to cancel.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                }
                .padding(.bottom, 50)
            }
        }
    }
    
    private func startEmergencyMode() {
           isRecording = true
        //   emergencyManager.startEmergencyRecording()
           
           // 开始倒计时
           timeRemaining = 60
           timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
               if timeRemaining > 0 {
                   timeRemaining -= 1
               } else {
                   // 时间到，发送数据
               //    emergencyManager.sendEmergencyData()
                   stopEmergencyMode()
               }
           }
       }
       
       private func stopEmergencyMode() {
           isRecording = false
//           emergencyManager.stopEmergencyRecording()
           timer?.invalidate()
           timer = nil
       }
       
       private func authenticateUser() {
           let context = LAContext()
           var error: NSError?
           
           if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
               context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Verify your identity to cancel emergency mode") { success, error in
                   DispatchQueue.main.async {
                       if success {
                           stopEmergencyMode()
                       }
                   }
               }
           }
       }
   }

// 紧急按钮组件
struct EmergencyButton: View {
    @Binding var isRecording: Bool
    let onLongPressStart: () -> Void
    let onLongPressEnd: () -> Void
    @State private var isPressed = false
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        Circle()
            .fill(isRecording ? Color.red : Color.red.opacity(0.9))
            .frame(width: 120, height: 120)
            .overlay(
                ZStack {
                    // 脉动动画
                    if isRecording {
                        ForEach(0..<3) { i in
                            Circle()
                                .stroke(Color.red.opacity(0.5), lineWidth: 2)
                                .frame(width: 120, height: 120)
                                .scaleEffect(CGFloat(i + 1) * 0.3 + 1)
                                .opacity(1 - CGFloat(i) * 0.3)
                                .animation(
                                    Animation.easeInOut(duration: 1)
                                        .repeatForever(autoreverses: false)
                                        .delay(Double(i) * 0.3),
                                    value: isRecording
                                )
                        }
                    }
                    
                    // 按压进度环
                    if isPressed {
                        Circle()
                            .trim(from: 0, to: 1)
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 110, height: 110)
                            .rotationEffect(.degrees(-90))
                    }
                    
                    // 图标和文字
                    VStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                        Text(isRecording ? "Recording" : (isPressed ? "Hold..." : "Hold"))
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
            )
            .scaleEffect(scale)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isPressed = true
                                scale = 0.9
                            }
                            // 延迟启动紧急模式
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                if isPressed {
                                    onLongPressStart()
                                }
                            }
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isPressed = false
                            scale = 1.0
                        }
                        onLongPressEnd()
                    }
            )
            .shadow(radius: 5)
    }
}


// 紧急管理器
class EmergencyManager: ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    private let motionManager = CMMotionManager()
    private var emergencyTimer: Timer?
    private var motionData: [CMDeviceMotion] = []
    
    init() {
        setupAudioRecorder()
        setupMotionManager()
    }
    
    private func setupAudioRecorder() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord)
            try audioSession.setActive(true)
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentsPath.appendingPathComponent("emergency_recording.m4a")
            
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.prepareToRecord()
        } catch {
            print("Audio recorder setup failed: \(error)")
        }
    }
    
    private func setupMotionManager() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.1
        }
    }
    
    func startEmergencyRecording() {
        // 开始录音
        audioRecorder?.record()
        
        // 开始收集运动数据
        motionData.removeAll()
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            if let motion = motion {
                self?.motionData.append(motion)
            }
        }
        
        // 设置一分钟计时器
        emergencyTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: false) { [weak self] _ in
            self?.sendEmergencyData()
        }
    }
    
    func stopEmergencyRecording() {
        audioRecorder?.stop()
        motionManager.stopDeviceMotionUpdates()
        emergencyTimer?.invalidate()
    }
    
    func sendEmergencyData() {
        // 实现发送数据的逻辑
        let audioFileURL = getAudioFileURL()
        let motionDataSummary = processMotionData()
        let currentLocation = getCurrentLocation()
        
        // 这里应该实现实际的发送逻辑
        print("Sending emergency data to contacts...")
        print("Audio file: \(audioFileURL)")
        print("Motion data: \(motionDataSummary)")
        print("Location: \(currentLocation)")
    }
    
    private func getAudioFileURL() -> URL {
        // 返回录音文件的URL
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("emergency_recording.m4a")
    }
    
    private func processMotionData() -> String {
        // 处理和总结运动数据
        "Motion data collected: \(motionData.count) samples"
    }
    
    private func getCurrentLocation() -> String {
        // 获取当前位置
        "Location data would be included here"
    }
    
    deinit {
        stopEmergencyRecording()
    }
}

// 预览
struct EmergencyView2_Previews: PreviewProvider {
    static var previews: some View {
        EmergencyView2()
    }
} 

//
//  AudioManager.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-02-18.
//

import Speech
import AVFoundation
import WatchConnectivity

class AudioManager: NSObject, AVAudioRecorderDelegate {
    private var audioRecorder: AVAudioRecorder?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.record)
        try? audioSession.setActive(true)
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("recording.m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        audioRecorder = try? AVAudioRecorder(url: audioFilename, settings: settings)
        audioRecorder?.delegate = self
        audioRecorder?.record()
    }
    
    func stopRecordingAndRecognize() {
        audioRecorder?.stop()
        
        guard let audioFileURL = audioRecorder?.url else { return }
          let recognitionRequest = SFSpeechURLRecognitionRequest(url: audioFileURL)
        
        speechRecognizer?.recognitionTask(with: recognitionRequest) { (result, error) in
                    guard let result = result?.bestTranscription.formattedString else { return }
            
            // 发送识别结果到 iPhone
            if WCSession.default.isReachable {
                let message: [String: Any] = ["type": "voice", "text": result]
                               WCSession.default.sendMessage(message, replyHandler: { _ in
                                   // 处理成功回调
                               }, errorHandler: { error in
                                   print("发送消息错误: \(error.localizedDescription)")
                               })
            }
        }
    }
}

//
//  VideoView.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-01-20.
//

import SwiftUI
import AVFoundation
import Vision
#if canImport(UIKit)
import UIKit
#endif

struct VideoView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var poseDetector = PoseDetector()
    @State private var selectedWorkout: WorkoutType = .squats
    @State private var isRecording = false
    @State private var showWorkoutSelector = false
    @State private var workoutCount = 0
    @State private var currentPose: PoseType = .unknown
    @State private var poseAccuracy: Float = 0.0
    @State private var showInstructions = true
    
    var body: some View {
        NavigationView {
            ZStack {
                // Camera preview
                CameraPreviewView(session: cameraManager.session)
                    .ignoresSafeArea()
                
                // Overlay UI
                VStack {
                    // Top controls
                    HStack {
                        Button(action: {
                            print("DEBUG: VideoView - workout selector tapped")
                            showWorkoutSelector = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "figure.strengthtraining.traditional")
                                    .font(.title2)
                                Text(selectedWorkout.rawValue)
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(20)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            print("DEBUG: VideoView - instructions toggle tapped")
                            showInstructions.toggle()
                        }) {
                            Image(systemName: showInstructions ? "info.circle.fill" : "info.circle")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    Spacer()
                    
                    // Workout instructions
                    if showInstructions {
                        workoutInstructionsCard()
                    }
                    
                    // Pose detection info
                    poseDetectionCard()
                    
                    // Bottom controls
                    VStack(spacing: 20) {
                        // Camera switch button - moved to top
                        HStack {
                            Spacer()
                            Button(action: {
                                print("DEBUG: VideoView - camera switch tapped")
                                cameraManager.switchCamera()
                            }) {
                                Image(systemName: "camera.rotate")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(15)
                                    .background(Color.black.opacity(0.7))
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                            .padding(.trailing, 20)
                        }
                        
                        // Main control buttons
                        HStack(spacing: 40) {
                            Button(action: {
                                print("DEBUG: VideoView - reset count tapped")
                                workoutCount = 0
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(15)
                                    .background(Color.black.opacity(0.7))
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                            
                            Button(action: {
                                print("DEBUG: VideoView - record toggle tapped")
                                isRecording.toggle()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(isRecording ? Color.red : Color.white)
                                        .frame(width: 80, height: 80)
                                        .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                                    
                                    if isRecording {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.white)
                                            .frame(width: 30, height: 30)
                                    } else {
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 60, height: 60)
                                    }
                                }
                            }
                            
                            // Placeholder for symmetry
                            Circle()
                                .fill(Color.clear)
                                .frame(width: 50, height: 50)
                        }
                    }
                    .padding(.bottom, 40)
                }
                
                // Pose overlay
                if poseDetector.isDetecting {
                    PoseOverlayView(
                        pose: poseDetector.currentPose,
                        accuracy: poseAccuracy
                    )
                }
            }
            .navigationTitle("Fitness Guide")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                print("DEBUG: VideoView - appeared")
                cameraManager.startSession()
                poseDetector.startDetection()
            }
            .onDisappear {
                print("DEBUG: VideoView - disappeared")
                cameraManager.stopSession()
                poseDetector.stopDetection()
            }
            .onReceive(cameraManager.$capturedImage) { image in
                if let image = image {
                    poseDetector.detectPose(in: image)
                }
            }
            .onReceive(poseDetector.$detectedPose) { pose in
                currentPose = pose.type
                poseAccuracy = pose.accuracy
                
                // Check if pose matches selected workout
                if pose.type == selectedWorkout.poseType && pose.accuracy > 0.7 {
                    workoutCount += 1
                    print("DEBUG: VideoView - workout count increased to \(workoutCount)")
                }
            }
        }
        .sheet(isPresented: $showWorkoutSelector) {
            WorkoutSelectorView(selectedWorkout: $selectedWorkout)
        }
    }
    
    // MARK: - UI Components
    private func workoutInstructionsCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundColor(.blue)
                Text("Workout Instructions")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            
            Text(selectedWorkout.instructions)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(2)
        }
        .padding(16)
        .background(Color.black.opacity(0.7))
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }
    
    private func poseDetectionCard() -> some View {
        VStack(spacing: 8) {
            HStack {
                Text("Pose Detection")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text("\(workoutCount)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
            
            HStack {
                Text("Current: \(currentPose.rawValue)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Text("Accuracy: \(Int(poseAccuracy * 100))%")
                    .font(.subheadline)
                    .foregroundColor(poseAccuracy > 0.7 ? .green : .orange)
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.7))
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }
}

// MARK: - Camera Manager
class CameraManager: NSObject, ObservableObject {
    let session = AVCaptureSession()
    @Published var capturedImage: UIImage?
    
    private let videoOutput = AVCaptureVideoDataOutput()
    private let photoOutput = AVCapturePhotoOutput()
    private var currentCameraPosition: AVCaptureDevice.Position = .back
    
    override init() {
        super.init()
        setupCamera()
    }
    
    private func setupCamera() {
        session.beginConfiguration()
        
        // Add video input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCameraPosition),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            print("ERROR: CameraManager - Failed to setup video input")
            return
        }
        
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }
        
        // Add video output
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        }
        
        // Add photo output
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        
        session.commitConfiguration()
        print("DEBUG: CameraManager - Camera setup completed")
    }
    
    func startSession() {
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
            print("DEBUG: CameraManager - Session started")
        }
    }
    
    func stopSession() {
        session.stopRunning()
        print("DEBUG: CameraManager - Session stopped")
    }
    
    func switchCamera() {
        session.beginConfiguration()
        
        // Remove current input
        if let currentInput = session.inputs.first as? AVCaptureDeviceInput {
            session.removeInput(currentInput)
        }
        
        // Switch camera position
        currentCameraPosition = currentCameraPosition == .back ? .front : .back
        
        // Add new input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCameraPosition),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            print("ERROR: CameraManager - Failed to switch camera")
            session.commitConfiguration()
            return
        }
        
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }
        
        session.commitConfiguration()
        print("DEBUG: CameraManager - Camera switched to \(currentCameraPosition == .back ? "back" : "front")")
    }
}

// MARK: - Camera Preview
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.frame
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update preview layer frame if needed
    }
}

// MARK: - Pose Detection
class PoseDetector: NSObject, ObservableObject {
    @Published var isDetecting = false
    @Published var currentPose: DetectedPose = DetectedPose(type: .unknown, accuracy: 0.0)
    @Published var detectedPose: DetectedPose = DetectedPose(type: .unknown, accuracy: 0.0)
    
    private var request: VNDetectHumanBodyPoseRequest?
    
    override init() {
        super.init()
        setupPoseDetection()
    }
    
    private func setupPoseDetection() {
        request = VNDetectHumanBodyPoseRequest { [weak self] request, error in
            guard let self = self else { return }
            
            if let error = error {
                print("ERROR: PoseDetector - Detection failed: \(error)")
                return
            }
            
            self.processPoseResults(request.results)
        }
        print("DEBUG: PoseDetector - Setup completed")
    }
    
    func startDetection() {
        isDetecting = true
        print("DEBUG: PoseDetector - Detection started")
    }
    
    func stopDetection() {
        isDetecting = false
        print("DEBUG: PoseDetector - Detection stopped")
    }
    
    func detectPose(in image: UIImage) {
        guard let cgImage = image.cgImage,
              let request = request else { return }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            print("ERROR: PoseDetector - Failed to perform detection: \(error)")
        }
    }
    
    private func processPoseResults(_ results: [VNObservation]?) {
        guard let observations = results as? [VNHumanBodyPoseObservation], !observations.isEmpty else {
            currentPose = DetectedPose(type: .unknown, accuracy: 0.0)
            return
        }
        
        let observation = observations.first!
        let poseType = classifyPose(from: observation)
        let accuracy = observation.confidence
        
        let detectedPose = DetectedPose(type: poseType, accuracy: accuracy)
        
        DispatchQueue.main.async {
            self.currentPose = detectedPose
            self.detectedPose = detectedPose
        }
        
        print("DEBUG: PoseDetector - Detected pose: \(poseType.rawValue), accuracy: \(accuracy)")
    }
    
    private func classifyPose(from observation: VNHumanBodyPoseObservation) -> PoseType {
        // Simplified pose classification logic
        // In a real app, you would implement more sophisticated pose analysis
        
        do {
            let leftShoulder = try observation.recognizedPoint(.leftShoulder)
            let rightShoulder = try observation.recognizedPoint(.rightShoulder)
            let leftHip = try observation.recognizedPoint(.leftHip)
            let rightHip = try observation.recognizedPoint(.rightHip)
            let leftKnee = try observation.recognizedPoint(.leftKnee)
            let rightKnee = try observation.recognizedPoint(.rightKnee)
            
            // Check if key points are visible
            let keyPoints = [leftShoulder, rightShoulder, leftHip, rightHip, leftKnee, rightKnee]
            let visiblePoints = keyPoints.filter { $0.confidence > 0.5 }
            
            if visiblePoints.count < 4 {
                return .unknown
            }
            
            // Simple squat detection based on knee and hip positions
            let avgKneeY = (leftKnee.location.y + rightKnee.location.y) / 2
            let avgHipY = (leftHip.location.y + rightHip.location.y) / 2
            
            if avgKneeY > avgHipY {
                return .squat
            }
            
            return .standing
            
        } catch {
            print("ERROR: PoseDetector - Failed to extract key points: \(error)")
            return .unknown
        }
    }
}

// MARK: - Data Models
enum WorkoutType: String, CaseIterable {
    case squats = "Squats"
    case pushups = "Push-ups"
    case planks = "Planks"
    case lunges = "Lunges"
    
    var instructions: String {
        switch self {
        case .squats:
            return "Stand with feet shoulder-width apart. Lower your body by bending your knees and hips, keeping your back straight. Return to starting position."
        case .pushups:
            return "Start in a plank position. Lower your chest to the ground by bending your elbows, then push back up to starting position."
        case .planks:
            return "Hold a straight line from head to heels, supporting your weight on your forearms and toes. Keep your core tight."
        case .lunges:
            return "Step forward with one leg, lowering your hips until both knees are bent at 90 degrees. Return to starting position and repeat with other leg."
        }
    }
    
    var poseType: PoseType {
        switch self {
        case .squats, .lunges:
            return .squat
        case .pushups:
            return .pushup
        case .planks:
            return .plank
        }
    }
}

enum PoseType: String, CaseIterable {
    case unknown = "Unknown"
    case standing = "Standing"
    case squat = "Squat"
    case pushup = "Push-up"
    case plank = "Plank"
}

struct DetectedPose {
    let type: PoseType
    let accuracy: Float
}

// MARK: - Pose Overlay
struct PoseOverlayView: View {
    let pose: DetectedPose
    let accuracy: Float
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Pose: \(pose.type.rawValue)")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Accuracy: \(Int(accuracy * 100))%")
                        .font(.subheadline)
                        .foregroundColor(accuracy > 0.7 ? .green : .orange)
                }
                .padding()
                .background(Color.black.opacity(0.7))
                .cornerRadius(8)
                
                Spacer()
            }
            .padding()
        }
    }
}

// MARK: - Workout Selector
struct WorkoutSelectorView: View {
    @Binding var selectedWorkout: WorkoutType
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List(WorkoutType.allCases, id: \.self) { workout in
                Button(action: {
                    selectedWorkout = workout
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(workout.rawValue)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(workout.instructions)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        
                        Spacer()
                        
                        if selectedWorkout == workout {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Select Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Extensions
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            let image = UIImage(cgImage: cgImage)
            DispatchQueue.main.async {
                self.capturedImage = image
            }
        }
    }
}

struct VideoView_Previews: PreviewProvider {
    static var previews: some View {
        VideoView()
    }
}

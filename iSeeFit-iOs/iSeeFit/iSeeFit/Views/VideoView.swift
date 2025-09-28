//
//  VideoView.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-01-20.
//
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
    @State private var debugMode = false
    
    // MARK: - Computed Views
    private var cameraPreview: some View {
        #if canImport(UIKit)
        CameraPreviewView(session: cameraManager.session)
        #else
        Rectangle()
            .fill(Color.black)
            .overlay(
                Text("Camera not available on this platform")
                    .foregroundColor(.white)
            )
        #endif
    }
    
    private var overlayUI: some View {
        VStack {
            topControls
            Spacer()
            bottomUI
        }
    }
    
    private var topControls: some View {
        HStack {
            workoutSelectorButton
            Spacer()
            instructionToggleButton
            debugToggleButton
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private var workoutSelectorButton: some View {
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
    }
    
    private var instructionToggleButton: some View {
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
    
    private var debugToggleButton: some View {
        Button(action: {
            print("DEBUG: VideoView - debug mode toggle tapped")
            debugMode.toggle()
            poseDetector.debugMode = debugMode
        }) {
            Image(systemName: debugMode ? "eye.fill" : "eye")
                .font(.title2)
                .foregroundColor(.white)
                .padding(8)
                .background(Color.black.opacity(0.6))
                .clipShape(Circle())
        }
    }
    
    private var bottomUI: some View {
        VStack(spacing: 16) {
            if showInstructions {
                instructionCard
            }
            poseInfoCard
        }
        .padding(.bottom, 40)
    }
    
    private var instructionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.white)
                Spacer()
            }
            
            Text(selectedWorkout.instructions)
                .font(.subheadline)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .background(Color.black.opacity(0.7))
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }
    
    private var poseInfoCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Current Pose")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text(currentPose.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.6))
                    .cornerRadius(8)
            }
            
            HStack {
                Text("Accuracy")
                    .font(.subheadline)
                    .foregroundColor(.white)
                Spacer()
                Text("\(Int(poseAccuracy * 100))%")
                    .font(.subheadline)
                    .foregroundColor(poseAccuracy > 0.7 ? .green : .orange)
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.7))
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }
    
    private var poseOverlays: some View {
        Group {
            if poseDetector.isDetecting {
                PoseOverlayView(
                    pose: poseDetector.currentPose,
                    accuracy: poseAccuracy
                )
            }
            
            if poseDetector.isDetecting && (poseDetector.currentPose.type != .unknown || debugMode) {
                SkeletonOverlayView(
                    pose: poseDetector.currentPose,
                    keyPoints: poseDetector.keyPoints,
                    debugMode: debugMode
                )
            }
        }
    }
    
    private var debugOverlay: some View {
        VStack {
            HStack {
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Key Points: \(poseDetector.keyPoints.count)")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                    
                    Text("Detection: \(poseDetector.isDetecting ? "ON" : "OFF")")
                        .font(.caption)
                        .foregroundColor(poseDetector.isDetecting ? .green : .red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                    
                    if debugMode {
                        Text("Debug Mode")
                            .font(.caption)
                            .foregroundColor(.yellow)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(8)
                        
                        GeometryReader { geo in
                            Text("Safe: \(Int(geo.safeAreaInsets.top))")
                                .font(.caption)
                                .foregroundColor(.cyan)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(8)
                        }
                        .frame(width: 60, height: 20)
                    }
                }
            }
            Spacer()
        }
        .padding()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                cameraPreview
                
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
                        
                        Button(action: {
                            print("DEBUG: VideoView - debug mode toggle tapped")
                            debugMode.toggle()
                            poseDetector.debugMode = debugMode
                        }) {
                            Image(systemName: debugMode ? "eye.fill" : "eye")
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
                
                // Pose overlay with skeleton
                if poseDetector.isDetecting {
                    PoseOverlayView(
                        pose: poseDetector.currentPose,
                        accuracy: poseAccuracy
                    )
                }
                
                // Skeleton overlay
                if poseDetector.isDetecting && (poseDetector.currentPose.type != .unknown || debugMode) {
                    SkeletonOverlayView(
                        pose: poseDetector.currentPose,
                        keyPoints: poseDetector.keyPoints,
                        debugMode: debugMode
                    )
                }
                
                // Debug info overlay
                VStack {
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Key Points: \(poseDetector.keyPoints.count)")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(8)
                            
                            Text("Detection: \(poseDetector.isDetecting ? "ON" : "OFF")")
                                .font(.caption)
                                .foregroundColor(poseDetector.isDetecting ? .green : .red)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(8)
                            
                            if debugMode {
                                Text("Debug Mode")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.black.opacity(0.7))
                                    .cornerRadius(8)
                                
                                GeometryReader { geo in
                                    Text("Safe: \(Int(geo.safeAreaInsets.top))")
                                        .font(.caption)
                                        .foregroundColor(.cyan)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.black.opacity(0.7))
                                        .cornerRadius(8)
                                }
                                .frame(width: 60, height: 20)
                            }
                        }
                    }
                    Spacer()
                }
                .padding()
            }
            //.navigationTitle("Fitness Guide")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
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
            #if canImport(UIKit)
            .onChange(of: cameraManager.capturedImage) { image in
                if let image = image {
                    poseDetector.detectPose(in: image)
                }
            }
            #endif
            .onChange(of: poseDetector.detectedPose) { _, pose in
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
    #if canImport(UIKit)
    @Published var capturedImage: UIImage?
    #endif
    
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
        // Check camera permission first
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.global(qos: .background).async {
                self.session.startRunning()
                print("DEBUG: CameraManager - Session started")
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.global(qos: .background).async {
                        self.session.startRunning()
                        print("DEBUG: CameraManager - Session started after permission granted")
                    }
                } else {
                    print("ERROR: CameraManager - Camera permission denied")
                }
            }
        case .denied, .restricted:
            print("ERROR: CameraManager - Camera access denied or restricted")
        @unknown default:
            print("ERROR: CameraManager - Unknown camera authorization status")
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
#if canImport(UIKit)
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
#endif

// MARK: - Pose Detection
class PoseDetector: NSObject, ObservableObject {
    @Published var isDetecting = false
    @Published var currentPose: DetectedPose = DetectedPose(type: .unknown, accuracy: 0.0)
    @Published var detectedPose: DetectedPose = DetectedPose(type: .unknown, accuracy: 0.0)
    @Published var keyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    @Published var debugMode = false
    
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
    
    #if canImport(UIKit)
    func detectPose(in image: UIImage) {
        guard let cgImage = image.cgImage,
              let request = request else { 
            print("ERROR: PoseDetector - Missing cgImage or request")
            return 
        }
        
        print("DEBUG: PoseDetector - Starting pose detection on image: \(image.size)")
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
            print("DEBUG: PoseDetector - Detection request performed successfully")
        } catch {
            print("ERROR: PoseDetector - Failed to perform detection: \(error)")
        }
    }
    #endif
    
    private func processPoseResults(_ results: [VNObservation]?) {
        print("DEBUG: PoseDetector - Processing results: \(results?.count ?? 0) observations")
        
        guard let observations = results as? [VNHumanBodyPoseObservation], !observations.isEmpty else {
            print("DEBUG: PoseDetector - No human body pose observations found")
            DispatchQueue.main.async {
                self.currentPose = DetectedPose(type: .unknown, accuracy: 0.0)
            }
            return
        }
        
        let observation = observations.first!
        let poseType = classifyPose(from: observation)
        let accuracy = observation.confidence
        
        print("DEBUG: PoseDetector - Raw confidence: \(accuracy), classified as: \(poseType.rawValue)")
        
        let detectedPose = DetectedPose(type: poseType, accuracy: accuracy)
        
        // Extract key points for skeleton visualization
        var extractedKeyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        let jointNames: [VNHumanBodyPoseObservation.JointName] = [
            .leftWrist, .rightWrist, .leftElbow, .rightElbow, .leftShoulder, .rightShoulder,
            .leftHip, .rightHip, .leftKnee, .rightKnee, .leftAnkle, .rightAnkle,
            .neck, .nose, .leftEye, .rightEye, .leftEar, .rightEar
        ]
        
        for jointName in jointNames {
            do {
                let point = try observation.recognizedPoint(jointName)
                // 在调试模式下使用更低的阈值
                let threshold: Float = self.debugMode ? 0.2 : 0.5
                if point.confidence > threshold {
                    extractedKeyPoints[jointName] = CGPoint(x: point.location.x, y: point.location.y)
                    print("DEBUG: PoseDetector - Key point \(jointName.rawValue): confidence=\(point.confidence), location=(\(point.location.x), \(point.location.y))")
                }
            } catch {
                // Joint not detected, skip
            }
        }
        
        DispatchQueue.main.async {
            self.currentPose = detectedPose
            self.detectedPose = detectedPose
            self.keyPoints = extractedKeyPoints
            print("DEBUG: PoseDetector - Updated UI with pose: \(poseType.rawValue), accuracy: \(accuracy), key points: \(extractedKeyPoints.count)")
        }
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
            
            // Check if key points are visible (lowered threshold for better detection)
            let keyPoints = [leftShoulder, rightShoulder, leftHip, rightHip, leftKnee, rightKnee]
            let visiblePoints = keyPoints.filter { $0.confidence > 0.3 }
            
            print("DEBUG: PoseDetector - Visible key points: \(visiblePoints.count)/6")
            for (index, point) in keyPoints.enumerated() {
                print("DEBUG: PoseDetector - Point \(index): confidence = \(point.confidence)")
            }
            
            if visiblePoints.count < 3 {
                print("DEBUG: PoseDetector - Not enough visible key points")
                return .unknown
            }
            
            // Simple squat detection based on knee and hip positions
            let avgKneeY = (leftKnee.location.y + rightKnee.location.y) / 2
            let avgHipY = (leftHip.location.y + rightHip.location.y) / 2
            
            print("DEBUG: PoseDetector - Knee Y: \(avgKneeY), Hip Y: \(avgHipY)")
            
            // More lenient squat detection
            if avgKneeY > avgHipY + 0.05 { // Added small threshold
                print("DEBUG: PoseDetector - Detected SQUAT")
                return .squat
            }
            
            print("DEBUG: PoseDetector - Detected STANDING")
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

struct DetectedPose: Equatable {
    let type: PoseType
    let accuracy: Float
}

// MARK: - Supporting Data Structures
struct SkeletonConnection: Identifiable {
    let id: String
    let start: CGPoint
    let end: CGPoint
}

struct KeyPointView: Identifiable {
    let id: String
    let position: CGPoint
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

// MARK: - Skeleton Overlay
struct SkeletonOverlayView: View {
    let pose: DetectedPose
    let keyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    let debugMode: Bool
    
    // Helper function to determine if we need coordinate rotation
    private func needsCoordinateRotation(for geometry: GeometryProxy) -> Bool {
        // Check if the view is in portrait mode (height > width)
        let isPortrait = geometry.size.height > geometry.size.width
        
        // If we have shoulder points, use them to determine orientation
        if let leftShoulder = keyPoints[.leftShoulder], let rightShoulder = keyPoints[.rightShoulder] {
            let shoulderDistance = abs(leftShoulder.x - rightShoulder.x)
            let shoulderHeightDiff = abs(leftShoulder.y - rightShoulder.y)
            
            print("DEBUG: SkeletonOverlayView - Shoulder analysis:")
            print("  - Portrait mode: \(isPortrait)")
            print("  - Shoulder distance (x): \(shoulderDistance)")
            print("  - Shoulder height diff (y): \(shoulderHeightDiff)")
            print("  - Height > Distance: \(shoulderHeightDiff > shoulderDistance)")
            print("  - Left shoulder: (\(leftShoulder.x), \(leftShoulder.y))")
            print("  - Right shoulder: (\(rightShoulder.x), \(rightShoulder.y))")
            print("  - Safe area top: \(geometry.safeAreaInsets.top)")
            print("  - Safe area bottom: \(geometry.safeAreaInsets.bottom)")
            print("  - Adjusted height: \(geometry.size.height - geometry.safeAreaInsets.top - geometry.safeAreaInsets.bottom)")
            
            // If shoulders are more vertical than horizontal, we need rotation
            return isPortrait && shoulderHeightDiff > shoulderDistance
        }
        
        // Fallback: if portrait mode, assume we need rotation
        return isPortrait
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Draw skeleton lines
                ForEach(validSkeletonConnections(for: geometry), id: \.id) { connection in
                    Path { path in
                        path.move(to: connection.start)
                        path.addLine(to: connection.end)
                    }
                    .stroke(Color.green, lineWidth: 4)
                    .shadow(color: .green.opacity(0.5), radius: 2)
                }
                
                // Draw key points
                ForEach(validKeyPoints(for: geometry), id: \.id) { keyPoint in
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .position(keyPoint.position)
                        .shadow(color: .red.opacity(0.5), radius: 3)
                }
            }
        }
        .ignoresSafeArea()
    }
    
    // Helper function to get valid skeleton connections with converted coordinates
    private func validSkeletonConnections(for geometry: GeometryProxy) -> [SkeletonConnection] {
        let needsRotation = needsCoordinateRotation(for: geometry)
        
        // 获取安全区域信息来补偿导航栏高度
        let safeAreaTop = geometry.safeAreaInsets.top
        let safeAreaBottom = geometry.safeAreaInsets.bottom
        let adjustedHeight = geometry.size.height - safeAreaTop - safeAreaBottom
        
        return skeletonConnections.compactMap { connection in
            guard let startPoint = keyPoints[connection.start],
                  let endPoint = keyPoints[connection.end] else { return nil }
            
            let start: CGPoint
            let end: CGPoint
            
            if needsRotation {
                // For portrait video, try different rotation approach
                start = CGPoint(
                    x: (1.0 - startPoint.y) * geometry.size.width, // 翻转X坐标
                    y: startPoint.x * adjustedHeight + safeAreaTop // 补偿导航栏高度
                )
                end = CGPoint(
                    x: (1.0 - endPoint.y) * geometry.size.width, // 翻转X坐标
                    y: endPoint.x * adjustedHeight + safeAreaTop // 补偿导航栏高度
                )
            } else {
                // For landscape video, use normal coordinates with Y flip
                start = CGPoint(
                    x: startPoint.x * geometry.size.width,
                    y: (1.0 - startPoint.y) * adjustedHeight + safeAreaTop // 补偿导航栏高度
                )
                end = CGPoint(
                    x: endPoint.x * geometry.size.width,
                    y: (1.0 - endPoint.y) * adjustedHeight + safeAreaTop // 补偿导航栏高度
                )
            }
            
            return SkeletonConnection(
                id: "\(connection.start)-\(connection.end)",
                start: start,
                end: end
            )
        }
    }
    
    // Helper function to get valid key points with converted coordinates
    private func validKeyPoints(for geometry: GeometryProxy) -> [KeyPointView] {
        let needsRotation = needsCoordinateRotation(for: geometry)
        
        // 获取安全区域信息来补偿导航栏高度
        let safeAreaTop = geometry.safeAreaInsets.top
        let safeAreaBottom = geometry.safeAreaInsets.bottom
        let adjustedHeight = geometry.size.height - safeAreaTop - safeAreaBottom
        
        return keyPoints.compactMap { (jointName, point) in
            let position: CGPoint
            
            if needsRotation {
                // For portrait video, try different rotation approach
                position = CGPoint(
                    x: (1.0 - point.y) * geometry.size.width, // 翻转X坐标
                    y: point.x * adjustedHeight + safeAreaTop // 补偿导航栏高度
                )
            } else {
                // For landscape video, use normal coordinates with Y flip
                position = CGPoint(
                    x: point.x * geometry.size.width,
                    y: (1.0 - point.y) * adjustedHeight + safeAreaTop // 补偿导航栏高度
                )
            }
            
            return KeyPointView(
                id: "\(jointName)",
                position: position
            )
        }
    }
    
    // Define skeleton connections
    private var skeletonConnections: [(start: VNHumanBodyPoseObservation.JointName, end: VNHumanBodyPoseObservation.JointName)] {
        [
            // Head connections
            (.nose, .leftEye), (.nose, .rightEye),
            (.leftEye, .leftEar), (.rightEye, .rightEar),
            (.nose, .neck),
            
            // Torso connections
            (.neck, .leftShoulder), (.neck, .rightShoulder),
            (.leftShoulder, .leftHip), (.rightShoulder, .rightHip),
            (.leftHip, .rightHip),
            
            // Left arm connections
            (.leftShoulder, .leftElbow), (.leftElbow, .leftWrist),
            
            // Right arm connections
            (.rightShoulder, .rightElbow), (.rightElbow, .rightWrist),
            
            // Left leg connections
            (.leftHip, .leftKnee), (.leftKnee, .leftAnkle),
            
            // Right leg connections
            (.rightHip, .rightKnee), (.rightKnee, .rightAnkle),
            
            // Additional connections for better skeleton
            (.leftShoulder, .rightShoulder), // Shoulder line
            (.leftHip, .leftShoulder), // Left side
            (.rightHip, .rightShoulder) // Right side
        ]
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
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                #endif
            }
        }
    }
}

// MARK: - Extensions
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { 
            print("ERROR: CameraManager - Failed to get pixel buffer")
            return 
        }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            #if canImport(UIKit)
            let image = UIImage(cgImage: cgImage)
            DispatchQueue.main.async {
                self.capturedImage = image
                print("DEBUG: CameraManager - Captured image: \(image.size)")
            }
            #endif
        } else {
            print("ERROR: CameraManager - Failed to create CGImage from CIImage")
        }
    }
}

struct VideoView_Previews: PreviewProvider {
    static var previews: some View {
        VideoView()
    }
}

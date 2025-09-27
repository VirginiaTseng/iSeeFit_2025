//
//  PoseDetectionView.swift
//  iSeeFit
//
//  Created by VirginiaZheng on 2025-09-26.
//
//
//import SwiftUI
//import AVFoundation
//import Vision
//import UIKit
//
//struct PoseDetectionView: View {
//    @StateObject private var cameraManager = CameraManager()
//    @State private var selectedExercise: ExerciseType = .squat
//    @State private var showingExerciseSelector = false
//    
//    var body: some View {
//        ZStack {
//            // Camera preview
//            CameraPreviewView(cameraManager: cameraManager)
//                .ignoresSafeArea()
//            
//            // Pose overlay
//            PoseOverlayView(posePoints: cameraManager.detectedPose)
//            
//            // Reference pose overlay (ghost outline)
//            if let referencePose = selectedExercise.referencePose {
//                ReferencePoseOverlayView(posePoints: referencePose)
//                    .opacity(0.4)
//            }
//            
//            // UI Controls
//            VStack {
//                HStack {
//                    // Exercise selector
//                    Button(action: { showingExerciseSelector = true }) {
//                        HStack {
//                            Image(systemName: "figure.walk")
//                            Text(selectedExercise.rawValue.capitalized)
//                        }
//                        .padding()
//                        .background(Color.black.opacity(0.7))
//                        .foregroundColor(.white)
//                        .cornerRadius(10)
//                    }
//                    
//                    Spacer()
//                    
//                    // Accuracy indicator
//                    AccuracyIndicator(accuracy: cameraManager.poseAccuracy)
//                }
//                .padding(.top, 50)
//                
//                Spacer()
//                
//                // Feedback text
//                if !cameraManager.feedbackText.isEmpty {
//                    Text(cameraManager.feedbackText)
//                        .font(.headline)
//                        .foregroundColor(.white)
//                        .padding()
//                        .background(Color.black.opacity(0.7))
//                        .cornerRadius(10)
//                        .padding(.bottom, 100)
//                }
//            }
//            .padding()
//        }
//        .onAppear {
//            cameraManager.setReferenceExercise(selectedExercise)
//        }
//        .actionSheet(isPresented: $showingExerciseSelector) {
//            ActionSheet(
//                title: Text("Select Exercise"),
//                buttons: ExerciseType.allCases.map { exercise in
//                    ActionSheet.Button.default(Text(exercise.rawValue.capitalized)) {
//                        selectedExercise = exercise
//                        cameraManager.setReferenceExercise(exercise)
//                    }
//                } + [ActionSheet.Button.cancel()]
//            )
//        }
//    }
//}
//
//// MARK: - Camera Manager
//class CameraManager: NSObject, ObservableObject {
//    @Published var detectedPose: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
//    @Published var poseAccuracy: Double = 0.0
//    @Published var feedbackText: String = ""
//    
//    private var captureSession: AVCaptureSession!
//    private var previewLayer: AVCaptureVideoPreviewLayer!
//    private var videoOutput: AVCaptureVideoDataOutput!
//    private var currentExercise: ExerciseType = .squat
//    
//    override init() {
//        super.init()
//        setupCamera()
//    }
//    
//    private func setupCamera() {
//        captureSession = AVCaptureSession()
//        captureSession.sessionPreset = .high
//        
//        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
//            print("Unable to access back camera!")
//            return
//        }
//        
//        do {
//            let input = try AVCaptureDeviceInput(device: backCamera)
//            
//            videoOutput = AVCaptureVideoDataOutput()
//            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
//            
//            if captureSession.canAddInput(input) && captureSession.canAddOutput(videoOutput) {
//                captureSession.addInput(input)
//                captureSession.addOutput(videoOutput)
//                
//                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
//                previewLayer.videoGravity = .resizeAspectFill
//                
//                DispatchQueue.global(qos: .background).async {
//                    self.captureSession.startRunning()
//                }
//            }
//        } catch {
//            print("Error setting up camera: \(error)")
//        }
//    }
//    
//    func setReferenceExercise(_ exercise: ExerciseType) {
//        currentExercise = exercise
//    }
//    
//    func getPreviewLayer() -> AVCaptureVideoPreviewLayer {
//        return previewLayer
//    }
//}
//
//// MARK: - Video Processing
//extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
//    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
//        
//        let request = VNDetectHumanBodyPoseRequest { [weak self] request, error in
//            DispatchQueue.main.async {
//                self?.processBodyPoseResults(request.results)
//            }
//        }
//        
//        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
//        do {
//            try handler.perform([request])
//        } catch {
//            print("Failed to perform pose detection: \(error)")
//        }
//    }
//    
//    private func processBodyPoseResults(_ results: [VNObservation]?) {
//        guard let bodyPoseResults = results as? [VNHumanBodyPoseObservation],
//              let firstResult = bodyPoseResults.first else {
//            detectedPose = [:]
//            return
//        }
//        
//        var posePoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
//        
//        let jointNames: [VNHumanBodyPoseObservation.JointName] = [
//            .nose, .leftEye, .rightEye, .leftEar, .rightEar,
//            .leftShoulder, .rightShoulder, .leftElbow, .rightElbow,
//            .leftWrist, .rightWrist, .leftHip, .rightHip,
//            .leftKnee, .rightKnee, .leftAnkle, .rightAnkle
//        ]
//        
//        for jointName in jointNames {
//            do {
//                let joint = try firstResult.recognizedPoint(jointName)
//                if joint.confidence > 0.3 {
//                    posePoints[jointName] = CGPoint(x: joint.location.x, y: 1 - joint.location.y)
//                }
//            } catch {
//                continue
//            }
//        }
//        
//        detectedPose = posePoints
//        analyzePose(posePoints)
//    }
//    
//    private func analyzePose(_ posePoints: [VNHumanBodyPoseObservation.JointName: CGPoint]) {
//        let analysis = PoseAnalyzer.analyze(pose: posePoints, for: currentExercise)
//        poseAccuracy = analysis.accuracy
//        feedbackText = analysis.feedback
//    }
//}
//
//// MARK: - Camera Preview UIViewRepresentable
//struct CameraPreviewView: UIViewRepresentable {
//    let cameraManager: CameraManager
//    
//    func makeUIView(context: Context) -> UIView {
//        let view = UIView()
//        let previewLayer = cameraManager.getPreviewLayer()
//        previewLayer.frame = view.bounds
//        view.layer.addSublayer(previewLayer)
//        return view
//    }
//    
//    func updateUIView(_ uiView: UIView, context: Context) {
//        if let layer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
//            layer.frame = uiView.bounds
//        }
//    }
//}
//
//// MARK: - Pose Overlay View
//struct PoseOverlayView: View {
//    let posePoints: [VNHumanBodyPoseObservation.JointName: CGPoint]
//    
//    var body: some View {
//        GeometryReader { geometry in
//            ZStack {
//                // Draw pose skeleton
//                PoseSkeletonView(posePoints: posePoints, size: geometry.size)
//                
//                // Draw joint points
//                ForEach(Array(posePoints.keys), id: \.self) { jointName in
//                    if let point = posePoints[jointName] {
//                        Circle()
//                            .fill(Color.green)
//                            .frame(width: 8, height: 8)
//                            .position(
//                                x: point.x * geometry.size.width,
//                                y: point.y * geometry.size.height
//                            )
//                    }
//                }
//            }
//        }
//    }
//}
//
//// MARK: - Reference Pose Overlay
//struct ReferencePoseOverlayView: View {
//    let posePoints: [VNHumanBodyPoseObservation.JointName: CGPoint]
//    
//    var body: some View {
//        GeometryReader { geometry in
//            ZStack {
//                PoseSkeletonView(posePoints: posePoints, size: geometry.size, color: .white)
//                
//                ForEach(Array(posePoints.keys), id: \.self) { jointName in
//                    if let point = posePoints[jointName] {
//                        Circle()
//                            .fill(Color.white)
//                            .frame(width: 6, height: 6)
//                            .position(
//                                x: point.x * geometry.size.width,
//                                y: point.y * geometry.size.height
//                            )
//                    }
//                }
//            }
//        }
//    }
//}
//
//// MARK: - Pose Skeleton Drawing
//struct PoseSkeletonView: View {
//    let posePoints: [VNHumanBodyPoseObservation.JointName: CGPoint]
//    let size: CGSize
//    let color: Color
//    
//    init(posePoints: [VNHumanBodyPoseObservation.JointName: CGPoint], size: CGSize, color: Color = .green) {
//        self.posePoints = posePoints
//        self.size = size
//        self.color = color
//    }
//    
//    var body: some View {
//        Path { path in
//            drawSkeleton(path: &path)
//        }
//        .stroke(color, lineWidth: 2)
//    }
//    
//    private func drawSkeleton(path: inout Path) {
//        let connections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
//            // Head
//            (.nose, .leftEye), (.nose, .rightEye),
//            (.leftEye, .leftEar), (.rightEye, .rightEar),
//            
//            // Torso
//            (.leftShoulder, .rightShoulder),
//            (.leftShoulder, .leftHip), (.rightShoulder, .rightHip),
//            (.leftHip, .rightHip),
//            
//            // Arms
//            (.leftShoulder, .leftElbow), (.leftElbow, .leftWrist),
//            (.rightShoulder, .rightElbow), (.rightElbow, .rightWrist),
//            
//            // Legs
//            (.leftHip, .leftKnee), (.leftKnee, .leftAnkle),
//            (.rightHip, .rightKnee), (.rightKnee, .rightAnkle)
//        ]
//        
//        for (joint1, joint2) in connections {
//            if let point1 = posePoints[joint1], let point2 = posePoints[joint2] {
//                let startPoint = CGPoint(
//                    x: point1.x * size.width,
//                    y: point1.y * size.height
//                )
//                let endPoint = CGPoint(
//                    x: point2.x * size.width,
//                    y: point2.y * size.height
//                )
//                
//                path.move(to: startPoint)
//                path.addLine(to: endPoint)
//            }
//        }
//    }
//}
//
//// MARK: - Accuracy Indicator
//struct AccuracyIndicator: View {
//    let accuracy: Double
//    
//    var body: some View {
//        VStack {
//            Text("Accuracy")
//                .font(.caption)
//                .foregroundColor(.white)
//            
//            ZStack {
//                Circle()
//                    .stroke(Color.white.opacity(0.3), lineWidth: 4)
//                    .frame(width: 60, height: 60)
//                
//                Circle()
//                    .trim(from: 0, to: CGFloat(accuracy / 100))
//                    .stroke(accuracyColor, lineWidth: 4)
//                    .frame(width: 60, height: 60)
//                    .rotationEffect(.degrees(-90))
//                
//                Text("\(Int(accuracy))%")
//                    .font(.caption)
//                    .fontWeight(.bold)
//                    .foregroundColor(.white)
//            }
//        }
//        .padding()
//        .background(Color.black.opacity(0.7))
//        .cornerRadius(10)
//    }
//    
//    private var accuracyColor: Color {
//        if accuracy >= 80 { return .green }
//        else if accuracy >= 60 { return .yellow }
//        else { return .red }
//    }
//}
//
//// MARK: - Exercise Types
//enum ExerciseType: String, CaseIterable {
//    case squat = "squat"
//    case pushup = "push-up"
//    case plank = "plank"
//    case lunge = "lunge"
//    
//    var referencePose: [VNHumanBodyPoseObservation.JointName: CGPoint]? {
//        switch self {
//        case .squat:
//            return SquatReference.idealPose
//        case .pushup:
//            return PushupReference.idealPose
//        case .plank:
//            return PlankReference.idealPose
//        case .lunge:
//            return LungeReference.idealPose
//        }
//    }
//}
//
//// MARK: - Pose Analyzer
//struct PoseAnalyzer {
//    static func analyze(pose: [VNHumanBodyPoseObservation.JointName: CGPoint], for exercise: ExerciseType) -> (accuracy: Double, feedback: String) {
//        switch exercise {
//        case .squat:
//            return analyzeSquat(pose: pose)
//        case .pushup:
//            return analyzePushup(pose: pose)
//        case .plank:
//            return analyzePlank(pose: pose)
//        case .lunge:
//            return analyzeLunge(pose: pose)
//        }
//    }
//    
//    static private func analyzeSquat(pose: [VNHumanBodyPoseObservation.JointName: CGPoint]) -> (accuracy: Double, feedback: String) {
//        guard let leftHip = pose[.leftHip],
//              let rightHip = pose[.rightHip],
//              let leftKnee = pose[.leftKnee],
//              let rightKnee = pose[.rightKnee],
//              let leftAnkle = pose[.leftAnkle],
//              let rightAnkle = pose[.rightAnkle] else {
//            return (0, "Position yourself fully in frame")
//        }
//        
//        // Calculate knee angle
//        let leftKneeAngle = calculateAngle(point1: leftHip, point2: leftKnee, point3: leftAnkle)
//        let rightKneeAngle = calculateAngle(point1: rightHip, point2: rightKnee, point3: rightAnkle)
//        
//        let avgKneeAngle = (leftKneeAngle + rightKneeAngle) / 2
//        let idealSquatAngle: Double = 90 // degrees
//        
//        let angleAccuracy = max(0, 100 - abs(avgKneeAngle - idealSquatAngle) * 2)
//        
//        var feedback = ""
//        if avgKneeAngle > 110 {
//            feedback = "Squat deeper - bend your knees more"
//        } else if avgKneeAngle < 70 {
//            feedback = "Don't go too low - raise up slightly"
//        } else {
//            feedback = "Great squat form!"
//        }
//        
//        return (angleAccuracy, feedback)
//    }
//    
//    static private func analyzePushup(pose: [VNHumanBodyPoseObservation.JointName: CGPoint]) -> (accuracy: Double, feedback: String) {
//        // Similar analysis for push-up
//        return (75, "Keep your body straight")
//    }
//    
//    static private func analyzePlank(pose: [VNHumanBodyPoseObservation.JointName: CGPoint]) -> (accuracy: Double, feedback: String) {
//        // Similar analysis for plank
//        return (80, "Hold that position!")
//    }
//    
//    static private func analyzeLunge(pose: [VNHumanBodyPoseObservation.JointName: CGPoint]) -> (accuracy: Double, feedback: String) {
//        // Similar analysis for lunge
//        return (70, "Step forward more")
//    }
//    
//    static private func calculateAngle(point1: CGPoint, point2: CGPoint, point3: CGPoint) -> Double {
//        let vector1 = CGPoint(x: point1.x - point2.x, y: point1.y - point2.y)
//        let vector2 = CGPoint(x: point3.x - point2.x, y: point3.y - point2.y)
//        
//        let dotProduct = vector1.x * vector2.x + vector1.y * vector2.y
//        let magnitude1 = sqrt(vector1.x * vector1.x + vector1.y * vector1.y)
//        let magnitude2 = sqrt(vector2.x * vector2.x + vector2.y * vector2.y)
//        
//        let cosine = dotProduct / (magnitude1 * magnitude2)
//        let angle = acos(max(-1, min(1, cosine))) * 180 / .pi
//        
//        return angle
//    }
//}
//
//// MARK: - Reference Poses (you would define ideal poses for each exercise)
//struct SquatReference {
//    static let idealPose: [VNHumanBodyPoseObservation.JointName: CGPoint] = [
//        .nose: CGPoint(x: 0.5, y: 0.2),
//        .leftShoulder: CGPoint(x: 0.4, y: 0.3),
//        .rightShoulder: CGPoint(x: 0.6, y: 0.3),
//        .leftHip: CGPoint(x: 0.42, y: 0.55),
//        .rightHip: CGPoint(x: 0.58, y: 0.55),
//        .leftKnee: CGPoint(x: 0.4, y: 0.75),
//        .rightKnee: CGPoint(x: 0.6, y: 0.75),
//        .leftAnkle: CGPoint(x: 0.38, y: 0.9),
//        .rightAnkle: CGPoint(x: 0.62, y: 0.9)
//    ]
//}
//
//struct PushupReference {
//    static let idealPose: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
//}
//
//struct PlankReference {
//    static let idealPose: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
//}
//
//struct LungeReference {
//    static let idealPose: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
//}

//
//  ViewController.swift
//  HanTra
//
//  Created by ojiichan mecha on 2021/06/29.
//

import UIKit
import SceneKit
import ARKit
import AVFoundation
import Vision

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    private var feedView: FeedView { view as! FeedView }
    private var scnView: SCNView = SCNView()
    private var scene: SCNScene = SCNScene()
    
    private var arSession = ARSession()
    
    private var handPoseRequest = VNDetectHumanHandPoseRequest()
    private var lastHuman: Human?

    private let cameraFeedQueue = DispatchQueue(label: "Hantra.CameraFeed", qos: .userInteractive)
        
    override func viewDidLoad() {
        super.viewDidLoad()
        handPoseRequest.maximumHandCount = 2
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        do {
            scene.background.contents = UIColor.clear
            scnView.showsStatistics = true
            scnView.frame = self.view.bounds
            scnView.backgroundColor = UIColor.clear
            scnView.scene = scene
            view.contentMode = .scaleAspectFit
            view.addSubview(scnView)
            // setup ARSession
            let arConfiguration = try setupARSession()
            arSession.delegateQueue = cameraFeedQueue
            arSession.delegate = self
            arSession.run(arConfiguration)
        } catch {
            AppError.display(error, inViewController: self)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        arSession.pause()
        super.viewWillDisappear(animated)
    }
    
    func setupARSession() throws -> ARWorldTrackingConfiguration{
        guard ARWorldTrackingConfiguration.isSupported else {
            throw AppError.arSessionSetup(reason: "ARKit is not available on this device.")
        }
        guard ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification) else {
            throw AppError.arSessionSetup(reason: "Require a device with a LiDAR Scanner, such as the iPhone 12 Pro.")
        }
        
        let semantics: ARConfiguration.FrameSemantics = [.sceneDepth, .smoothedSceneDepth]
        //let semantics: ARConfiguration.FrameSemantics = [.smoothedSceneDepth]

        guard ARWorldTrackingConfiguration.supportsFrameSemantics(semantics) else {
            throw AppError.arSessionSetup(reason: "Require sceneDepth and smoothedSceneDepth")
        }
        
        // Create a session configuration
        let arConfiguration = ARWorldTrackingConfiguration()
        arConfiguration.frameSemantics = semantics
        return arConfiguration
    }
    
    func processFeedAndPoints(arData: ARData) {
        // Check that we have both points.
        feedView.updateFeed(pixelBuffer: arData.depthImage)
        guard let human = lastHuman else {
            // If there were no observations for more than 2 seconds reset gesture processor.
            feedView.showPoints(lPDArray: [], rPDArray: [], colorL: .clear, colorR: .clear)
            return
        }
                                        
        let colorL = UIColor.red
        let colorR = UIColor.blue
        let (pointsL, pointsR) = human.getPoints()
        let (lDepthArray, rDepthArray) = getDepth(arData: arData, pointsL: pointsL, pointsR: pointsR)
        
        var lPDArray: [PointAndDepth] = []
        var rPDArray: [PointAndDepth] = []
                
        // Convert points from hands coordinates to UIKit coordinates.

        for pi in 0 ..< pointsL.count {
            let point = feedView.convertPoint(point: pointsL[pi].point, screenSize: arData.screenResolution, imageSize: arData.adjustImageResolution)
            lPDArray.append(PointAndDepth(point: point, depth: lDepthArray[pi]))
        }
        for pi in 0 ..< pointsR.count {
            let point = feedView.convertPoint(point: pointsR[pi].point, screenSize: arData.screenResolution, imageSize: arData.adjustImageResolution)
            rPDArray.append(PointAndDepth(point: point, depth: rDepthArray[pi]))
        }
        feedView.showPoints(lPDArray : lPDArray, rPDArray : rPDArray, colorL: colorL, colorR: colorR)
    }
    
    private func getDepth(arData: ARData, pointsL: [HandPoint], pointsR: [HandPoint]) -> ([Float], [Float]) {
        CVPixelBufferLockBaseAddress(arData.depthImage, .readOnly)
        let base = CVPixelBufferGetBaseAddress(arData.depthImage)
        let width = CVPixelBufferGetWidth(arData.depthImage)
        let height = CVPixelBufferGetHeight(arData.depthImage)
        let bindPtr = base?.bindMemory(to: Float32.self, capacity: width * height)
        let bufPtr = UnsafeBufferPointer(start: bindPtr, count: width * height)
        let depthArray = Array(bufPtr)
        CVPixelBufferUnlockBaseAddress(arData.depthImage, .readOnly)
        var lDepthArray: [Float] = []
        for p in pointsL {
            let x = Int(CGFloat(width) * p.point.x)
            let y = Int(CGFloat(height) * p.point.y)
            var depth = depthArray[(width * y) + x]
            if depth.isNaN {
                depth = 0
            }
            if p.parentIndex >= 0 {
                let parentDepth = lDepthArray[p.parentIndex]
                if parentDepth - depth > p.length {
                    depth = parentDepth - p.length
                } else if depth - parentDepth > p.length {
                    depth = parentDepth + p.length
                }
            }
            lDepthArray.append(depth)
        }
        var rDepthArray: [Float] = []
        for p in pointsR {
            let x = Int(CGFloat(width) * p.point.x)
            let y = Int(CGFloat(height) * p.point.y)
            var depth = depthArray[(width * y) + x]
            if depth.isNaN {
                depth = 0
            }
            if p.parentIndex >= 0 {
                let parentDepth = rDepthArray[p.parentIndex]
                if parentDepth - depth > p.length {
                    depth = parentDepth - p.length
                } else if depth - parentDepth > p.length {
                    depth = parentDepth + p.length
                }
            }
            rDepthArray.append(depth)
        }
        return (lDepthArray, rDepthArray)
    }
    
    public func getHands(arData: ARData) {
        defer {
            DispatchQueue.main.async {
                self.processFeedAndPoints(arData: arData)
            }
        }
 
        // .upをleftやrightにするとx,y座標入れ替わる
        // .upが横で見た時に一番綺麗な感じ
        let handler = VNImageRequestHandler(cvPixelBuffer: arData.colorImage, orientation: .up, options: [:])
        
        do {
            // Perform VNDetectHumanHandPoseRequest
            try handler.perform([handPoseRequest])
            // Continue only when a hand was detected in the frame.
            // Since we set the maximumHandCount property of the request to 1, there will be at most one observation.
                        
            guard let observations = handPoseRequest.results else {
                return
            }
            
            if lastHuman == nil && observations.count < 2 {
                // XXX chirality が使えないので
                // XXX 最初に両手を認識するまではスルー
                return
            }
            
            // Get points.
            let human = Human()
            var handCount = 0
            for observation in observations {
                // thumb
                let thumbCMCPoint = try observation.recognizedPoint(.thumbCMC)
                let thumbMPPoint = try observation.recognizedPoint(.thumbMP)
                let thumbIPPoint = try observation.recognizedPoint(.thumbIP)
                let thumbTipPoint = try observation.recognizedPoint(.thumbTip)
                // index
                let indexMCPPoint = try observation.recognizedPoint(.indexMCP)
                let indexPIPPoint = try observation.recognizedPoint(.indexPIP)
                let indexDIPPoint = try observation.recognizedPoint(.indexDIP)
                let indexTipPoint = try observation.recognizedPoint(.indexTip)
                // middle
                let middleMCPPoint = try observation.recognizedPoint(.middleMCP)
                let middlePIPPoint = try observation.recognizedPoint(.middlePIP)
                let middleDIPPoint = try observation.recognizedPoint(.middleDIP)
                let middleTipPoint = try observation.recognizedPoint(.middleTip)
                // ring
                let ringMCPPoint = try observation.recognizedPoint(.ringMCP)
                let ringPIPPoint = try observation.recognizedPoint(.ringPIP)
                let ringDIPPoint = try observation.recognizedPoint(.ringDIP)
                let ringTipPoint = try observation.recognizedPoint(.ringTip)
                // little
                let littleMCPPoint = try observation.recognizedPoint(.littleMCP)
                let littlePIPPoint = try observation.recognizedPoint(.littlePIP)
                let littleDIPPoint = try observation.recognizedPoint(.littleDIP)
                let littleTipPoint = try observation.recognizedPoint(.littleTip)
                // wrist
                let wristPoint = try observation.recognizedPoint(.wrist)
                
                // Ignore low confidence points.
                guard
                    // thumb
                    thumbCMCPoint.confidence > 0.2 &&
                    thumbMPPoint.confidence > 0.2 &&
                    thumbIPPoint.confidence > 0.2 &&
                    thumbTipPoint.confidence > 0.2 &&
                    // index
                    indexMCPPoint.confidence > 0.2 &&
                    indexPIPPoint.confidence > 0.2 &&
                    indexDIPPoint.confidence > 0.2 &&
                    indexTipPoint.confidence > 0.2 &&
                    // middle
                    middleMCPPoint.confidence > 0.2 &&
                    middlePIPPoint.confidence > 0.2 &&
                    middleDIPPoint.confidence > 0.2 &&
                    middleTipPoint.confidence > 0.2 &&
                    // ring
                    ringMCPPoint.confidence > 0.2 &&
                    ringPIPPoint.confidence > 0.2 &&
                    ringDIPPoint.confidence > 0.2 &&
                    ringTipPoint.confidence > 0.2 &&
                    // little
                    littleMCPPoint.confidence > 0.2 &&
                    littlePIPPoint.confidence > 0.2 &&
                    littleDIPPoint.confidence > 0.2 &&
                    littleTipPoint.confidence > 0.2 &&
                    // wrist
                    wristPoint.confidence > 0.2 else {
                    return
                }
                if let prevHuman = lastHuman {
                    // XXX chirality が使えないので
                    // XXX 最後の情報と中心座標が近いほうが同じ手とみなす
                    let tmpHand = Hand(handType: .unknown)
                    getFingers(hand: tmpHand,
                               thumbCMCPoint: thumbCMCPoint,
                               thumbMPPoint: thumbMPPoint,
                               thumbIPPoint: thumbIPPoint,
                               thumbTipPoint: thumbTipPoint,
                               indexMCPPoint: indexMCPPoint,
                               indexPIPPoint: indexPIPPoint,
                               indexDIPPoint: indexDIPPoint,
                               indexTipPoint: indexTipPoint,
                               middleMCPPoint: middleMCPPoint,
                               middlePIPPoint: middlePIPPoint,
                               middleDIPPoint: middleDIPPoint,
                               middleTipPoint: middleTipPoint,
                               ringMCPPoint: ringMCPPoint,
                               ringPIPPoint: ringPIPPoint,
                               ringDIPPoint: ringDIPPoint,
                               ringTipPoint: ringTipPoint,
                               littleMCPPoint: littleMCPPoint,
                               littlePIPPoint: littlePIPPoint,
                               littleDIPPoint: littleDIPPoint,
                               littleTipPoint: littleTipPoint,
                               wristPoint: wristPoint)
                    tmpHand.updateBarycenter()
                    // check distance
                    let prevHumanLeftHand = prevHuman.getHand(handType: .left)
                    let leftDistance = prevHumanLeftHand.barycenter.distance(from: tmpHand.barycenter)
                    let prevHumanRightHand = prevHuman.getHand(handType: .right)
                    let rightDistance = prevHumanRightHand.barycenter.distance(from: tmpHand.barycenter)
                    var handType: HandType
                    if leftDistance < rightDistance {
                        handType = .left
                    } else {
                        handType = .right
                    }
                    // copy
                    let hand = human.getHand(handType: handType)
                    hand.copyPoints(srcHand: tmpHand)
                    hand.active = true
                } else {
                    // XXX chirality が使えないので決め打ち
                    // XXX 反対ならユーザーがUIからスワップできるようにする
                    var handType: HandType = .unknown
                    if handCount == 0 {
                        handType = HandType.right
                    } else if handCount == 1 {
                        handType = HandType.left
                    }
                    if handType == .unknown {
                        continue
                    }
                    let hand = human.getHand(handType: handType)
                    getFingers(hand: hand,
                               thumbCMCPoint: thumbCMCPoint,
                               thumbMPPoint: thumbMPPoint,
                               thumbIPPoint: thumbIPPoint,
                               thumbTipPoint: thumbTipPoint,
                               indexMCPPoint: indexMCPPoint,
                               indexPIPPoint: indexPIPPoint,
                               indexDIPPoint: indexDIPPoint,
                               indexTipPoint: indexTipPoint,
                               middleMCPPoint: middleMCPPoint,
                               middlePIPPoint: middlePIPPoint,
                               middleDIPPoint: middleDIPPoint,
                               middleTipPoint: middleTipPoint,
                               ringMCPPoint: ringMCPPoint,
                               ringPIPPoint: ringPIPPoint,
                               ringDIPPoint: ringDIPPoint,
                               ringTipPoint: ringTipPoint,
                               littleMCPPoint: littleMCPPoint,
                               littlePIPPoint: littlePIPPoint,
                               littleDIPPoint: littleDIPPoint,
                               littleTipPoint: littleTipPoint,
                               wristPoint: wristPoint)
                    hand.updateBarycenter()
                    hand.active = true
                }
                handCount += 1
                if handCount > 2 {
                    NSLog("XXX hand count = %d", handCount)
                }
            }
            if lastHuman ==  nil {
                lastHuman = human
                NSLog("init human")
            } else {
                if let h = lastHuman {
                    NSLog("update hands %d", handCount)
                    h.update(srcHuman: human)
                }
            }
        } catch {
            //cameraFeedSession?.stopRunning()
            let error = AppError.visionError(error: error)
            DispatchQueue.main.async {
                error.displayInViewController(self)
            }
        }
    }
 
    private func getFingers(hand: Hand,
                            thumbCMCPoint: VNRecognizedPoint,
                            thumbMPPoint: VNRecognizedPoint,
                            thumbIPPoint: VNRecognizedPoint,
                            thumbTipPoint: VNRecognizedPoint,
                            indexMCPPoint: VNRecognizedPoint,
                            indexPIPPoint: VNRecognizedPoint,
                            indexDIPPoint: VNRecognizedPoint,
                            indexTipPoint: VNRecognizedPoint,
                            middleMCPPoint: VNRecognizedPoint,
                            middlePIPPoint: VNRecognizedPoint,
                            middleDIPPoint: VNRecognizedPoint,
                            middleTipPoint: VNRecognizedPoint,
                            ringMCPPoint: VNRecognizedPoint,
                            ringPIPPoint: VNRecognizedPoint,
                            ringDIPPoint: VNRecognizedPoint,
                            ringTipPoint: VNRecognizedPoint,
                            littleMCPPoint: VNRecognizedPoint,
                            littlePIPPoint: VNRecognizedPoint,
                            littleDIPPoint: VNRecognizedPoint,
                            littleTipPoint: VNRecognizedPoint,
                            wristPoint: VNRecognizedPoint) {
        // thumb
        let thumb = hand.getFinger(fingerType: .thumb)
        thumb.joints[0] = CGPoint(x: thumbCMCPoint.location.x, y: 1 - thumbCMCPoint.location.y)
        thumb.joints[1] = CGPoint(x: thumbMPPoint.location.x, y: 1 - thumbMPPoint.location.y)
        thumb.joints[2] = CGPoint(x: thumbIPPoint.location.x, y: 1 - thumbIPPoint.location.y)
        thumb.joints[3] = CGPoint(x: thumbTipPoint.location.x, y: 1 - thumbTipPoint.location.y)
        // index
        let index = hand.getFinger(fingerType: .index)
        index.joints[0] = CGPoint(x: indexMCPPoint.location.x, y: 1 - indexMCPPoint.location.y)
        index.joints[1] = CGPoint(x: indexPIPPoint.location.x, y: 1 - indexPIPPoint.location.y)
        index.joints[2] = CGPoint(x: indexDIPPoint.location.x, y: 1 - indexDIPPoint.location.y)
        index.joints[3] = CGPoint(x: indexTipPoint.location.x, y: 1 - indexTipPoint.location.y)
        // middle
        let middle = hand.getFinger(fingerType: .middle)
        middle.joints[0] = CGPoint(x: middleMCPPoint.location.x, y: 1 - middleMCPPoint.location.y)
        middle.joints[1] = CGPoint(x: middlePIPPoint.location.x, y: 1 - middlePIPPoint.location.y)
        middle.joints[2] = CGPoint(x: middleDIPPoint.location.x, y: 1 - middleDIPPoint.location.y)
        middle.joints[3] = CGPoint(x: middleTipPoint.location.x, y: 1 - middleTipPoint.location.y)
        // ring
        let ring = hand.getFinger(fingerType: .ring)
        ring.joints[0] = CGPoint(x: ringMCPPoint.location.x, y: 1 - ringMCPPoint.location.y)
        ring.joints[1] = CGPoint(x: ringPIPPoint.location.x, y: 1 - ringPIPPoint.location.y)
        ring.joints[2] = CGPoint(x: ringDIPPoint.location.x, y: 1 - ringDIPPoint.location.y)
        ring.joints[3] = CGPoint(x: ringTipPoint.location.x, y: 1 - ringTipPoint.location.y)
        // little
        let little = hand.getFinger(fingerType: .little)
        little.joints[0] = CGPoint(x: littleMCPPoint.location.x, y: 1 - littleMCPPoint.location.y)
        little.joints[1] = CGPoint(x: littlePIPPoint.location.x, y: 1 - littlePIPPoint.location.y)
        little.joints[2] = CGPoint(x: littleDIPPoint.location.x, y: 1 - littleDIPPoint.location.y)
        little.joints[3] = CGPoint(x: littleTipPoint.location.x, y: 1 - littleTipPoint.location.y)
        // wrist
        hand.wrist = CGPoint(x: wristPoint.location.x, y: 1 - wristPoint.location.y)
    }
    
    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let depthData = frame.sceneDepth else { return }
        guard let smoothedSceneDepth = frame.smoothedSceneDepth else { return }
        // Use depth data
        let arData = ARData(depthImage: depthData.depthMap,
                            confidenceImage: depthData.confidenceMap,
                  depthSmoothImage: smoothedSceneDepth.depthMap,
                  confidenceSmoothImage: smoothedSceneDepth.confidenceMap,
                  colorImage: frame.capturedImage,
                  cameraIntrinsics: frame.camera.intrinsics,
                  cameraResolution: frame.camera.imageResolution,
                  deviceOrientation: UIDevice.current.orientation,
                  screenResolution: UIScreen.main.bounds.size)
        getHands(arData: arData)
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}

extension CGPoint {
    func distance(from point: CGPoint) -> CGFloat {
        return hypot(point.x - x, point.y - y)
    }
}

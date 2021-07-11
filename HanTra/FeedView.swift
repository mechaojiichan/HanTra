//
//  CameraView.swift
//  HanTra
//
//  Created by ojiichan mecha on 2021/06/29.
//

import UIKit
import ARKit

class FeedView: UIImageView {

    private var overlayLayerL = CAShapeLayer()
    private var overlayLayerR = CAShapeLayer()
    private var pointsPathL = UIBezierPath()
    private var pointsPathR = UIBezierPath()

    var previewLayer: CALayer {
        return layer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)        
        setupOverlay()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupOverlay()
    }
    
    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        if layer == previewLayer {
            debugPrint(layer.bounds)
            overlayLayerL.frame = layer.bounds
            overlayLayerR.frame = layer.bounds
        }
    }

    private func setupOverlay() {
        previewLayer.addSublayer(overlayLayerL)
        previewLayer.addSublayer(overlayLayerR)
    }
    
    func updateFeed(pixelBuffer: CVPixelBuffer) {
        image = UIImage(pixelBuffer: pixelBuffer)
    }
    
    func convertPoint(point: CGPoint, screenSize: CGSize, imageSize: CGSize) -> CGPoint {
        let margin = screenSize.width - imageSize.width
        //debugPrint(margin, imageSize, point)
        let newPoint =  CGPoint(x: (point.x * imageSize.width) + (margin / 2), y: point.y * imageSize.height)
        //debugPrint(newPoint)
        return newPoint
    }
    
    func showPoints(lPDArray: [PointAndDepth], rPDArray: [PointAndDepth], colorL: UIColor, colorR: UIColor) {
        pointsPathL.removeAllPoints()
        for pd in lPDArray {
            pointsPathL.move(to: pd.point)
            let rad = (0.4 - (pd.depth * pd.depth)) * 50
            debugPrint(rad)
            pointsPathL.addArc(withCenter: pd.point, radius: rad, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        }
        overlayLayerL.fillColor = colorL.cgColor
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        overlayLayerL.path = pointsPathL.cgPath
        CATransaction.commit()
        
        pointsPathR.removeAllPoints()
        for pd in rPDArray {
            pointsPathR.move(to: pd.point)
            let rad = (0.4 - (pd.depth * pd.depth)) * 50
            debugPrint(rad)
            pointsPathR.addArc(withCenter: pd.point, radius: rad, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        }
        overlayLayerR.fillColor = colorR.cgColor
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        overlayLayerR.path = pointsPathR.cgPath
        CATransaction.commit()
    }
}

class PointAndDepth {
    public var point: CGPoint
    public var depth: CGFloat
    public var vector3: SCNVector3
    
    init(point: CGPoint, depth: Float) {
        self.point = point
        self.depth = CGFloat(depth)
        self.vector3 = SCNVector3(x: Float(point.x), y: Float(point.y), z: Float(depth))
    }
}

extension UIImage {
    public convenience init?(pixelBuffer: CVPixelBuffer) {
        //var cgImage: CGImage?
        //VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)

        //guard let cgImage = cgImage else {
        //    return nil
        //}
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let cgImage = CIContext().createCGImage(ciImage, from: ciImage.extent)
        guard let image = cgImage else {
            return nil
        }
        self.init(cgImage: image)
    }
}

/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The camera view shows the feed from the camera, and renders the points
     returned from VNDetectHumanHandpose observations.
*/

import UIKit
import AVFoundation

class CameraView: UIView {

    private var overlayThumbLayer = CAShapeLayer()
    private var overlayIndexLayer = CAShapeLayer()
    private var overlayMiddleLayer = CAShapeLayer()
    private var overlayRingLayer = CAShapeLayer()
    private var overlayLittleLayer = CAShapeLayer()
    private var overlayGestureTextLayer = CATextLayer()

    var previewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }

    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
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
            overlayThumbLayer.frame = layer.bounds
            overlayIndexLayer.frame = layer.bounds
            overlayMiddleLayer.frame = layer.bounds
            overlayRingLayer.frame = layer.bounds
            overlayLittleLayer.frame = layer.bounds
            overlayGestureTextLayer.frame = layer.bounds
        }
    }

    private func setupOverlay() {
        previewLayer.addSublayer(overlayThumbLayer)
        previewLayer.addSublayer(overlayIndexLayer)
        previewLayer.addSublayer(overlayMiddleLayer)
        previewLayer.addSublayer(overlayRingLayer)
        previewLayer.addSublayer(overlayLittleLayer)
        previewLayer.addSublayer(overlayGestureTextLayer)
    }
    
    func showPoints(_ points: [CGPoint]) {
        
        guard let wrist: CGPoint = points.last else {
            // Clear all CALayers
            clearLayers()
            return
        }
        
        let thumbColor = UIColor.green
        let indexColor = UIColor.blue
        let middleColor = UIColor.yellow
        let ringColor = UIColor.cyan
        let littleColor = UIColor.red
        let gestureTextColor = UIColor.init(red: 19/255, green: 93/255, blue: 148/255, alpha: 1)
        
        drawFinger(overlayThumbLayer, Array(points[0...4]), thumbColor, wrist)
        drawFinger(overlayIndexLayer, Array(points[4...8]), indexColor, wrist)
        drawFinger(overlayMiddleLayer, Array(points[8...12]), middleColor, wrist)
        drawFinger(overlayRingLayer, Array(points[12...16]), ringColor, wrist)
        drawFinger(overlayLittleLayer, Array(points[16...20]), littleColor, wrist)
        drawGesture(overlayGestureTextLayer, points, gestureTextColor, wrist)
    }
    
    func calculateDistance(_ point1: CGPoint, _ point2: CGPoint) -> Double {
        return sqrt(((point1.x - point2.x) * (point1.x - point2.x)) + ((point1.x - point2.x) * (point1.x - point2.x)))
    }
    
    func calculateAngle( startPoint: CGPoint, middlePoint: CGPoint = CGPoint(x: 0, y: 0),
                endPoint: CGPoint = CGPoint(x: 1, y: 0), clockWise: Bool = false) -> Float {
        
        if ((middlePoint.x != 0 && middlePoint.y != 0) && (endPoint.x != 1 && endPoint.y != 0)) {
            let vectorBA = CGPoint(x: startPoint.x - middlePoint.x, y: startPoint.y - middlePoint.y)
            let vectorBC = CGPoint(x: endPoint.x - middlePoint.x, y: endPoint.y - middlePoint.y)
            let vectorBAAngle = calculateAngle(startPoint: vectorBA)
            let vectorBCAngle = calculateAngle(startPoint: vectorBC)
            var angleValue = (vectorBAAngle > vectorBCAngle) ? (vectorBAAngle - vectorBCAngle) : (360 + vectorBAAngle - vectorBCAngle)
            
            if (clockWise) {
                angleValue = 360 - angleValue
            }
            
            return angleValue
            
        } else {
            let x = startPoint.x
            let y = startPoint.y
            let magnitude = sqrt(Double(x * x + y * y))
            var angleValue = (magnitude >= 0.0001) ? acos(Double(x) / magnitude) : 0
            angleValue = (angleValue * 180) / Double.pi
            
            if (y < 0) {
                angleValue = 360 - angleValue
            }
            return Float(angleValue)
        }
    }
    
    func drawGesture(_ layer: CATextLayer, _ points: [CGPoint], _ color: UIColor, _ wrist: CGPoint) {
        
        let middlePipPoint = points[10]
        let middleMcpPoint = points[11]
        
        let angle = calculateAngle(
            startPoint: middlePipPoint,
            middlePoint: middleMcpPoint,
            endPoint: wrist,
            clockWise: false
        )
        print("angle:: \(angle)")
        
        if points[0].y < wrist.y && (angle < 160 || angle > 200) {
            layer.string = "THUMBS UP"
        }
        else if points[0].y > wrist.y && (angle < 160 || angle > 200) {
            layer.string = "THUMBS DOWN"
        }
        else {
            layer.string = ""
        }
        
        layer.fontSize = 40
        layer.alignmentMode = .center
        layer.foregroundColor = color.cgColor
    }
    
    func drawFinger(_ layer: CAShapeLayer, _ points: [CGPoint], _ color: UIColor, _ wrist: CGPoint) {
        let fingerPath = UIBezierPath()
        
        for point in points {
            fingerPath.move(to: point)
            fingerPath.addArc(withCenter: point, radius: 5, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        }
        
        fingerPath.move(to: points[0])
        fingerPath.addLine(to: points[1])
        fingerPath.move(to: points[1])
        fingerPath.addLine(to: points[2])
        fingerPath.move(to: points[2])
        fingerPath.addLine(to: points[3])
        fingerPath.move(to: points[3])
        fingerPath.addLine(to: wrist)
        
        layer.fillColor = color.cgColor
        layer.strokeColor = color.cgColor
        layer.lineWidth = 5.0
        layer.lineCap = .round
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.path = fingerPath.cgPath
        CATransaction.commit()
    }
    
    func clearLayers() {
        let emptyPath = UIBezierPath()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        overlayThumbLayer.path = emptyPath.cgPath
        overlayIndexLayer.path = emptyPath.cgPath
        overlayMiddleLayer.path = emptyPath.cgPath
        overlayRingLayer.path = emptyPath.cgPath
        overlayLittleLayer.path = emptyPath.cgPath
        CATransaction.commit()
    }
}

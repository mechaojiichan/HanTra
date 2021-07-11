//
//  Hands.swift
//  HanTra
//
//  Created by ojiichan mecha on 2021/06/29.
//

import UIKit

enum HandType: Int {
    case left    = 0
    case right   = 1
    case unknown = 2
}

enum FingerType: Int {
    case thumb   = 0
    case index   = 1
    case middle  = 2
    case ring    = 3
    case little  = 4
    case unknown = 5
}

class Human {
    var hands: [Hand] = [Hand(handType: .left), Hand(handType: .right)]
    
    func getHand(handType: HandType) -> Hand {
        return hands[handType.rawValue]
    }
    
    func getPoints() -> ([HandPoint], [HandPoint]) {
        var pointsL: [HandPoint] = []
        var pointsR: [HandPoint] = []
        if hands[0].active {
            pointsL.append(HandPoint(point: hands[0].wrist, parentIndex: -1, length: 0))
            for fi in 0 ..< hands[0].fingers.count {
                for ji in 0 ..< hands[0].fingers[fi].joints.count {
                    // thumb
                    if fi == 0 && ji == 0 {
                        pointsL.append(HandPoint(point: hands[0].fingers[fi].joints[ji], parentIndex: 0, length: 0.03))
                    } else if fi == 0 && ji == 1 {
                        pointsL.append(HandPoint(point: hands[0].fingers[fi].joints[ji], parentIndex: (fi * 4) + ji, length: 0.05))
                    } else if fi == 0 && ji == 2 {
                        pointsL.append(HandPoint(point: hands[0].fingers[fi].joints[ji], parentIndex: (fi * 4) + ji, length: 0.04))
                    } else if fi == 0 && ji == 3 {
                        pointsL.append(HandPoint(point: hands[0].fingers[fi].joints[ji], parentIndex: (fi * 4) + ji, length: 0.03))
                    // index
                    } else if fi == 1 && ji == 0 {
                        pointsL.append(HandPoint(point: hands[0].fingers[fi].joints[ji], parentIndex: 0, length: 0.1))
                    } else if fi == 1 && ji == 1 {
                        pointsL.append(HandPoint(point: hands[0].fingers[fi].joints[ji], parentIndex: (fi * 4) + ji, length: 0.055))
                    } else if fi == 1 && ji == 2 {
                        pointsL.append(HandPoint(point: hands[0].fingers[fi].joints[ji], parentIndex: (fi * 4) + ji, length: 0.03))
                    } else if fi == 1 && ji == 3 {
                        pointsL.append(HandPoint(point: hands[0].fingers[fi].joints[ji], parentIndex: (fi * 4) + ji, length: 0.025))
                    // middle
                    } else if fi == 2 && ji == 0 {
                        pointsL.append(HandPoint(point: hands[0].fingers[fi].joints[ji], parentIndex: 0, length: 0.1))
                    } else if fi == 2 && ji == 1 {
                        pointsL.append(HandPoint(point: hands[0].fingers[fi].joints[ji], parentIndex: (fi * 4) + ji, length: 0.055))
                    } else if fi == 2 && ji == 2 {
                        pointsL.append(HandPoint(point: hands[0].fingers[fi].joints[ji], parentIndex: (fi * 4) + ji, length: 0.04))
                    } else if fi == 2 && ji == 3 {
                        pointsL.append(HandPoint(point: hands[0].fingers[fi].joints[ji], parentIndex: (fi * 4) + ji, length: 0.025))
                    // ring
                    } else if fi == 3 && ji == 0 {
                        pointsL.append(HandPoint(point: hands[0].fingers[fi].joints[ji], parentIndex: 0, length: 0.1))
                    } else if fi == 3 && ji == 1 {
                        pointsL.append(HandPoint(point: hands[0].fingers[fi].joints[ji], parentIndex: (fi * 4) + ji, length: 0.055))
                    } else if fi == 3 && ji == 2 {
                        pointsL.append(HandPoint(point: hands[0].fingers[fi].joints[ji], parentIndex: (fi * 4) + ji, length: 0.04))
                    } else if fi == 3 && ji == 3 {
                        pointsL.append(HandPoint(point: hands[0].fingers[fi].joints[ji], parentIndex: (fi * 4) + ji, length: 0.025))
                    // little
                    } else if fi == 4 && ji == 0 {
                        pointsL.append(HandPoint(point: hands[0].fingers[fi].joints[ji], parentIndex: 0, length: 0.095))
                    } else if fi == 4 && ji == 1 {
                        pointsL.append(HandPoint(point: hands[0].fingers[fi].joints[ji], parentIndex: (fi * 4) + ji, length: 0.05))
                    } else if fi == 4 && ji == 2 {
                        pointsL.append(HandPoint(point: hands[0].fingers[fi].joints[ji], parentIndex: (fi * 4) + ji, length: 0.03))
                    } else if fi == 4 && ji == 3 {
                        pointsL.append(HandPoint(point: hands[0].fingers[fi].joints[ji], parentIndex: (fi * 4) + ji, length: 0.025))
                    }
                }
            }
        }
        if hands[1].active {
            pointsR.append(HandPoint(point: hands[1].wrist, parentIndex: -1, length: 0))
            for fi in 0 ..< hands[0].fingers.count {
                for ji in 0 ..< hands[0].fingers[fi].joints.count {
                    // thumb
                    if fi == 0 && ji == 0 {
                        pointsR.append(HandPoint(point: hands[1].fingers[fi].joints[ji], parentIndex: 0, length: 0.03))
                    } else if fi == 0 && ji == 1 {
                        pointsR.append(HandPoint(point: hands[1].fingers[fi].joints[ji], parentIndex: (fi * 4) + ji, length: 0.05))
                    } else if fi == 0 && ji == 2 {
                        pointsR.append(HandPoint(point: hands[1].fingers[fi].joints[ji], parentIndex: (fi * 4) + ji, length: 0.04))
                    } else if fi == 0 && ji == 3 {
                        pointsR.append(HandPoint(point: hands[1].fingers[fi].joints[ji], parentIndex: (fi * 4) + ji, length: 0.03))
                    // index
                    } else if fi == 1 && ji == 0 {
                        pointsR.append(HandPoint(point: hands[1].fingers[fi].joints[ji], parentIndex: 0, length: 0.1))
                    } else if fi == 1 && ji == 1 {
                        pointsR.append(HandPoint(point: hands[1].fingers[fi].joints[ji], parentIndex: (fi * 4) + ji, length: 0.055))
                    } else if fi == 1 && ji == 2 {
                        pointsR.append(HandPoint(point: hands[1].fingers[fi].joints[ji], parentIndex: (fi * 4) + ji, length: 0.03))
                    } else if fi == 1 && ji == 3 {
                        pointsR.append(HandPoint(point: hands[1].fingers[fi].joints[ji], parentIndex: (fi * 4) + ji, length: 0.025))
                    // middle
                    } else if fi == 2 && ji == 0 {
                        pointsR.append(HandPoint(point: hands[1].fingers[fi].joints[ji], parentIndex: 0, length: 0.1))
                    } else if fi == 2 && ji == 1 {
                        pointsR.append(HandPoint(point: hands[1].fingers[fi].joints[ji], parentIndex: (fi * 4) + ji, length: 0.055))
                    } else if fi == 2 && ji == 2 {
                        pointsR.append(HandPoint(point: hands[1].fingers[fi].joints[ji], parentIndex: (fi * 4) + ji, length: 0.04))
                    } else if fi == 2 && ji == 3 {
                        pointsR.append(HandPoint(point: hands[1].fingers[fi].joints[ji], parentIndex: (fi * 4) + ji, length: 0.025))
                    // ring
                    } else if fi == 3 && ji == 0 {
                        pointsR.append(HandPoint(point: hands[1].fingers[fi].joints[ji], parentIndex: 0, length: 0.1))
                    } else if fi == 3 && ji == 1 {
                        pointsR.append(HandPoint(point: hands[1].fingers[fi].joints[ji], parentIndex: (fi * 4) + ji, length: 0.055))
                    } else if fi == 3 && ji == 2 {
                        pointsR.append(HandPoint(point: hands[1].fingers[fi].joints[ji], parentIndex: (fi * 4) + ji, length: 0.04))
                    } else if fi == 3 && ji == 3 {
                        pointsR.append(HandPoint(point: hands[1].fingers[fi].joints[ji], parentIndex: (fi * 4) + ji, length: 0.025))
                    // little
                    } else if fi == 4 && ji == 0 {
                        pointsR.append(HandPoint(point: hands[1].fingers[fi].joints[ji], parentIndex: 0, length: 0.095))
                    } else if fi == 4 && ji == 1 {
                        pointsR.append(HandPoint(point: hands[1].fingers[fi].joints[ji], parentIndex: (fi * 4) + ji, length: 0.05))
                    } else if fi == 4 && ji == 2 {
                        pointsR.append(HandPoint(point: hands[1].fingers[fi].joints[ji], parentIndex: (fi * 4) + ji, length: 0.03))
                    } else if fi == 4 && ji == 3 {
                        pointsR.append(HandPoint(point: hands[1].fingers[fi].joints[ji], parentIndex: (fi * 4) + ji, length: 0.025))
                    }
                }
            }
        }
        return (pointsL, pointsR)
    }
    
    func update(srcHuman : Human) {
        for hi in 0 ..< hands.count {
            hands[hi].active = srcHuman.hands[hi].active
            if !srcHuman.hands[hi].active {
                continue
            }
            hands[hi].copyPoints(srcHand: srcHuman.hands[hi])
        }
    }
    
}

class Hand {
    private var handType: HandType
    var fingers: [Finger] = [ Finger(fingerType: .thumb),
                              Finger(fingerType: .index),
                              Finger(fingerType: .middle),
                              Finger(fingerType: .ring),
                              Finger(fingerType: .little)]
    var wrist: CGPoint = CGPoint.zero
    var barycenter: CGPoint = CGPoint.zero
    var active: Bool = false
    
    init(handType : HandType) {
        self.handType = handType
    }
    
    func getHandtype() -> HandType {
        return handType
    }
    
    func getFinger(fingerType: FingerType) -> Finger {
        return fingers[fingerType.rawValue]
    }
    
    func updateBarycenter() {
        var count: CGFloat = 0
        var tmp = CGPoint.zero
        for f in fingers {
            for j in f.joints {
                tmp.x += j.x
                tmp.y += j.y
                count += 1
            }
        }
        tmp.x += wrist.x
        tmp.y += wrist.y
        count += 1
        tmp.x = tmp.x / count
        tmp.y = tmp.y / count
        barycenter = tmp
    }
    
    func copyPoints(srcHand: Hand) {
        for fi in 0 ..< fingers.count {
            fingers[fi].copyPoints(srcFinger: srcHand.fingers[fi])
        }
        wrist = srcHand.wrist
        barycenter = srcHand.barycenter
    }
}

class Finger {
    private var fingerType: FingerType
    var joints: [CGPoint] = [CGPoint.zero, CGPoint.zero, CGPoint.zero, CGPoint.zero]
    
    init(fingerType: FingerType) {
        self.fingerType = fingerType
    }
    
    func getFingerType() -> FingerType {
        return fingerType
    }
    
    func copyPoints(srcFinger: Finger) {
        for ji in 0 ..< joints.count {
            joints[ji] = srcFinger.joints[ji]
        }
    }
}

class HandPoint {
    var point: CGPoint
    var parentIndex: Int
    var length: Float
    
    init(point: CGPoint, parentIndex: Int, length: Float) {
        self.point = point
        self.parentIndex = parentIndex
        self.length = length
    }
}

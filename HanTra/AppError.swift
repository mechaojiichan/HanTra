//
//  AppError.swift
//  HanTra
//
//  Created by ojiichan mecha on 2021/06/29.
//

import UIKit

enum AppError: Error {
    case arSessionSetup(reason: String)
    case captureSessionSetup(reason: String)
    case visionError(error: Error)
    case assertionError(reason: String)
    case otherError(error: Error)

    static func display(_ error: Error, inViewController viewController: UIViewController) {
        if let appError = error as? AppError {
            appError.displayInViewController(viewController)
        } else {
            AppError.otherError(error: error).displayInViewController(viewController)
        }
    }
    
    func displayInViewController(_ viewController: UIViewController) {
        let title: String?
        let message: String?
        switch self {
        case .arSessionSetup(let reason):
            title = "ARSession Setup Error"
            message = reason
        case .captureSessionSetup(let reason):
            title = "AVSession Setup Error"
            message = reason
        case .visionError(let error):
            title = "Vision Error"
            message = error.localizedDescription
        case .assertionError(let reason):
            title = "Error"
            message = reason
        case .otherError(let error):
            title = "Error"
            message = error.localizedDescription
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        viewController.present(alert, animated: true, completion: nil)
    }
}

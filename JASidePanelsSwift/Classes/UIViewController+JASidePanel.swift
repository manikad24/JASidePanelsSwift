//
//  UIViewController+JASidePanel.swift
//  Pods
//
//  Created by Manikandan Prabhu on 18/11/16.
//
//

import Foundation
import UIKit

extension UIViewController{
    public func sidePanelController() -> JASidePanelController {
        var iter = self.parentViewController
        while (iter != nil) {
            if (iter is JASidePanelController) {
                return (iter as! JASidePanelController)
            }
            else if (iter!.parentViewController! != iter) {
                iter = iter!.parentViewController!
            }
            else {
                iter = nil
            }
        }
        return JASidePanelController()
    }
}

extension Int {
    var f: CGFloat { return CGFloat(self) }
}

extension Float {
    var f: CGFloat { return CGFloat(self) }
}

extension Double {
    var f: CGFloat { return CGFloat(self) }
}

extension CGFloat {
    var swf: Float { return Float(self) }
}

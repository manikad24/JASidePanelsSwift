//
//  UIViewController+JASidePanel.swift
//  JASidePanels
//
//  Created by vgs-user on 15/11/16.
//  Copyright © 2016 vgs. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController{
    func sidePanelController() -> JASidePanelController {
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

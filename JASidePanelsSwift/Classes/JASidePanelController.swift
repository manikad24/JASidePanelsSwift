//
//  JASidePanelController.swift
//  JASidePanels
//
//  Created by vgs-user on 03/11/16.
//  Copyright © 2016 vgs. All rights reserved.
//

import UIKit

enum JASidePanelStyle : Int {
    case JASidePanelSingleActive = 0
    case JASidePanelMultipleActive
}

enum JASidePanelState : Int {
    case JASidePanelCenterVisible = 1
    case JASidePanelLeftVisible
    case JASidePanelRightVisible
}


class JASidePanelController: UIViewController,UIGestureRecognizerDelegate {
    let ja_kvoContext : UnsafeMutablePointer<Void> = nil
    
    
    var _tapView : UIView?
    var tapView : UIView?{
        set{
            if newValue != _tapView {
                if(_tapView != nil){
                _tapView!.removeFromSuperview()
                }
                
                if newValue != nil {
                    self._tapView = newValue!
                    self._tapView!.frame = self.centerPanelContainer.bounds
                    self._tapView!.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
                    self._addTapGestureToView(_tapView!)
                    if self.recognizesPanGesture {
                        self._addPanGestureToView(_tapView!)
                    }
                    self.centerPanelContainer.addSubview(_tapView!)
                }
            }

        }
        get{
            return self._tapView
        }
    }
    // set the panels
    var _leftPanel: UIViewController!
    var leftPanel: UIViewController!  {
        set{
            if newValue != _leftPanel {
                if(_leftPanel != nil){
                _leftPanel.willMoveToParentViewController(nil)
                _leftPanel.view.removeFromSuperview()
                _leftPanel.removeFromParentViewController()
                }
                self._leftPanel = newValue
                if (_leftPanel != nil) {
                    self.addChildViewController(_leftPanel)
                    _leftPanel.didMoveToParentViewController(self)
                    self._placeButtonForLeftPanel()
                }
                if self.state == .JASidePanelLeftVisible {
                    self.visiblePanel = _leftPanel
                }
            }

        }
        get{
            return self._leftPanel
        }
    }// optional
    
    var _centerPanel: UIViewController!
    var centerPanel: UIViewController!{
        set{
            let previous = self._centerPanel
            if(newValue != _centerPanel){
                if(_centerPanel != nil){
                _centerPanel.removeObserver(self, forKeyPath: "view")
                _centerPanel.removeObserver(self, forKeyPath: "viewControllers")
                }
                self._centerPanel = newValue
                _centerPanel.addObserver(self, forKeyPath: "viewControllers", options: [], context: ja_kvoContext)
                _centerPanel.addObserver(self, forKeyPath: "view", options: .Initial, context: ja_kvoContext)
                if self.state == .JASidePanelCenterVisible {
                    self.visiblePanel = _centerPanel
                }
            }
            if self.isViewLoaded() && self.state == .JASidePanelCenterVisible {
                self._swapCenter(previous, previousState: JASidePanelState(rawValue: 0)!, with: _centerPanel)
            }
            else if self.isViewLoaded() {
                // update the state immediately to prevent user interaction on the side panels while animating
                let previousState = self.state
                self.state = .JASidePanelCenterVisible
                UIView.animateWithDuration(0.2, animations: {() -> Void in
                    if self.bounceOnCenterPanelChange {
                        // first move the centerPanel offscreen
                        let x: CGFloat = (previousState == .JASidePanelLeftVisible) ? self.view!.bounds.size.width : -self.view!.bounds.size.width
                        self.centerPanelRestingFrame.origin.x = x
                    }
                    self.centerPanelContainer.frame = self.centerPanelRestingFrame
                    }, completion: {(finished) -> Void in
                        self._swapCenter(previous, previousState: previousState, with: self._centerPanel)
                        self._showCenterPanel(true, bounce: false)
                })
            }
            
            
            
        }
        get{
            return self._centerPanel
        }
    }// required
    
    var _rightPanel: UIViewController!
    var rightPanel: UIViewController!{
        set{
            if newValue != _rightPanel {
                if(_rightPanel != nil){
                _rightPanel.willMoveToParentViewController(nil)
                _rightPanel.view.removeFromSuperview()
                _rightPanel.removeFromParentViewController()
                }
                self._rightPanel = newValue
                if (_rightPanel != nil) {
                    self.addChildViewController(_rightPanel)
                    _rightPanel.didMoveToParentViewController(self)
                }
                if self.state == .JASidePanelRightVisible {
                    self.visiblePanel = _rightPanel
                }
            }

        }
        get{
            return self._rightPanel
        }
    }// optional
    
    // style
    var _style: JASidePanelStyle = .JASidePanelSingleActive // default is JASidePanelSingleActive
    
    
    var style: JASidePanelStyle  {
        set{
            if(newValue != self._style){
                self._style = newValue
                if(self.isViewLoaded()){
                    self._configureContainers()
                    self._layoutSideContainers(true, duration: 0.0)
                }
            }
        }
        get{
            return self._style
            
        }
    }
    // push side panels instead of overlapping them
    var pushesSidePanels: Bool = false
    
    // size the left panel based on % of total screen width
    var leftGapPercentage: CGFloat = 0.0
    
    // size the left panel based on this fixed size. overrides leftGapPercentage
    var leftFixedWidth: CGFloat = 0.0
    
    // the visible width of the left panel
    
    var _leftVisibleWidth: CGFloat = 0.0
    var leftVisibleWidth: CGFloat{
        set{
            self._leftVisibleWidth = newValue
        }
        get{
            if self.centerPanelHidden && self.shouldResizeLeftPanel {
                return self.view!.bounds.size.width
            }
            else {
                return (self.leftFixedWidth != 0.0) ? self.leftFixedWidth : floorf((self.view!.bounds.size.width).swf * self.leftGapPercentage.swf).f
            }
        }
    }
    
    // size the right panel based on % of total screen width
    var rightGapPercentage: CGFloat = 0.0
    
    // size the right panel based on this fixed size. overrides rightGapPercentage
    var rightFixedWidth: CGFloat = 0.0
    
    // the visible width of the right panel
    var _rightVisibleWidth: CGFloat = 0.0
    var rightVisibleWidth: CGFloat {
        set{
            self._rightVisibleWidth = newValue
        }
        get{
            if self.centerPanelHidden && self.shouldResizeRightPanel {
                return self.view!.bounds.size.width
            }
            else {
                return self.rightFixedWidth != 0.0 ? self.rightFixedWidth : floorf((self.view!.bounds.size.width).swf * self.rightGapPercentage.swf).f
            }
        }
    }
    
    //MARK: - Animation
    
    // the minimum % of total screen width the centerPanel.view must move for panGesture to succeed
    var minimumMovePercentage: CGFloat = 0.0
    
    // the maximum time panel opening/closing should take. Actual time may be less if panGesture has already moved the view.
    var maximumAnimationDuration: CGFloat = 0.0
    
    // how long the bounce animation should take
    var bounceDuration: CGFloat = 0.0
    
    // how far the view should bounce
    var bouncePercentage: CGFloat = 0.0
    
    // should the center panel bounce when you are panning open a left/right panel.
    var bounceOnSidePanelOpen: Bool = true // defaults to YES
    
    // should the center panel bounce when you are panning closed a left/right panel.
    var bounceOnSidePanelClose: Bool = false // defaults to NO
    
    // while changing the center panel, should we bounce it offscreen?
    var bounceOnCenterPanelChange: Bool = true // defaults to YES
    
    //MARK: - Gesture Behavior
    
    // Determines whether the pan gesture is limited to the top ViewController in a UINavigationController/UITabBarController
    var panningLimitedToTopViewController: Bool = true// default is YES
    
    // Determines whether showing panels can be controlled through pan gestures, or only through buttons
    var recognizesPanGesture: Bool = true // default is YES
    
    //MARK: - Nuts & Bolts
    
    // Current state of panels. Use KVO to monitor state changes
    //MARK:  - State
    var _state: JASidePanelState = .JASidePanelCenterVisible
    
    var state: JASidePanelState {
        set {
            if(_state != newValue){
                self._state = newValue
                switch _state {
                case .JASidePanelCenterVisible:
                    self.visiblePanel = self.centerPanel
                    self.leftPanelContainer.userInteractionEnabled = false
                    self.rightPanelContainer.userInteractionEnabled = false
                    break
                    
                case .JASidePanelLeftVisible:
                    self.visiblePanel = self.leftPanel
                    self.leftPanelContainer.userInteractionEnabled = true
                    break
                    
                case .JASidePanelRightVisible:
                    self.visiblePanel = self.rightPanel
                    self.rightPanelContainer.userInteractionEnabled = true
                    break
                }
            }
        }
        get{
            return self._state
        }
    }
    
    // Whether or not the center panel is completely hidden
    var _centerPanelHidden: Bool = false
    var centerPanelHidden: Bool{
        set{
            self.setCenterPanelHidden(_centerPanelHidden, animated: false, duration: 0.0)
        }
        get{
            return self._centerPanelHidden
        }
    }
    
    // The currently visible panel
    private var visiblePanel: UIViewController!
    
    // If set to yes, "shouldAutorotateToInterfaceOrientation:" will be passed to self.visiblePanel instead of handled directly
    var shouldDelegateAutorotateToVisiblePanel: Bool = true // defaults to YES
    
    // Determines whether or not the panel's views are removed when not visble. If YES, rightPanel & leftPanel's views are eligible for viewDidUnload
    var canUnloadRightPanel: Bool = false// defaults to NO
    var canUnloadLeftPanel: Bool = false // defaults to NO
    
    // Determines whether or not the panel's views should be resized when they are displayed. If yes, the views will be resized to their visible width
    var shouldResizeRightPanel: Bool = false // defaults to NO
    var shouldResizeLeftPanel: Bool = false // defaults to NO
    
    // Determines whether or not the center panel can be panned beyound the the visible area of the side panels
    var allowRightOverpan: Bool = true// defaults to YES
    var allowLeftOverpan: Bool = true // defaults to YES
    
    // Determines whether or not the left or right panel can be swiped into view. Use if only way to view a panel is with a button
    var allowLeftSwipe: Bool = true // defaults to YES
    var allowRightSwipe: Bool = true // defaults to YES
    
    // Containers for the panels.
    private var leftPanelContainer : UIView!
    private var rightPanelContainer : UIView!
    private var centerPanelContainer : UIView!
    
    var centerPanelRestingFrame: CGRect = CGRectZero
    var locationBeforePan: CGPoint = CGPointZero
    
    //MARK: - Icon
    class func defaultImage() -> UIImage {
        var defaultImage: UIImage = UIImage()
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 20.0, height: 13.0), false, 0.0)
        UIColor.blackColor().setFill()
        UIBezierPath(rect: CGRect(x: 0, y: 0, width: 20, height: 1)).fill()
        UIBezierPath(rect: CGRect(x: 0, y: 5, width: 20, height: 1)).fill()
        UIBezierPath(rect: CGRect(x: 0, y: 10, width: 20, height: 1)).fill()
        
        UIColor.whiteColor().setFill()
        UIBezierPath(rect: CGRect(x: 0, y: 1, width: 20, height: 2)).fill()
        UIBezierPath(rect: CGRect(x: 0, y: 6, width: 20, height: 2)).fill()
        UIBezierPath(rect: CGRect(x: 0, y: 11, width: 20, height: 2)).fill()
        
        defaultImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return defaultImage
    }
    
    //Support creating from Storyboard
    
    init() {
        super.init(nibName:nil, bundle:nil)
        self._baseInit()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self._baseInit()
        fatalError("")
    }
    
    func _baseInit(){
        self.style = .JASidePanelSingleActive
        self.leftGapPercentage = 0.8
        self.rightGapPercentage = 0.8
        self.minimumMovePercentage = 0.15
        self.maximumAnimationDuration = 0.2
        self.bounceDuration = 0.1
        self.bouncePercentage = 0.075
        self.panningLimitedToTopViewController = true
        self.recognizesPanGesture = true
        self.allowLeftOverpan = true
        self.allowRightOverpan = true
        self.bounceOnSidePanelOpen = true
        self.bounceOnSidePanelClose = false
        self.bounceOnCenterPanelChange = true
        self.shouldDelegateAutorotateToVisiblePanel = true
        self.allowRightSwipe = true
        self.allowLeftSwipe = true
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        self.centerPanelContainer = UIView(frame: self.view.bounds)
        self.centerPanelRestingFrame = self.centerPanelContainer.frame
        self.centerPanelHidden = false
        self.leftPanelContainer = UIView(frame: self.view.bounds)
        self.leftPanelContainer.hidden = true
        self.rightPanelContainer = UIView(frame: self.view.bounds)
        self.rightPanelContainer.hidden = true
        self._configureContainers()
        self.view.addSubview(self.centerPanelContainer)
        self.view.addSubview(self.leftPanelContainer)
        self.view.addSubview(self.rightPanelContainer)
        self.state = .JASidePanelCenterVisible
        self._swapCenter(UIViewController(), previousState: .JASidePanelCenterVisible, with: centerPanel)
        self.view.bringSubviewToFront(self.centerPanelContainer)
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        // ensure correct view dimensions
        self._layoutSideContainers(false, duration: 0.0)
        self._layoutSidePanels()
        self.centerPanelContainer.frame = self._adjustCenterFrame()
        self.styleContainer(self.centerPanelContainer, animate: false, duration: 0.0)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self._adjustCenterFrame()
        //Account for possible rotation while view appearing
    }
    
    
    
    
    override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        self.centerPanelContainer.frame = self._adjustCenterFrame()
        self._layoutSideContainers(true, duration: duration)
        self._layoutSidePanels()
        self.styleContainer(self.centerPanelContainer, animate: true, duration: duration)
        if self.centerPanelHidden {
            var frame = self.centerPanelContainer.frame
            frame.origin.x = self.state == .JASidePanelLeftVisible ? self.centerPanelContainer.frame.size.width : -self.centerPanelContainer.frame.size.width
            self.centerPanelContainer.frame = frame
        }
    }
    
    
    func styleContainer(container: UIView, animate: Bool, duration: NSTimeInterval) {
        let shadowPath = UIBezierPath(roundedRect: container.bounds, cornerRadius: 0.0)
        if animate {
            let animation = CABasicAnimation(keyPath: "shadowPath")
            animation.fromValue = (container.layer.shadowPath as! AnyObject)
            animation.toValue = (shadowPath.CGPath as AnyObject)
            animation.duration = duration
            container.layer.addAnimation(animation, forKey: "shadowPath")
        }
        container.layer.shadowPath = shadowPath.CGPath
        container.layer.shadowColor = UIColor.blackColor().CGColor
        container.layer.shadowRadius = 10.0
        container.layer.shadowOpacity = 0.75
        container.clipsToBounds = false
    }
    
    
    func stylePanel(panel: UIView) {
        //panel.layer.cornerRadius = 6.0f;
        panel.clipsToBounds = true
    }
    
    func _configureContainers() {
        self.leftPanelContainer.autoresizingMask = [.FlexibleHeight, .FlexibleRightMargin]
        self.rightPanelContainer.autoresizingMask = [.FlexibleLeftMargin, .FlexibleHeight]
        self.centerPanelContainer.frame = self.view.bounds
        self.centerPanelContainer.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
    }
    
    func _layoutSideContainers(animate: Bool, duration: NSTimeInterval) {
        var leftFrame = self.view!.bounds
        var rightFrame = self.view!.bounds
        if self.style == .JASidePanelMultipleActive {
            // left panel container
            leftFrame.size.width = self.leftVisibleWidth
            leftFrame.origin.x = self.centerPanelContainer.frame.origin.x - leftFrame.size.width
            // right panel container
            rightFrame.size.width = self.rightVisibleWidth
            rightFrame.origin.x = self.centerPanelContainer.frame.origin.x + self.centerPanelContainer.frame.size.width
        }
        else if self.pushesSidePanels && !self.centerPanelHidden {
            leftFrame.origin.x = self.centerPanelContainer.frame.origin.x - self.leftVisibleWidth
            rightFrame.origin.x = self.centerPanelContainer.frame.origin.x + self.centerPanelContainer.frame.size.width
        }
        
        self.leftPanelContainer.frame = leftFrame
        self.rightPanelContainer.frame = rightFrame
        self.styleContainer(self.leftPanelContainer, animate: animate, duration: duration)
        self.styleContainer(self.rightPanelContainer, animate: animate, duration: duration)
    }
    
    func _layoutSidePanels() {
        if(rightPanel != nil){
        if self.rightPanel.isViewLoaded() {
            var frame = self.rightPanelContainer.bounds
            if self.shouldResizeRightPanel {
                if !self.pushesSidePanels {
                    frame.origin.x = self.rightPanelContainer.bounds.size.width - self.rightVisibleWidth
                }
                frame.size.width = self.rightVisibleWidth
            }
            self.rightPanel.view.frame = frame
        }
        }
        if self.leftPanel.isViewLoaded() {
            var frame = self.leftPanelContainer.bounds
            if self.shouldResizeLeftPanel {
                frame.size.width = self.leftVisibleWidth
            }
            self.leftPanel.view.frame = frame
        }
    }
    
    func _swapCenter(previous: UIViewController, previousState: JASidePanelState, with next: UIViewController) {
        if previous != next {
            previous.willMoveToParentViewController(nil)
            previous.view.removeFromSuperview()
            previous.removeFromParentViewController()
            if ( next != UIViewController() ) {
                self._loadCenterPanelWithPreviousState(previousState)
                self.addChildViewController(next)
                self.centerPanelContainer.addSubview(next.view)
                next.didMoveToParentViewController(self)
            }
        }
    }
    
    // MARK: - Panel Buttons
    func _placeButtonForLeftPanel() {
        if (self.leftPanel != nil) {
            var buttonController = self.centerPanel
            if (buttonController is UINavigationController) {
                let nav = (buttonController as! UINavigationController)
                if nav.viewControllers.count > 0 {
                    buttonController = nav.viewControllers[0]
                }
            }
            if (buttonController.navigationItem.leftBarButtonItem == nil) {
                buttonController.navigationItem.leftBarButtonItem = self.leftButtonForCenterPanel()
            }
        }
    }
    
    // MARK: - Gesture Recognizer Delegate
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.view! == self.tapView {
            return true
        }
        else if self.panningLimitedToTopViewController && !self._isOnTopLevelViewController(self.centerPanel) {
            return false
        }
        else if (gestureRecognizer is UIPanGestureRecognizer) {
            let pan = (gestureRecognizer as! UIPanGestureRecognizer)
            let translate = pan.translationInView(self.centerPanelContainer)
            // determine if right swipe is allowed
            if translate.x < 0 && !self.allowRightSwipe {
                return false
            }
            // determine if left swipe is allowed
            if translate.x > 0 && !self.allowLeftSwipe {
                return false
            }
            let possible = translate.x != 0 && ((fabsf(translate.y.swf).f / fabsf(translate.x.swf).f) < 1.0)
            if possible && (translate.x > 0 && self.leftPanel != nil) || (translate.x < 0 && self.rightPanel != nil) {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Pan Gestures
    
    func _addPanGestureToView(view: UIView) {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self._handlePan))
        panGesture.delegate = self
        panGesture.maximumNumberOfTouches = 1
        panGesture.minimumNumberOfTouches = 1
        view.addGestureRecognizer(panGesture)
    }
    
    
    func _handlePan(sender: UIGestureRecognizer) {
        if !recognizesPanGesture {
            return
        }
        if (sender is UIPanGestureRecognizer) {
            let pan = (sender as! UIPanGestureRecognizer)
            if pan.state == .Began {
                self.locationBeforePan = self.centerPanelContainer.frame.origin
            }
            let translate = pan.translationInView(self.centerPanelContainer)
            var frame = centerPanelRestingFrame
            frame.origin.x += roundf(self._correctMovement(translate.x).swf).f
            if self.style == .JASidePanelMultipleActive {
                frame.size.width = self.view!.bounds.size.width - frame.origin.x
            }
            self.centerPanelContainer.frame = frame
            // if center panel has focus, make sure correct side panel is revealed
            if self.state == .JASidePanelCenterVisible {
                if frame.origin.x > 0.0 {
                    self._loadLeftPanel()
                }
                else if frame.origin.x < 0.0 {
                    self._loadRightPanel()
                }
            }
            // adjust side panel locations, if needed
            if self.style == .JASidePanelMultipleActive || self.pushesSidePanels {
                self._layoutSideContainers(false, duration: 0)
            }
            if sender.state == .Ended {
                let deltaX: CGFloat = frame.origin.x - locationBeforePan.x
                if self._validateThreshold(deltaX) {
                    self._completePan(deltaX)
                }
                else {
                    self._undoPan()
                }
            }
            else if sender.state == .Cancelled {
                self._undoPan()
            }
        }
    }
    
    
    func _completePan(deltaX: CGFloat) {
        switch self.state {
        case .JASidePanelCenterVisible:
            if deltaX > 0.0 {
                self._showLeftPanel(true, bounce: self.bounceOnSidePanelOpen)
            }
            else {
                self._showRightPanel(true, bounce: self.bounceOnSidePanelOpen)
            }
            
        case .JASidePanelLeftVisible:
            self._showCenterPanel(true, bounce: self.bounceOnSidePanelClose)
            
        case .JASidePanelRightVisible:
            self._showCenterPanel(true, bounce: self.bounceOnSidePanelClose)
            
        }
        
    }
    
    func _undoPan() {
        switch self.state {
        case .JASidePanelCenterVisible:
            self._showCenterPanel(true, bounce: false)
            
        case .JASidePanelLeftVisible:
            self._showLeftPanel(true, bounce: false)
            
        case .JASidePanelRightVisible:
            self._showRightPanel(true, bounce: false)
            
        }
        
    }
    
    
    func _addTapGestureToView(view: UIView) {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self._centerPanelTapped))
        view.addGestureRecognizer(tapGesture)
    }

    func _centerPanelTapped(gesture: UIGestureRecognizer) {
        self._showCenterPanel(true, bounce: false)
    }
    
    // MARK: - Internal Methods
    
    func _correctMovement(movement: CGFloat) -> CGFloat {
        let position: CGFloat = centerPanelRestingFrame.origin.x + movement
        if self.state == .JASidePanelCenterVisible {
            if (position > 0.0 && self.leftPanel == nil) || (position < 0.0 && self.rightPanel == nil) {
                return 0.0
            }
            else if !self.allowLeftOverpan && position > self.leftVisibleWidth {
                return self.leftVisibleWidth
            }
            else if !self.allowRightOverpan && position < -self.rightVisibleWidth {
                return -self.rightVisibleWidth
            }
        }
        else if self.state == .JASidePanelRightVisible && !self.allowRightOverpan {
            if position < -self.rightVisibleWidth {
                return 0.0
            }
            else if position > self.rightPanelContainer.frame.origin.x {
                return self.rightPanelContainer.frame.origin.x - centerPanelRestingFrame.origin.x
            }
        }
        else if self.state == .JASidePanelLeftVisible && !self.allowLeftOverpan {
            if position > self.leftVisibleWidth {
                return 0.0
            }
            else if (self.style == .JASidePanelMultipleActive || self.pushesSidePanels) && position < 0.0 {
                return -centerPanelRestingFrame.origin.x
            }
            else if position < self.leftPanelContainer.frame.origin.x {
                return self.leftPanelContainer.frame.origin.x - centerPanelRestingFrame.origin.x
            }
        }
        
        return movement
    }
    
    
    func _validateThreshold(movement: CGFloat) -> Bool {
        let minimum: CGFloat = floorf((self.view!.bounds.size.width).swf * self.minimumMovePercentage.swf).f
        switch self.state {
        case .JASidePanelLeftVisible:
            return movement <= -minimum
            
        case .JASidePanelCenterVisible:
            return fabsf(movement.swf).f >= minimum
            
        case .JASidePanelRightVisible:
            return movement >= minimum
            
        }
        
        return false
    }
    
    func _isOnTopLevelViewController(root: UIViewController) -> Bool {
        if (root is UINavigationController) {
            let nav = (root as! UINavigationController)
            return nav.viewControllers.count == 1
        }
        else if (root is UITabBarController) {
            let tab = (root as! UITabBarController)
            return self._isOnTopLevelViewController(tab.selectedViewController!)
        }
        
        return true
    }
    
    
    //MARK:- Loading Panels
    func _loadCenterPanelWithPreviousState(previousState: JASidePanelState) {
        self._placeButtonForLeftPanel()
        // for the multi-active style, it looks better if the new center starts out in it's fullsize and slides in
        if self.style == .JASidePanelMultipleActive {
            switch previousState {
            case .JASidePanelLeftVisible:
                var frame = self.centerPanelContainer.frame
                frame.size.width = self.view.bounds.size.width
                self.centerPanelContainer.frame = frame
                
            case .JASidePanelRightVisible:
                var frame = self.centerPanelContainer.frame
                frame.size.width = self.view.bounds.size.width
                frame.origin.x = -self.rightVisibleWidth
                self.centerPanelContainer.frame = frame
                
            default:
                break
            }
        }
        self.centerPanel.view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        self.centerPanel.view.frame = self.centerPanelContainer.bounds
        self.stylePanel(centerPanel.view)
    }
    
    
    
    
    func _loadLeftPanel() {
        self.rightPanelContainer.hidden = true
        if (self.leftPanelContainer.hidden && (self.leftPanel != nil)) {
            if leftPanel.view.superview == nil {
                self._layoutSidePanels()
                self.leftPanel.view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
                self.stylePanel(leftPanel.view)
                self.leftPanelContainer.addSubview(leftPanel.view)
            }
            self.leftPanelContainer.hidden = false
        }
    }
    
    
    func _loadRightPanel() {
        self.leftPanelContainer.hidden = true
        if (self.rightPanelContainer.hidden && self.rightPanel != nil) {
            if rightPanel.view.superview == nil {
                self._layoutSidePanels()
                self.rightPanel.view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
                self.stylePanel(rightPanel.view)
                self.rightPanelContainer.addSubview(rightPanel.view)
            }
            self.rightPanelContainer.hidden = false
        }
    }
    
    
    func _unloadPanels() {
        if self.canUnloadLeftPanel && self.leftPanel.isViewLoaded() {
            self.leftPanel.view.removeFromSuperview()
        }
        if self.canUnloadRightPanel && self.rightPanel.isViewLoaded() {
            self.rightPanel.view.removeFromSuperview()
        }
    }
    
    // MARK: - Animation
    func _calculatedDuration() -> CGFloat {
        let diff = (self.centerPanelContainer.frame.origin.x - centerPanelRestingFrame.origin.x).swf
        let remaining: CGFloat = fabsf(diff).f
        let max: CGFloat = (locationBeforePan.x == centerPanelRestingFrame.origin.x) ? remaining : fabsf((locationBeforePan.x - centerPanelRestingFrame.origin.x).swf).f
        return max > 0.0 ? self.maximumAnimationDuration * (remaining / max) : self.maximumAnimationDuration
    }
    
    
    func _animateCenterPanel(shouldBounce: Bool, completion: (finished: Bool) -> Void) {
        var shouldBounces = shouldBounce
        let bounceDistance : CGFloat = (centerPanelRestingFrame.origin.x - self.centerPanelContainer.frame.origin.x) * self.bouncePercentage
        // looks bad if we bounce when the center panel grows
        if centerPanelRestingFrame.size.width > self.centerPanelContainer.frame.size.width {
             shouldBounces = false
        }
        let duration: CGFloat = self._calculatedDuration()
        UIView.animateWithDuration(Double(duration), delay: 0.0, options: [.CurveLinear, .LayoutSubviews], animations: {() -> Void in
            self.centerPanelContainer.frame = self.centerPanelRestingFrame
            self.styleContainer(self.centerPanelContainer, animate: true, duration: Double(duration))
            if self.style == .JASidePanelMultipleActive || self.pushesSidePanels {
                self._layoutSideContainers(false, duration: 0.0)
            }
            }, completion: {(finished: Bool) -> Void in
                if shouldBounces {
                    // make sure correct panel is displayed under the bounce
                    if self.state == .JASidePanelCenterVisible {
                        if bounceDistance > 0.0 {
                            self._loadLeftPanel()
                        }
                        else {
                            self._loadRightPanel()
                        }
                    }
                    // animate the bounce
                    UIView.animateWithDuration(Double(self.bounceDuration), delay: 0.0, options: .CurveEaseOut, animations: {() -> Void in
                        var bounceFrame = self.centerPanelRestingFrame
                        bounceFrame.origin.x += bounceDistance
                        self.centerPanelContainer.frame = bounceFrame
                        }, completion: {(finished2) -> Void in
                            UIView.animateWithDuration(Double(self.bounceDuration), delay: 0.0, options: .CurveEaseIn, animations: {() -> Void in
                                self.centerPanelContainer.frame = self.centerPanelRestingFrame
                                }, completion: completion)
                    })
                }
                else {
                    completion(finished: finished)
                }
                
        })
    }
    
    // MARK: - Panel Sizing
    
    func _adjustCenterFrame() -> CGRect {
        var frame = self.view!.bounds
        switch self.state {
        case .JASidePanelCenterVisible:
            frame.origin.x = 0.0
            if self.style == .JASidePanelMultipleActive {
                frame.size.width = self.view!.bounds.size.width
            }
            
        case .JASidePanelLeftVisible:
            frame.origin.x = self.leftVisibleWidth
            if self.style == .JASidePanelMultipleActive {
                frame.size.width = self.view!.bounds.size.width - self.leftVisibleWidth
            }
            
        case .JASidePanelRightVisible:
            frame.origin.x = -self.rightVisibleWidth
            if self.style == .JASidePanelMultipleActive {
                frame.origin.x = 0.0
                frame.size.width = self.view!.bounds.size.width - self.rightVisibleWidth
            }
            
        }
        
        self.centerPanelRestingFrame = frame
        return centerPanelRestingFrame
    }
    
    
    
    
    
    
    // MARK: - Showing Panels
    
    func _showLeftPanel(animated: Bool, bounce shouldBounce: Bool) {
        self.state = .JASidePanelLeftVisible
        self._loadLeftPanel()
        self._adjustCenterFrame()
        if animated {
            self._animateCenterPanel(shouldBounce, completion: { _ in })
        }
        else {
            self.centerPanelContainer.frame = centerPanelRestingFrame
            self.styleContainer(self.centerPanelContainer, animate: false, duration: 0.0)
            if self.style == .JASidePanelMultipleActive || self.pushesSidePanels {
                self._layoutSideContainers(false, duration: 0.0)
            }
        }
        if self.style == .JASidePanelSingleActive {
            self.tapView = UIView()
        }
        self._toggleScrollsToTopForCenter(false, left: true, right: false)
    }
    
    
    func _showRightPanel(animated: Bool, bounce shouldBounce: Bool) {
        self.state = .JASidePanelRightVisible
        self._loadRightPanel()
        self._adjustCenterFrame()
        if animated {
            self._animateCenterPanel(shouldBounce, completion: { _ in })
        }
        else {
            self.centerPanelContainer.frame = centerPanelRestingFrame
            self.styleContainer(self.centerPanelContainer, animate: false, duration: 0.0)
            if self.style == .JASidePanelMultipleActive || self.pushesSidePanels {
                self._layoutSideContainers(false, duration: 0.0)
            }
        }
        if self.style == .JASidePanelSingleActive {
            self.tapView = UIView()
        }
        self._toggleScrollsToTopForCenter(false, left: false, right: true)
    }
    
    
    func _showCenterPanel(animated: Bool, bounce shouldBounce: Bool) {
        self.state = .JASidePanelCenterVisible
        self._adjustCenterFrame()
        if animated {
            self._animateCenterPanel(shouldBounce, completion: {(finished) -> Void in
                self.leftPanelContainer.hidden = true
                self.rightPanelContainer.hidden = true
                self._unloadPanels()
            })
        }
        else {
            self.centerPanelContainer.frame = centerPanelRestingFrame
            self.styleContainer(self.centerPanelContainer, animate: false, duration: 0.0)
            if self.style == .JASidePanelMultipleActive || self.pushesSidePanels {
                self._layoutSideContainers(false, duration: 0.0)
            }
            self.leftPanelContainer.hidden = true
            self.rightPanelContainer.hidden = true
            self._unloadPanels()
        }
        self.tapView = nil
        self._toggleScrollsToTopForCenter(true, left: false, right: false)
    }
    
    
    func _hideCenterPanel() {
        self.centerPanelContainer.hidden = true
        if self.centerPanel.isViewLoaded() {
            self.centerPanel.view.removeFromSuperview()
        }
    }
    
    func _unhideCenterPanel() {
        self.centerPanelContainer.hidden = false
        if !(self.centerPanel.view.superview != nil) {
            self.centerPanel.view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            self.centerPanel.view.frame = self.centerPanelContainer.bounds
            self.stylePanel(self.centerPanel.view)
            self.centerPanelContainer.addSubview(self.centerPanel.view)
        }
    }
    
    
    func _toggleScrollsToTopForCenter(center: Bool, left: Bool, right: Bool) {
        // iPhone only supports 1 active UIScrollViewController at a time
        if UI_USER_INTERFACE_IDIOM() == .Phone {
            self._toggleScrollsToTop(center, forView: self.centerPanelContainer)
            self._toggleScrollsToTop(left, forView: self.leftPanelContainer)
            self._toggleScrollsToTop(right, forView: self.rightPanelContainer)
        }
    }
    
    func _toggleScrollsToTop(enabled: Bool, forView view: UIView) -> Bool {
        if (view is UIScrollView) {
            let scrollView = (view as! UIScrollView)
            scrollView.scrollsToTop = enabled
            return true
        }
        else {
            for subview: UIView in view.subviews {
                if self._toggleScrollsToTop(enabled, forView: subview) {
                    return true
                }
            }
        }
        return false
    }
    
    // MARK: - Key Value Observing
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>){
        if context == ja_kvoContext {
            if (keyPath == "view") {
                if self.centerPanel.isViewLoaded() && self.recognizesPanGesture {
                    self._addPanGestureToView(self.centerPanel.view)
                }
            }
            else if (keyPath! == "viewControllers") && object as! UIViewController == self.centerPanel {
                // view controllers have changed, need to replace the button
                self._placeButtonForLeftPanel()
            }
        }
        else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    // MARK: - Public Methods
    /*- (UIBarButtonItem *)leftButtonForCenterPanel {
     return [[UIBarButtonItem alloc] initWithImage:[[self class] defaultImage] style:UIBarButtonItemStylePlain target:self action:@selector(toggleLeftPanel:)];
     }*/
    
    func leftButtonForCenterPanel() -> UIBarButtonItem {
        return UIBarButtonItem(image: JASidePanelController.defaultImage(), style: .Plain, target: self, action: #selector(self.toggleLeftPanel))
    }
    
    func showLeftPanel(animated: Bool) {
        self.showLeftPanelAnimated(animated)
    }
    
    func showRightPanel(animated: Bool) {
        self.showRightPanelAnimated(animated)
    }
    
    func showCenterPanel(animated: Bool) {
        self.showCenterPanelAnimated(animated)
    }
    
    func showLeftPanelAnimated(animated: Bool) {
        self._showLeftPanel(animated, bounce: false)
    }
    
    func showRightPanelAnimated(animated: Bool) {
        self._showRightPanel(animated, bounce: false)
    }
    
    
    func showCenterPanelAnimated(animated: Bool) {
        // make sure center panel isn't hidden
        if centerPanelHidden {
            self.centerPanelHidden = false
            self._unhideCenterPanel()
        }
        self._showCenterPanel(animated, bounce: false)
    }
    
    func toggleLeftPanel(sender: AnyObject) {
        if self.state == .JASidePanelLeftVisible {
            self._showCenterPanel(true, bounce: false)
        }
        else if self.state == .JASidePanelCenterVisible {
            self._showLeftPanel(true, bounce: false)
        }
        
    }
    
    func toggleRightPanel(sender: AnyObject) {
        if self.state == .JASidePanelRightVisible {
            self._showCenterPanel(true, bounce: false)
        }
        else if self.state == .JASidePanelCenterVisible {
            self._showRightPanel(true, bounce: false)
        }
        
    }
    
    
    
    
    func setCenterPanelHidden(centerPanelHidden: Bool, animated: Bool, duration: NSTimeInterval) {
        if centerPanelHidden != centerPanelHidden && self.state != .JASidePanelCenterVisible {
            self.centerPanelHidden = centerPanelHidden
            let duration = animated ? duration : 0.0
            if centerPanelHidden {
                UIView.animateWithDuration(duration, animations: {() -> Void in
                    var frame = self.centerPanelContainer.frame
                    frame.origin.x = self.state == .JASidePanelLeftVisible ? self.centerPanelContainer.frame.size.width : -self.centerPanelContainer.frame.size.width
                    self.centerPanelContainer.frame = frame
                    self._layoutSideContainers(false, duration: 0)
                    if self.shouldResizeLeftPanel || self.shouldResizeRightPanel {
                        self._layoutSidePanels()
                    }
                    }, completion: {(finished) -> Void in
                        // need to double check in case the user tapped really fast
                        if centerPanelHidden {
                            self._hideCenterPanel()
                        }
                })
            }
            else {
                self._unhideCenterPanel()
                UIView.animateWithDuration(duration, animations: {() -> Void in
                    if self.state == .JASidePanelLeftVisible {
                        self.showLeftPanelAnimated(false)
                    }
                    else {
                        self.showRightPanelAnimated(false)
                    }
                    if self.shouldResizeLeftPanel || self.shouldResizeRightPanel {
                        self._layoutSidePanels()
                    }
                })
            }
        }
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

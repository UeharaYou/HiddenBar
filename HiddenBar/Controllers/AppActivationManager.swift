//
//  AppActivationManager.swift
//  Hidden Bar
//
//  Created by 上原葉 on 8/4/23.
//  Copyright © 2023 UeharaYou. All rights reserved.
//

import AppKit

class AppActivationManager {
    //static private var activationPolicy: NSApplication.ActivationPolicy = .accessory
    private let updateLock = NSLock()
    
    private static let instance = AppActivationManager()
    
    public static func setup() {
        NotificationCenter.default.addObserver(forName: NotificationNames.prefsChanged, object: nil, queue: Global.mainQueue) {[] (notification) in
            triggerAdjustment()
        }
        
        // Manually adjusting the bar once
        triggerAdjustment()
    }
    
    public static func finishUp() {
    }
    
    private static func triggerAdjustment() {
        adjustAppActivation()
    }
    
    private static func adjustAppActivation() {
        
        //TODO: do not deactivate if preference window is shown
        let lock = instance.updateLock
        lock.lock(before: Date(timeIntervalSinceNow: 1))
        
        let shouldActiveIgnoringOtherApp = !Util.hasFullScreenWindow()
        let previousActivationPolicy = NSApp.activationPolicy()
        
        // Handle Activation Policy
        // First Layer Decision: UI State
        // Querying before storyboard is ready WILL DEADLOCK the app!!!!!!!!!
        if(PreferencesWindowController.isPrefWindowVisible) {
            NSApp.setActivationPolicy(.regular)
        }
        else {
            // Second Layer Decision: Preference
            switch (PreferenceManager.isUsingFullStatusBar, PreferenceManager.isEditMode, PreferenceManager.statusBarPolicy) {
            case (false, _, _), (true, false, .collapsed):
                NSApp.setActivationPolicy(.accessory)
            case (true, true, _), (true, _, .partialExpand), (true, _, .fullExpand):
                NSApp.setActivationPolicy(.regular)
            }
        }
        
        // Handle App Activation
        switch (previousActivationPolicy, NSApp.activationPolicy()) {
        case (.accessory, .regular):
//            if #available(macOS 14.0, *) {
//                if (shouldActiveIgnoringOtherApp && !NSApp.isActive) {
//                    NSApp.activate()
//                }
//            }
//            else {
                NSApp.activate(ignoringOtherApps: shouldActiveIgnoringOtherApp)
//            }
        case (.regular, .accessory):
            if (NSApp.isActive) {
                NSApp.deactivate()
            }
        default:
            break;
        }
        
        lock.unlock()
    }
}

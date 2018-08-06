//
//  PreferenceManager.swift
//  vCommander
//
//  Created by Jamie on 15/11/8.
//  Copyright © 2015年 Jamie. All rights reserved.
//

import Foundation

private let textEditorKey = "textEditor"

private let diffToolKey = "diffTool"

private let leftPanelKey = "leftPanel"

private let rightPanelKey = "rightPanel"

private let modeKey = "mode"

private let sortDescriptorsKey = "sortDescriptors"

class PreferenceManager {
    fileprivate let userDefaults = UserDefaults.standard
    
    init() {
        registerDefaultPreferences()
    }
    
    func registerDefaultPreferences() {
        let defaults = [
            textEditorKey: "/Applications/textEdit.app",
            diffToolKey: "/usr/local/bin/bcompare",
            modeKey: 0,
            sortDescriptorsKey: Data()
        ] as [String : Any]
        
        userDefaults.register(defaults: defaults)
    }
    
    var textEditor: String? {
        set (newTextEditor) {
            userDefaults.set(newTextEditor, forKey: textEditorKey)
        }
        get {
            return userDefaults.object(forKey: textEditorKey) as? String
        }
    }
    
    var diffTool: String? {
        set (newDiffTool) {
            userDefaults.set(newDiffTool, forKey: diffToolKey)
        }
        get {
            return userDefaults.object(forKey: diffToolKey) as? String
        }
    }
    
    var mode: NSNumber? {
        set (newMode) {
            userDefaults.set(newMode, forKey: modeKey)
        }
        get {
            return userDefaults.object(forKey: modeKey) as? NSNumber
        }
    }
    
    var leftPanelData: Dictionary<String, Any>? {
        set (panelData) {
            userDefaults.set(panelData, forKey: leftPanelKey)
        }
        get {
            return userDefaults.dictionary(forKey: leftPanelKey)
        }
    }
    
    var rightPanelData: Dictionary<String, Any>? {
        set (panelData) {
            userDefaults.set(panelData, forKey: rightPanelKey)
        }
        get {
            return userDefaults.dictionary(forKey: rightPanelKey)
        }
    }
    
    var sortDescriptors: Data? {
        set (sortDescriptorsData) {
            userDefaults.set(sortDescriptorsData, forKey: sortDescriptorsKey)
        }
        get {
            return userDefaults.data(forKey: sortDescriptorsKey)
        }
    }
    
}

//
//  PreferenceManager.swift
//  SimpleCommander
//
//  Created by Jamie on 15/11/8.
//  Copyright © 2015年 Jamie. All rights reserved.
//

import Foundation

private let textEditorKey = "textEditor"

private let diffToolKey = "diffTool"

class PreferenceManager {
    fileprivate let userDefaults = UserDefaults.standard
    
    init() {
        registerDefaultPreferences()
    }
    
    func registerDefaultPreferences() {
        let defaults = [ textEditorKey: "/Applications/textEdit.app", diffToolKey: "/usr/local/bin/bcompare" ]
        
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
    
}

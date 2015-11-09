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
    private let userDefaults = NSUserDefaults.standardUserDefaults()
    
    init() {
        registerDefaultPreferences()
    }
    
    func registerDefaultPreferences() {
        let defaults = [ textEditorKey: "/Applications/textEdit.app", diffToolKey: "/usr/local/bin/bcompare" ]
        
        userDefaults.registerDefaults(defaults)
    }
    
    var textEditor: String? {
        set (newTextEditor) {
            userDefaults.setObject(newTextEditor, forKey: textEditorKey)
        }
        get {
            return userDefaults.objectForKey(textEditorKey) as? String
        }
    }
    
    var diffTool: String? {
        set (newDiffTool) {
            userDefaults.setObject(newDiffTool, forKey: diffToolKey)
        }
        get {
            return userDefaults.objectForKey(diffToolKey) as? String
        }
    }
    
}

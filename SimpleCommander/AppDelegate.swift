//
//  AppDelegate.swift
//  SimpleCommander
//
//  Created by Jamie on 15/5/12.
//  Copyright (c) 2015年 Jamie. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowRestoration {
    
    var _mainWindowController: MainWindowController?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.mainWindowController()?.showWindow(self)
    }
    
    func mainWindowController() -> MainWindowController? {
        if _mainWindowController == nil {
            _mainWindowController = MainWindowController()
            _mainWindowController?.window?.isRestorable = true
            _mainWindowController?.window?.restorationClass = type(of: self)
            _mainWindowController?.window?.identifier = "mainWindow"
        }
        
        return _mainWindowController
    }


    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    public static func restoreWindow(withIdentifier identifier: String, state: NSCoder, completionHandler: @escaping (NSWindow?, Error?) -> Void) {
        var window: NSWindow? = nil
        if identifier == "mainWindow" {
            let appDelegate = NSApp.delegate as! AppDelegate
            window = appDelegate.mainWindowController()?.window
        }
        
        print("restoreWindow in AppDelegate calle.")
        completionHandler(window, nil)
    }

}


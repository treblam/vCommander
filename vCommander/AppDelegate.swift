//
//  AppDelegate.swift
//  vCommander
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
        storeTabsData()
    }
    
    func applicationWillResignActive(_ notification: Notification) {
        storeTabsData()
    }
    
    func applicationWillHide(_ notification: Notification) {
        storeTabsData()
    }
    
//    @IBAction func newWindowForTab(_ sender: Any?) {
//        
//    }
    
    func storeTabsData() {
        print("start to store tabs data")
        if let mainController = _mainWindowController {
            mainController.leftPanel.storeTabsData()
            mainController.rightPanel.storeTabsData()
        }
    }
    
    public static func restoreWindow(withIdentifier identifier: String, state: NSCoder, completionHandler: @escaping (NSWindow?, Error?) -> Void) {
        var window: NSWindow? = nil
        if identifier == "mainWindow" {
            let appDelegate = NSApp.delegate as! AppDelegate
            window = appDelegate.mainWindowController()?.window
        }
        
        print("restoreWindow in AppDelegate called.")
        completionHandler(window, nil)
    }
    
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        return (mainWindowController()?.openFile(for: filename)) ?? false
    }

}


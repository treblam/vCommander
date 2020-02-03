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
    
    let preferenceManager = PreferenceManager()
    
    var sortDescriptors: Dictionary<String, Any>!
    
    override init() {
        if let sortDescriptorsData = preferenceManager.sortDescriptors {
            sortDescriptors = (NSKeyedUnarchiver.unarchiveObject(with: sortDescriptorsData) as! Dictionary<String, Any>)
        } else {
            sortDescriptors = Dictionary<String, Any>()
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.mainWindowController()?.showWindow(self)
    }
    
    func mainWindowController() -> MainWindowController? {
        if _mainWindowController == nil {
            _mainWindowController = MainWindowController()
            _mainWindowController?.window?.isRestorable = true
            _mainWindowController?.window?.restorationClass = type(of: self)
            _mainWindowController?.window?.identifier = NSUserInterfaceItemIdentifier(rawValue: "mainWindow")
            _mainWindowController?.window?.setFrameAutosaveName("mainWindow")
        }
        
        return _mainWindowController
    }


    func applicationWillTerminate(_ aNotification: Notification) {
        storeTabsData()
        storeSortDescriptors()
    }
    
    func applicationWillResignActive(_ notification: Notification) {
        storeTabsData()
        storeSortDescriptors()
    }
    
    func applicationWillHide(_ notification: Notification) {
        storeTabsData()
        storeSortDescriptors()
    }
    
    func storeSortDescriptors() {
        preferenceManager.sortDescriptors = NSKeyedArchiver.archivedData(withRootObject: sortDescriptors!)
    }
    
    func storeTabsData() {
        print("start to store tabs data")
        mainWindowController()?.leftPanel.storeTabsData()
        mainWindowController()?.rightPanel.storeTabsData()
    }
    
    public static func restoreWindow(withIdentifier identifier: NSUserInterfaceItemIdentifier, state: NSCoder, completionHandler: @escaping (NSWindow?, Error?) -> Void) {
        print("restoreWindow in AppDelegate called.")
        var window: NSWindow? = nil
        if identifier.rawValue == "mainWindow" {
            let appDelegate = NSApp.delegate as! AppDelegate
            window = appDelegate.mainWindowController()?.window
            // The system should but doesn't call it, I have to do it myself
            appDelegate.mainWindowController()?.restoreState(with: state)
        }
        
        completionHandler(window, nil)
    }
    
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        return (mainWindowController()?.openFile(for: filename)) ?? false
    }

}


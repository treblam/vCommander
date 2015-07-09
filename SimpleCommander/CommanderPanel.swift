//
//  CommanderPanel.swift
//  SimpleCommander
//
//  Created by Jamie on 15/6/4.
//  Copyright (c) 2015年 Jamie. All rights reserved.
//

import Cocoa

class CommanderPanel: NSViewController, NSTableViewDataSource, NSTableViewDelegate, MMTabBarViewDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        tabBar.setShowAddTabButton(true)
        tabBar.setStyleNamed("Card")
        
        addNewTabToTabView(tabView)
    }
    
    
    @IBOutlet weak var tabView: NSTabView!
    
    @IBOutlet weak var tabBar: MMTabBarView!
    
    func addNewTabToTabView(aTabView: NSTabView!) {
        var newModel = TabBarModel()
        
        var newItem = NSTabViewItem(identifier: newModel)
        
        var curViewController = tabView.selectedTabViewItem?.viewController as? TabItemController
        var url = curViewController?.curFsItem.fileURL
        
        var newItemController = TabItemController(nibName: "TabItemController", bundle: nil, url: url)
        
        newModel.title = newItemController?.title ?? "Untitled"
        
        newItem.viewController = newItemController!
        newItem.identifier = newModel
        
        tabView.addTabViewItem(newItem)
        tabView.selectTabViewItem(newItem)
    }
    
    func tabView(aTabView: NSTabView!, shouldCloseTabViewItem tabViewItem: NSTabViewItem!) -> Bool {
        return true
    }
    
    func tabView(aTabView: NSTabView!, shouldAllowTabViewItem tabViewItem: NSTabViewItem!, toLeaveTabBarView tabBarView: MMTabBarView!) -> Bool {
        return true
    }
    
    func tabView(aTabView: NSTabView!, toolTipForTabViewItem tabViewItem: NSTabViewItem!) -> String! {
        return tabViewItem.label
    }
    
    func tabView(aTabView: NSTabView!, tabBarViewDidHide tabBarView: MMTabBarView!) {
        println("tabBarViewDidHide")
    }
    
    func tabView(aTabView: NSTabView!, tabBarViewDidUnhide tabBarView: MMTabBarView!) {
        println("tabBarViewDidUnhide")
    }

    
}

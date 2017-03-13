//
//  TabBarModal.swift
//  vCommander
//
//  Created by Jamie on 15/6/2.
//  Copyright (c) 2015年 Jamie. All rights reserved.
//

import Foundation

class TabBarModel: NSObject, MMTabBarItem {
    
    var title: String
    
    var length = 10
    
    var hasCloseButton = true
    
    override init () {
        title = "Untitled"
        super.init()
    }
    
}

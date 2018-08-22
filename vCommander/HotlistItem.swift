//
//  HotlistItem.swift
//  vCommander
//
//  Created by Jerry's Macbook on 2018/8/21.
//  Copyright © 2018年 Jamie. All rights reserved.
//

import Cocoa

class HotlistItem: NSObject {
    var name: String
    var hotkey: String?
    var url: URL?
    let isSubmenu: Bool
    
    var path: String? {
        return url?.path
    }
    
    var children = [HotlistItem]()
    
    init(name: String, hotkey: String?, isSubmenu: Bool, url: URL?) {
        self.name = name
        self.hotkey = hotkey
        self.isSubmenu = isSubmenu
        self.url = url
    }
    
    convenience init(name: String, hotkey: String?, isSubmenu: Bool) {
        self.init(name: name, hotkey: hotkey, isSubmenu: isSubmenu, url: nil)
    }
    
}

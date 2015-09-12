//
//  FileSystemItem.swift
//  SimpleCommander
//
//  Created by Jamie on 15/5/15.
//  Copyright (c) 2015年 Jamie. All rights reserved.
//

import Cocoa

class FileSystemItem: NSObject {
    
    let propertyKeys = [NSURLLocalizedNameKey, NSURLEffectiveIconKey, NSURLIsPackageKey, NSURLIsDirectoryKey,NSURLTypeIdentifierKey]
    
    let fileURL: NSURL
    
    let workspace = NSWorkspace()
    
    lazy var path: String! = { [unowned self] in
        return self.fileURL.path
    }()
    
    lazy var name: String! = { [unowned self] in
        let resourceValues = self.fileURL.resourceValuesForKeys([NSURLNameKey], error: nil)
        return resourceValues![NSURLNameKey] as? String
    }()
    
    lazy var localizedName: String! = { [unowned self] in
        let resourceValues = self.fileURL.resourceValuesForKeys([NSURLLocalizedNameKey], error: nil)
        return resourceValues![NSURLLocalizedNameKey] as? String
    }()
    
    lazy var localizedType: String! = { [unowned self] in
        let workspace = NSWorkspace()
        return workspace.localizedDescriptionForType(self.typeIdentifier)
    }()
    
    lazy var icon: NSImage! = { [unowned self] in
        let resourceValues = self.fileURL.resourceValuesForKeys([NSURLEffectiveIconKey], error: nil)
        return resourceValues![NSURLEffectiveIconKey] as? NSImage
    }()
    
    lazy var dateOfCreation: NSDate! = { [unowned self] in
        let resourceValues = self.fileURL.resourceValuesForKeys([NSURLCreationDateKey], error: nil)
        return resourceValues![NSURLCreationDateKey] as? NSDate
    }()
    
    lazy var dateOfLastModification: NSDate! = { [unowned self] in
        let resourceValues = self.fileURL.resourceValuesForKeys([NSURLContentModificationDateKey], error: nil)
        return resourceValues![NSURLContentModificationDateKey] as? NSDate
    }()
    
    lazy var typeIdentifier: String! = { [unowned self] in
        let resourceValues = self.fileURL.resourceValuesForKeys([NSURLTypeIdentifierKey], error: nil)
        return resourceValues![NSURLTypeIdentifierKey] as? String
    }()
    
    lazy var isDirectory: Bool = { [unowned self] in
        let resourceValues = self.fileURL.resourceValuesForKeys([NSURLIsDirectoryKey], error: nil)
        let number = resourceValues![NSURLIsDirectoryKey] as? NSNumber
        
        if let isDir = number {
            return isDir.boolValue && !self.isPackage
        } else {
            return false
        }
    }()
    
    lazy var isPackage: Bool = { [unowned self] in
        return self.workspace.isFilePackageAtPath(self.fileURL.path!)
    }()
    
    lazy var size: NSNumber! = { [unowned self] in
        if self.isDirectory {
            return -1
        }
        
        let resourceValues = self.fileURL.resourceValuesForKeys([NSURLFileSizeKey], error: nil)
        let fileSize = resourceValues![NSURLFileSizeKey] as? NSNumber
        
        return fileSize ?? -1
    }()
    
    lazy var localizedSize: String! = { [unowned self] in
        let fileSize = self.size.intValue
        if fileSize >= 0 {
            let formatter = NSByteCountFormatter()
            formatter.allowsNonnumericFormatting = false
            return formatter.stringFromByteCount(Int64(fileSize))
        } else {
            return "--"
        }
    }()
    
    lazy var children: [FileSystemItem] = { [unowned self] in
        
        var childs: [FileSystemItem] = []
        var isDirectory: ObjCBool = ObjCBool(true)
        let fileManager = NSFileManager.defaultManager()
        
        if (fileManager.fileExistsAtPath(self.fileURL.relativePath!)) {
            
            if let itemURLs = fileManager.contentsOfDirectoryAtURL(self.fileURL, includingPropertiesForKeys: self.propertyKeys, options:.SkipsHiddenFiles, error:nil) {
                
                for fsItemURL in itemURLs as! [NSURL] {
                    
                    if fileManager.fileExistsAtPath(fsItemURL.relativePath!, isDirectory: &isDirectory) {
                        //if(isDirectory.boolValue) {
                            let checkItem = FileSystemItem(fileURL: fsItemURL)
                            childs.append(checkItem)
                        //}
                    }
                    
                }
            }
        }
        return childs
    }()
    
    init (fileURL: NSURL) {
        self.fileURL = fileURL
    }
    
    func hasChildren() -> Bool {
        return self.children.count > 0
    }
    
}

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
        let resourceValues = try? self.fileURL.resourceValuesForKeys([NSURLNameKey])
        return resourceValues![NSURLNameKey] as? String
    }()
    
    lazy var localizedName: String! = { [unowned self] in
        let resourceValues = try? self.fileURL.resourceValuesForKeys([NSURLLocalizedNameKey])
        return resourceValues![NSURLLocalizedNameKey] as? String
    }()
    
    lazy var localizedType: String! = { [unowned self] in
        let workspace = NSWorkspace()
        return workspace.localizedDescriptionForType(self.typeIdentifier)
    }()
    
    lazy var icon: NSImage! = { [unowned self] in
        let resourceValues = try? self.fileURL.resourceValuesForKeys([NSURLEffectiveIconKey])
        return resourceValues![NSURLEffectiveIconKey] as? NSImage
    }()
    
    lazy var dateOfCreation: NSDate! = { [unowned self] in
        let resourceValues = try? self.fileURL.resourceValuesForKeys([NSURLCreationDateKey])
        return resourceValues![NSURLCreationDateKey] as? NSDate
    }()
    
    lazy var dateOfLastModification: NSDate! = { [unowned self] in
        let resourceValues = try? self.fileURL.resourceValuesForKeys([NSURLContentModificationDateKey])
        return resourceValues![NSURLContentModificationDateKey] as? NSDate
    }()
    
    lazy var typeIdentifier: String! = { [unowned self] in
        let resourceValues = try? self.fileURL.resourceValuesForKeys([NSURLTypeIdentifierKey])
        return resourceValues![NSURLTypeIdentifierKey] as? String
    }()
    
    lazy var isDirectory: Bool = { [unowned self] in
        let resourceValues = try? self.fileURL.resourceValuesForKeys([NSURLIsDirectoryKey])
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
        
        let resourceValues = try? self.fileURL.resourceValuesForKeys([NSURLFileSizeKey])
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
            
            if let itemURLs = try? fileManager.contentsOfDirectoryAtURL(self.fileURL, includingPropertiesForKeys: self.propertyKeys, options:.SkipsHiddenFiles) {
                
                for fsItemURL in itemURLs {
                    
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

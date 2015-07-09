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
    
    var path: String! {
        return fileURL.path
    }
    
    var name: String! {
        let resourceValues = fileURL.resourceValuesForKeys([NSURLNameKey], error: nil)
        return resourceValues![NSURLNameKey] as? String
    }
    
    var localizedName: String! {
        let resourceValues = fileURL.resourceValuesForKeys([NSURLLocalizedNameKey], error: nil)
        return resourceValues![NSURLLocalizedNameKey] as? String
    }
    
    var localizedType: String! {
        let workspace = NSWorkspace()
        return workspace.localizedDescriptionForType(typeIdentifier)
    }
    
    var icon: NSImage! {
        let resourceValues = fileURL.resourceValuesForKeys([NSURLEffectiveIconKey], error: nil)
        return resourceValues![NSURLEffectiveIconKey] as? NSImage
    }
    
    var dateOfCreation: NSDate! {
        let resourceValues = fileURL.resourceValuesForKeys([NSURLCreationDateKey], error: nil)
        return resourceValues![NSURLCreationDateKey] as? NSDate
    }
    
    var dateOfLastModification: NSDate! {
        let resourceValues = fileURL.resourceValuesForKeys([NSURLContentModificationDateKey], error: nil)
        return resourceValues![NSURLContentModificationDateKey] as? NSDate
    }
    
    var typeIdentifier: String! {
        let resourceValues = fileURL.resourceValuesForKeys([NSURLTypeIdentifierKey], error: nil)
        return resourceValues![NSURLTypeIdentifierKey] as? String
    }
    
    var isDirectory: Bool {
        let resourceValues = fileURL.resourceValuesForKeys([NSURLIsDirectoryKey], error: nil)
        let number = resourceValues![NSURLIsDirectoryKey] as? NSNumber
        
        if let isDir = number {
            return isDir.boolValue && !isPackage
        } else {
            return false
        }
    }
    
    var isPackage: Bool {
        return workspace.isFilePackageAtPath(fileURL.path!)
    }
    
    var size: String! {
        if isDirectory {
            return "--"
        }
        
        let resourceValues = fileURL.resourceValuesForKeys([NSURLFileSizeKey], error: nil)
        let fileSize = resourceValues![NSURLFileSizeKey] as? NSNumber
        let formatter = NSByteCountFormatter()
        formatter.allowsNonnumericFormatting = false
        if let size = fileSize {
            return formatter.stringFromByteCount(Int64(size.intValue))
        } else {
            return "unknow"
        }
    }
    
    var children: [FileSystemItem] {
        
        var childs: [FileSystemItem] = []
        var isDirectory: ObjCBool = ObjCBool(true)
        let fileManager = NSFileManager.defaultManager()
        var checkValidation = NSFileManager.defaultManager()
        
        if (checkValidation.fileExistsAtPath(fileURL.relativePath!)) {
            
            if let itemURLs = fileManager.contentsOfDirectoryAtURL(fileURL, includingPropertiesForKeys:propertyKeys, options:.SkipsHiddenFiles, error:nil) {
                
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
    }
    
    init (fileURL: NSURL) {
        self.fileURL = fileURL
    }
    
    func hasChildren() -> Bool {
        return self.children.count > 0
    }
    
}

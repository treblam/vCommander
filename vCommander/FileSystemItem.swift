//
//  FileSystemItem.swift
//  vCommander
//
//  Created by Jamie on 15/5/15.
//  Copyright (c) 2015年 Jamie. All rights reserved.
//

import Cocoa

class FileSystemItem: NSObject {
    
    let propertyKeys = [URLResourceKey.localizedNameKey, URLResourceKey.effectiveIconKey, URLResourceKey.isPackageKey, URLResourceKey.isDirectoryKey,URLResourceKey.typeIdentifierKey]
    
    let fileURL: URL
    
    let workspace = NSWorkspace()
    
    lazy var path: String! = { [unowned self] in
        return self.fileURL.path
    }()
    
    @objc lazy dynamic var name: String! = { [unowned self] in
        let resourceValues = try? (self.fileURL as NSURL).resourceValues(forKeys: [URLResourceKey.nameKey])
        return resourceValues![URLResourceKey.nameKey] as? String
    }()
    
    @objc lazy dynamic var localizedName: String! = { [unowned self] in
        let resourceValues = try? (self.fileURL as NSURL).resourceValues(forKeys: [URLResourceKey.localizedNameKey])
        return resourceValues?[URLResourceKey.localizedNameKey] as? String ?? ""
    }()
    
    @objc lazy dynamic var localizedType: String! = { [unowned self] in
        let workspace = NSWorkspace()
        return workspace.localizedDescription(forType: self.typeIdentifier)
    }()
    
    lazy var icon: NSImage! = { [unowned self] in
        let resourceValues = try? (self.fileURL as NSURL).resourceValues(forKeys: [URLResourceKey.effectiveIconKey])
        return resourceValues![URLResourceKey.effectiveIconKey] as? NSImage
    }()
    
    @objc lazy dynamic var dateOfCreation: Date! = { [unowned self] in
        let resourceValues = try? (self.fileURL as NSURL).resourceValues(forKeys: [URLResourceKey.creationDateKey])
        return resourceValues![URLResourceKey.creationDateKey] as? Date
    }()
    
    @objc lazy dynamic var dateOfLastModification: Date! = { [unowned self] in
        let resourceValues = try? (self.fileURL as NSURL).resourceValues(forKeys: [URLResourceKey.contentModificationDateKey])
        return resourceValues![URLResourceKey.contentModificationDateKey] as? Date
    }()
    
    @objc lazy dynamic var typeIdentifier: String! = { [unowned self] in
        let resourceValues = try? (self.fileURL as NSURL).resourceValues(forKeys: [URLResourceKey.typeIdentifierKey])
        return resourceValues![URLResourceKey.typeIdentifierKey] as? String
    }()
    
    lazy var isDirectory: Bool = { [unowned self] in
        let resourceValues = try? (self.fileURL as NSURL).resourceValues(forKeys: [URLResourceKey.isDirectoryKey])
        let isDir = resourceValues?[URLResourceKey.isDirectoryKey] as? Bool
        
        return isDir != nil && isDir! && !self.isPackage
    }()
    
    lazy var isPackage: Bool = { [unowned self] in
        return self.workspace.isFilePackage(atPath: self.fileURL.path)
    }()
    
    lazy var isSymbolicLink: Bool = { [unowned self] in
        let resourceValues = try? (self.fileURL as NSURL).resourceValues(forKeys: [.isSymbolicLinkKey])
        return resourceValues![URLResourceKey.isSymbolicLinkKey] as? Bool ?? false
    }()
    
    lazy var destinationItem: FileSystemItem? = { [unowned self] in
        let path = try? FileManager.default.destinationOfSymbolicLink(atPath: self.fileURL.path)
        return path != nil ? FileSystemItem(fileURL: URL(fileURLWithPath: path!))  : nil
    }()
    
    lazy var isReadable: Bool = { [unowned self] in
        let resourceValues = try? (self.fileURL as NSURL).resourceValues(forKeys: [.isReadableKey])
        return resourceValues?[URLResourceKey.isReadableKey] as? Bool ?? false
    }()
    
    @objc lazy dynamic var size: NSNumber! = { [unowned self] in
        if self.isDirectory {
            return -1
        }
        
        let resourceValues = try? (self.fileURL as NSURL).resourceValues(forKeys: [URLResourceKey.fileSizeKey])
        let fileSize = resourceValues![URLResourceKey.fileSizeKey] as? NSNumber
        
        return fileSize ?? -1
    }()
    
    lazy var localizedSize: String! = { [unowned self] in
        let fileSize = self.size.int32Value
        if fileSize >= 0 {
            let formatter = ByteCountFormatter()
            formatter.allowsNonnumericFormatting = false
            return formatter.string(fromByteCount: Int64(fileSize))
        } else {
            return "--"
        }
    }()
    
    lazy var children: [FileSystemItem]! = { [unowned self] in
        
        var childs: [FileSystemItem] = []
        var isDirectory: ObjCBool = ObjCBool(true)
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: self.fileURL.relativePath) {
            if let itemURLs = try? fileManager.contentsOfDirectory(at: self.fileURL, includingPropertiesForKeys: self.propertyKeys, options:.skipsHiddenFiles) {
                for fsItemURL in itemURLs {
                    if fileManager.fileExists(atPath: fsItemURL.relativePath, isDirectory: &isDirectory) {
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
    
    init (fileURL: URL) {
        self.fileURL = fileURL
    }
    
    func hasChildren() -> Bool {
        return self.children.count > 0
    }
    
}

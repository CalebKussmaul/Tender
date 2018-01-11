//
//  FolderState.swift
//  Tender
//
//  Created by Caleb Kussmaul on 1/10/18.
//  Copyright © 2018 Caleb Kussmaul. All rights reserved.
//

import AppKit

enum StateError: Error {
  case EmptyDir
}

class TenderState {
  
  let manager = FileManager.default
  
  let dir:URL
  let stateFile:URL
  
  public var rejected:[URL]
  public var accepted:[URL]
  public var unsorted:[URL]
  
  init(dir: URL) throws {
    self.dir = dir
    self.stateFile = dir.appendingPathComponent(".tender_state")
    do {
      try self.unsorted = manager.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.tagNamesKey, .creationDateKey, .contentModificationDateKey, .nameKey, .fileSizeKey, .isDirectoryKey], options: [.skipsHiddenFiles])
    } catch let error as NSError {
      throw error
    }
    if unsorted.isEmpty {
      throw StateError.EmptyDir
    }
    
    self.rejected = []
    self.accepted = []
  }
  
  func promptRestore(window: NSWindow, onCompletion: @escaping () -> Void) {
    if(!manager.fileExists(atPath: stateFile.path)) {
      onCompletion()
      return
    }
    let alert = NSAlert()
    alert.messageText = "Restore previous state?"
    alert.informativeText = "Tender was exited prematurely in this directory. You can continue where you left off, or start over."
    alert.alertStyle = NSAlertStyle.informational
    alert.addButton(withTitle: "Restore")
    alert.addButton(withTitle: "Start over")
    alert.beginSheetModal(for: window, completionHandler: {(result) in
      if result == NSAlertFirstButtonReturn {
        self.restore()
      }
      onCompletion()
    })
  }
  
  func restore() {
    if let dict = NSDictionary(contentsOf: stateFile) {
      if let aNames = (dict["accepted"] ?? nil) as? [String], let rNames = (dict["rejected"] ?? nil) as? [String] {
        for name in aNames {
          for (i, f) in unsorted.enumerated() {
            if f.path == dir.appendingPathComponent(name).path {
              accepted.append(f)
              unsorted.remove(at: i)
              break
            }
          }
        }
        for name in rNames {
          for (i, f) in unsorted.enumerated() {
            if f.path == dir.appendingPathComponent(name).path {
              rejected.append(f)
              unsorted.remove(at: i)
              break
            }
          }
        }
      }
    }
  }
  
  func sortFiles(sortBy: SortBy, groupByType: Bool, descending: Bool) {
    unsorted.sort(by:{a, b in
      if groupByType {
        let aComp = (isLikelyJunk(a), a.hasDirectoryPath ? 1 : 0, a.pathExtension)
        let bComp = (isLikelyJunk(b), b.hasDirectoryPath ? 1 : 0, b.pathExtension)
        if aComp != bComp {
          return aComp < bComp
        }
      }
      var comp:Bool = false
      switch sortBy {
      case .Name:
          comp = a.lastPathComponent < b.lastPathComponent
      case .Created:
        if let (aVals, bVals) = try? (a.resourceValues(forKeys: [.creationDateKey]), b.resourceValues(forKeys: [.creationDateKey])) {
          return aVals.creationDate! > bVals.creationDate!
        }
      case .Modified:
        if let (aVals, bVals) = try? (a.resourceValues(forKeys: [.contentModificationDateKey]), b.resourceValues(forKeys: [.contentModificationDateKey])) {
          comp = aVals.contentModificationDate! > bVals.contentModificationDate!
        }
      }
      return (descending ? !comp: comp)
    })
  }
  
  func isLikelyJunk(_ file: URL) -> Int {
    return ["zip", "dmg"].contains(file.pathExtension) ? 0 : 1
  }
  
  func remaining() -> Int {
    return unsorted.count
  }
  
  func total()->Int {
    return unsorted.count + rejected.count + accepted.count
  }
  
  func pctDone()->Double {
    return 100.0 * (1.0 - Double(remaining())/Double(total()))
  }
  
  func rejectedSize()->Int64 {
    var size:Int64 = 0
    for f in rejected {
      if(f.hasDirectoryPath) {
        size += dirSize(file: f)
      } else {
        try? size += FileManager.default.attributesOfItem(atPath: f.path)[FileAttributeKey.size] as! Int64
      }
    }
    return size
  }
  
  func dirSize(file: URL)->Int64 {
    var folderSize:Int64 = 0
    manager.enumerator(at: file, includingPropertiesForKeys: [.fileSizeKey], options: [])?.forEach {
      folderSize += Int64((try? ($0 as? URL)?.resourceValues(forKeys: [.fileSizeKey]))??.fileSize ?? 0)
    }
    return folderSize;
  }
  
  func accept() -> URL {
    let url = unsorted.removeFirst()
    accepted.append(url)
    return url
  }
  
  func undoAccept() {
    unsorted.insert(accepted.removeLast(), at: 0)
  }
  
  func reject() -> URL {
    let url = unsorted.removeFirst()
    rejected.append(url)
    return url
  }
  
  func undoReject() {
    unsorted.insert(rejected.removeLast(), at: 0)
  }
  
  //undoing renames can be done by undoing the change in the text field and re-renaming
  func rename(name: String) throws {
    if name == unsorted.first!.lastPathComponent {
      return
    }
    let newPath = unsorted.first!.deletingLastPathComponent().path + "/" + name
    do {
      try manager.moveItem(atPath: unsorted.first!.path, toPath: newPath)
      unsorted.removeFirst()
      unsorted.insert(URL(fileURLWithPath: newPath), at: 0)
    } catch {
      throw error
    }
  }
  
  //Can't undo moves due to sandboxing!
  func move(to: URL) throws {
    do {
      try manager.moveItem(atPath: unsorted.removeFirst().path, toPath: to.path)
    } catch {
      throw error
    }
  }
  
  func setFinderTags(tags: [String]) throws {
    do {
      try (unsorted.first! as NSURL).setResourceValue(tags, forKey: .tagNamesKey)
    } catch {
      throw error
    }
  }
  
  func open() {
    NSWorkspace.shared().open(unsorted.first!)
  }
  
  func showInFinder() {
    NSWorkspace.shared().selectFile(unsorted.first!.path, inFileViewerRootedAtPath: unsorted.first!.relativePath)
  }
  
  func rejectAllOfType() -> ([URL], String) {
    var ext = unsorted.first!.pathExtension
    let isDir = unsorted.first!.hasDirectoryPath
    let toReject = unsorted.filter({url in
      return url.pathExtension == ext && url.hasDirectoryPath == isDir
    })
    toReject.forEach({url in
      rejected.insert(url, at: 0)
    })
    unsorted = unsorted.filter({url in
      return url.pathExtension != ext || url.hasDirectoryPath != isDir
    })
    if(ext == "") {
      if(!isDir){
        ext = "no-extension"
      } else {
        ext = "directory"
      }
    }
    return (toReject, ext)
  }
  
  func undoRejectAllOfType(numRejected: Int) {
    unsorted = rejected[0..<numRejected] + unsorted
    rejected.removeFirst(numRejected)
  }
  
  func save() {
    let acceptedNames = accepted.map{$0.lastPathComponent}
    let rejectedNames = rejected.map{$0.lastPathComponent}
    var dict = [String: Any]()
    dict["accepted"] = acceptedNames
    dict["rejected"] = rejectedNames
    do {
      try (dict as NSDictionary).write(to: stateFile)
    } catch {
      let nsError = error as NSError
      print(nsError.localizedDescription)
    }
  }
  
  func finishMoveFiles() {
    let folder = dir.appendingPathComponent("rejected files")
    if(!manager.fileExists(atPath: folder.path)) {
      do {
        try manager.createDirectory(at: folder, withIntermediateDirectories: false, attributes: nil)
      } catch {
        let alert = NSAlert()
        alert.messageText = "rejected file folder could not be created. Tender state has been saved"
        alert.alertStyle = NSAlertStyle.informational
        alert.addButton(withTitle: "Okay")
        alert.runModal()
        return
      }
      
      NSWorkspace.shared().selectFile(folder.path, inFileViewerRootedAtPath: folder.deletingLastPathComponent().path)
      var errors: [String] = []
      for f in rejected {
        do {
          try manager.moveItem(at: f, to: folder.appendingPathComponent(f.lastPathComponent))
        } catch {
          errors.append(f.lastPathComponent)
        }
      }
      if errors.isEmpty {
        deleteStateFile()
      } else {
        let alert = NSAlert()
        alert.messageText = "The following files: \(errors.joined(separator: ",")) could not be moved"
        alert.alertStyle = NSAlertStyle.informational
        alert.addButton(withTitle: "Okay")
        alert.runModal()
      }
    }
  }
  
  func finishDeleteFiles() {
    var errors: [String] = []
    for f in rejected {
      do {
        try manager.removeItem(at: f)
      } catch {
        errors.append(f.lastPathComponent)
      }
    }
    if errors.isEmpty {
      deleteStateFile()
    } else {
      let alert = NSAlert()
      alert.messageText = "The following files: \(errors.joined(separator: ",")) could not be deleted"
      alert.alertStyle = NSAlertStyle.informational
      alert.addButton(withTitle: "Okay")
      alert.runModal()
    }
  }
  
  func deleteStateFile() {
    do {
      try manager.removeItem(at: stateFile)
    } catch {
      let nsError = error as NSError
      print(nsError.localizedDescription)
    }
  }
}

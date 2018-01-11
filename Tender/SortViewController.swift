//
//  SortViewController.swift
//  Tender
//
//  Created by Caleb Kussmaul on 11/19/17.
//  Copyright © 2017 Caleb Kussmaul. All rights reserved.
//

import AppKit
import QuickLook

class SortViewController: NSViewController, NSWindowDelegate {
  
  var state: TenderState!
  
  let preloadCount = 16;
  var preloadedPreviews:Dictionary<URL,NSImage> = [:]
  var previewsBeingLoaded = Set<URL>()
  var previewSize: CGSize = CGSize(width: 1, height: 1)
  
  @IBOutlet var preview: NSImageView!
  @IBOutlet var filenameField: NSTextField!
  @IBOutlet var filesizeField: NSTextField!
  @IBOutlet var createdField: NSTextField!
  @IBOutlet var editedField: NSTextField!
  @IBOutlet var tagField: NSTokenField!
  @IBOutlet var progressIndicator: NSProgressIndicator!
  @IBOutlet var statusLabel: NSTextField!
  
  
  let dfmt = DateFormatter() //ISO8601DateFormatter()
  let previewOpts:CFDictionary = [kQLThumbnailOptionScaleFactorKey as String: 1,
                                  kQLThumbnailOptionIconModeKey as String: true] as CFDictionary
  
  override func viewDidAppear() {
    super.viewDidAppear()
    self.view.window!.delegate = self
  }
  
  func windowShouldClose(_ sender: Any) -> Bool {
    state.save()
    NSApplication.shared().terminate(self)
    return true
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    dfmt.setLocalizedDateFormatFromTemplate("MMMdYYYY")
  }
  
  func setState(state: TenderState) {
    previewSize = preview.bounds.size
    self.state = state
    refresh(reverse:false)
    preloadedPreviews = [:]
    preloadImages()
  }
  
  func preloadImages() {
    for i in 0..<min(state.remaining(), self.preloadCount) {
      preloadPreview(file: state.unsorted[i], fast: false)
    }
  }
  
  @IBAction func onRename(_ sender: NSTextField) {
    do {
      try state.rename(name: sender.stringValue)
    } catch {
      let alert = NSAlert()
      alert.messageText = "Error renaming file"
      alert.informativeText = "The file could not be renamed. Please check its permissions"
      alert.alertStyle = NSAlertStyle.warning
      alert.addButton(withTitle: "Okay")
      alert.beginSheetModal(for: self.view.window!, completionHandler: {(response) in })
    }
  }
  
  @IBAction func onEditTags(_ sender: NSTokenField) {
    print("set tags")
    do {
      try state.setFinderTags(tags: sender.objectValue as! [String])
    } catch {
      let alert = NSAlert()
      alert.messageText = "Error changing file tags"
      alert.informativeText = "The file's Finder tags could not be modified. Please check its permissions"
      alert.alertStyle = NSAlertStyle.warning
      alert.addButton(withTitle: "Okay")
      alert.beginSheetModal(for: self.view.window!, completionHandler: {(response) in })
    }
  }
  
  @IBAction func onReject(_ sender: NSButton) {
    saveChanges()
    next(oldFile: state.reject())
    refresh(reverse:false)
    
    undoManager?.setActionName("reject file")
    undoManager?.registerUndo(withTarget: self, handler: { me in
      me.undoReject(sender: sender)
    })
  }
  
  func undoReject(sender: NSButton) {
    state.undoReject()
    refresh(reverse:true)
    
    undoManager?.setActionName("reject file")
    undoManager?.registerUndo(withTarget: self, handler: { me in
      me.onReject(sender)
    })
  }
  
  @IBAction func onKeep(_ sender: NSButton) {
    saveChanges()
    next(oldFile: state.accept())
    refresh(reverse:true)
    
    undoManager?.setActionName("keep file")
    undoManager?.registerUndo(withTarget: self, handler: { me in
      me.undoKeep(sender: sender)
    })
  }
  
  func undoKeep(sender: NSButton) {
    state.undoAccept()
    refresh(reverse:false)
    
    undoManager?.setActionName("keep file")
    undoManager?.registerUndo(withTarget: self, handler: { me in
      me.onKeep(sender)
    })
  }
  
  @IBAction func onBack(_ sender: NSButton) {
    undoManager?.undo()
  }
  @IBAction func onMove(_ sender: NSButton) {
    let savePanel = NSSavePanel()
    savePanel.nameFieldStringValue = state.unsorted.first!.lastPathComponent
    savePanel.beginSheetModal(for: view.window!, completionHandler: {(result) -> Void in
      if result == NSModalResponseOK {
        self.onMoveConfirm(to: savePanel.url!)
      }
    })
  }
  
  func onMoveConfirm(to: URL) {
    do {
      try state.move(to: to)
      refresh(reverse: false)
    } catch {
      let alert = NSAlert()
      alert.messageText = "File could not be moved to specified location"
      alert.alertStyle = NSAlertStyle.warning
      alert.addButton(withTitle: "Okay")
      alert.runModal()
    }
  }
  
  @IBAction func onOpen(_ sender: NSMenuItem) {
    state.open()
  }
  
  @IBAction func onOpenInFinder(_ sender: NSMenuItem) {
    state.showInFinder()
  }
  

  @IBAction func onRejectAll(_ sender: NSMenuItem) {
    let (ofType, ext) = state.rejectAllOfType()
    for url in ofType {
      preloadedPreviews[url] = nil
    }
    preloadImages()
    
    undoManager?.setActionName("reject all \(ext) files")
    undoManager?.registerUndo(withTarget: self, handler: { me in
      me.undoRejectAll(sender, numRejected: ofType.count, ext:ext)
    })
    refresh(reverse: false)
  }
  
  func undoRejectAll(_ sender: NSMenuItem, numRejected: Int, ext: String) {
    state.undoRejectAllOfType(numRejected: numRejected)
    preloadImages()
    undoManager?.setActionName("reject all .\(ext) files")
    undoManager?.registerUndo(withTarget: self, handler: { me in
      me.onRejectAll(sender)
    })
    refresh(reverse: false)
  }
  
  func next(oldFile: URL) {
    preloadedPreviews[oldFile] = nil
    loadOneMorePreview()
  }
  
  func loadOneMorePreview() {
    for f in state.unsorted {
      if(!self.preloadedPreviews.keys.contains(f) && !self.previewsBeingLoaded.contains(f)) {
        preloadPreview(file: f, fast: false)
        break
      }
    }
  }
  
  func preloadPreview(file: URL, fast: Bool) {
    if previewsBeingLoaded.contains(file) || preloadedPreviews[file] != nil {
      return
    }
    previewsBeingLoaded.insert(file)
    let speed:DispatchQoS.QoSClass = (fast ? .userInitiated : .background)
    DispatchQueue.global(qos: speed).async {
      let img = self.filePreview(file: file)
      self.preloadedPreviews[file] = img
      self.previewsBeingLoaded.remove(file)
      if(file == self.state.unsorted.first!) {
        DispatchQueue.main.async {
          self.preview.transitionWithImage(image: img, reverse:false, notrans:true)
        }
      }
    }
  }
  
  func filePreview(file: URL)->NSImage {
    if let ref = QLThumbnailImageCreate(kCFAllocatorDefault, file as CFURL, previewSize, previewOpts) {
      let bit = NSBitmapImageRep(cgImage:ref.takeRetainedValue())
      let img = NSImage(size: previewSize as NSSize)
      img.addRepresentation(bit)
      return img
    } else {
      let img = NSWorkspace().icon(forFile: file.path)
      img.size = previewSize
      return img
    }
  }
  
  func rename(file: URL, newName: String)->URL {
    
    let newPath = file.deletingLastPathComponent().path + "/" + newName
    try?FileManager.default.moveItem(atPath: file.path, toPath: newPath)
    return URL(fileURLWithPath: newPath)
  }
  
  func saveChanges() {
    //onEditTags(tagField) //disabled because warning may show for no reason
    onRename(filenameField)
  }
  
  func finish() {
    
    if state.rejected.isEmpty {
      let alert = NSAlert()
      alert.messageText = "No files to delete"
      alert.informativeText = "You did not reject any files. Would you like to start over?"
      alert.alertStyle = NSAlertStyle.informational
      alert.addButton(withTitle: "Restart")
      alert.addButton(withTitle: "Exit Tinder")
      alert.beginSheetModal(for: self.view.window!, completionHandler: {(response) in
        if response == NSAlertFirstButtonReturn {
          let wc = self.storyboard!.instantiateInitialController() as! NSWindowController
          self.view.window?.close()
          wc.showWindow(self)
        } else {
          NSApplication.shared().terminate(self)
        }
      })
      return
    }
    self.view.window?.close()
    
    if let wc = storyboard?.instantiateController(withIdentifier: "review") as? NSWindowController {
      if let rc = wc.contentViewController as? ReviewViewController {
        rc.setState(state: state)
        wc.showWindow(self)
      }
    }
  }
  
  func refresh(reverse: Bool) {
    if(state.unsorted.count == 0) {
      finish()
      return
    }
    
    let file = state.unsorted.first!
    let pathComponent = file.lastPathComponent
    filenameField.stringValue = pathComponent

    var img:NSImage? = nil
    
    if let loaded = preloadedPreviews[file] {
      img = loaded
    } else {
      preloadPreview(file: file, fast: true)
      img = NSWorkspace().icon(forFile: file.path)
      img?.size = preview.bounds.size
    }
    
    self.preview.transitionWithImage(image: img!, reverse:reverse, notrans: false)
    
    let keys: Set<URLResourceKey> = [.tagNamesKey, .creationDateKey, .contentModificationDateKey, .nameKey, .fileSizeKey, .isDirectoryKey]
    
    if let resourceValues:URLResourceValues = try? file.resourceValues(forKeys: keys) {
      if file.hasDirectoryPath {
        self.filesizeField.stringValue = "--"
        DispatchQueue.main.async {
          do {
            try self.filesizeField.stringValue = file.fileSize().byteCount(style: .file)
          } catch {
            self.filesizeField.stringValue = "?"
          }
        }
      } else {
        do {
          try filesizeField.stringValue = file.fileSize().byteCount(style: .file)
        } catch {
          filesizeField.stringValue = "?"
        }
      }
      let created = resourceValues.creationDate
      createdField.stringValue = dfmt.string(from: created!)
      let edited = resourceValues.contentModificationDate
      editedField.stringValue = dfmt.string(from: edited!)
      if let tags = resourceValues.tagNames {
        tagField.objectValue = tags
      } else {
        tagField.objectValue = [String]()
      }
      progressIndicator.doubleValue = state.pctDone()
      statusLabel.stringValue = "\(state.rejected.count) rejected \(state.accepted.count) accepted \(state.unsorted.count) remaining"
    }
  }
}

extension NSImageView {
  
  func transitionWithImage(image: NSImage, reverse: Bool, notrans: Bool) {
    if(!notrans) {
      let transition = CATransition()
      transition.duration = 0.25
      transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
      transition.type = kCATransitionPush
      transition.subtype = reverse ? kCATransitionFromLeft : kCATransitionFromRight
      wantsLayer = true
      layer?.add(transition, forKey: kCATransition)
    }
    self.image = image
  }
}

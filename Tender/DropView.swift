//
//  DropView.swift
//  Tender
//
//  Created by Caleb Kussmaul on 12/10/17.
//  Copyright © 2017 Caleb Kussmaul. All rights reserved.
//

import AppKit

class DropView: NSView {
  
  var onDrop:((URL) -> Void)?
  
  func setDropListener(ftn: @escaping ((URL) -> Void)) {
    onDrop = ftn
  }
  
  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    register(forDraggedTypes: [NSFilenamesPboardType])
  }
    
  override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
    return checkFile(drag: sender) ? .copy : []
  }
  
  override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
    return checkFile(drag: sender) ? .copy : []
  }
  
  override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
    if let board = sender.draggingPasteboard().propertyList(forType: "NSFilenamesPboardType") as? NSArray,
      let filePath = board[0] as? String {
      onDrop?(URL(fileURLWithPath: filePath))
      return true
    }
    return false
  }
  
  func checkFile(drag: NSDraggingInfo) -> Bool {
    if let board = drag.draggingPasteboard().propertyList(forType: "NSFilenamesPboardType") as? NSArray, let path = board[0] as? String {
      if board.count > 1 {
        return false
      }
      let url = NSURL(fileURLWithPath: path)
      return url.hasDirectoryPath
    }
    return false
  }
}

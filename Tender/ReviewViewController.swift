//
//  ReviewViewController.swift
//  Tender
//
//  Created by Caleb Kussmaul on 12/27/17.
//  Copyright © 2017 Caleb Kussmaul. All rights reserved.
//

import AppKit

class ReviewViewController: NSViewController, NSWindowDelegate {

  var state: TenderState!
  
  @IBOutlet var titleField: NSTextField!
  
  func setState(state: TenderState) {
    self.state = state
    titleField.stringValue = "\(state.rejected.count) files totaling \(state.rejectedSize().byteCount(style: .file)) are ready to be deleted"
  }

  @IBAction func deleteRejected(_ sender: Any) {
    let wc = self.storyboard!.instantiateInitialController() as! NSWindowController
    view.window?.close()
    wc.showWindow(self)
    state.finishDeleteFiles()
  }
  
  @IBAction func moveRejected(_ sender: Any) {
    let wc = self.storyboard!.instantiateInitialController() as! NSWindowController
    view.window?.close()
    wc.showWindow(self)
    state.finishMoveFiles()
  }
  
  override func viewDidAppear() {
    super.viewDidAppear()
    self.view.window!.delegate = self
  }
  
  func windowShouldClose(_ sender: Any) -> Bool {
    NSApplication.shared().terminate(self)
    return true
  }
}

//
//  ReviewViewController.swift
//  Tender
//
//  Created by Caleb Kussmaul on 12/27/17.
//  Copyright © 2017 Caleb Kussmaul. All rights reserved.
//

import AppKit

class ReviewViewController: NSViewController {

  var state:TenderState!
  
  @IBOutlet var titleField: NSTextField!
  
  func setState(state: TenderState) {
    self.state = state
    titleField.stringValue = "\(state.rejected.count) files totalling \(state.rejectedSize()) are ready to be deleted"
  }

  @IBAction func deleteRejected(_ sender: Any) {
    self.view.window?.close()
    state.finishDeleteFiles()
    exit(0)
  }
  
  @IBAction func moveRejected(_ sender: Any) {
    self.view.window?.close()
    state.finishMoveFiles()
    exit(0)
  }
}

//
//  ViewController.swift
//  Tender
//
//  Created by Caleb Kussmaul on 11/8/17.
//  Copyright © 2017 Caleb Kussmaul. All rights reserved.
//

import AppKit

class InitialViewController: NSViewController, NSWindowDelegate {
  
  var state:TenderState!
  
  let appDelegate = NSApplication.shared().delegate as! AppDelegate
  
  @IBOutlet var startButton: NSButton!
  @IBOutlet var sortByPopUp: NSPopUpButton!
  @IBOutlet var groupByFiletypeCheckBox: NSButton!
  @IBOutlet var descendingCheckBox: NSButton!
  @IBOutlet var dropFileView: DropView!
  @IBOutlet var pathControl: NSPathControl!
  
  @IBAction func onSelect(_ sender: NSPathControl) {
    select(sender.url!)
  }
  
  func select(_ url: URL) {
    do {
      try state = TenderState(dir: url)
      startButton.isEnabled = true
    } catch StateError.EmptyDir {
      let alert = NSAlert()
      alert.messageText = "Folder cannot be empty"
      alert.informativeText = "Tender has nothing to sort in an empty folder. Please select another directory."
      alert.alertStyle = NSAlertStyle.warning
      alert.addButton(withTitle: "Okay")
      alert.beginSheetModal(for: self.view.window!, completionHandler: {(response) in })
    } catch {
      let alert = NSAlert()
      alert.messageText = "Error reading folder"
      alert.informativeText = "Something went wrong parsing files in the given directory. Please check your permissions."
      alert.alertStyle = NSAlertStyle.warning
      alert.addButton(withTitle: "Okay")
      alert.beginSheetModal(for: self.view.window!, completionHandler: {(response) in })
    }
  }
  
  func getSortBy() -> SortBy {
    switch sortByPopUp.indexOfSelectedItem {
    case 0: return .Name
    case 1: return .Created
    case 2: return .Modified
    default:
      return .Name
    }
  }
  
  @IBAction func onStart(_ sender: NSButton) {
    let wc = storyboard!.instantiateController(withIdentifier: "sortWindow") as! NSWindowController
    let vc = wc.contentViewController! as! SortViewController
    state.promptRestore(window: view.window!, onCompletion: {() in
      self.state.sortFiles(sortBy: self.getSortBy(), groupByType: self.groupByFiletypeCheckBox.state == 1, descending: self.descendingCheckBox.state == 1)
      self.view.window?.close()
      vc.setState(state: self.state)
      vc.view.window?.title = "Tender - " + self.pathControl.url!.lastPathComponent
      wc.showWindow(sender)
    })
  }
  
  override func viewDidAppear() {
    super.viewDidAppear()
    dropFileView.setDropListener(ftn: {(url: URL) -> Void in
      self.pathControl.url = url
      self.select(url)
    })
    self.view.window!.delegate = self
  }
  
  func windowShouldClose(_ sender: Any) -> Bool {
    NSApplication.shared().terminate(self)
    return true
  }
}


//
//  ViewController.swift
//  Tender
//
//  Created by Caleb Kussmaul on 11/8/17.
//  Copyright © 2017 Caleb Kussmaul. All rights reserved.
//

import AppKit

class InitialViewController: NSViewController, NSWindowDelegate {
  
  var state:TenderState?
  
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
    } catch {
      
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
    let wc = appDelegate.storyboard!.instantiateController(withIdentifier: "sortWindow") as! NSWindowController
    let vc = wc.contentViewController! as! SortViewController
    state?.promptRestore(window: view.window!, onCompletion: {() in
      self.state?.sortFiles(sortBy: self.getSortBy(), groupByType: self.groupByFiletypeCheckBox.state == 1, descending: self.descendingCheckBox.state == 1)
      self.view.window?.close()
      vc.setState(state: self.state!)
      vc.view.window?.title = "Tender - " + self.pathControl.url!.lastPathComponent
      wc.showWindow(sender)
    })
  }
  
  override func viewDidAppear() {
    dropFileView.setDropListener(ftn: {(url: URL) -> Void in
      self.pathControl.url = url
      self.select(url)
    })
    
    super.viewDidAppear()
    self.view.window!.delegate = self
  }
  
  func windowShouldClose(_ sender: Any) -> Bool {
    NSApplication.shared().terminate(self)
    return true
  }
}


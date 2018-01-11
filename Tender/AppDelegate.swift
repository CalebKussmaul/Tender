//
//  AppDelegate.swift
//  Tender
//
//  Created by Caleb Kussmaul on 11/8/17.
//  Copyright © 2017 Caleb Kussmaul. All rights reserved.
//

import AppKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  var storyboard: NSStoryboard? = nil

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    storyboard = NSStoryboard(name: "Main", bundle: nil)
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }


}


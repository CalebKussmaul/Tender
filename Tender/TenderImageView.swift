//
//  TenderImageView.swift
//  Tender
//
//  Created by Caleb Kussmaul on 1/15/18.
//  Copyright © 2018 Caleb Kussmaul. All rights reserved.
//

import AppKit

class TenderImageView:NSImageView, CAAnimationDelegate {
  
  var nextImage:NSImage?
  var nextType: String?
  
  var isAnimating:Bool = false
  
  private func clear(subtype: String?) {
    slideIn(image: NSImage(), subtype: subtype)
  }
  
  private func slideIn(image: NSImage, subtype: String?) {
    if let sub = subtype {
      isAnimating = true
      let trans = CATransition()
      trans.duration = 0.2
      trans.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
      trans.type = kCATransitionPush
      trans.subtype = sub
      trans.delegate = self
      wantsLayer = true
      layer?.add(trans, forKey: kCATransition)
    }
    self.image = image
  }
  
  public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
    if let img = nextImage {
      nextImage = nil
      if (nextType == nil) {
        isAnimating = false
      }
      slideIn(image: img, subtype: nextType)
      nextType = nil
    }
    else {
      isAnimating = false
    }
  }
  
  func replaceImage(image: NSImage) {
    if(nextImage == nil) {
      self.image = image
    } else {
      nextImage = image
    }
  }
  
  
  func transition(next: NSImage, action: TenderAction) {
    if(isAnimating) {
      nextImage = next
    } else if let subtype = action.animationSubtype {
      
      if(action.isReverse) {
        clear(subtype: kCATransitionFromBottom)
        nextType = subtype
        
      } else {
        clear(subtype: subtype)
        nextType = kCATransitionFromTop
      }
      nextImage = next
    } else {
      self.image = next
    }
  }
}

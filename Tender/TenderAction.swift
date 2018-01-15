//
//  TenderAction.swift
//  Tender
//
//  Created by Caleb Kussmaul on 1/15/18.
//  Copyright © 2018 Caleb Kussmaul. All rights reserved.
//

import AppKit

enum TenderAction {
  case Init
  case Move
  case Accept
  case UndoAccept
  case Reject
  case UndoReject
  case RejectAll
  case UndoRejectAll
  
  var animationSubtype:String? {
    switch self {
    case .Init: return nil
    case .Move: return kCATransitionFromRight
    case .Accept: return kCATransitionFromLeft
    case .UndoAccept: return kCATransitionFromRight
    case .Reject: return kCATransitionFromRight
    case .UndoReject: return kCATransitionFromLeft
    case .RejectAll: return kCATransitionFromRight
    case .UndoRejectAll: return kCATransitionFromLeft
      
    }
  }
  
  var isReverse:Bool {
    switch self {
    case .UndoAccept: return true
    case .UndoReject: return true
    case .UndoRejectAll: return true
    default: return false
    }
  }
}

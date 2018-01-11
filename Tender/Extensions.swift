//
//  Extensions.swift
//  Tender
//
//  Created by Caleb Kussmaul on 1/10/18.
//  Copyright © 2018 Caleb Kussmaul. All rights reserved.
//

import Foundation

extension URL {
  enum URLError: Error {
    case NotAFileURL
  }
  
  func fileSize() throws -> Int64 {
    if !self.isFileURL {
      throw URLError.NotAFileURL
    }
    if self.hasDirectoryPath {
      var folderSize:Int64 = 0
      FileManager.default.enumerator(at: self, includingPropertiesForKeys: [.fileSizeKey], options: [])?.forEach {
        folderSize += Int64((try? ($0 as? URL)?.resourceValues(forKeys: [.fileSizeKey]))??.fileSize ?? 0)
      }
      return folderSize;
    } else {
      do {
        let rv = try self.resourceValues(forKeys: [.fileSizeKey])
        return Int64(rv.fileSize!)
      } catch {
        throw error
      }
    }
  }
}

extension Int64 {
  func byteCount(style: ByteCountFormatter.CountStyle) -> String {
    let byteCountFormatter =  ByteCountFormatter()
    byteCountFormatter.countStyle = style
    return byteCountFormatter.string(fromByteCount: self)
  }
}

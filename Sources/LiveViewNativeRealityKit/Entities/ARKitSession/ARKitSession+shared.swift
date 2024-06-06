//
//  File.swift
//  
//
//  Created by Carson.Katri on 5/30/24.
//

import ARKit

enum SharedARKitSessionStore {
    private static var _shared: ARKitSession?
    
    static var shared: ARKitSession {
        if let _shared {
            return _shared
        } else {
            _shared = .init()
            return _shared!
        }
    }
}

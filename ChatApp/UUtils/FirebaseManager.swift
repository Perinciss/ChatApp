//
//  FirebaseManager.swift
//  ChatApp
//
//  Created by Kevin Heryanto on 05/09/2566 BE.
//

import Foundation
import Firebase
import FirebaseFirestore

class FirebaseManager: NSObject{
    
    let auth: Auth
    let firestore: Firestore
    
    static let shared = FirebaseManager()
    
    override init() {
        FirebaseApp.configure()
        
        self.auth = Auth.auth()
        self.firestore = Firestore.firestore()
        
        super.init()
    }
}

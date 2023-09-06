//
//  ChatUser.swift
//  ChatApp
//
//  Created by Kevin Heryanto on 06/09/2566 BE.
//

import Foundation


struct ChatUser: Identifiable {
    
    var id: String { uid }
    
    let uid, email: String
    
    init(data: [String: Any]){
        self.uid = data["uid"] as? String ?? ""
        self.email = data["email"] as? String ?? ""
    }
}

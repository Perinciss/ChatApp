//
//  ChatLogView.swift
//  ChatApp
//
//  Created by Kevin Heryanto on 06/09/2566 BE.
//

import SwiftUI
import Firebase
import FirebaseFirestore


struct FirebaseConstants {
    static let fromId = "fromId"
    static let toId = "toId"
    static let text = "text"
    static let timestamp = "timestamp"
    static let email = "email"
}

struct ChatMessage: Identifiable {
    
    var id: String { documentId }
    
    let documentId: String
    let fromId, toId, text: String
    
    init(documentId: String, data: [String: Any]){
        self.documentId = documentId
        self.fromId = data[FirebaseConstants.fromId] as? String ?? ""
        self.toId = data[FirebaseConstants.toId] as? String ?? ""
        self.text = data[FirebaseConstants.text] as? String ?? ""
    }
}

class ChatLogViewModel: ObservableObject{
    
    @Published var chatText = ""
    @Published var errorMessage = ""
    
    @Published var chatMessages = [ChatMessage]()
    
    let chatUser: ChatUser?
    
    init(chatUser: ChatUser?){
        self.chatUser = chatUser
        
        fetchMessages()
    }
    
    
//     Fetch Messages
    private func fetchMessages(){
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let toId = chatUser?.uid else { return }
        FirebaseManager.shared.firestore
            .collection("messages")
            .document(fromId)
            .collection(toId)
            .order(by: "timestamp")
            .addSnapshotListener{ querySnapshot, error in
                if let error = error {
                    self.errorMessage = "Gagal mengambil untuk pesan: \(error)"
                    print(error)
                    return
                }
                
                querySnapshot?.documentChanges.forEach({ change in
                    if change.type == .added{
                        let data = change.document.data()
                        self.chatMessages.append(.init(documentId: change.document.documentID, data: data))
                    }
                })
                DispatchQueue.main.async {
                    self.count += 1
                }
            }
    }
    
    
    func handlesend(){
        print(chatText)
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let toId = chatUser?.uid else { return }
        
        let document = FirebaseManager.shared.firestore
            .collection("messages")
            .document(fromId)
            .collection(toId)
            .document()
        
        let messageData = [FirebaseConstants.fromId: fromId, FirebaseConstants.toId: toId, FirebaseConstants.text: self.chatText, "timestamp": Timestamp()] as [String: Any]
        
        document.setData(messageData){
            error in
            if let error = error {
                print(error)
                self.errorMessage = "Gagal Menyimpan Pesan ke Firestore: \(error)"
                return
            }
            print("Successfully save current user sending message")
            
            self.persistRecentMessage()
            
            self.chatText = ""
            self.count += 1
        }
        let recepientMessageDocument = FirebaseManager.shared.firestore.collection("messages")
            .document(toId)
            .collection(fromId)
            .document()
        
        recepientMessageDocument.setData(messageData){
            error in
            if let error = error {
                print(error)
                self.errorMessage = "Gagal Menyimpan Pesan ke Firestore: \(error)"
                return
            }
            print("Recepient saved message as well")
        }
    }
    
    private func persistRecentMessage() {
        guard let chatUser = chatUser else { return }
        
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let toId = self.chatUser?.uid else {  return }
        
        let document = FirebaseManager.shared.firestore
            .collection("recent_messsages")
            .document(uid)
            .collection("messages")
            .document(toId)
        
        let data = [
            FirebaseConstants.timestamp: Timestamp(),
            FirebaseConstants.text: self.chatText,
            FirebaseConstants.fromId: uid,
            FirebaseConstants.toId: toId,
            FirebaseConstants.email: chatUser.email
        ] as [String: Any]
        
        
        
        document.setData(data) { error in
            if let error = error {
                self.errorMessage = "Gagal menyimpan pesan baru: \(error)"
                print("Gagal menyimpan pesan baru: \(error)")
                return
            }
            
        }
    }
    
    @Published var count = 0
    
}

struct ChatLogView: View{
    
    let chatUser: ChatUser?
    
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        self.vm = .init(chatUser: chatUser)
    }
    
    @ObservedObject var vm: ChatLogViewModel
       
       var body: some View {
           ZStack{
               messagesView
               Text(vm.errorMessage)
           }
           .navigationTitle(chatUser?.email ?? "")
               .navigationBarTitleDisplayMode(.inline)
//               .navigationBarItems(trailing: Button(action: {
//                   vm.count += 1
//               }, label: {
//                   Text("Count: \(vm.count)")
//               }))
       }
    
    static let emptyScrollToString = "Empty"
       
    private var messagesView: some View {
        VStack {
                        ScrollView {
                            ScrollViewReader{ scrollViewProxy in
                                VStack{
                                    ForEach(vm.chatMessages) { message in
                                        MessageView(message: message)
                                    }
                                    
                                    HStack{ Spacer() }
                                        .id(Self.emptyScrollToString)
                                }
                                .onReceive(vm.$count) { _ in
                                    withAnimation(.easeOut(duration: 0.5)){
                                        scrollViewProxy.scrollTo(Self.emptyScrollToString, anchor: .bottom)
                                    }
                                   
                                }
                                
                                   
                            }
                            
                        }
                        .background(Color(.init(white: 0.95, alpha: 1)))
                        .safeAreaInset(edge: .bottom) {
                            chatBottomBar
                                .background(Color(.systemBackground).ignoresSafeArea())
                        }
                }
            }
       
       private var chatBottomBar: some View {
           HStack(spacing: 16) {
               Spacer()
               ZStack {
                   DescriptionPlaceholder()
                   TextEditor(text: $vm.chatText)
                       .opacity(vm.chatText.isEmpty ? 0.5 : 1)
               }
               .frame(height: 40)
               
               Button {
                   vm.handlesend()
               } label: {
                   Text("Send")
                       .foregroundColor(.white)
               }
               .padding(.horizontal)
               .padding(.vertical, 8)
               .background(Color.blue)
               .cornerRadius(4)
           }
           .padding(.horizontal)
           .padding(.vertical, 8)
       }
}

struct MessageView: View {
    
    let message: ChatMessage
    
    var body: some View {
        VStack {
            if message.fromId == FirebaseManager.shared.auth.currentUser?.uid {
                HStack {
                    Spacer()
                    HStack {
                        Text(message.text)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
                }
            } else {
                HStack {
                    HStack {
                        Text(message.text)
                            .foregroundColor(.black)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    Spacer()
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

private struct DescriptionPlaceholder: View {
    var body: some View {
        HStack {
            Text("Description")
                .foregroundColor(Color(.gray))
                .font(.system(size: 17))
                .padding(.leading, 5)
                .padding(.top, -4)
            Spacer()
        }
    }
}



struct ChatLogView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView{
            ChatLogView(chatUser: .init(data: ["uid": "Brl5O5vcvgU0Fb3y4hgz4jpxBpf1","email": "cengceng@gmail.com"]))
        }.navigationBarTitleDisplayMode(.inline)
    }
}

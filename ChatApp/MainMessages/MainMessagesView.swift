//
//  MainMessagesView.swift
//  ChatApp
//
//  Created by Kevin Heryanto on 05/09/2566 BE.
//

import SwiftUI
import Firebase
import FirebaseFirestore

struct RecentMessage: Identifiable {
    
    var id: String { documentId }
    
    let documentId: String
    let text: String
    let fromId, toId: String
    let email: String
    let timestamp: Timestamp
    
    init(documentId: String, data: [String: Any]) {
        self.documentId = documentId
        self.text = data["text"] as? String ?? ""
        self.fromId = data["fromId"] as? String ?? ""
        self.toId = data["toId"] as? String ?? ""
        self.email = data["email"] as? String ?? ""
        self.timestamp = data["timestamp"] as? Timestamp ?? Timestamp(date: Date())
    }
}

class MainMessagesViewModel: ObservableObject{
    @Published var errorMessage = ""
       @Published var chatUser: ChatUser?
    
       
       init() {
           
           DispatchQueue.main.async {
               self.isUserCurrentlyLoggedIn = true
               FirebaseManager.shared.auth.currentUser?.uid == nil
           }
          
           
           fetchCurrentUser()

           fetchRecentMessages()
       }
    
    @Published var recentMessages = [RecentMessage]()
    
    private func fetchRecentMessages(){
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        FirebaseManager.shared.firestore
            .collection("recent_messages")
            .document(uid)
            .collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    self.errorMessage = "Gagal mendapatkan pesan baru: \(error)"
                    print(error)
                    return
                }
                
                querySnapshot?.documentChanges.forEach({ change in
                    let docId = change.document.documentID
                    
                    if let index = self.recentMessages.firstIndex(where: { rm in
                        return rm.documentId == docId
                    }) {
                        self.recentMessages.remove(at: index)
                    }
                    
                    self.recentMessages.insert(.init(documentId: docId, data: change.document.data()), at: 0)
                    
//                        self.recentMessages.append()
                    
                })
            }
    }
       
       func fetchCurrentUser() {
           
           guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {
               self.errorMessage = "uid tidak ditemukan di firebase"
               return
           }
           
           
           FirebaseManager.shared.firestore.collection("users").document(uid).getDocument { snapshot, error in
               if let error = error {
                   self.errorMessage = "Gagal mengambil user login: \(error)"
                   print("Gagal mengambil user login:", error)
                   return
               }
               
   //            self.errorMessage = "123"
               
               guard let data = snapshot?.data() else {
                   self.errorMessage = "Data tidak ditemukan"
                   return
                   
               }
   //            self.errorMessage = "Data: \(data.description)"
               
               self.chatUser = .init(data: data)
//               FirebaseManager.shared.currentUser = self.chatUser
               
               
           }
       }
    
    @Published var isUserCurrentlyLoggedIn = false
    
    
    
    func handleSignOut(){
        isUserCurrentlyLoggedIn.toggle()
        try? FirebaseManager.shared.auth.signOut()
    }
}

struct MainMessagesView: View {
    @State var OptionKeluar = false
    
    @State var shouldNavigateToChatLogView = false
    
    @ObservedObject private var vm = MainMessagesViewModel()
    
    var body: some View {
        NavigationView {
            
            VStack {
//                Text("User: \(vm.chatUser?.uid ?? "")")
                customNavBar
                messagesView
                NavigationLink("", isActive: $shouldNavigateToChatLogView) {
                    ChatLogView(chatUser: self.chatUser)
                }
               
            }
            .overlay(
                newMessageButton, alignment: .bottom)
            .navigationBarHidden(true)
        }
    }
        
        private var customNavBar: some View {
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    let email = vm.chatUser?.email.replacingOccurrences(of: "@gmail.com", with: "") ?? ""
                                    Text(email)
                                        .font(.system(size: 24, weight: .bold))
                    
                    HStack {
                        Circle()
                            .foregroundColor(.green)
                            .frame(width: 14, height: 14)
                        Text("aktif")
                            .font(.system(size: 12))
                            .foregroundColor(Color(.lightGray))
                    }
                    
                }
                
                Spacer()
                Button {
                    OptionKeluar.toggle()
                } label: {
                    Image(systemName: "gear")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(.label))
                }
            }
            .padding()
            .actionSheet(isPresented: $OptionKeluar) {
                .init(title: Text("Pengaturan"), message: Text("Apa yang ingin anda lakukan?"), buttons: [
                    .destructive(Text("Keluar"), action: {
                        print("handle sign out")
                        vm.handleSignOut()
                    }),
                        .cancel()
                ])
            }
            .fullScreenCover(isPresented: $vm.isUserCurrentlyLoggedIn, onDismiss: nil){
                LoginView(didCompleteLoginProcess: {
                    self.vm.isUserCurrentlyLoggedIn = false
                    self.vm.fetchCurrentUser()
                })
            }
        }
        
        
        
        private var messagesView: some View {
            ScrollView {
                ForEach(vm.recentMessages) { recentMessage in
                    VStack {
                        NavigationLink{
                            Text("Destination")
                        } label: {
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(recentMessage.email)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(Color(.label))
                                    Text(recentMessage.text)
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(.darkGray))
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer()

                                Text("2d")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                        
                        Divider()
                            .padding(.vertical, 8)
                    }.padding(.horizontal)

                }.padding(.bottom, 50)
            }
}
    
    @State var shouldShowNewMessageScreen = false
    
    private var newMessageButton: some View {
            Button {
                shouldShowNewMessageScreen.toggle()
            } label: {
                HStack {
                    Spacer()
                    Text("+ Pesan Baru")
                        .font(.system(size: 16, weight: .bold))
                    Spacer()
                }
                .foregroundColor(.white)
                .padding(.vertical)
                    .background(Color.blue)
                    .cornerRadius(32)
                    .padding(.horizontal)
                    .shadow(radius: 15)
            }
            .fullScreenCover(isPresented: $shouldShowNewMessageScreen){
                NewMessageView(didSelectNewUser: { user in print(user.email)
                    self.shouldNavigateToChatLogView.toggle()
                    self.chatUser = user
                })
            }
        }
    
    @State var chatUser: ChatUser?
    }



struct MainMessagesView_Previews: PreviewProvider {
    static var previews: some View {
        MainMessagesView()
    }
}

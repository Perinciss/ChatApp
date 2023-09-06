//
//  ContentView.swift
//  ChatApp
//
//  Created by Kevin Heryanto on 04/09/2566 BE.
//

import SwiftUI
import Firebase
import FirebaseFirestore

struct LoginView: View {
    
    let didCompleteLoginProcess: () -> ()
    
    @State private var isLoginMode = false
    @State private var email = ""
    @State private var password = ""
    
    
    var body: some View {
        NavigationView{
            ScrollView{
                VStack(spacing: 16){
                    Picker(selection: $isLoginMode, label:
                            Text("Picker Here")) {
                        Text("Masuk")
                            .tag(true)
                        Text("Buat Akun")
                            .tag(false)
                    }.pickerStyle(SegmentedPickerStyle())
                        .padding()

                    
                    Group{
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        SecureField("Password", text: $password)
                        
                    }
                    .padding(12)
                    .background(Color.white)
                    
                    Button {
                        handleAction()
                    } label: {
                        HStack{
                            Spacer()
                            Text(isLoginMode ? "Masuk" : "Buat Akun")
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .font(.system(size: 14, weight: .semibold))
                            Spacer()
                        }.background(Color.blue)
                    }
                    Text(self.LoginStatusMessage)
                        .foregroundColor(.red)
                }.padding()
                
            }
            .navigationTitle(isLoginMode ? "Masuk" : "Buat Akun")
            .background(Color(.init(white: 0, alpha: 0.05))
                .ignoresSafeArea())
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    @State var image: UIImage?
    
    private func handleAction() {
        if isLoginMode {
            print("Should log into Firebase with existing credentials")
            loginUser()
        } else {
            buatAkunBaru()
            print("Register a new account inside of Firebase Auth and then store image in Storage somehow....")
        }
    }
    
    private func loginUser() {
        FirebaseManager.shared.auth.signIn(withEmail: email, password: password) {
            result, err in
            if let err = err{
                print("Failed to login user", err)
                self.LoginStatusMessage = "Failed to login user \(err)"
                return
            }
            print("Successfully logged in as user: \(result?.user.uid ?? "")")
            
            self.LoginStatusMessage = "Successfully logged in as user: \(result?.user.uid ?? "")"
            
            self.didCompleteLoginProcess()
        }
    }
    
    @State var LoginStatusMessage = ""
    
    private func buatAkunBaru(){
        FirebaseManager.shared.auth.createUser(withEmail: email, password: password){
            result, err in
            if let err = err{
                print("Failed to create user", err)
                self.LoginStatusMessage = "Failed to create user \(err)"
                return
            }
            print("Successfully created user: \(result?.user.uid ?? "")")
            self.LoginStatusMessage = "Successfully created user: \(result?.user.uid ?? "")"
            
            self.storeUserInformation()
        }
        
    }
    
    private func storeUserInformation() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        let userData = ["email": self.email, "uid": uid]
        FirebaseManager.shared.firestore.collection("users")
            .document(uid).setData(userData) { err in
                if let err = err {
                    print(err)
                    self.LoginStatusMessage = "\(err)"
                    return
                }
                
                print("Success")
                
                self.didCompleteLoginProcess()
            }
    }
    
    }


struct ContentView_Previews1: PreviewProvider {
    static var previews: some View {
        LoginView(didCompleteLoginProcess: {
            
        })
    }
}

//
//  bento_ios_exampleApp.swift
//  bento-ios-example
//
//  Created by Zachary Oakes on 2024/10/06.
//

import SwiftUI

@main
struct bento_ios_exampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

import SwiftUI

struct ContentView: View {
    @State private var siteUUID = ""
    @State private var username = ""
    @State private var password = ""
    @State private var isLoggedIn = false
    
    var body: some View {
        if isLoggedIn {
            TabView {
                SubmitEventsView()
                    .tabItem {
                        Label("Submit Events", systemImage: "arrow.up.doc")
                    }
                
                ValidateEmailView()
                    .tabItem {
                        Label("Validate Email", systemImage: "checkmark.circle")
                    }
                
                FetchSubscriberView()
                    .tabItem {
                        Label("Fetch Subscriber", systemImage: "person.fill")
                    }
                
                ExecuteCommandView()
                    .tabItem {
                        Label("Execute Command", systemImage: "terminal")
                    }
            }
            .environmentObject(BentoAPIManager(siteUUID: siteUUID, username: username, password: password))
        } else {
            LoginView(siteUUID: $siteUUID, username: $username, password: $password, isLoggedIn: $isLoggedIn)
        }
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}

struct LoginView: View {
    @Binding var siteUUID: String
    @Binding var username: String
    @Binding var password: String
    @Binding var isLoggedIn: Bool
    
    var body: some View {
        VStack {
            Image("bento-logo")
                .resizable()
                .scaledToFit()
                .frame(height: 200)
                .padding(.bottom, 20)
            
            VStack(spacing: 15) {
                TextField("Site UUID", text: $siteUUID)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("BENTO_PUBLISHABLE_KEY", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                SecureField("BENTO_SECRET_KEY", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)
            
            Button(action: {
                isLoggedIn = true
            }) {
                Text("Login")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: 0x6366f1))
                    .cornerRadius(10)
            }
            .disabled(siteUUID.isEmpty || username.isEmpty || password.isEmpty)
            .padding()
            
            Text("Please sign up for an account at [bentonow.com](https://www.bentonow.com) and visit our docs at [docs.bentonow.com](https://docs.bentonow.com) for detailed information on the SDK and APIs.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .padding()
                .environment(\.openURL, OpenURLAction { url in
                    UIApplication.shared.open(url)
                    return .handled
                })
        }
    }
}

class BentoAPIManager: ObservableObject {
    let api: BentoAPI
    
    init(siteUUID: String, username: String, password: String) {
        self.api = BentoAPI(siteUUID: siteUUID, username: username, password: password)
    }
}

struct SubmitEventsView: View {
    @EnvironmentObject var apiManager: BentoAPIManager
    @State private var eventType = ""
    @State private var email = ""
    @State private var result = ""
    
    var body: some View {
        Form {
            TextField("Event Type", text: $eventType)
            TextField("Email", text: $email)
            
            Button("Submit Event") {
                Task {
                    do {
                        let event = BentoEvent(type: eventType, email: email.lowercased())
                        let response = try await apiManager.api.submitEvents([event])
                        result = "Events submitted: \(response.results)"
                    } catch {
                        result = "Error: \(error.localizedDescription)"
                    }
                }
            }
            
            Text(result)
        }
    }
}

struct ValidateEmailView: View {
    @EnvironmentObject var apiManager: BentoAPIManager
    @State private var email = ""
    @State private var result = ""
    
    var body: some View {
        Form {
            TextField("Email", text: $email)
            
            Button("Validate Email") {
                Task {
                    do {
                        let isValid = try await apiManager.api.validateEmail(email: email.lowercased())
                        result = isValid ? "Email is valid" : "Email is invalid"
                    } catch {
                        result = "Error: \(error.localizedDescription)"
                    }
                }
            }
            
            Text(result)
        }
    }
}

struct FetchSubscriberView: View {
    @EnvironmentObject var apiManager: BentoAPIManager
    @State private var email = ""
    @State private var result = ""
    
    var body: some View {
        Form {
            TextField("Email", text: $email)
            
            Button("Fetch Subscriber") {
                Task {
                    do {
                        let response = try await apiManager.api.fetchSubscriber(email: email.lowercased())
                        let jsonData = try JSONEncoder().encode(response)
                        let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
                        let prettyJsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
                        result = String(data: prettyJsonData, encoding: .utf8) ?? "Unable to format JSON"
                    } catch {
                        result = "Error: \(error.localizedDescription)"
                    }
                }
            }
            
            TextEditor(text: .constant(result))
                .frame(minHeight: 200)
                .font(.system(.body, design: .monospaced))
        }
    }
}

struct ExecuteCommandView: View {
    @EnvironmentObject var apiManager: BentoAPIManager
    @State private var email = ""
    @State private var commandType = 0
    @State private var tag = ""
    @State private var field = ""
    @State private var value = ""
    @State private var newEmail = ""
    @State private var result = ""
    
    let commandTypes = ["Add Tag", "Remove Tag", "Add Field", "Remove Field", "Subscribe", "Unsubscribe", "Change Email"]
    
    var body: some View {
        Form {
            TextField("Email", text: $email)
            
            Picker("Command Type", selection: $commandType) {
                ForEach(0..<commandTypes.count, id: \.self) {
                    Text(self.commandTypes[$0])
                }
            }
            
            switch commandTypes[commandType] {
            case "Add Tag", "Remove Tag":
                TextField("Tag", text: $tag)
            case "Add Field":
                TextField("Field", text: $field)
                TextField("Value", text: $value)
            case "Remove Field":
                TextField("Field", text: $field)
            case "Change Email":
                TextField("New Email", text: $newEmail)
            default:
                EmptyView()
            }
            
            Button("Execute Command") {
                executeCommand()
            }
            
            Text(result)
        }
    }
    
    private func executeCommand() {
        let command: SubscriberCommand
        
        switch commandTypes[commandType] {
        case "Add Tag":
            command = .addTag(email: email.lowercased(), tag: tag)
        case "Remove Tag":
            command = .removeTag(email: email.lowercased(), tag: tag)
        case "Add Field":
            command = .addField(email: email.lowercased(), field: field, value: value)
        case "Remove Field":
            command = .removeField(email: email.lowercased(), field: field)
        case "Subscribe":
            command = .subscribe(email: email.lowercased())
        case "Unsubscribe":
            command = .unsubscribe(email: email.lowercased())
        case "Change Email":
            command = .changeEmail(oldEmail: email.lowercased(), newEmail: newEmail)
        default:
            result = "Invalid command type"
            return
        }
        
        Task {
            do {
                let response = try await apiManager.api.executeCommand(command)
                result = "Command executed successfully. Successful Commands Executed: \(response)"
            } catch {
                result = "Error: \(error.localizedDescription)"
            }
        }
    }
}




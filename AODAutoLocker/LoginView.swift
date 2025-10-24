import SwiftUI
internal import Combine

struct LoginView: View {

    @StateObject private var userManager = UserManager.shared
    
    @State private var username: String = ""
    @State private var password: String = ""
    
    @State private var inProgress = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack {
            Spacer()
            Text("Sign in to your AOD account")
                .foregroundStyle(.gray)
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundStyle(.blue, .gray)
                    TextField(
                        "Phone",
                        text: $userManager.loginInfo.phone)
                        .frame(minHeight: 48)
                        .keyboardType(.numberPad)
                        .disabled(inProgress)
                }
                .padding(Edge.Set.horizontal, 10)
                .background(Color(cgColor: CGColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 255)))
                Divider()
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.blue, .gray)
                    TextField("Password (Encrypted)", text: $userManager.loginInfo.password)
                        .frame(minHeight: 48)
                        .keyboardType(.asciiCapable)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                        .disabled(inProgress)
                }
                .padding(Edge.Set.horizontal, 10)
                .background(Color(cgColor: CGColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 255)))
            }
            .cornerRadius(20)
            if (!alertMessage.isEmpty) {
                Spacer().frame(height: 20)
                Text(alertMessage).foregroundColor(Color.red)
            }
            Spacer()
            Button(action: {
                inProgress = true
                alertMessage = ""
                Task {
                    if (await userManager.login(
                        phone: userManager.loginInfo.phone,
                        password: userManager.loginInfo.password)) {
                        userManager.saveLoginInfo()
                    } else {
                        alertMessage = "An error occurred when signing in"
                    }
                    inProgress = false
                }
            }) {
                Text("Sign In")
                    .frame(maxWidth: .infinity)
                    .font(.system(size: 24))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(inProgress)
        }
        .padding(20)
        .listStyle(.inset)
        .navigationTitle("Sign in")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        LoginView()
    }
}

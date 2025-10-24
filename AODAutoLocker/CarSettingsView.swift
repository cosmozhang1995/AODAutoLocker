import SwiftUI
internal import Combine

struct CarSettingsView: View {

    @StateObject private var userManager = UserManager.shared
    
    @State private var carStatus: CarStatus? = nil
    
    @State private var carNearBy: Bool = false
    
    private var pageTitle: String {
        get {
            return userManager.car?.no ?? "My Car"
        }
    }
    
    private func getDefaultImage() -> UIImage? {
        if let imageUrl = Bundle.main.url(forResource: "Car_Mazda", withExtension: "png"),
           let imageData = try? Data(contentsOf: imageUrl),
           let uiImage = UIImage(data: imageData) {
            return uiImage
        } else {
            return nil
        }
    }

    var body: some View {
        Form {
            Section() {
                HStack {
                    Text("Car No.")
                    Divider().padding(.horizontal, 10)
                    Text(userManager.car?.no ?? "-")
                }
            }
            Section(header: Text("Beacon")) {
                Button(action: {
                    
                }, label: {
                    Text("Bind beacon...")
                })
                HStack {
                    Toggle("Unlock car when nearby", isOn: $carNearBy)
                }
            }
            Section(header: Text("User")) {
                HStack {
                    Spacer()
                    Button(action: {
                        UserManager.shared.logout()
                    }, label: {
                        Text("Sign out")
                    })
                    .foregroundStyle(.red)
                    Spacer()
                }
            }
        }
        .navigationTitle("Car Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        CarSettingsView()
    }
}

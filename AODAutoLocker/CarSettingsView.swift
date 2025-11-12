import SwiftUI
internal import Combine

struct CarSettingsView: View {

    @StateObject private var userManager = UserManager.shared
    @StateObject private var carSettingsManager = CarSettingsManager.shared

    @State private var carStatus: CarStatus? = nil

    private var carNearByAvailable: Bool {
        get {
            let carId = userManager.car?.id
            if carId == nil {
                return false
            }
            if carSettingsManager.get(carId!).beacoUUID == nil {
                return false
            }
            return true
        }
    }

    private var carNearBy: Binding<Bool> {
        Binding(
            get: {
                if !carNearByAvailable {
                    false
                } else if let carId = userManager.car?.id {
                    carSettingsManager.get(carId).isUnlockOnNearby ?? false
                } else {
                    false
                }
            },
            set: { isUnlockNearby in
                if carNearByAvailable {
                    if let carId = userManager.car?.id {
                        carSettingsManager.set(carId, isUnlockOnNearby: isUnlockNearby)
                    }
                }
            }
        )
    }

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
                Button(action: {
                    UserManager.shared.resetCar()
                    MainNavigationController.shared.root()
                }, label: {
                    HStack {
                        Text("Car No.")
                        Divider().padding(.horizontal, 10)
                        Text(userManager.car?.no ?? "-")
                    }
                })
            }
            Section(header: Text("Beacon")) {
                let carId = userManager.car?.id
                let beaconUUID = carId != nil ?  carSettingsManager.get(carId!).beacoUUID : nil
                if beaconUUID != nil {
                    Button(
                        action: {
                            carSettingsManager.set(carId!, isUnlockOnNearby: false)
                            carSettingsManager.set(carId!, beaconUUID: nil)
                        },
                        label: {
                            HStack {
                                Text(beaconUUID!.uuidString.suffix(12))
                                Spacer()
                                Text("Unbind beacon")
                                    .foregroundStyle(.red)
                            }
                        })
                } else {
                    NavigationLink(destination: {
                        BeaconListView {
                            if let carId = userManager.car?.id {
                                carSettingsManager.set(carId, beaconUUID: $0.uuid)
                            }
                        }
                    }, label: {
                        HStack {
                            Text("No beacon")
                                .foregroundStyle(.black)
                            Spacer()
                            Text("Bind beacon")
                                .foregroundStyle(.blue)
                        }
                    })
                }
                HStack {
                    Toggle(isOn: carNearBy, label: {
                        Text("Unlock car when nearby")
                            .foregroundStyle(carNearByAvailable ? .black : .gray)
                    })
                        .disabled(!carNearByAvailable)
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

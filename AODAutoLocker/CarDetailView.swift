import SwiftUI
internal import Combine

struct CarDetailView: View {

    @StateObject private var userManager = UserManager.shared
    @StateObject private var controller = CarDetailViewController()
    
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
        VStack {
            Spacer()
            if let defaultImage = getDefaultImage() {
                Image(uiImage: defaultImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 160)
            } else {
                Image(systemName: "car.front.waves.up")
                    .foregroundStyle(.blue, .gray)
                    .font(.system(size: 80))
                    .frame(height: 160)
            }
            Spacer().frame(height: 20)
            HStack {
                Spacer()
                Button(
                    action: {},
                    label: {
                        VStack {
                            Image(systemName: "fuelpump.circle")
                                .font(.system(size: 48))
                                .foregroundStyle(.black, .blue)
                            Text("\(controller.carStatus?.oil?.stringValue ?? "-") L")
                                .font(.system(size: 20))
                                .foregroundStyle(.black)
                        }
                    })
                .disabled(controller.inLoading)
                Spacer()
                Button(
                    action: {
                        Task {
                            let result: Bool
                            let carStatus = controller.carStatus
                            if carStatus?.locked ?? false {
                                result = await UserManager.shared.carUnlock()
                                
                            } else {
                                result = await UserManager.shared.carLock()
                            }
                            if result {
                                if carStatus != nil && carStatus!.locked != nil {
                                    controller.carStatus = CarStatus(
                                        locked: !(carStatus!.locked!),
                                        oil: carStatus!.oil
                                    )
                                }
                            }
                        }
                    },
                    label: {
                        VStack {
                            if (controller.inLocking) {
                                Image(systemName: "lock.circle.dotted")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.black, .blue)
                            } else if (controller.carStatus?.locked == nil) {
                                Image(systemName: "lock.trianglebadge.exclamationmark")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.black, .blue)
                                Text("-")
                                    .font(.system(size: 20))
                                    .foregroundStyle(.black)
                            } else if (controller.carStatus!.locked!) {
                                Image(systemName: "lock.circle")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.black, .blue)
                                Text("Locked")
                                    .font(.system(size: 20))
                                    .foregroundStyle(.black)
                            } else {
                                Image(systemName: "lock.open.rotation")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.black, .blue)
                                Text("Unlocked")
                                    .font(.system(size: 20))
                                    .foregroundStyle(.black)
                            }
                        }
                    })
                .disabled(controller.inLoading)
                Spacer()
            }
            Spacer()
        }
        .padding(20)
        .listStyle(.inset)
        .navigationTitle(pageTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar() {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: {
                    CarSettingsView()
                }, label: {
                    Text("Settings")
                })
                .disabled(controller.inLoading)
            }
        }
        .onAppear {
            controller.startPollingStatus()
        }
        .onDisappear() {
            controller.stopPollingStatus()
        }
    }
}

fileprivate class CarDetailViewController : ObservableObject {
    
    @Published fileprivate var carStatus: CarStatus? = nil
    
    @Published fileprivate var inUpdating: Bool = false
    @Published fileprivate var inLocking: Bool = false
    
    fileprivate var inLoading: Bool {
        get {
            return inUpdating || inLocking
        }
    }
    
    private var timer: Timer? = nil
    
    func startPollingStatus() {
        updateStatusSync()
        if timer != nil {
            timer!.invalidate()
        }
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { timer in
            if !self.inUpdating {
                self.updateStatusSync()
            }
        }
    }
    
    func stopPollingStatus() {
        if timer != nil {
            timer!.invalidate()
        }
    }
    
    func updateStatusSync() {
        Task {
            await self.updateStatus()
        }
    }

    func updateStatus() async {
        inUpdating = true
        print("updating car status")
        let status = await UserManager.shared.carStatus()
        if status != nil {
            carStatus = status
        }
        inUpdating = false
    }
}

#Preview {
    NavigationStack {
        CarDetailView()
    }
}

import SwiftUI
internal import Combine

enum MainNavigationPage: Hashable {
    case BeaconList
    case BeaconDetail(_ beaconUUID: UUID)
    case CarSettings
}

class MainNavigationController : ObservableObject {
    static let shared = MainNavigationController()

    @Published fileprivate var navPath: [MainNavigationPage] = []
    
    func push(_ path: MainNavigationPage) {
        navPath.append(path)
    }
    
    func pop() {
        let _ = navPath.popLast()
    }
    
    func root() {
        navPath.removeAll()
    }
}

struct MainView: View {
    @StateObject private var userManager = UserManager.shared
    @StateObject private var mainNavigationController = MainNavigationController.shared

    var body: some View {
        NavigationStack(path: $mainNavigationController.navPath) {
            if !UserManager.shared.isLogin {
                LoginView()
            } else if UserManager.shared.car == nil {
                CarListView()
            } else {
                CarDetailView()
            }
        }
        .background(Color.gray)
    }
}

import SwiftUI

struct MainView: View {
    @StateObject private var userManager = UserManager.shared
    
    var body: some View {
        NavigationStack {
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

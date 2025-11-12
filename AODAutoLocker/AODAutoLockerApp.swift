import SwiftUI
import OSLog

@main
struct AODAutoLockerApp: App {
    
    let logger = Logger()
    
    init() {
        logger.info("App started")
        LockerService.shared.update()
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}

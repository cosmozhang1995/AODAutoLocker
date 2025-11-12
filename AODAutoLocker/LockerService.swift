import Foundation
import OSLog
internal import Combine

class LockerService: BeaconManagerDelegate {
    
    static let shared = LockerService()
    
    let logger = Logger()
    
    var userManagerCarInfoSubsriber: AnyCancellable? = nil
    var carSettingsSubscriber: AnyCancellable? = nil

    private var carSettings: CarSettings? = nil

    private init() {
        BeaconManager.shared.delegate = self
        userManagerCarInfoSubsriber = UserManager.shared.carPublisher
            .sink(receiveValue: { value in
                self.update(carId: value?.id)
            })
        self.update(carId: UserManager.shared.car?.id)
    }
    
    deinit {
        BeaconManager.shared.delegate = nil
    }

    public func update() {
        self.update(carId: UserManager.shared.car?.id)
    }

    private func update(carId: String?) {
        if carId == nil {
            carSettingsSubscriber = nil
            self.update(settings: nil)
        } else {
            carSettingsSubscriber = CarSettingsManager.shared.publisher(carId!)
                .sink(receiveValue: { value in
                    self.update(settings: value)
                })
            self.update(settings: CarSettingsManager.shared.get(carId!))
        }
    }
    
    private func update(settings: CarSettings?) {
        if (settings != nil && settings!.isUnlockOnNearby ?? false) && settings!.beacoUUID != nil {
            BeaconManager.shared.startMonitoringBeacon(uuid: settings!.beacoUUID!)
        } else {
            BeaconManager.shared.stopMonitoringBeacon()
        }
    }
    
    func onBeaconEnterRegion() {
        logger.info("onBeaconEnterRegion")
    }
    
    func onBeaconExitRegion() {
        logger.info("onBeaconExitRegion")
    }
    
    func onBeaconInRange() {
        logger.info("onBeaconInRange")
    }
    
    func onBeaconOutRange() {
        logger.info("onBeaconOutRange")
    }
}

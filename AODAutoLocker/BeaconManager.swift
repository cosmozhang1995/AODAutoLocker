import Foundation
import SwiftUI
import CoreLocation
import CoreBluetooth
import OSLog
internal import Combine

struct BeaconInfo: Identifiable {
    let uuid: UUID
    let manufacturerId: UInt16
    let major: UInt16
    let minor: UInt16
    let txPower: Int8
    let rssi: NSNumber
    let updateTime: Date
    var id: UUID {
        get {
            return uuid
        }
    }
}

protocol BeaconManagerDelegate {
    func onBeaconEnterRegion() -> Void
    func onBeaconExitRegion() -> Void
    func onBeaconInRange() -> Void
    func onBeaconOutRange() -> Void
}

class BeaconManager : NSObject, ObservableObject, CLLocationManagerDelegate, CBCentralManagerDelegate {
    static let shared: BeaconManager = BeaconManager()
    
    let logger = Logger()

    private let locationManager = CLLocationManager()
    private let centralManager = CBCentralManager(delegate: nil, queue: .global())

    @Published private var beaconInfoList: [BeaconInfo] = provideSampleBeacons()
    @Published private var _isScanning: Bool = false
    
    private var beaconUUID: UUID? = nil
    
    var delegate: BeaconManagerDelegate? = nil

    var beacons: [BeaconInfo] {
        get {
            return beaconInfoList
        }
    }
    
    var isScanning: Bool {
        get {
            return _isScanning
        }
    }

    override init() {
        super.init()
        locationManager.delegate = self
        centralManager.delegate = self
    }
    
    func startMonitoringBeacon(uuid beaconUUID: UUID) {
        logger.info("start monitoring beacon: \(beaconUUID.uuidString)")
        
        self.beaconUUID = beaconUUID

        locationManager.requestAlwaysAuthorization()
        
        let region = CLBeaconRegion(uuid: beaconUUID, identifier: "com.cosmozhang.beacon")
        region.notifyOnEntry = true
        region.notifyOnExit = true
        region.notifyEntryStateOnDisplay = true
        locationManager.startMonitoring(for: region)
        
        let constraint = CLBeaconIdentityConstraint(uuid: beaconUUID)
        var foundConstraint = false
        let rangedBeaconConstraints = locationManager.rangedBeaconConstraints
        for _constraint in rangedBeaconConstraints {
            if constraint == _constraint {
                foundConstraint = true
                break
            }
        }
        if !foundConstraint {
            locationManager.startRangingBeacons(satisfying: constraint)
        }
    }
    
    func stopMonitoringBeacon() {
        logger.info("stop monitoring beacon")
        
        beaconUUID = nil
        
        let rangedBeaconConstraints = locationManager.rangedBeaconConstraints
        for constraint in rangedBeaconConstraints {
            locationManager.stopRangingBeacons(satisfying: constraint)
        }
        
        let monitoredRegions = locationManager.monitoredRegions
        for region in monitoredRegions {
            if (region as? CLBeaconRegion) != nil && region.identifier == "com.cosmozhang.beacon" {
                locationManager.stopMonitoring(for: region)
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        guard let beaconRegion = region as? CLBeaconRegion else { return }
        guard beaconRegion.uuid == beaconUUID else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Beacon detected")
        if state == .inside {
            content.body = String(localized: "Beacon enter region")
        } else {
            content.body = String(localized: "Beacon exit region")
        }
        let request = UNNotificationRequest(identifier: "beaconEnter", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)

        if state == .inside {
            delegate?.onBeaconEnterRegion()
        } else {
            delegate?.onBeaconExitRegion()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
        var matchBeacon: CLBeacon? = nil
        for beacon in beacons {
            if beacon.uuid == beaconUUID {
                matchBeacon = beacon
                break
            }
        }
        if matchBeacon != nil {
            delegate?.onBeaconInRange()
        } else {
            delegate?.onBeaconOutRange()
        }
    }
    
    func startScanning() -> Bool {
        guard centralManager.state == .poweredOn else {
            print("Bluetooth is off")
            return false
        }
        _isScanning = true
        centralManager.scanForPeripherals(withServices: nil, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: true
        ])
        print("Start scanning")
        return true
    }
    
    func stopScanning() {
        centralManager.stopScan()
        print("Stop scanning")
        _isScanning = false
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi: NSNumber) {
        guard let beaconInfo = parseIBeacon(from: advertisementData, rssi: rssi) else {
            return
        }
        if let existIndex = beaconInfoList.firstIndex(where: { $0.uuid == beaconInfo.uuid }) {
            beaconInfoList[existIndex] = beaconInfo
        } else {
            beaconInfoList.append(beaconInfo)
        }
    }
    
    private func parseIBeacon(from advertisementData: [String: Any], rssi: NSNumber) -> BeaconInfo? {
        // Fetch the iBeacon protocol data
        guard let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data else {
            return nil
        }

        // iBeacon 数据格式：共 25 字节
        // 0-1: 制造商 ID（苹果为 0x004C）
        // 2: 类型（0x02）
        // 3: 长度（0x15 = 21 字节）
        // 4-19: UUID（16 字节）
        // 20-21: Major（2 字节）
        // 22-23: Minor（2 字节）
        // 24: 信号强度（0-255，对应 -128 至 +127 dBm）
        guard manufacturerData.count == 25 else { return nil }

        let companyID = manufacturerData.subdata(in: 0..<2).withUnsafeBytes { $0.load(as: UInt16.self).littleEndian }

        let type = manufacturerData[2]
        let length = manufacturerData[3]
        guard type == 0x02 && length == 0x15 else { return nil } // 确认是 iBeacon 类型

        // 提取 UUID（16 字节）
        let uuidData = manufacturerData.subdata(in: 4..<20)
        let uuidBytes = uuidData.withUnsafeBytes { $0.bindMemory(to: uuid_t.self) } [0]
        let uuid = UUID(uuid: uuidBytes)

        // 提取 Major（2 字节，大端模式）
        let majorData = manufacturerData.subdata(in: 20..<22)
        let major = majorData.withUnsafeBytes { $0.load(as: UInt16.self).bigEndian }

        // 提取 Minor（2 字节，大端模式）
        let minorData = manufacturerData.subdata(in: 22..<24)
        let minor = minorData.withUnsafeBytes { $0.load(as: UInt16.self).bigEndian }

        // 信号强度（转换为 dBm）
        let txPower = Int8(bitPattern: manufacturerData[24])

        return BeaconInfo(
            uuid: uuid,
            manufacturerId: companyID,
            major: major,
            minor: minor,
            txPower: txPower,
            rssi: rssi,
            updateTime: Date()
        )
    }
}


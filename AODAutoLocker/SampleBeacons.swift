import Foundation

func provideSampleBeacons() -> [BeaconInfo] {
    return [
        BeaconInfo(
            uuid: UUID(uuidString: "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0")!,
            manufacturerId: 0x004C,
            major: 0,
            minor: 0,
            txPower: 127,
            rssi: -85
        ),
        BeaconInfo(
            uuid: UUID(uuidString: "5A4BCFCE-174E-4BAC-A814-092E77F6B7E5")!,
            manufacturerId: 0x004C,
            major: 0,
            minor: 0,
            txPower: 100,
            rssi: -65
        ),
        BeaconInfo(
            uuid: UUID(uuidString: "7B2F9D0A-3C4E-4D1F-8E9A-0B3C5D7E9F1A")!,
            manufacturerId: 0x004C,
            major: 0,
            minor: 0,
            txPower: -50,
            rssi: -85
        ),
        BeaconInfo(
            uuid: UUID(uuidString: "E2C56DB5-DFFB-48D2-B060-D0F5A71096E1")!,
            manufacturerId: 0x004C,
            major: 0,
            minor: 0,
            txPower: 127,
            rssi: -85
        ),
        BeaconInfo(
            uuid: UUID(uuidString: "5A4BCFCE-174E-4BAC-A814-092E77F6B7E6")!,
            manufacturerId: 0x004C,
            major: 0,
            minor: 0,
            txPower: 100,
            rssi: -65
        ),
        BeaconInfo(
            uuid: UUID(uuidString: "7B2F9D0A-3C4E-4D1F-8E9A-0B3C5D7E9F1B")!,
            manufacturerId: 0x004C,
            major: 0,
            minor: 0,
            txPower: -50,
            rssi: -85
        ),
    ]
}

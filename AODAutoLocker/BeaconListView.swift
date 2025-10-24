//
//  ContentView.swift
//  AODAutoLocker
//
//  Created by Mac出租 on 2025/10/21.
//

import SwiftUI
import CoreBluetooth
internal import Combine

struct BeaconListView: View {
    
    @Environment(\.dismiss) var dismiss

    @StateObject private var controller: BeaconListViewController = BeaconListViewController()

    private let onSelect: ((_: BeaconInfo) -> Void)?
    
    init(onSelect: ((_: BeaconInfo) -> Void)? = nil) {
        self.onSelect = onSelect
    }
    
    var body: some View {
        VStack() {
            List {
                ForEach(controller.beaconList) { beaconInfo in
                    NavigationLink(
                        destination: {
                            BeaconDetailView(beaconInfo) {
                                dismiss()
                                if onSelect != nil {
                                    onSelect!(beaconInfo)
                                }
                            }
                        },
                        label: {
                            Button(action: {}) {
                                VStack(alignment: .leading) {
                                    Text(formatBeaconTitle(beaconInfo))
                                        .foregroundColor(.gray)
                                    Text(formatBeaconDescription(beaconInfo))
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    )
                }
            }
            .padding(0)
            .listStyle(.plain)
            Button(controller.isScanning ? "Stop" : "Scan") {
                if controller.isScanning {
                    controller.stopScan()
                } else {
                    controller.startScan()
                }
            }
            .buttonStyle(.borderedProminent)
            .font(.system(size: 24))
            .controlSize(.large)
        }
        .padding()
        .navigationTitle("Detected Devices")
    }

    func formatBeaconTitle(_ beaconInfo: BeaconInfo) -> String {
        let manufacturerId = String(format: "0x%04X", beaconInfo.manufacturerId)
        let uuid = beaconInfo.uuid.uuidString.suffix(12)
        return "\(manufacturerId)(\(uuid))"
    }

    func formatBeaconDescription(_ beaconInfo: BeaconInfo) -> String {
        return "RSSI: \(beaconInfo.rssi)    TX Pwr: \(beaconInfo.txPower)"
    }
}

fileprivate class BeaconListViewController : ObservableObject, BeaconManagerScanDelegate {
    @Published fileprivate var isScanning = false
    @Published fileprivate var beaconList: [BeaconInfo] = provideSampleBeacons()

    func startScan() {
        isScanning = BeaconManager.shared.startScanning()
    }
    
    func stopScan() {
        BeaconManager.shared.stopScanning()
        isScanning = false
    }
    
    func onBeaconListUpdate(_: [BeaconInfo]) {
        self.beaconList = beaconList
    }
}

#Preview {
    BeaconListView() { beaconInfo in
        print("selected:", beaconInfo.id)
    }
}

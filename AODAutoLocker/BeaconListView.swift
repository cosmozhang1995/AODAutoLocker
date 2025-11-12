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

    @StateObject private var beaconManager: BeaconManager = BeaconManager.shared

    private let onSelect: ((_: BeaconInfo) -> Void)?
    
    init(onSelect: ((_: BeaconInfo) -> Void)? = nil) {
        self.onSelect = onSelect
    }
    
    var body: some View {
        VStack() {
            List {
                ForEach(beaconManager.beacons) { beaconInfo in
                    NavigationLink(
                        destination: {
                            BeaconDetailView(beaconInfo.uuid) {
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
//            if beaconManager.isScanning {
//                Button("Stop") {
//                    beaconManager.stopScanning()
//                }
//                .buttonStyle(.borderedProminent)
//                .foregroundStyle(.red)
//                .font(.system(size: 24))
//                .controlSize(.large)
//            } else {
//                Button("Scan") {
//                    let _ = beaconManager.startScanning()
//                }
//                .buttonStyle(.borderedProminent)
//                .font(.system(size: 24))
//                .controlSize(.large)
//            }
        }
        .padding()
        .navigationTitle("Detected Beacons")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear() {
            if !beaconManager.isScanning {
                let _ = beaconManager.startScanning()
            }
        }
        .onDisappear() {
            if beaconManager.isScanning {
                beaconManager.stopScanning()
            }
        }
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

#Preview {
    NavigationStack {
        BeaconListView() { beaconInfo in
            print("selected:", beaconInfo.id)
        }
    }
}

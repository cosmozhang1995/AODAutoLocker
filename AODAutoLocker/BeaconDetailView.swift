//
//  BeaconDetailView.swift
//  AODAutoLocker
//
//  Created by Mac出租 on 2025/10/22.
//

import SwiftUI
internal import Combine


fileprivate struct ViewItem: View {
    let label: String
    let value: String
    let isShowAlertOnTap: Bool

    @State var isShowAlert: Bool = false

    init(label: String, value: String, showAlertOnTap isShowAlertOnTap: Bool = false) {
        self.label = label
        self.value = value
        self.isShowAlertOnTap = isShowAlertOnTap
    }
    var body: some View {
        Button(
            action: {
                if isShowAlertOnTap {
                    isShowAlert = true
                }
            },
            label: {
                HStack {
                    Text("")
                    HStack() {
                        Spacer()
                        Text(label)
                            .foregroundStyle(.gray)
                    }
                    .frame(width: 108)
                    .padding(0)
                    Spacer().frame(width: 20)
                    Text(value)
                        .foregroundStyle(.black)
                        .lineLimit(2)
                        .minimumScaleFactor(0.1)
                }
            })
        .alert(label, isPresented: $isShowAlert, actions: {
            VStack {
                Text(value)
                Button("OK") {
                    isShowAlert = false
                }
            }
        })
    }
}

struct BeaconDetailView: View {
    
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var beaconManager: BeaconManager = BeaconManager.shared

    let beaconUUID: UUID

    var beaconInfo: BeaconInfo? {
        get {
            beaconManager.beacons.first(where: {
                $0.uuid == beaconUUID
            })
        }
    }

    private let onSelect: (() -> Void)?
    
    init(_ beaconUUID: UUID, onSelect: (() -> Void)? = nil) {
        self.beaconUUID = beaconUUID
        self.onSelect = onSelect
    }
    
    var body: some View {
        Form {
            ViewItem(label: "Manufactory", value: formatManufactoryId(beaconInfo))
            ViewItem(label: "Version", value: formatVersion(beaconInfo))
            ViewItem(label: "UUID", value: formatUUID(beaconInfo), showAlertOnTap: true)
            ViewItem(label: "TX Power", value: beaconInfo != nil ? String(beaconInfo!.txPower) : "-")
            ViewItem(label: "RSSI", value: beaconInfo?.rssi.stringValue ?? "-")
        }
        .navigationTitle("Beacon Detail")
        .toolbar {
            if onSelect != nil {
                ToolbarItem(placement: .bottomBar) {
                    Button("Select this beacon") {
                        dismiss()
                        onSelect!()
                    }
                    .buttonStyle(.borderedProminent)
                    .font(.system(size: 24))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }
            }
        }
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
    
    func formatManufactoryId(_ beaconInfo: BeaconInfo?) -> String {
        if beaconInfo != nil {
            return String(format: "0x%04X", beaconInfo!.manufacturerId)
        } else {
            return "NIL"
        }
    }

    func formatVersion(_ beaconInfo: BeaconInfo?) -> String {
        if beaconInfo != nil {
            return "\(beaconInfo!.major).\(beaconInfo!.minor)"
        } else {
            return "NIL"
        }
    }
    
    func formatUUID(_ beaconInfo: BeaconInfo?) -> String {
        if beaconInfo != nil {
            return beaconInfo!.uuid.uuidString
        } else {
            return "NIL"
        }
    }
}

#Preview {
    NavigationStack {
        BeaconDetailView(
            provideSampleBeacons()[0].uuid
        ) {
            print("selected")
        }
    }
}

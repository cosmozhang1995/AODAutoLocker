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
    init(label: String, value: String) {
        self.label = label
        self.value = value
    }
    var body: some View {
        Button(action: {}, label: {
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
                    .lineLimit(1)
            }
        })
    }
}

struct BeaconDetailView: View {
    
    @Environment(\.dismiss) var dismiss
    
    private let beaconInfo: BeaconInfo
    @StateObject private var controller = BeaconDetailViewController()

    private let onSelect: (() -> Void)?
    
    init(_ beaconInfo: BeaconInfo, onSelect: (() -> Void)? = nil) {
        self.beaconInfo = beaconInfo
        self.onSelect = onSelect
    }
    
    var body: some View {
        Form {
            ViewItem(label: "Manufactory", value: formatManufactoryId(beaconInfo))
            ViewItem(label: "Version", value: formatVersion(beaconInfo))
            ViewItem(label: "UUID", value: formatUUID(beaconInfo))
            ViewItem(label: "TX Power", value: String(beaconInfo.txPower))
            ViewItem(label: "RSSI", value: controller.rssi?.stringValue ?? "NIL")
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

class BeaconDetailViewController : ObservableObject, BeaconManagerScanDelegate {

    fileprivate var beaconInfo: BeaconInfo? = nil
    @Published fileprivate var rssi: NSNumber? = nil

    func onBeaconListUpdate(_ beaconList: [BeaconInfo]) {
        if self.beaconInfo != nil {
            let beaconInfo = beaconList.first(where: { $0.uuid == self.beaconInfo!.uuid })
            self.rssi = beaconInfo?.rssi
        } else {
            self.rssi = nil
        }
    }
}

#Preview {
    NavigationStack {
        BeaconDetailView(
            provideSampleBeacons()[0]
        ) {
            print("selected")
        }
    }
}

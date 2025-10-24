//
//  ContentView.swift
//  AODAutoLocker
//
//  Created by Mac出租 on 2025/10/21.
//

import SwiftUI
import CoreBluetooth
internal import Combine

struct CarListView: View {

    @State var carList: [CarInfo] = []

    var body: some View {
        VStack() {
            List {
                ForEach(carList) { carInfo in
                    Button(
                        action: {
                            UserManager.shared.setCar(carInfo)
                        },
                        label: {
                            HStack(alignment: .center) {
                                Text("")
                                Image(systemName: "car")
                                    .foregroundStyle(.blue, .gray)
                                    .font(.largeTitle)
                                Text(carInfo.no ?? "Unknown car")
                                    .font(.system(size: 20))
                                Spacer()
                                Text(formatCarSubtitle(carInfo))
                                    .foregroundColor(.gray)
                                    .font(.system(size: 20))
                            }
                            .padding(.vertical, 10)
                        }
                    )
                }
            }
            .padding(0)
            .listStyle(.plain)
            HStack {
                Button("Sign out") {
                    UserManager.shared.logout()
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.red)
                .font(.system(size: 20))
            }
            .padding(.horizontal, 20)
        }
        .padding()
        .navigationTitle("Choose your car")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            Task {
                carList = await UserManager.shared.carList() ?? []
            }
        }
    }

    func formatCarSubtitle(_ carInfo: CarInfo) -> String {
        if (carInfo.brand != nil && carInfo.model != nil) {
            return "\(carInfo.brand!) \(carInfo.model!)"
        } else if (carInfo.brand != nil) {
            return carInfo.brand!
        } else if (carInfo.model != nil) {
            return carInfo.model!
        } else {
            return ""
        }
    }
}

#Preview {
    NavigationStack {
        CarListView()
    }
}

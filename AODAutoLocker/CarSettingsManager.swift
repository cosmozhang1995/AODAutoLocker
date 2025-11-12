import Foundation
internal import Combine

struct CarSettings: Codable {
    var beacoUUID: UUID?
    var isUnlockOnNearby: Bool?
}

fileprivate let CAR_SETTINGS_ROOT_PATH = "car_settings"

class CarSettingsManager : ObservableObject {
    static let shared = CarSettingsManager()
    
    @Published private var settingsMap: [String: CarSettings] = [:]

    init() {
        loadAll()
    }

    private class SettingsSubscription<P, S>: Subscription where
    S: Subscriber, Never == S.Failure, CarSettings? == S.Input,
    P: Publisher, Never == P.Failure, [String: CarSettings] == P.Output
    {
        public typealias Input = CarSettings?
        public typealias Failure = Never

        private let mapPublisher: P
        private var subscriber: S?
        private let mapKey: String
        
        private var sinkedSubscription: AnyCancellable? = nil
        
        init(mapPublisher: P, subscriber: S, mapKey: String) {
            self.mapPublisher = mapPublisher
            self.subscriber = subscriber
            self.mapKey = mapKey
            sinkedSubscription = self.mapPublisher
                .sink(receiveValue: { [weak self] newMap in
                    guard let mapKey = self?.mapKey else { return }
                    guard let subscriber = self?.subscriber else { return }
                    let value = newMap[mapKey]
                    let _ = subscriber.receive(value)
                })
        }
        
        func request(_ demand: Subscribers.Demand) {
        }
        
        func cancel() {
            self.subscriber = nil
            self.sinkedSubscription = nil
        }
    }
    
    public struct SettingsPublisher<P>: Publisher where P : Publisher, Never == P.Failure, [String: CarSettings] == P.Output {
        
        public typealias Output = CarSettings?
        public typealias Failure = Never

        private let carId: String
        private let mapPublisher: P
        
        init(mapPublisher: P, carId: String) {
            self.mapPublisher = mapPublisher
            self.carId = carId
        }
        
        func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, CarSettings? == S.Input {
            subscriber.receive(subscription: SettingsSubscription(mapPublisher: self.mapPublisher, subscriber: subscriber, mapKey: self.carId))
        }
    }

    func publisher(_ carId: String) -> SettingsPublisher<Published<[String: CarSettings]>.Publisher> {
        return SettingsPublisher(mapPublisher: $settingsMap, carId: carId)
    }
    
    func get(_ carId: String) -> CarSettings {
        return settingsMap[carId] ?? CarSettings()
    }
    
    func set(_ carId: String, beaconUUID: UUID?) {
        var settings = settingsMap[carId] ?? CarSettings()
        settings.beacoUUID = beaconUUID
        save(carId, settings)
    }
    
    func set(_ carId: String, isUnlockOnNearby: Bool?) {
        var settings = settingsMap[carId] ?? CarSettings()
        settings.isUnlockOnNearby = isUnlockOnNearby
        save(carId, settings)
    }

    private var carSettingsRootPath: URL {
        get {
            FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("car_settings")
        }
    }
    
    private func sentinelCarSettingsRootPath() throws {
        if !FileManager.default.fileExists(atPath: carSettingsRootPath.path()) {
            try FileManager.default.createDirectory(at: carSettingsRootPath, withIntermediateDirectories: true)
        }
    }

    private func carSettingsPath(_ carId: String) -> URL {
        return carSettingsRootPath.appendingPathComponent("\(carId).json")
    }

    private func save(_ carId: String, _ settings: CarSettings?) {
        if settings == nil {
            settingsMap.removeValue(forKey: carId)
            do {
                try FileManager.default.removeItem(at: carSettingsPath(carId))
            } catch {
                print("Failed to delete car settings: \(error.localizedDescription)")
            }
        } else {
            settingsMap[carId] = settings
            let encoder = JSONEncoder()
            do {
                try sentinelCarSettingsRootPath()
                try encoder.encode(settings).write(to: carSettingsPath(carId))
            } catch {
                print("Failed to save car settings: \(error.localizedDescription)")
            }
        }
    }
    
    private func loadAll() {
        if !FileManager.default.fileExists(atPath: carSettingsRootPath.path()) {
            return
        }
        do {
            let files = try FileManager.default.contentsOfDirectory(at: carSettingsRootPath, includingPropertiesForKeys: [.isRegularFileKey])
            for filePath in files {
                let carId = filePath.deletingPathExtension().lastPathComponent
                let decoder = JSONDecoder()
                let data = try Data(contentsOf: filePath)
                let settings = try decoder.decode(CarSettings.self, from: data)
                settingsMap[carId] = settings
            }
        } catch {
            print("Failed to list files in \(carSettingsRootPath.path()): \(error.localizedDescription)")
        }
        
    }
}

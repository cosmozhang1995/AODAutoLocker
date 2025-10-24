import Foundation
internal import Combine

fileprivate let UDKEY_TOKEN = "aod.token"
fileprivate let UDKEY_USERNAME = "aod.username"
fileprivate let UDKEY_PASSWORD = "aod.password"
fileprivate let FILEPATH_CARINFO = "car_info.data"

struct CarInfo: Codable, Identifiable {
    let id: String?
    let no: String?
    let brand: String?
    let model: String?
}

struct CarStatus {
    let locked: Bool?
    let oil: NSNumber?
}

class UserManager : ObservableObject {
    static let shared = UserManager()
    
    @Published private var token: String? = nil
    @Published private var carInfo: CarInfo? = nil
    
    struct LoginInfo {
        var phone: String = ""
        var password: String = ""
    }
    @Published var loginInfo: LoginInfo = LoginInfo()

    var isLogin: Bool {
        get {
            return token != nil
        }
    }
    
    var car: CarInfo? {
        get {
            return carInfo
        }
    }
    
    private let URLBASE = "https://iov.edaoduo.com/aoduo/prod/api/v3"
    
    init() {
        let defaults = UserDefaults.standard
        token = defaults.string(forKey: UDKEY_TOKEN)
        loadLoginInfo()
        loadCar()
    }
    
    private func generateNonce() -> String {
        let DD = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var s = ""
        for _ in 0..<8 {
            s.append(DD.randomElement()!)
        }
        return s
    }

    private enum ResponseStatus: Int {
        case Success = 200
        case AuthFailure = 401
        case OtherFailure = -1
    }
    private struct Response {
        let status: ResponseStatus
        let data: [String: Any]?
        init(status: ResponseStatus, data: [String: Any]? = nil) {
            self.status = status
            self.data = data
        }
    }
    
    private enum HttpMethod: String {
        case GET = "GET"
        case POST = "POST"
    }

    private func exchange(method: HttpMethod, path: String, params: [String: Any]) async -> Response {
        var fullParams = params
        fullParams["nonce"] = generateNonce()
        fullParams["timestamp"] = Int(Date().timeIntervalSince1970)
        let paramString = Array(fullParams.keys)
            .sorted()
            .map({ "\($0)=\(fullParams[$0]!)" })
            .joined(separator: "&")
        var request: URLRequest
        switch method {
        case .GET:
            request = URLRequest(url: URL(string: "\(URLBASE)\(path)?\(paramString)")!)
            request.httpMethod = method.rawValue
        case .POST:
            request = URLRequest(url: URL(string: "\(URLBASE)\(path)")!)
            request.httpMethod = method.rawValue
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpBody = paramString.data(using: .utf8)
        }
        if token != nil {
            request.setValue(token!, forHTTPHeaderField: "token")
        }
        do {
            let (rawData, res) = try await URLSession.shared.data(for: request)
            guard let httpRes = res as? HTTPURLResponse, (200...299).contains(httpRes.statusCode) else {
                return Response(status: .OtherFailure)
            }
            guard let result = try JSONSerialization.jsonObject(with: rawData) as? [String: Any] else {
                return Response(status: .OtherFailure)
            }
            guard let data = result["data"] as? [String: Any]? else {
                return Response(status: .OtherFailure)
            }
            let resultStatus = (result["status"] as? Int) ?? -1
            let status = ResponseStatus(rawValue: resultStatus) ?? ResponseStatus.OtherFailure
            return Response(status: status, data: data)
        } catch {
            return Response(status: .OtherFailure)
        }
    }
    
    func saveLoginInfo() {
        let defaults = UserDefaults.standard
        defaults.set(loginInfo.phone, forKey: UDKEY_USERNAME)
        defaults.set(loginInfo.password, forKey: UDKEY_PASSWORD)
        defaults.synchronize()
    }
    
    func loadLoginInfo() {
        let defaults = UserDefaults.standard
        loginInfo.phone = defaults.string(forKey: UDKEY_USERNAME) ?? "";
        loginInfo.password = defaults.string(forKey: UDKEY_PASSWORD) ?? "";
    }

    func login(phone: String, password: String) async -> Bool {
        let response = await exchange(
            method: .POST,
            path: "/aodkey/login",
            params: [ "phone": phone, "passwd": password ])
        switch response.status {
        case .Success:
            guard let token = response.data?["token"] as? String else {
                return false
            }
            self.token = token
            let defaults = UserDefaults.standard
            defaults.set(token, forKey: UDKEY_TOKEN)
            defaults.synchronize()
            return true
        default:
            return false
        }
    }
    
    func logout() {
        token = nil
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: UDKEY_TOKEN)
        defaults.synchronize()
    }

    private func handleAuthFailure() {
        self.token = nil
    }
    
    func carList() async -> [CarInfo]? {
        let response = await exchange(
            method: .GET,
            path: "/car/carList",
            params: [
                "flag": 0,
                "keyword": "",
                "page": 0,
                "pagesize": 0
            ])
        if (response.status == .AuthFailure) {
            handleAuthFailure()
            return nil
        }
        if (response.status != .Success) {
            return nil
        }
        guard let rawList = response.data?["list"] as? [[String: Any]] else {
            return nil
        }
        return rawList.map({
            CarInfo(
                id: $0["carid"] as? String,
                no: $0["carno"] as? String,
                brand: $0["brand"] as? String,
                model: $0["car_model"] as? String)
        })
    }
 
    private func carInfoPath() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(FILEPATH_CARINFO)
    }
    
    func setCar(_ carInfo: CarInfo?) {
        self.carInfo = carInfo
        let encoder = JSONEncoder()
        do {
            try encoder.encode(carInfo).write(to: carInfoPath())
        } catch {
            print("Failed to serialize car info")
        }
    }
    
    func resetCar() {
        self.carInfo = nil
    }
    
    func loadCar() {
        let decoder = JSONDecoder()
        do {
            try carInfo = decoder.decode(CarInfo.self, from: Data(contentsOf: carInfoPath()))
        } catch {
            print("Failed to deserialize car info")
        }
    }
    
    private enum CarControlAction: String {
        case Lock = "lock"
        case Unlock = "unlock"
    }
    private func carControl(_ action: CarControlAction) async -> Bool {
        if carInfo?.id == nil {
            return false
        }
        let response = await exchange(
            method: .POST,
            path: "/car/ctrl",
            params: [
                "boot_time": 0,
                "carid": carInfo!.id!,
                "ctrl": action.rawValue
            ])
        if (response.status == .AuthFailure) {
            handleAuthFailure()
            return false
        }
        if (response.status != .Success) {
            return false
        }
        return true
    }
    
    func carLock() async -> Bool {
        return await carControl(.Lock)
    }
    
    func carUnlock() async -> Bool {
        return await carControl(.Unlock)
    }
    
    func carStatus() async -> CarStatus? {
        if carInfo?.id == nil {
            return nil
        }
        let response = await exchange(
            method: .GET,
            path: "/car/status",
            params: [ "carid": carInfo!.id! ])
        if (response.status == .AuthFailure) {
            handleAuthFailure()
            return nil
        }
        if (response.status != .Success) {
            return nil
        }
        guard let rawInfo = response.data else {
            return nil
        }
        let locked: Bool?
        if let rawLock = rawInfo["lock"] as? [String: Any] {
            let lf = rawLock["lf"] as? Int
            let lr = rawLock["lr"] as? Int
            let rf = rawLock["rf"] as? Int
            let rr = rawLock["rr"] as? Int
            if lf != nil && lr != nil && rf != nil && rr != nil {
                locked = lf! == 0 && lr! == 0 && rf! == 0 && rr! == 0
            } else {
                locked = nil
            }
        } else {
            locked = nil
        }
        let oilString = rawInfo["oil"] as? String
        let oilAmount = oilString != nil ? NumberFormatter().number(from: oilString!) : nil
        return CarStatus(
                locked: locked,
                oil: oilAmount)
    }
}

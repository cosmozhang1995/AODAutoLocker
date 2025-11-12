import SwiftUI
import OSLog

struct LogView: View {

    @State private var queryDate = Date(timeInterval: -30 * 3600, since: Date.now)
    
//    func fetchLogs() {
//        do {
//            OSLogStore.local().position(date: queryDate)
//            
//            // 1. 检查权限
//            guard try OSLogStore.local().checkAccess(to: .currentProcess) else {
//                return ["无日志查询权限"]
//            }
//            
//            // 2. 定义查询时间范围（最近 N 分钟）
//            let store = OSLogStore.shared
//            let endDate = Date()
//            guard let startDate = Calendar.current.date(byAdding: .minute, value: -recentMinutes, to: endDate) else {
//                return ["时间范围计算失败"]
//            }
//            
//            let timeRange = DateInterval(start: startDate, end: endDate)
//            
//            // 3. 构建查询条件（只查询当前 App 的日志）
//            let predicate = NSPredicate(format: "subsystem == %@", Bundle.main.bundleIdentifier!)
//            let entries = try store.getEntries(with: predicate, in: timeRange)
//            
//            // 4. 解析日志条目
//            var logs = [String]()
//            for entry in entries {
//                guard let logEntry = entry as? OSLogEntryLog else { continue }
//                
//                // 日志内容（包含时间戳、级别、信息）
//                let timeFormatter = DateFormatter()
//                timeFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
//                let timestamp = timeFormatter.string(from: logEntry.date)
//                
//                let logContent = "[\(timestamp)] [\(logEntry.level.rawValue.uppercased())] - \(logEntry.composedMessage)"
//                logs.append(logContent)
//            }
//            
//            return logs.reversed() // 倒序排列（最新日志在最后）
//        } catch {
//            return ["日志查询失败：\(error.localizedDescription)"]
//        }
//    }
    
    var body: some View {
        List {
            
            HStack {
                Text("")
            }
        }
        .navigationTitle("Logs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .bottomBar, content: {
                DatePicker("Since", selection: $queryDate)
            })
        }
    }
}

#Preview {
    NavigationStack {
        LogView()
    }
}

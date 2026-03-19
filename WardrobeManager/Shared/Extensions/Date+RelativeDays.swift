import Foundation

extension Date {
    func daysSinceNow(calendar: Calendar = .current) -> Int {
        calendar.dateComponents([.day], from: self, to: .now).day ?? 0
    }
}

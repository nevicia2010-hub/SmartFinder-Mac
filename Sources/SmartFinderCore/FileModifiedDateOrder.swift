import Foundation

public enum FileModifiedDateOrder {
    public enum Bucket: Equatable {
        case today
        case pastSevenDays
        case pastThirtyDays
        case month(Date)
        case year(Date)
        case future
        case undated
    }

    public struct Section {
        public let bucket: Bucket?
        public let range: Range<Int>

        public init(bucket: Bucket?, range: Range<Int>) {
            self.bucket = bucket
            self.range = range
        }
    }

    public static func sorted(
        _ items: [FileItem],
        newestFirst: Bool,
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> [FileItem] {
        let tomorrow = calendar.dateInterval(of: .day, for: referenceDate)?.end ?? .distantFuture
        return items.sorted { left, right in
            switch (left.modifiedAt, right.modifiedAt) {
            case let (leftDate?, rightDate?) where leftDate != rightDate:
                let leftIsFuture = leftDate >= tomorrow
                let rightIsFuture = rightDate >= tomorrow
                if leftIsFuture != rightIsFuture {
                    return !leftIsFuture
                }
                return newestFirst ? leftDate > rightDate : leftDate < rightDate
            case (.some, nil):
                return true
            case (nil, .some):
                return false
            default:
                return left.name.localizedStandardCompare(right.name) == .orderedAscending
            }
        }
    }

    public static func sections(
        for sortedItems: [FileItem],
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> [Section] {
        guard let first = sortedItems.first else {
            return []
        }

        let today = calendar.startOfDay(for: referenceDate)
        let tomorrow = calendar.dateInterval(of: .day, for: referenceDate)?.end ?? .distantFuture
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? .distantPast
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: today) ?? .distantPast
        let yearStart = calendar.dateInterval(of: .year, for: today)?.start ?? today

        func bucket(for date: Date?) -> Bucket {
            guard let date else { return .undated }
            if date >= tomorrow { return .future }
            if date >= today { return .today }
            if date >= sevenDaysAgo { return .pastSevenDays }
            if date >= thirtyDaysAgo { return .pastThirtyDays }
            if date >= yearStart {
                return .month(calendar.dateInterval(of: .month, for: date)?.start ?? date)
            }
            return .year(calendar.dateInterval(of: .year, for: date)?.start ?? date)
        }

        var sections: [Section] = []
        var start = 0
        var current = bucket(for: first.modifiedAt)
        for index in sortedItems.indices.dropFirst() {
            let next = bucket(for: sortedItems[index].modifiedAt)
            if next != current {
                sections.append(Section(bucket: current, range: start..<index))
                start = index
                current = next
            }
        }
        sections.append(Section(bucket: current, range: start..<sortedItems.count))
        return sections
    }
}

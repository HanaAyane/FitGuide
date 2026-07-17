import Foundation

enum BodyPartTranslation {
    static let map: [String: String] = [
        "back": "背部",
        "cardio": "有氧",
        "chest": "胸部",
        "lower arms": "前臂",
        "lower legs": "小腿",
        "neck": "颈部",
        "shoulders": "肩部",
        "upper arms": "上臂",
        "upper legs": "大腿",
        "waist": "腰腹"
    ]

    static func zh(for key: String) -> String {
        map[key.lowercased()] ?? key
    }
}

enum BodyPartOrder {
    static let order: [String] = [
        "chest", "back", "shoulders", "upper arms",
        "upper legs", "lower legs", "waist", "lower arms",
        "cardio", "neck"
    ]

    static func indexOf(_ key: String) -> Int {
        let k = key.lowercased()
        if let i = order.firstIndex(of: k) { return i }
        return order.count
    }
}
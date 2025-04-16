import Foundation
import FirebaseFirestore

struct Transaction: Identifiable, Codable {
    var id: String
    var userId: String
    var amount: Double
    var type: TransactionType
    var category: String
    var remark: String?
    var date: Date
    var tags: [String]
    
    enum TransactionType: String, Codable {
        case income
        case expenses
    }
    
    var dictionary: [String: Any] {
        return [
            "transaction_id": id,
            "transaction_user_id": userId,
            "transaction_amount": String(amount),
            "transaction_type": type.rawValue,
            "transaction_category": category,
            "transaction_remark": remark ?? "",
            "transaction_date": String(Int(date.timeIntervalSince1970 * 1000)),
            "transaction_tags": tags
        ]
    }
    
    init(id: String = UUID().uuidString,
         userId: String,
         amount: Double,
         type: TransactionType,
         category: String,
         remark: String? = nil,
         date: Date = Date(),
         tags: [String] = []) {
        self.id = id
        self.userId = userId
        self.amount = amount
        self.type = type
        self.category = category
        self.remark = remark
        self.date = date
        self.tags = tags
    }
    
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        
        guard let id = data["transaction_id"] as? String,
              let userId = data["transaction_user_id"] as? String,
              let amountString = data["transaction_amount"] as? String,
              let amount = Double(amountString),
              let typeString = data["transaction_type"] as? String,
              let type = TransactionType(rawValue: typeString),
              let category = data["transaction_category"] as? String,
              let dateString = data["transaction_date"] as? String,
              let dateMillis = Double(dateString) else {
            return nil
        }
        
        self.id = id
        self.userId = userId
        self.amount = amount
        self.type = type
        self.category = category
        self.remark = data["transaction_remark"] as? String
        self.date = Date(timeIntervalSince1970: dateMillis / 1000)
        self.tags = data["transaction_tags"] as? [String] ?? []
    }
} 
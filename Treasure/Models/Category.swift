import Foundation
import FirebaseFirestore

struct Category: Identifiable, Codable {
    var id: String
    var name: String
    var image: String
    var type: CategoryType
    var order: Int
    
    enum CategoryType: String, Codable {
        case income
        case expenses
    }
    
    var dictionary: [String: Any] {
        return [
            "category_name": name,
            "category_image": image,
            "category_type": type.rawValue,
            "category_order": order
        ]
    }
    
    init(id: String = UUID().uuidString,
         name: String,
         image: String,
         type: CategoryType,
         order: Int) {
        self.id = id
        self.name = name
        self.image = image
        self.type = type
        self.order = order
    }
    
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        
        guard let name = data["category_name"] as? String,
              let image = data["category_image"] as? String,
              let typeString = data["category_type"] as? String,
              let type = CategoryType(rawValue: typeString) else {
            return nil
        }
        
        // Handle different types for order
        let order: Int
        if let intOrder = data["category_order"] as? Int {
            order = intOrder
        } else if let int64Order = data["category_order"] as? Int64 {
            order = Int(int64Order)
        } else if let doubleOrder = data["category_order"] as? Double {
            order = Int(doubleOrder)
        } else if let stringOrder = data["category_order"] as? String,
                  let parsedOrder = Int(stringOrder) {
            order = parsedOrder
        } else if let numberOrder = data["category_order"] as? NSNumber {
            order = numberOrder.intValue
        } else {
            // If all else fails, try converting to string and parsing
            if let orderValue = data["category_order"],
               let orderString = String(describing: orderValue) as String?,
               let parsedOrder = Int(orderString) {
                order = parsedOrder
            } else {
                print("Failed to parse order from: \(String(describing: data["category_order"]))")
                return nil
            }
        }
        
        self.id = document.documentID
        self.name = name
        self.image = image
        self.type = type
        self.order = order
    }
} 
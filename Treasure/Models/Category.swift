import Foundation
import FirebaseAuth
import FirebaseFirestore

struct Category: Identifiable, Codable {
    var id: String
    var name: String
    var image: String
    var type: CategoryType
    var order: Int
    var createdBy: String
    var active: Bool

    enum CategoryType: String, Codable {
        case income
        case expenses
    }

    var isPersonal: Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        return createdBy == uid
    }

    var dictionary: [String: Any] {
        return [
            "category_name": name,
            "category_image": image,
            "category_type": type.rawValue,
            "category_order": order,
            "created_by": createdBy,
            "active": active
        ]
    }

    init(id: String = UUID().uuidString,
         name: String,
         image: String,
         type: CategoryType,
         order: Int,
         createdBy: String = "admin",
         active: Bool = true) {
        self.id = id
        self.name = name
        self.image = image
        self.type = type
        self.order = order
        self.createdBy = createdBy
        self.active = active
    }

    init?(document: QueryDocumentSnapshot) {
        let data = document.data()

        guard let name = data["category_name"] as? String,
              let typeString = data["category_type"] as? String,
              let type = CategoryType(rawValue: typeString) else {
            return nil
        }

        if let active = data["active"] as? Bool, active == false {
            return nil
        }

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
        } else if let orderValue = data["category_order"],
                  let parsedOrder = Int(String(describing: orderValue)) {
            order = parsedOrder
        } else {
            return nil
        }

        self.id = document.documentID
        self.name = name
        self.image = data["category_image"] as? String ?? ""
        self.type = type
        self.order = order
        self.createdBy = data["created_by"] as? String ?? "admin"
        self.active = true
    }
}

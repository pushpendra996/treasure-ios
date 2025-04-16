import UIKit
import FirebaseAuth

class PhoneAuthDelegateManager {
    static let shared = PhoneAuthDelegateManager()
    let delegate = PhoneAuthUIDelegate()
    private init() {}
}

class PhoneAuthUIDelegate: NSObject, AuthUIDelegate {
    private var presentedViewController: UIViewController?
    
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            // Get the root view controller
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first,
                  let rootViewController = window.rootViewController else {
                print("Failed to get root view controller")
                return
            }
            
            // Find the topmost presented view controller
            var topController = rootViewController
            while let presented = topController.presentedViewController {
                topController = presented
            }
            
            // Present the view controller
            topController.present(viewControllerToPresent, animated: flag) { [weak self] in
                self?.presentedViewController = viewControllerToPresent
                completion?()
            }
        }
    }
    
    func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        DispatchQueue.main.async { [weak self] in
            self?.presentedViewController?.dismiss(animated: flag) {
                self?.presentedViewController = nil
                completion?()
            }
        }
    }
} 
import SwiftUI
import CoreLocation
import MessageUI

class EmergencyService: ObservableObject {
    static let shared = EmergencyService()
    
    // Make emergency call
    func callEmergencyContact(_ phoneNumber: String) {
        if let url = URL(string: "tel://\(phoneNumber)"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    // Send emergency message
    func sendEmergencyMessage(to contact: EmergencyContactPerson,
                            location: CLLocation?,
                            tripInfo: String? = nil) {
        var message = "🆘 Emergency Alert\n"
        
        if let location = location {
            message += "\n📍 My Location:\n"
            message += "https://maps.google.com/?q=\(location.coordinate.latitude),\(location.coordinate.longitude)\n"
        }
        
        if let tripInfo = tripInfo {
            message += "\n🚶‍♂️ Current Trip:\n\(tripInfo)"
        }
        
        if let url = URL(string: "sms:\(contact.phoneNumber)&body=\(message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
} 

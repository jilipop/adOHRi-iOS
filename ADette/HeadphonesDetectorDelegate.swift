import Foundation

protocol HeadphonesDetectorDelegate: AnyObject {
    func headphonesDidDisconnect(_ sender:HeadphonesDetector)
}

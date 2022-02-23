import UIKit

extension Bundle {
    var displayName: String? {
        return infoDictionary?["CFBundleDisplayName"] as? String
    }
    var version: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
}

class InfoViewController: UIViewController {
    
    let authorText = NSLocalizedString("InfoViewController.AuthorLabel", comment: "Nennung des App-Entwicklers und des Auftraggebers")
    let licencesButtonText = NSLocalizedString("InfoViewController.LicencesButtonText", comment: "Text des Lizenzen-Buttons")
    

    @IBOutlet weak var appNameAndVersion: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var licencesButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        appNameAndVersion.text = ""
        if let displayName = Bundle.main.displayName {
            appNameAndVersion.text = "\(displayName) "
        }
        if let version = Bundle.main.version {
            appNameAndVersion.text?.append(version)
        }
        authorLabel.text = authorText
        licencesButton.setTitle(licencesButtonText, for: .normal)
    }
}

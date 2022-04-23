import UIKit
import LicensesKit

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
    let sourceCodeButtonText = NSLocalizedString("InfoViewController.SourceCodeButtonText", comment: "Text des Quellcode-Buttons")
    
    let licensesVC = LicensesViewController()

    @IBOutlet weak var appNameAndVersion: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var licencesButton: UIButton!
    @IBOutlet weak var sourceCodeButton: UIButton!
    
    @IBAction func didTapSourceCodeButton(sender: AnyObject) {
        UIApplication.shared.open(URL(string:"https://github.com/jilipop/adOHRi-iOS")!, options: [:], completionHandler: nil)
    }
    
    @IBAction func didTapLicensesButton(sender: AnyObject) {
        licensesVC.setNoticesFromJSONFile(filepath: Bundle.main.path(forResource: "licenses.json", ofType: nil)!)
        licensesVC.pageHeader = NSLocalizedString("LicensesViewController.HeaderText", comment: "HTML-formatierte Überschrift der Lizenzliste")
        licensesVC.navigationTitle = NSLocalizedString("LicensesViewController.Title", comment: "Titel der Lizenzliste – ganz oben in der Navigationsleiste")
        self.navigationController!.pushViewController(licensesVC, animated: true)
    }
    
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
        sourceCodeButton.setTitle(sourceCodeButtonText, for: .normal)
    }
}

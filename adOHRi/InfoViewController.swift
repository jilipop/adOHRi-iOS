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
    let infoText = NSLocalizedString("InfoViewController.InfoLabel", comment: "Erklärtext zur App")
    let privacyButtonText = NSLocalizedString("InfoViewController.PrivacyButtonText", comment: "Text des Datenschutz-Buttons")
    let licencesButtonText = NSLocalizedString("InfoViewController.LicencesButtonText", comment: "Text des Lizenzen-Buttons")
    let sourceCodeButtonText = NSLocalizedString("InfoViewController.SourceCodeButtonText", comment: "Text des Quellcode-Buttons")
    
    let licensesVC = LicensesViewController()
    let licensesCss = "body {\nbackground-color: #000;\ncolor: #fff;\nfont-family: sans-serif;\noverflow-wrap:\nbreak-word;\n}\npre {\nbackground-color: #181818;\npadding: 1em;\nwhite-space: pre-wrap;\n}\na {\ncolor: #1E90FF;\n}\np.license {\nbackground:grey;\n}"
    
    @IBOutlet weak var appNameAndVersion: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var privacyButton: UIButton!
    @IBOutlet weak var licencesButton: UIButton!
    @IBOutlet weak var sourceCodeButton: UIButton!
    
    @IBAction func didTapPrivacyButton(sender: AnyObject) {
        UIApplication.shared.open(URL(string:"https://ag-kurzfilm.de/de/impressum/2222.html")!, options: [:], completionHandler: nil)
    }
    
    @IBAction func didTapSourceCodeButton(sender: AnyObject) {
        UIApplication.shared.open(URL(string:"https://github.com/jilipop/adOHRi-iOS")!, options: [:], completionHandler: nil)
    }
    
    @IBAction func didTapLicensesButton(sender: AnyObject) {
        licensesVC.setNoticesFromJSONFile(filepath: Bundle.main.path(forResource: "licenses.json", ofType: nil)!)
        licensesVC.pageHeader = NSLocalizedString("LicensesViewController.HeaderText", comment: "HTML-formatierte Überschrift der Lizenzliste")
        licensesVC.navigationTitle = NSLocalizedString("LicensesViewController.Title", comment: "Titel der Lizenzliste – ganz oben in der Navigationsleiste")
        self.navigationController!.pushViewController(licensesVC, animated: true)
        licensesVC.cssStyle = licensesCss
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
        infoLabel.text = infoText
        licencesButton.setTitle(licencesButtonText, for: .normal)
        sourceCodeButton.setTitle(sourceCodeButtonText, for: .normal)
    }
}

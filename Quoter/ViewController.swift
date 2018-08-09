import UIKit

class ViewController: UIViewController {
    
    var api: QuoterAPI = QuoterAPI()
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var quoteView: UITextView!
    @IBOutlet weak var authorView: UILabel!
    @IBOutlet weak var adderView: UILabel!
    
    @IBAction func btnPrev(_ sender: UIButton) {
        if api.isReady() && api.canPrevious() {
            api.loadQuoteByID(api.currentQuote.id - 1, onLoad: { quote in
                self.api.currentQuote = quote
                self.displayQuote(quote)
            }, onError: { json, alternateMessage in
                DispatchQueue.main.async {
                    if json != nil {
                        self.displayErrorByResponse(json!)
                    } else {
                        self.displayAlert(title: "Ошибка", message: alternateMessage!, actionText: "Ок")
                    }
                }
            })
        }
    }
    @IBAction func btnRandom(_ sender: UIButton) {
        if api.isReady() {
            api.loadRandomQuote(onLoad: { quote in
                self.api.currentQuote = quote
                self.displayQuote(quote)
            }, onError: { json, alternateMessage in
                DispatchQueue.main.async {
                    if json != nil {
                        self.displayErrorByResponse(json!)
                    } else {
                        self.displayAlert(title: "Ошибка", message: alternateMessage!, actionText: "Ок")
                    }
                }
            })
        }
    }
    @IBAction func btnNext(_ sender: UIButton) {
        if api.isReady() && api.canNext() {
            api.loadQuoteByID(api.currentQuote.id + 1, onLoad: { quote in
                self.api.currentQuote = quote
                self.displayQuote(quote)
            }, onError: { json, alternateMessage in
                DispatchQueue.main.async {
                    if json != nil {
                        self.displayErrorByResponse(json!)
                    } else {
                        self.displayAlert(title: "Ошибка", message: alternateMessage!, actionText: "Ок")
                    }
                }
            })
        }
    }
    
    @IBAction func btnGoto(_ sender: UIButton) {
        if api.isReady() {
            let alertController = UIAlertController(title: "Номер цитаты", message: "Введите число - ID цитаты", preferredStyle: .alert)
            alertController.addTextField { (textField) in
                textField.placeholder = "1 .. \(self.api.totalCount)"
            }
            alertController.addAction(UIAlertAction(title: "Перейти", style: .default) { (_) in
                if let id: Int = Int((alertController.textFields?[0].text)!) {
                    if id < 1 || id > self.api.totalCount {
                        return self.displayAlert(title: "Ошибка", message: "Неверное число", actionText: "Окей")
                    }
                    self.api.loadQuoteByID(id, onLoad: { quote in
                        self.api.currentQuote = quote
                        self.displayQuote(quote)
                    }, onError: { json, alternateMessage in
                        DispatchQueue.main.async {
                            if json != nil {
                                self.displayErrorByResponse(json!)
                            } else {
                                self.displayAlert(title: "Ошибка", message: alternateMessage!, actionText: "Ок")
                            }
                        }
                    })
                }else{
                    self.displayAlert(title: "Ошибка", message: "Неверное число", actionText: "Окей")
                }
            })
            alertController.addAction(UIAlertAction(title: "Отмена", style: .cancel))
            self.present(alertController, animated: true, completion: nil)
        }
    }
    @IBAction func nbShare(_ sender: UIBarButtonItem) {
        if api.isReady() && api.hasQuote() {
            shareQuote(api.currentQuote)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadingIndicator.startAnimating()
        loadingIndicator.hidesWhenStopped = true
        initAPI()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func onAPIReady() {
        self.loadingIndicator.stopAnimating()
        self.api.loadRandomQuote(onLoad: { quote in
            self.api.currentQuote = quote
            self.displayQuote(quote)
        }, onError: { json, alternateMessage in
            DispatchQueue.main.async {
                if json != nil {
                    self.displayErrorByResponse(json!)
                } else {
                    self.displayAlert(title: "Ошибка", message: alternateMessage!, actionText: "Ок")
                }
            }
        })
    }
    
    func initAPI() {
        api.initializeContext({
            DispatchQueue.main.async { self.onAPIReady() }
        }, {
            DispatchQueue.main.async { self.displayRetry() }
        })
    }

    func displayQuote(_ quote: Quote) {
        DispatchQueue.main.async {
            self.quoteView.text = quote.text
            self.authorView.text = "Автор: \(quote.author)"
            self.adderView.text = "Добавил \(quote.adder)"
        }
    }
    
    func displayRetry() {
        displayAlert(title: "Ошибка", message: "Во время загрузки необходимых для работы приложения данных произошла ошибка", actionText: "Повторить", action: { _ in
            self.initAPI()
        })
    }
    
    func displayErrorByResponse(_ json: [String: Any]) {
        DispatchQueue.main.async {
            self.authorView.text = ""
            self.adderView.text = ""
            if let rError = json["error"] as? Bool {
                if rError {
                    self.quoteView.text = "Произошла ошибка при получении данных с сервера. Если это что-то вам скажет, вот: \(json["message"] as? String ?? "''")"
                }else {
                    self.quoteView.text = "Request error, but server don't know about it"
                }
            } else {
                self.quoteView.text = "Error"
            }
        }
    }
    
    func displayAlert(title: String, message: String, actionText: String, action: ((UIAlertController) -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: actionText, style: .default, handler: { _ in
            if action != nil {
                action!(alert)
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func shareQuote(_ quote: Quote, copyright: Bool = true) {
        let text = "\(quote.text)\n(c)\(quote.author)\(copyright ? "\n\nQuoter for iOS" : "")"
        let textToShare = [ text ]
        let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        activityViewController.excludedActivityTypes = [ UIActivityType.airDrop, UIActivityType.postToFacebook ]
        self.present(activityViewController, animated: true, completion: nil)
    }
    
}


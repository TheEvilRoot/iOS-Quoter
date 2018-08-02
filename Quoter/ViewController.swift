import UIKit

class ViewController: UIViewController {

    var total: Int = -1
    var currentID: Int = 0
    var currentQuote: Quote? = nil
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var quoteView: UITextView!
    @IBOutlet weak var authorView: UILabel!
    @IBOutlet weak var adderView: UILabel!
    
    @IBAction func btnPrev(_ sender: UIButton) {
        if currentID - 1 > 0 {
            loadQuoteByID(currentID - 1)
        }
    }
    @IBAction func btnRandom(_ sender: UIButton) {
        if currentID != -1 {
            loadRandomQuote()
        }
    }
    @IBAction func btnNext(_ sender: UIButton) {
        if currentID + 1 <= total && currentID != -1 {
            loadQuoteByID(currentID + 1)
        }
    }
    
    @IBAction func btnGoto(_ sender: UIButton) {
        if currentID != -1 {
            let alertController = UIAlertController(title: "Номер цитаты", message: "Введите число - ID цитаты", preferredStyle: .alert)
            alertController.addTextField { (textField) in
                textField.placeholder = "123"
            }
            alertController.addAction(UIAlertAction(title: "Перейти", style: .default) { (_) in
                if let id: Int = Int((alertController.textFields?[0].text)!) {
                    self.loadQuoteByID(id)
                }else{
                    self.displayAlert(title: "Ошибка", message: "Неверное число", actionText: "Окей")
                }
            })
            alertController.addAction(UIAlertAction(title: "Отмена", style: .cancel))
            self.present(alertController, animated: true, completion: nil)
        }
    }
    @IBAction func nbShare(_ sender: UIBarButtonItem) {
        if currentQuote != nil {
            shareQuote(author: currentQuote!.author,quoteText: currentQuote!.text,copyright: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadingIndicator.startAnimating()
        loadingIndicator.hidesWhenStopped = true
        loadData {
            DispatchQueue.main.async {
                self.loadingIndicator.stopAnimating()
            }
            print(self.total)
            self.loadRandomQuote()
        }
    }

    func loadData(_ onLoad: @escaping () -> Void) {
        req(params: ["task":"GET", "mode": "total"], onLoad: { json in
            print(json)
            if let rError = json["error"] as? Bool {
                if !rError {
                    if let data = json["data"] as? [String: Int] {
                        self.total = data["count"]!
                        return onLoad()
                    }
                }
            }
            self.displayRetry(onLoad)
        }) { _ in
            self.displayRetry(onLoad)
        }
    }

    func displayRetry(_ onRetry: @escaping () -> Void) {
        let alert = UIAlertController(title: "Ошибка", message: "Во время загрузки необходимых для работы приложения данных произошла ошибка", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Повторить", style: .default, handler: { _ in
            self.loadData(onRetry)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

    func req(params parameters: [String: String], onLoad: @escaping ([String: Any]) -> Void, onError: @escaping (Optional<Error>) -> Void) {
        let url = URL(string: "http://52.48.142.75:8888/backend/quoter")!
        let session = URLSession.shared
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = formatParams(parameters).data(using: .utf8)
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            guard error == nil else {
                return
            }
            guard let data = data else {
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                    onLoad(json)
                }else{
                    onError(Optional<Error>.none)
                }
            } catch let error {
                onError(error)
            }
        })
        task.resume()
    }
    
    func loadRandomQuote() {
        req(params: ["task": "GET", "mode": "rand"], onLoad: { json in
            print(json)
            if let data: [String: Any] = json["data"] as? [String: Any] {
                self.displayQuoteFromData(data)
            }else {
                self.displayErrorByResponse(json)
            }
        }, onError: {error in
            if let exception = error {
                self.displayAlert(title: "Ошибка", message: exception.localizedDescription, actionText: "Ок")
            }else {
                self.displayAlert(title: "Ошибка", message: "Непредвиденная ошибка", actionText: "Ок")
            }
        })
    }
    
    func loadQuoteByID(_ id: Int) {
        req(params: ["task": "GET", "mode": "pos", "pos": String(id)], onLoad: { json in
            print(json)
            if let data: [String: Any] = json["data"] as? [String: Any] {
                self.displayQuoteFromData(data)
            }else {
                self.displayErrorByResponse(json)
            }
        }, onError: { error in
            if let exception = error {
                print(exception.localizedDescription)
            }else {
                print("Error!")
            }
        })
    }
    
    func displayQuoteFromData(_ data: [String: Any]) {
        self.currentID = data["id"] as! Int
        DispatchQueue.main.async {
            self.currentQuote = Quote()
            if let quote = data["quote"] as? String {
                self.quoteView.text = quote
                self.currentQuote?.text = quote
            }
            if let author = data["author"] as? String {
                self.authorView.text = "Автор: \(author)"
                self.currentQuote?.author = author
            }
            if let adder = data["adder"] as? String {
                self.adderView.text = "Добавил цитату: \(adder)"
                self.currentQuote?.adder = adder
            }
            if let id = data["id"] as? Int {
                self.currentQuote?.id = id
            }
        }
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
    
    func formatParams(_ params: [String: String]) -> String{
        var args: [String] = []
        for (key, value) in params {
            args.append("\(key)=\(value)")
        }
        return args.joined(separator: "&")
    }
    
    func shareQuote(author: String, quoteText: String, copyright: Bool) {
        let text = "\(quoteText)\n(c)\(author)\(copyright ? "\n\nQuoter for iOS" : "")"
        let textToShare = [ text ]
        let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        activityViewController.excludedActivityTypes = [ UIActivityType.airDrop, UIActivityType.postToFacebook ]
        self.present(activityViewController, animated: true, completion: nil)
    }
    
}

class Quote {
    var id: Int = 0
    var author: String = ""
    var adder: String = ""
    var text: String = ""
}


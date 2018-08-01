import UIKit

class ViewController: UIViewController {

    var currentID: Int = 0
    
    @IBOutlet weak var quoteView: UITextView!
    @IBOutlet weak var authorView: UILabel!
    @IBOutlet weak var adderView: UILabel!
    @IBAction func btnPrev(_ sender: UIButton) {
        if currentID - 1 > 0 {
            loadQuoteByID(currentID - 1)
        }
    }
    @IBAction func btnRandom(_ sender: UIButton) {
        loadRandomQuote()
    }
    @IBAction func btnNext(_ sender: UIButton) {
       loadQuoteByID(currentID + 1)
    }
    
    @IBAction func btnGoto(_ sender: UIButton) {
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadRandomQuote()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func getQuote(params parameters: [String: String], onLoad: @escaping ([String: Any]) -> Void, onError: @escaping (Optional<Error>) -> Void) {
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
        getQuote(params: ["task": "GET", "mode": "rand"], onLoad: { json in
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
        getQuote(params: ["task": "GET", "mode": "pos", "pos": String(id)], onLoad: { json in
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
            if let quote = data["quote"] as? String {
                self.quoteView.text = quote
            }
            if let author = data["author"] as? String {
                self.authorView.text = "Автор: \(author)"
            }
            if let adder = data["adder"] as? String {
                self.adderView.text = "Добавил цитату: \(adder)"
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
    
    func displayAlert(title: String, message: String, actionText: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: actionText, style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func formatParams(_ params: [String: String]) -> String{
        var args: [String] = []
        for (key, value) in params {
            args.append("\(key)=\(value)")
        }
        return args.joined(separator: "&")
    }
    
}


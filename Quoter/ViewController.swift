import UIKit

class ViewController: UIViewController {

    var currentID: Int = 0
    
    @IBOutlet weak var quoteView: UILabel!
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
        
        let confirmAction = UIAlertAction(title: "Перейти", style: .default) { (_) in
            if let id: Int = Int((alertController.textFields?[0].text)!) {
                self.loadQuoteByID(id)
            }else{
                let alert = UIAlertController(title: "Ошибка", message: "Неверное число", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                    switch action.style{
                    case .default:
                        print("default")
                    case .cancel:
                        print("cancel")
                    case .destructive:
                        print("destructive")
                    }}))
                self.present(alert, animated: true, completion: nil)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Отмена", style: .cancel) { (_) in }
        
        alertController.addTextField { (textField) in
            textField.placeholder = "123"
        }
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadRandomQuote()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func getQuote(params parameters: String, onLoad: @escaping ([String: Any]) -> Void, onError: @escaping (Optional<Error>) -> Void) {
        let url = URL(string: "http://52.48.142.75:8888/backend/quoter")!
        let session = URLSession.shared
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = parameters.data(using: .utf8)
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
        getQuote(params: "task=GET&mode=rand", onLoad: { json in
            print(json)
            if let data: [String: Any] = json["data"] as? [String: Any] {
                self.displayQuoteFromData(data)
            }else {
                DispatchQueue.main.async {
                    self.quoteView.text = "Error"
                }
            }
        }, onError: {error in
            if let exception = error {
                print(exception.localizedDescription)
            }else {
                print("Error!")
            }
        })
    }
    
    func loadQuoteByID(_ id: Int) {
        getQuote(params: "task=GET&mode=pos&pos=\(id)", onLoad: { json in
            print(json)
            if let data: [String: Any] = json["data"] as? [String: Any] {
                self.displayQuoteFromData(data)
            }else {
                DispatchQueue.main.async {
                    self.quoteView.text = "Error"
                }
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
                let lines = quote.split(separator: "\n").count
                self.quoteView.numberOfLines = lines == 1 ? 0 : lines
            }
            if let author = data["author"] as? String {
                self.authorView.text = "Автор: \(author)"
            }
            if let adder = data["adder"] as? String {
                self.adderView.text = "Добавил цитату: \(adder)"
            }
        }
    }
    
}


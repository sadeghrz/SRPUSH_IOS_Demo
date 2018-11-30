import UIKit
import SwiftyJSON

class PageTwoViewController: UIViewController {

    var onTextIndex = -1;
    @IBOutlet weak var txt_newMsg: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        onTextIndex = wsConnectionHandler.registerForOnText(cb: { (json: JSON?) in
            print("recieve text");
            self.txt_newMsg.text = json!["_id"].stringValue;
        });
    }
    
    deinit {
        if (onTextIndex > -1) {
            wsConnectionHandler.unRegisterForOnText(index: onTextIndex);
        }
    }
}

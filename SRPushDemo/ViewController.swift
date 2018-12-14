import UIKit
import SwiftyJSON
import Alamofire

class ViewController: UIViewController {
    
    var Username: String = "testcom1";
    var SoPass: String = "641b788bcd0fd46eed0f41870a5fc804560f7fba";
    var apiHost: String = "http://192.168.1.100:9779/api/createSession";
    //var apiHost = "https://testcom1.srpush.ir:2021/api/createSession";
    //var wsHost = "ss://testcom1.srpush.ir:2020";
    var wsHost: String = "ws://192.168.1.100:9780";
    var clientUserID = "DRIVER_146";
    var sessionExpireTime = 0; // session expire after this time (as seconds)
    var session: String = "";
    
    @IBOutlet weak var lbl_status: UILabel!
    @IBOutlet weak var lbl_msg: UILabel!
    @IBOutlet weak var btn_connect: UIButton!
    @IBOutlet weak var lbl_session: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func connectWS() {
        if (self.session.count <= 0) {
            print("session not set");
            return;
        }
        
        lbl_status.text = "Connecting...";
        btn_connect.isEnabled = false;
        
        _ = wsConnectionHandler.registerForOnConnect(cb: { () in
            print("connect");
            self.lbl_status.text = "Connected";
            self.btn_connect.setTitle("Disconnect", for: .normal)
            self.btn_connect.isEnabled = true;
        });
        
        _ = wsConnectionHandler.registerForOnDisConnect(cb: { (error: Error?) in
            print("disconnect");
            self.lbl_status.text = "Disconnected";
            self.btn_connect.setTitle("Connect", for: .normal)
            self.btn_connect.isEnabled = true;
            //self.connectWS();
        });
        
        _ = wsConnectionHandler.registerForOnText(cb: { (json: JSON?) in
            print("recieve text");
            self.lbl_msg.text = json!["_id"].stringValue;
        });
        
        wsConnectionHandler.connect(host: self.wsHost, sess: self.session);
    }
    
    @IBAction func ConnectClick(_ sender: Any) {
        if (wsConnectionHandler.isConnected()) {
            wsConnectionHandler.disconnect();
            lbl_status.text = "disconnected";
            btn_connect.setTitle("Connect", for: .normal)
            return;
        }
        connectWS();
    }
    
    @IBAction func GeSessionClick(_ sender: Any) {
        let parameters: Parameters = [
            "uid": self.clientUserID,
            "ExTime": self.sessionExpireTime
        ]
        
        var headers: HTTPHeaders = [
            "Authorization": "Basic",
            "Content-Type": "application/json; charset=utf-8"
        ]
        
        if let authorizationHeader = Request.authorizationHeader(user: self.Username, password: self.SoPass) {
            headers[authorizationHeader.key] = authorizationHeader.value
        }
        
        Alamofire.request(self.apiHost, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
        .response { response in
            if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                if (utf8Text.contains("wss-")) {
                    self.session = utf8Text;
                    self.lbl_session.text = utf8Text;
                } else {
                    print("response: \(utf8Text)")
                }
                
            }
        }
    }
}

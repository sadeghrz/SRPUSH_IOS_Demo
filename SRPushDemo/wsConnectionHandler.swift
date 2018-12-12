import Starscream
import SwiftyJSON

class wsConnectionHandler: NSObject {
    
    typealias onConnectCB = ()  -> Void
    typealias onDisConnectCB = (_ error: Error?)  -> Void
    typealias onTextCB = (_ error: JSON?)  -> Void
    
    static var onConnects = [onConnectCB]();
    static var onDisconnects = [onDisConnectCB]();
    static var onTexts = [onTextCB]();
    
    static var socket : WebSocket!
    static var onlineCheckerTimer: Timer? = nil;
    static var lastPingDate: Date = Date();
    static var hostname: String = "";
    static var session: String = "";
    
    static func onlineChecker() {
        onlineCheckerTimer?.invalidate();
        onlineCheckerTimer = nil;
        
        onlineCheckerTimer = Timer.scheduledTimer(withTimeInterval: 8, repeats: true) { _ in
            print(lastPingDate.timeIntervalSinceNow);
            if (lastPingDate.timeIntervalSinceNow < -8) {
                print("reconnecting...")
                connect();
            }
        }
    }
    
    static func connect(host: String!, sess: String!) {
        if (onlineCheckerTimer == nil) {
            onlineChecker();
        }
        
        hostname = host;
        session = sess;
        
        if (hostname.count <= 0 || session.count <= 0) {
            print("session or hostname not set");
            return;
        }
        
        var request = URLRequest(url: URL(string: hostname)!);
        request.setValue(session, forHTTPHeaderField: "session");
        request.setValue("IOS", forHTTPHeaderField: "platform");
        socket = WebSocket(request: request);
        
        socket.onConnect = {
            for cb in onConnects {
                cb();
            }
        }
        
        socket.onDisconnect = { (error: Error?) in
            for cb in onDisconnects {
                cb(error);
            }
        }
        
        socket.onText = { (text: String) in
            if (text == "pi") {
                socket.write(string: "po");
                lastPingDate = Date();
                return;
            }
            let jsonMessage = JSON.init(parseJSON: text);
            let _id = jsonMessage["_id"].stringValue;
            if (_id.count > 0) {
                socket.write(string: """
                    {
                    "SeId": "\(session)",
                    "ReId": "0",
                    "MsgDT": { "MsgType": 1, "Data": { "_id": "\(_id)"} }
                    }
                    """);
                
            }
            
            for cb in onTexts {
                cb(jsonMessage);
            }
        }
        
        socket.respondToPingWithPong = false
        socket.connect();
    }
    
    static func connect() {
        self.connect(host: hostname, sess: session)
    }
    
    static func disconnect() {
        onlineCheckerTimer?.invalidate();
        onlineCheckerTimer = nil;
        socket.disconnect();
    }
    
    static func isConnected() -> Bool {
        if (socket == nil) {
            return false;
        }
        return socket!.isConnected;
    }
    
    // -------- Registers ----------- //
    
    static func registerForOnConnect(cb: onConnectCB!) -> Int {
        onConnects.append(cb);
        return onConnects.count-1;
    }
    
    static func registerForOnDisConnect(cb: onDisConnectCB!) -> Int {
        onDisconnects.append(cb);
        return onDisconnects.count-1;
    }
    
    static func registerForOnText(cb: onTextCB!) -> Int {
        onTexts.append(cb);
        return onTexts.count-1;
    }
    
    // -------- unRegisters ----------- //
    
    static func unRegisterForOnConnect(index: Int) {
        _ = onConnects.remove(at: index);
    }
    
    static func unRegisterForOnDisConnect(index: Int) {
        _ = onDisconnects.remove(at: index);
    }
    
    static func unRegisterForOnText(index: Int) {
        _ = onTexts.remove(at: index);
    }
}

import Flutter
import UIKit
import ChatProvidersSDK

public class SwiftZendesk2Plugin: NSObject, FlutterPlugin {
    
    private var zendesk2Chat: SwiftZendesk2Chat? = nil
    private var zendesk2Answer: SwiftZendesk2Answer? = nil
    
    private var channel: FlutterMethodChannel
    
    private var accountKey: String? = nil
    private var appId: String? = nil
    
    public static func register(with registrar: FlutterPluginRegistrar) -> Void {
        let channel = FlutterMethodChannel(name: "zendesk2", binaryMessenger: registrar.messenger())
    
        let instance = SwiftZendesk2Plugin(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)
    }
        
     init(channel: FlutterMethodChannel) {
        self.channel = channel
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) -> Void {
        
        if zendesk2Chat == nil {
            zendesk2Chat = SwiftZendesk2Chat(channel: channel)
        }
        if zendesk2Answer == nil {
            zendesk2Answer = SwiftZendesk2Answer(channel: channel)
        }
        
        let method = call.method
        let arguments = call.arguments as? Dictionary<String, Any>
        var mResult: Any? = nil
        
        
        switch(method){
        case "init":
            self.accountKey = (arguments?["accountKey"] ?? "") as? String
            self.appId = (arguments?["appId"] ?? "") as? String
            break
        case "init_chat":
            if self.accountKey != nil && self.appId != nil {
                Chat.initialize(accountKey: self.accountKey!, appId: self.appId!)
            }
            break;
        case "init_answer":
            if self.accountKey != nil && self.appId != nil {
                
            }
            break;
        // chat sdk method channels
        case "logger":
            mResult = zendesk2Chat?.logger(arguments)
            break
        case "setVisitorInfo":
            mResult = zendesk2Chat?.setVisitorInfo(arguments)
            break
        case "startChatProviders":
            mResult = zendesk2Chat?.startChatProviders()
            break
        case "dispose":
            mResult = zendesk2Chat?.dispose()
            break
        case "getChatProviders":
            mResult = zendesk2Chat?.getChatProviders()
            break
        case "sendMessage":
            mResult = zendesk2Chat?.sendMessage(arguments)
            break
        case "sendFile":
            mResult = zendesk2Chat?.sendFile(arguments)
            break
        case "compatibleAttachmentsExtensions":
            mResult = zendesk2Chat?.getAttachmentsExtension()
            break
        case "endChat":
            mResult = zendesk2Chat?.endChat()
            break
        case "sendIsTyping":
            mResult = zendesk2Chat?.sendTyping(arguments)
        case "connect":
            mResult = zendesk2Chat?.connect()
        case "disconnect":
            mResult = zendesk2Chat?.disconnect()
        // answer sdk method channels
        
        
        
        default:
            break
        }
        
        if mResult is Array<Any?> || mResult is Dictionary<String, Any?> {
            result(mResult)
        }
        
        result(0)
    }
    
    
    public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) -> Bool {
        
        if Chat.pushNotificationsProvider?.isChatPushNotification(userInfo) ?? false {
            let application = UIApplication.shared
            Chat.didReceiveRemoteNotification(userInfo, in: application)
            completionHandler(.noData)
            return true
        }
        return false
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       willPresent notification: UNNotification,
                                       withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if Chat.pushNotificationsProvider?.isChatPushNotification(notification.request.content.userInfo) ?? false {
            completionHandler([.alert, .sound, .badge])
        }
    }
}

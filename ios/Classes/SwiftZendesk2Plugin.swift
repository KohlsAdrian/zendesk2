import Flutter
import UIKit
import ChatProvidersSDK
import ZendeskCoreSDK
import SupportProvidersSDK
import AnswerBotProvidersSDK

public class SwiftZendesk2Plugin: NSObject, FlutterPlugin {
    
    private var navigationController: UINavigationController? = nil
    private var zendesk2Chat: SwiftZendesk2Chat? = nil
    private var channel: FlutterMethodChannel
    
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
        
        let arguments = call.arguments as? Dictionary<String, Any>
        var mResult: Any? = nil
        switch(call.method){
        case "init":
            let accountKey: String = (arguments?["accountKey"] ?? "") as! String
            let appId: String = (arguments?["appId"] ?? "") as! String
            
            chatConfiguration = ChatConfiguration()
            
            Chat.initialize(accountKey: accountKey, appId: appId)
            
            var result = Dictionary<String, Any>()
            result["zendesk_account_key"] = Chat.instance?.accountKey
            result["zendesk_app_id"] = Chat.instance?.appId
            mResult = result
            break
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
        case "customize":
            mResult = zendesk2Chat?.customize(arguments)
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

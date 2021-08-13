import Flutter
import UIKit
import ChatProvidersSDK
import AnswerBotProvidersSDK
import ZendeskCoreSDK
import SupportProvidersSDK

public class SwiftZendesk2Plugin: NSObject, FlutterPlugin {
    
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
        let method = call.method
        let arguments = call.arguments as? Dictionary<String, Any>
        
        var mResult: Any? = nil
        
        let zendesk2Chat = SwiftZendesk2Chat(channel: channel)
        let zendesk2Answer = SwiftZendesk2Answer(channel: channel)
        
        switch(method){
        case "init":
            let accountKey = (arguments?["accountKey"] ?? "") as? String
            let appId = (arguments?["appId"] ?? "") as? String
            let clientId = (arguments?["clientId"] ?? "") as? String
            let zendeskUrl = (arguments?["zendeskUrl"] ?? "") as? String
            
            let standard = UserDefaults.standard
            
            standard.setValue(accountKey, forKey: "accountKey")
            standard.setValue(appId, forKey: "appId")
            
            if clientId != nil && zendeskUrl != nil {
                Zendesk.initialize(appId: appId!, clientId: accountKey!, zendeskUrl: zendeskUrl!)
                Support.initialize(withZendesk: Zendesk.instance!)
                AnswerBot.initialize(withZendesk: Zendesk.instance, support: Support.instance!)
            }
            break
        case "init_chat":
            let standard = UserDefaults.standard
            
            let accountKey = standard.string(forKey: "accountKey")
            let appId = standard.string(forKey: "appId")
        
            Chat.initialize(accountKey: accountKey!, appId: appId!)
            break;
        // chat sdk method channels
        case "logger":
            zendesk2Chat.logger(arguments)
            break
        case "setVisitorInfo":
            zendesk2Chat.setVisitorInfo(arguments)
            break
        case "startChatProviders":
            zendesk2Chat.startChatProviders()
            break
        case "chat_dispose":
            zendesk2Chat.dispose()
            break
        case "getChatProviders":
            mResult = zendesk2Chat.getChatProviders()
            break
        case "sendMessage":
            zendesk2Chat.sendMessage(arguments)
            break
        case "sendFile":
            zendesk2Chat.sendFile(arguments)
            break
        case "compatibleAttachmentsExtensions":
            mResult = zendesk2Chat.getAttachmentsExtension()
            break
        case "endChat":
            zendesk2Chat.endChat()
            break
        case "sendIsTyping":
            zendesk2Chat.sendTyping(arguments)
            break
        case "connect":
            zendesk2Chat.connect()
            break
        case "disconnect":
            zendesk2Chat.disconnect()
            break
        case "dispose_chat":
            zendesk2Chat.dispose()
            break
        // answer sdk method channels
        case "query":
            zendesk2Answer.deflectionQuery(arguments)
            break
        case "dispose_answer":
            zendesk2Answer.dispose()
            break
        case "sendAnswerProviderModel":
            mResult = zendesk2Answer.getAnswerProviders()
            break
        case "sendResolveArticleDeflection":
            mResult = zendesk2Answer.getResolveArticleDeflection()
            break
        case "sendRejectArticleDeflection":
            mResult = zendesk2Answer.getResolveArticleDeflection()
            break
        default:
            break
        }
        if mResult != nil {
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

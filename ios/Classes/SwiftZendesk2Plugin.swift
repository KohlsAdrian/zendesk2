import Flutter
import UIKit
import ChatProvidersSDK
import TalkSDK

public class SwiftZendesk2Plugin: NSObject, FlutterPlugin {
    
    var chatStateObservationToken: ObservationToken? = nil
    var accountObservationToken: ObservationToken? = nil
    var settingsObservationToken: ObservationToken? = nil
    var statusObservationToken: ObservationToken? = nil
    var talk: Talk? = nil
    var talkCall: TalkCall? = nil
    
    private var streamingChatSDK: Bool = false
    private var streamingAnswerSDK: Bool = false
    
    
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
        
        let zendesk2Chat = SwiftZendesk2Chat(channel: channel, flutterPlugin: self)
        let zendesk2Answer = SwiftZendesk2Answer(channel: channel, flutterPlugin: self)
        let zendesk2Talk = SwiftZendesk2Talk(channel: channel, flutterPlugin: self)
        
        switch(method){
        // chat sdk method channels
        case "init_chat":
            zendesk2Chat.initialize(arguments)
            break;
        case "setVisitorInfo":
            zendesk2Chat.setVisitorInfo(arguments)
            break
        case "startChatProviders":
            if streamingChatSDK {
                NSLog("Chat Providers already started!")
            } else {
                zendesk2Chat.startChatProviders()
                streamingChatSDK = true
            }
            break
        case "sendChatProvidersResult":
            mResult = arguments
            break
        case "sendChatConnectionStatusResult":
            mResult = arguments
            break
        case "sendChatSettingsResult":
            mResult = arguments
            break
        case "sendChatIsOnlineResult":
            mResult = arguments
            break
        case "sendMessage":
            zendesk2Chat.sendMessage(arguments)
            break
        case "sendFile":
            zendesk2Chat.sendFile(arguments)
            break
        case "endChat":
            zendesk2Chat.endChat()
            break
        case "sendIsTyping":
            zendesk2Chat.sendTyping(arguments)
            break
        case "chat_connect":
            zendesk2Chat.connect()
            break
        case "chat_disconnect":
            zendesk2Chat.disconnect()
            break
        case "chat_dispose":
            self.chatStateObservationToken?.cancel()
            self.accountObservationToken?.cancel()
            self.settingsObservationToken?.cancel()
            self.statusObservationToken?.cancel()
            zendesk2Chat.dispose()
            streamingChatSDK = false
            break
        // answer sdk method channels
        case "init_answer":
            if streamingAnswerSDK {
                NSLog("Answer Providers already started!")
            } else {
                zendesk2Answer.initialize(arguments)
            }
            break
        case "query":
            zendesk2Answer.deflectionQuery(arguments)
            break
        case "resolve_article":
            zendesk2Answer.resolveArticleDeflection(arguments)
            break
        case "reject_article":
            zendesk2Answer.rejectArticleDeflection(arguments)
            break
        case "sendAnswerProviderModel":
            mResult = arguments
            break
        case "sendResolveArticleDeflection":
            mResult = arguments
            break
        case "sendRejectArticleDeflection":
            mResult = arguments
            break
        // talk sdk method channels
        case "init_talk":
            zendesk2Talk.initialize(arguments)
            break
        case "talk_recording_permission":
            mResult = zendesk2Talk.recordingPermission()
            break
        case "talk_check_availability":
            zendesk2Talk.checkAvailability(arguments)
            break
        case "talk_call":
            zendesk2Talk.call(arguments)
            break
        case "talk_disconnect":
            zendesk2Talk.disconnect()
            break
        case "talk_toggle_mute":
            mResult = zendesk2Talk.toggleMute()
            break
        case "talk_toggle_output":
            mResult = zendesk2Talk.toggleOutput()
            break
        case "talk_available_audio_routing_options":
            mResult = zendesk2Talk.availableAudioRoutingOptions()
            break
        case "sendTalkAvailability":
            mResult = arguments
            break
        case "sendTalkCall":
            mResult = arguments
            break
        default:
            break
        }
        if mResult != nil {
            result(mResult)
        }
        result(nil)
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

import Flutter
import UIKit

public class SwiftZendesk2Plugin: NSObject, FlutterPlugin {
    
    private var navigationController: UINavigationController? = nil
    private var zendesk2Chat: SwiftZendesk2Chat? = nil
    
    public static func register(with registrar: FlutterPluginRegistrar) -> Void {
        let channel = FlutterMethodChannel(name: "zendesk2", binaryMessenger: registrar.messenger())
        let instance = SwiftZendesk2Plugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) -> Void {
        if zendesk2Chat == nil {
            zendesk2Chat = SwiftZendesk2Chat()
        }
        
        let arguments = call.arguments as? Dictionary<String, Any>
        var mResult: Any? = nil
        switch(call.method){
        case "init":
            mResult = zendesk2Chat?.zendeskInit(arguments)
            break
        case "logger":
            mResult = zendesk2Chat?.logger(arguments)
            break
        case "setVisitorInfo":
            mResult = zendesk2Chat?.setVisitorInfo(arguments)
            break
        case "startChat":
            mResult = zendesk2Chat?.startChat(arguments)
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
        case "sendRatingComment":
            mResult = zendesk2Chat?.sendRatingComment(arguments)
            break
        case "sendRatingReview":
            mResult = zendesk2Chat?.sendRatingReview(arguments)
            break
        case "sendIsTyping":
            mResult = zendesk2Chat?.sendTyping(arguments)
        default:
            break
        }
        
        if mResult is Array<Any?> || mResult is Dictionary<String, Any?> {
            result(mResult)
        }
        
        result(0)
    }
}

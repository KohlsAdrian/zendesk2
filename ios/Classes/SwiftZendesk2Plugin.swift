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
        switch(call.method){
        case "init":
            zendesk2Chat?.zendeskInit(arguments)
            break
        case "logger":
            zendesk2Chat?.logger(arguments)
            break
        case "setVisitorInfo":
            zendesk2Chat?.setVisitorInfo(arguments)
            break
        case "startChat":
            zendesk2Chat?.startChat(arguments)
            break
        case "startChatProviders":
            zendesk2Chat?.startChatProviders()
            break
        case "dispose":
            zendesk2Chat?.dismiss()
            break
        case "customize":
            zendesk2Chat?.customize(arguments)
            break
        case "getChatProviders":
            let providers = zendesk2Chat?.getChatProviders()
            result(providers)
            break;
        case "sendMessage":
            zendesk2Chat?.sendMessage(arguments)
            break;
        case "sendFile":
            zendesk2Chat?.sendFile(arguments)
            break;
        case "compatibleAttachmentsExtensions":
            let value = zendesk2Chat?.getAttachmentsExtension()
            result(value)
            break;
        case "sendIsTyping":
            zendesk2Chat?.sendTyping(arguments)
        default:
            break
        }
        
        result(0)
    }
}

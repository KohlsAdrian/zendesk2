import Flutter
import UIKit
import ChatSDK
import MessagingSDK
import ChatProvidersSDK
import CommonUISDK

public class SwiftZendesk2Plugin: NSObject, FlutterPlugin {
    
    private var chatConfiguration: ChatConfiguration? = nil
    private var navigationController: UINavigationController? = nil
    
    
    ///
    /// FLUTTER PLUGIN SETTINGS
    ///
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "zendesk2", binaryMessenger: registrar.messenger())
        let instance = SwiftZendesk2Plugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if navigationController == nil {
            let rootViewController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController
            self.navigationController = rootViewController
        }
        
        let arguments = call.arguments as? Dictionary<String, Any>
        switch(call.method){
        case "init":
            zendeskInit(arguments)
            break
        case "logger":
            logger(arguments)
            break
        case "setVisitorInfo":
            setVisitorInfo(arguments)
            break
        case "startChat":
            startChat(arguments)
            break
        case "dispose":
            dismiss()
            break
        case "customize":
            customize(arguments)
            break
        default:
            break
        }
        
        result(0)
    }
    
    ///
    /// PLUGIN FEATURES
    ///
    
    /// Initialize Zendesk SDK
    private func zendeskInit(_ arguments: Dictionary<String, Any>?) {
        let accountKey = arguments!["accountKey"] as? String
        let appId = arguments?["appId"] as? String
        //let firebaseToken = call.argument("firebaseToken")
        let rgb = arguments?["iosThemeColor"] as? Int
        
        if rgb != nil {
            let color = uiColorFromHex(rgbValue: rgb!)
            CommonTheme.currentTheme.primaryColor = color
        }
        chatConfiguration = ChatConfiguration()
        
        Chat.initialize(accountKey: accountKey!, appId: appId!)
    }
    
    /// Logging  Zendesk API
    private func logger(_ arguments: Dictionary<String, Any>?) {
        if chatConfiguration == nil {
            NSLog("You must call init first")
        }
        let enabled = arguments?["enabled"] as? Bool
        Logger.isEnabled = enabled ?? false
        Logger.defaultLevel = .verbose
    }
    
    /// setVisitorInfo Zendesk API
    private func setVisitorInfo(_ arguments: Dictionary<String, Any>?) {
        if chatConfiguration == nil {
            NSLog("You must call init first")
        }
        
        let name = arguments?["name"] as? String?
        let email = arguments?["email"] as? String?
        let phoneNumber = arguments?["phoneNumber"] as? String?
        let departmentName = arguments?["departmentName"] as? String?
        
        let tags = (arguments?["tags"] as? Array<String>?) ?? Array<String>()
        
        let visitorInfo = VisitorInfo.init(name: (name ?? "")!, email: (email ?? "")!, phoneNumber: (phoneNumber ?? "")!)
        
        let chatAPIConfiguration = ChatAPIConfiguration()
        chatAPIConfiguration.tags = tags!
        chatAPIConfiguration.visitorInfo = visitorInfo
        chatAPIConfiguration.department = departmentName ?? ""
        
        Chat.instance?.configuration = chatAPIConfiguration
        
    }
    
    /// startChat v2 Zendesk API
    private func startChat(_ arguments: Dictionary<String, Any>?) {
        if chatConfiguration == nil {
            NSLog("You must call init first")
        }
        let botLabel = arguments?["botLabel"] as? String
        let toolbarTitle = arguments?["toolbarTitle"] as? String
        let backButtonLabel = arguments?["backButtonLabel"] as? String
        
        let mChatConfiguration = self.chatConfiguration
        mChatConfiguration?.isPreChatFormEnabled = true
        
        if mChatConfiguration != nil {
            let messagingConfiguration = MessagingConfiguration()
            if botLabel != nil {
                messagingConfiguration.name = botLabel!
            }
            
            do {
                let chatEngine = try ChatEngine.engine()
                let messaging = Messaging.instance
                
                let themeColor = CommonTheme.currentTheme.primaryColor
                let brightnessColor = uiColorByTheme(color: themeColor)
                
                let backButton = UIBarButtonItem.init(title: backButtonLabel ?? "Back", style:.plain, target: self, action: #selector(dismiss))
                backButton.tintColor = brightnessColor
                
                // creates zendesk chat UI
                let viewController = try messaging.buildUI(engines: [chatEngine], configs: [messagingConfiguration, mChatConfiguration!])
                viewController.navigationItem.leftBarButtonItem = backButton //Close/back button
                
                
                // customize navigation controller
                viewController.navigationItem.rightBarButtonItem?.tintColor = brightnessColor
                
                let navigationBar = self.navigationController?.navigationBar
                navigationBar?.barTintColor = themeColor // bar tint color
                navigationBar?.backgroundColor = themeColor //Toolbar background color
                navigationBar?.barTintColor = themeColor //Toolbar background color
                navigationBar?.titleTextAttributes = [NSAttributedString.Key.foregroundColor:brightnessColor] // set title color
                
                let navigationItem = viewController.navigationItem
                navigationItem.title = toolbarTitle
                
                self.navigationController?.isNavigationBarHidden = false
                // present navigation controller
                self.navigationController?.pushViewController(viewController, animated: true)
            } catch {
                print(error)
            }
            
            
        }
    }
    
    /// customize Zendesk API
    private func customize(_ arguments: Dictionary<String, Any>?) {
        if chatConfiguration == nil {
            NSLog("You must call init first")
        }
        let agentAvailability = arguments?["agentAvailability"] as? Bool
        let preChatForm = arguments?["preChatForm"] as? Bool
        let offlineForms = arguments?["offlineForms"] as? Bool
        let endChatEnabled = arguments?["endChatEnabled"] as? Bool
        let transcriptChatEnabled = arguments?["transcriptChatEnabled"] as? Bool
        
        //let transcript = arguments?["transcript"] as? Bool
        let nameFieldStatus = arguments?["nameFieldStatus"] as? String
        let emailFieldStatus = arguments?["emailFieldStatus"] as? String
        let phoneFieldStatus = arguments?["phoneFieldStatus"] as? String
        let departmentFieldStatus = arguments?["departmentFieldStatus"] as? String
        
        let nameFieldEnum = getPreChatEnumByString(preChatName: nameFieldStatus)
        let emailFieldEnum = getPreChatEnumByString(preChatName: emailFieldStatus)
        let phoneFieldEnum = getPreChatEnumByString(preChatName: phoneFieldStatus)
        let departmentFieldEnum = getPreChatEnumByString(preChatName: departmentFieldStatus)
        
        var menuActions = Array<ChatMenuAction>()
        
        if endChatEnabled != nil && endChatEnabled ?? false {
            menuActions.append(ChatMenuAction.endChat)
        }
        if transcriptChatEnabled != nil && transcriptChatEnabled ?? false {
            menuActions.append(ChatMenuAction.emailTranscript)
        }
        
        let chatConfiguration = ChatConfiguration()
        let formConfiguration = ChatFormConfiguration.init(name: nameFieldEnum, email: emailFieldEnum, phoneNumber: phoneFieldEnum, department: departmentFieldEnum)
        
        chatConfiguration.isPreChatFormEnabled = preChatForm ?? false
        chatConfiguration.isAgentAvailabilityEnabled = agentAvailability ?? false
        chatConfiguration.isChatTranscriptPromptEnabled = transcriptChatEnabled ?? false
        chatConfiguration.isOfflineFormEnabled = offlineForms ?? false
        chatConfiguration.chatMenuActions = menuActions
        chatConfiguration.preChatFormConfiguration = formConfiguration
        
        self.chatConfiguration = chatConfiguration
    }
    
    /// get ENUM chat options by Flutter String Zendesk API
    private func getPreChatEnumByString(preChatName: String?) -> FormFieldStatus{
        switch preChatName {
        case "OPTIONAL": return FormFieldStatus.optional
        case "HIDDEN": return FormFieldStatus.hidden
        case "REQUIRED": return FormFieldStatus.required
        default:
            return FormFieldStatus.hidden
        }
    }
    /// get Color Birghtness by Color Theme
    private func uiColorByTheme(color: UIColor) -> UIColor {
        return color.isLight ? UIColor.black : UIColor.white
    }
    
    /// convert color Int32 Hex to UIColor object
    private func uiColorFromHex(rgbValue: Int) -> UIColor {
        let red =   CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue =  CGFloat(rgbValue & 0x0000FF) / 255.0
        let alpha = CGFloat(1.0)
        
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    /// Shows Zendesk Chat actions
    @objc private func actions() {
        let localizedEndChat = NSLocalizedString("ios.conversation.ui.end_chat.button_label", comment: "")
        let localizedTranscriptChat = NSLocalizedString("ios.conversation.ui.chat.transcript.prompt.request_transcript.title", comment: "")
        let localizedCancel = NSLocalizedString("ios.conversation.ui.chat.transcript.prompt.cancel", comment: "")
        let localzedHelp = NSLocalizedString("ios.conversation.ui.chat.welcome_message.conversation_start", comment: "")
        
        let actionsAlertController = UIAlertController(title: localzedHelp, message: "", preferredStyle: .alert)
        
        let actions = chatConfiguration?.chatMenuActions
        
        if actions?.contains(.endChat) ?? false {
            let alertActionEndChat = UIAlertAction.init(title: localizedEndChat, style: .default) { (alertAction) in
                Chat.chatProvider?.endChat() { (result) in
                    switch result {
                    case .success(let success):
                        NSLog(success ? "success" : "not success")
                        self.dismiss()
                    case .failure(let error):
                        NSLog(error.localizedDescription)
                    }
                }
            }
            actionsAlertController.addAction(alertActionEndChat)
        }
        
        if actions?.contains(.emailTranscript) ?? false {
            let alertActionTranscriptChat = UIAlertAction.init(title: localizedTranscriptChat, style: .default) { (alertAction) in
                let email = self.chatConfiguration?.preChatFormConfiguration.email
                if email != nil {
                    let email = Chat.instance?.configuration.visitorInfo?.email
                    Chat.chatProvider?.sendEmailTranscript(email!) { (result) in
                        switch result {
                        case .success(let success):
                            NSLog(success)
                            self.dismiss()
                        case .failure(let error):
                            NSLog(error.localizedDescription)
                        }
                    }
                }
            }
            actionsAlertController.addAction(alertActionTranscriptChat)
        }
        
        let alertActionCancel = UIAlertAction.init(title: localizedCancel, style: .cancel, handler: nil)
        actionsAlertController.addAction(alertActionCancel)
        
        self.navigationController?.present(actionsAlertController, animated: true, completion: nil)
    }
    
    /// Closes Zendesk Chat
    @objc private func dismiss() {
        self.navigationController?.isNavigationBarHidden = true
        self.navigationController?.popViewController(animated: true)
        
        let chat = Chat.instance
        
        chat?.clearCache()
        chat?.resetIdentity({
            print("Identity reseted")
        })
        self.chatConfiguration = nil
        self.navigationController = nil
        
    }
}

/// Extension to check color brightness
extension UIColor {
    var isLight: Bool {
        var white: CGFloat = 0
        getWhite(&white, alpha: nil)
        return white > 0.6
    }
}

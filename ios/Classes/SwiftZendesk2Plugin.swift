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
        //let firebaseToken = call.argument("firebaseToken")
        let accountKey: String = (arguments?["accountKey"] ?? "") as! String
        let appId: String = (arguments?["appId"] ?? "") as! String
        let rgb = arguments?["iosThemeColor"] as? Int
        
        if rgb != nil{
            let color = uiColorFromHex(rgbValue: rgb!)
            CommonTheme.currentTheme.primaryColor = color
        }
        chatConfiguration = ChatConfiguration()
        
        Chat.initialize(accountKey: accountKey, appId: appId)
    }
    
    /// Logging  Zendesk API
    private func logger(_ arguments: Dictionary<String, Any>?) {
        if chatConfiguration == nil {
            NSLog("You must call init first")
        }
        let enabled: Bool = (arguments?["enabled"] ?? false) as! Bool
        Logger.isEnabled = enabled
        Logger.defaultLevel = .verbose
    }
    
    /// setVisitorInfo Zendesk API
    private func setVisitorInfo(_ arguments: Dictionary<String, Any>?) {
        if chatConfiguration == nil {
            NSLog("You must call init first")
        }
        
        let name: String = (arguments?["name"] ?? "") as! String
        let email: String = (arguments?["email"] ?? "") as! String
        let phoneNumber: String = (arguments?["phoneNumber"] ?? "") as! String
        let departmentName = arguments?["departmentName"] as? String
        let tags: Array<String> = (arguments?["tags"] ?? Array<String>()) as! Array<String>
        
        let visitorInfo = VisitorInfo.init(name: name, email: email, phoneNumber: phoneNumber)
        
        let chatAPIConfiguration = ChatAPIConfiguration()
        chatAPIConfiguration.tags = tags
        chatAPIConfiguration.visitorInfo = visitorInfo
        chatAPIConfiguration.department = departmentName
        
        Chat.instance?.configuration = chatAPIConfiguration
    }
    
    /// startChat v2 Zendesk API
    private func startChat(_ arguments: Dictionary<String, Any>?) {
        if chatConfiguration == nil {
            NSLog("You must call init first")
        }
        let botLabel: String = (arguments?["botLabel"] ?? "") as! String
        let toolbarTitle: String = (arguments?["toolbarTitle"] ?? "") as! String
        let backButtonLabel: String = (arguments?["backButtonLabel"] ?? "Back") as! String
        
        let mChatConfiguration = self.chatConfiguration
        mChatConfiguration?.isPreChatFormEnabled = true
        
        
        let themeColor = CommonTheme.currentTheme.primaryColor
        let brightnessColor = uiColorByTheme(color: themeColor)
        
        if mChatConfiguration != nil {
            
            let messagingConfiguration = MessagingConfiguration()
            messagingConfiguration.name = botLabel
            
            do {
                let chatEngine = try ChatEngine.engine()
                let messaging = Messaging.instance
                
                let backButton = UIBarButtonItem.init(title: backButtonLabel, style:.plain, target: self, action: #selector(dismiss))
                backButton.tintColor = brightnessColor
                
                // creates zendesk chat UI
                let viewController = try messaging.buildUI(engines: [chatEngine], configs: [messagingConfiguration, mChatConfiguration!])
                viewController.navigationItem.leftBarButtonItem = backButton //Close/back button
                
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
        let agentAvailability: Bool = arguments?["agentAvailability"] as! Bool
        let preChatForm: Bool = arguments?["preChatForm"] as! Bool
        let offlineForms: Bool = arguments?["offlineForms"] as! Bool
        let endChatEnabled: Bool = arguments?["endChatEnabled"] as! Bool
        let transcriptChatEnabled: Bool = arguments?["transcriptChatEnabled"] as! Bool
        
        //let transcript = (arguments?["transcript"] ?? false) as! Bool
        let nameFieldStatus: String = (arguments?["nameFieldStatus"] ?? false) as! String
        let emailFieldStatus: String = (arguments?["emailFieldStatus"] ?? false) as! String
        let phoneFieldStatus: String = (arguments?["phoneFieldStatus"] ?? "") as! String
        let departmentFieldStatus: String = (arguments?["departmentFieldStatus"] ?? "") as! String
        
        let nameFieldEnum: FormFieldStatus = getPreChatEnumByString(preChatName: nameFieldStatus)
        let emailFieldEnum: FormFieldStatus = getPreChatEnumByString(preChatName: emailFieldStatus)
        let phoneFieldEnum: FormFieldStatus = getPreChatEnumByString(preChatName: phoneFieldStatus)
        let departmentFieldEnum: FormFieldStatus = getPreChatEnumByString(preChatName: departmentFieldStatus)
        
        var menuActions = Array<ChatMenuAction>()
        
        if endChatEnabled {
            menuActions.append(ChatMenuAction.endChat)
        }
        if transcriptChatEnabled {
            menuActions.append(ChatMenuAction.emailTranscript)
        }
        
        let chatConfiguration = ChatConfiguration()
        let formConfiguration = ChatFormConfiguration.init(name: nameFieldEnum, email: emailFieldEnum, phoneNumber: phoneFieldEnum, department: departmentFieldEnum)
        
        chatConfiguration.isPreChatFormEnabled = preChatForm
        chatConfiguration.isAgentAvailabilityEnabled = agentAvailability
        chatConfiguration.isChatTranscriptPromptEnabled = transcriptChatEnabled
        chatConfiguration.isOfflineFormEnabled = offlineForms
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
    
    /// Closes Zendesk Chat
    @objc private func dismiss() {
        
        let chat = Chat.instance
        
        chat?.clearCache()
        chat?.resetIdentity({
            print("Identity reseted")
        })
        
        chat?.chatProvider.endChat()
        
        self.chatConfiguration = nil
        
        self.navigationController?.isNavigationBarHidden = true
        self.navigationController?.popViewController(animated: true)
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

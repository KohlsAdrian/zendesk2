//
//  SwiftZendesk2Chat.swift
//  zendesk2
//
//  Created by Adrian Kohls on 07/01/21.
//

import ChatSDK
import MessagingSDK
import ChatProvidersSDK
import CommonUISDK

public class SwiftZendesk2Chat {
    
    private var chatConfiguration: ChatConfiguration? = nil
    private var navigationController: UINavigationController? = nil
    private var observeAccoutToken: ObservationToken? = nil
    private var observeChatSettingsToken: ObservationToken? = nil
    private var observeConnectionStatusToken: ObservationToken? = nil
    private var observeChatStateToken: ObservationToken? = nil
    private var isOnline: Bool = false
    private var isChatting: Bool = false
    private var hasAgents: Bool = false
    private var isFileSendingEnabled: Bool = false
    private var connectionStatus: String = "UNKNOWN"
    private var chatSessionStatus: String = "UNKNOWN"
    private var chatId: String? = nil
    private var agents: Array<Agent> = Array<Agent>()
    private var logs: Array<ChatLog> = Array<ChatLog>()
    private var queuePosition: QueuePosition? = nil
    private var rating: Rating? = nil
    private var comment: String? = nil
    
    private var messageId: String? = nil
    private var messageIds: Array<String> = []
    
    init() {
        let rootViewController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController
        self.navigationController = rootViewController
    }
    
    /// Initialize Zendesk SDK
    func zendeskInit(_ arguments: Dictionary<String, Any>?)  -> Void{
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
    func logger(_ arguments: Dictionary<String, Any>?)  -> Void{
        if chatConfiguration == nil {
            NSLog("You must call init first")
        }
        let enabled: Bool = (arguments?["enabled"] ?? false) as! Bool
        Logger.isEnabled = enabled
        Logger.defaultLevel = .verbose
    }
    
    /// setVisitorInfo Zendesk API
    func setVisitorInfo(_ arguments: Dictionary<String, Any>?)  -> Void{
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
    func startChat(_ arguments: Dictionary<String, Any>?)  -> Void{
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
                
                let backButton = UIBarButtonItem.init(title: backButtonLabel, style:.plain, target: self, action: #selector(dispose))
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
    
    /// startChat v2 Zendesk API Providers
    func startChatProviders()  -> Void{
        if chatConfiguration == nil {
            NSLog("You must call init first")
        }
        startProviders()
        Chat.connectionProvider?.connect()
    }
    
    /// customize Zendesk API
    func customize(_ arguments: Dictionary<String, Any>?) -> Void {
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
    func getPreChatEnumByString(preChatName: String?) -> FormFieldStatus{
        switch preChatName {
        case "OPTIONAL": return FormFieldStatus.optional
        case "HIDDEN": return FormFieldStatus.hidden
        case "REQUIRED": return FormFieldStatus.required
        default:
            return FormFieldStatus.hidden
        }
    }
    /// get Color Birghtness by Color Theme
    func uiColorByTheme(color: UIColor) -> UIColor {
        return color.isLight ? UIColor.black : UIColor.white
    }
    
    /// convert color Int32 Hex to UIColor object
    func uiColorFromHex(rgbValue: Int) -> UIColor {
        let red =   CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue =  CGFloat(rgbValue & 0x0000FF) / 255.0
        let alpha = CGFloat(1.0)
        
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    /// Closes Zendesk Chat
    @objc func dispose() -> Void {
        
        let chat = Chat.instance
        
        chat?.clearCache()
        chat?.resetIdentity({
            print("Identity reseted")
        })
        
        endChat()
        
        self.chatConfiguration = nil
        
        self.navigationController?.isNavigationBarHidden = true
        self.navigationController?.popViewController(animated: true)
        self.navigationController = nil
        
        releaseProviders()
    }
    
    /// PROVIDERS FOR CUSTOM UI
    
    private func releaseProviders() -> Void {
        self.observeAccoutToken?.cancel()
        self.observeChatSettingsToken?.cancel()
        self.observeConnectionStatusToken?.cancel()
        self.observeChatStateToken?.cancel()
        Chat.connectionProvider?.disconnect()
    }
    
    private func startProviders() -> Void {
        /// Chat providers
        chatProviderStart()
        /// Account providers
        accountProviderStart()
        /// Settings providers
        settingsProviderStart()
        /// Connection providers
        connectionProviderStart()
    }
    
    
    private func chatProviderStart() -> Void {
        Chat.chatProvider?.getChatInfo { (result) in
            switch result {
            case .success(let chatInfo):
                if chatInfo.isChatting {
                    self.isChatting = false
                }
            case .failure(let error):
                print(error)
            }
        }
        
        observeChatStateToken = Chat.chatProvider?.observeChatState { (chatState) in
            let isChatting = chatState.isChatting
            let chatSessionStatus = chatState.chatSessionStatus
            let chatId = chatState.chatId
            let agents = chatState.agents
            let logs = chatState.logs
            let queuePosition = chatState.queuePosition
            let rating = chatState.rating
            let comment = chatState.comment
            
            self.isChatting = isChatting
            self.chatId = chatId
            self.agents = agents
            self.logs = logs
            self.queuePosition = queuePosition
            self.rating = rating
            self.comment = comment
            
            switch chatSessionStatus {
            case .configuring: self.chatSessionStatus = "CONFIGURING"
            case .ended: self.chatSessionStatus = "ENDED"
            case .ending: self.chatSessionStatus = "ENDING"
            case .initializing: self.chatSessionStatus = "INITIALIZING"
            case .started: self.chatSessionStatus = "STARTED"
            default: self.chatSessionStatus = "UNKNOWN"
            }
        }
    }
    
    private func accountProviderStart() -> Void {
        observeAccoutToken = Chat.accountProvider?.observeAccount { (account) in
            let accountStatus = account.accountStatus
            self.isOnline = accountStatus == .online
            self.hasAgents = self.isOnline
        }
        
        Chat.accountProvider?.getAccount { (result) in
            switch result {
            case .success(let account):
                self.hasAgents = true
                self.isOnline = account.accountStatus == .online
            case .failure(let error):
                print(error)
            }
        }
    }
    
    private func settingsProviderStart() -> Void {
        observeChatSettingsToken = Chat.settingsProvider?.observeChatSettings { (settings) in
            self.isFileSendingEnabled = settings.isFileSendingEnabled
        }
    }
    
    private func connectionProviderStart() -> Void {
        observeConnectionStatusToken = Chat.connectionProvider?.observeConnectionStatus { (status) in
            switch status {
            case .connected:
                self.connectionStatus = "CONNECTED"
                break
            case .connecting:
                self.connectionStatus = "CONNECTING"
                break
            case .disconnected:
                self.connectionStatus = "DISCONNECTED"
                break
            case .failed:
                self.connectionStatus = "FAILED"
                break
            case .reconnecting:
                self.connectionStatus = "RECONNECTING"
                break
            case .unreachable:
                self.connectionStatus = "UNREACHABLE"
                break
            default:
                self.connectionStatus = "UNKNOWN"
            }
        }
    }
    
    func sendMessage(_ arguments: Dictionary<String, Any>?) -> Void {
        let message: String = (arguments?["message"] ?? "") as! String
        
        Chat.chatProvider?.sendMessage(message) { (result) in
            switch result {
            case .success(let messageId):
                self.messageId = messageId
                self.messageIds.append(messageId)
            case .failure(let error):
                NSLog("Send failed, resending....")
                let messageId = error.messageId
                if messageId != nil && !(messageId?.isEmpty ?? false) {
                    Chat.chatProvider?.resendFailedFile(withId: messageId!)
                }
            }
        }
    }
    
    func sendFile(_ arguments: Dictionary<String, Any>?) -> Void {
        let file: String = (arguments?["file"] ?? "") as! String
        
        let fileURL = URL(fileURLWithPath: file)
        
        Chat.chatProvider?.sendFile(url: fileURL, onProgress: { (progress) in
            NSLog("%@ % completed", NSNumber.init(value: progress))
        }, completion: { result in
            switch result {
            case .success:
                print("success")
            case .failure(let error):
                NSLog("Send attachment failed, resending...")
                let messageId = error.messageId
                if(messageId != nil && !(messageId?.isEmpty ?? false)){
                    Chat.chatProvider?.resendFailedFile(withId: messageId!, onProgress: { (progress) in
                        print(progress)
                    }, completion: { (result) in
                        print(result)
                    })
                }
            }
        })
    }
    
    func getAttachmentsExtension() -> Array<String> {
        var array = Array<String>()
        let types = Chat.settingsProvider?.settings.supportedFileTypes
        for type in types ?? [] {
            array.append(type)
        }
        return array
    }
    
    func sendTyping(_ arguments: Dictionary<String, Any>?) -> Void {
        let isTyping: Bool = (arguments?["isTyping"] ?? false) as! Bool
        Chat.chatProvider?.sendTyping(isTyping: isTyping)
    }
    
    func getChatProviders() -> Dictionary<String, Any> {
        var dictionary = [String: Any]()
        dictionary["isOnline"] = self.isOnline
        dictionary["isChatting"] = self.isChatting
        dictionary["hasAgents"] = self.hasAgents
        dictionary["isFileSendingEnabled"] = self.isFileSendingEnabled
        dictionary["connectionStatus"] = self.connectionStatus
        dictionary["chatSessionStatus"] = self.chatSessionStatus        
        
        switch self.rating {
        case .bad: dictionary["rating"] = "BAD"
        case .good: dictionary["rating"] = "GOOD"
        default: dictionary["rating"] = "NONE"
        }
        
        let queuePosition = self.queuePosition?.queue
        dictionary["queuePosition"] = queuePosition
        
        var agentsList = Array<Dictionary<String, Any>>()
        for agent in agents {
            var agentDict = [String: Any]()
            
            let avatar = agent.avatar?.absoluteString
            let displayName = agent.displayName
            let isTyping = agent.isTyping
            let nick = agent.nick
            
            agentDict["avatar"] = avatar
            agentDict["displayName"] = displayName
            agentDict["isTyping"] = isTyping
            agentDict["nick"] = nick
            agentsList.append(agentDict)
        }
        
        var logsList = Array<Dictionary<String, Any>>()
        for log in logs {
            var logDict = [String: Any]()
            logDict["id"] = log.id
            logDict["createdByVisitor"] = log.createdByVisitor
            logDict["createdTimestamp"] = log.createdTimestamp
            logDict["displayName"] = log.displayName
            logDict["lastModifiedTimestamp"] = log.lastModifiedTimestamp
            logDict["nick"] = log.nick
            
            var logCP = [String: Any]()
            let chatParticipant = log.participant
            switch chatParticipant {
            case .agent:
                logCP["chatParticipant"] = "AGENT"
            case .system:
                logCP["chatParticipant"] = "SYSTEM"
            case .trigger:
                logCP["chatParticipant"] = "TRIGGER"
            case .visitor:
                logCP["chatParticipant"] = "VISITOR"
            }
            
            
            var logDS = [String: Any]()
            let deliveryStatus = log.status
            let isFailed = deliveryStatus.isFailed
            logDS["isFailed"] = isFailed
            switch deliveryStatus {
            case .delivered:
                logDS["status"] = "DELIVERED"
            case .pending:
                logDS["status"] = "PENDING"
            case .failed(reason: let reason):
                print(reason)
            default:
                logDS["status"] = "UNKNOWN"
            }
            
            var logT = [String: Any]()
            let chatLogType = log.type
            switch chatLogType {
            case .attachmentMessage:
                logT["type"] = "ATTACHMENT_MESSAGE"
            case .chatComment:
                logT["type"] = "CHAT_COMMENT"
            case .chatRating:
                logT["type"] = "CHAT_RATING"
            case .chatRatingRequest:
                logT["type"] = "CHAT_RATING_REQUEST"
            case .memberJoin:
                logT["type"] = "MEMBER_JOIN"
            case .memberLeave:
                logT["type"] = "MEMBER_LEAVE"
            case .message:
                logT["type"] = "MESSAGE"
            case .optionsMessage:
                logT["type"] = "OPTIONS_MESSAGE"
            default:
                logT["type"] = "UNKNOWN"
            }
            
            if log is ChatMessage {
                let chatMessage = log as! ChatMessage
                
                var logChatMessage = [String: Any]()
                
                let id = chatMessage.id
                let message = chatMessage.message
                
                logChatMessage["id"] = id
                logChatMessage["message"] = message
                
                
                logT["chatMessage"] = logChatMessage
            } else if log is ChatAttachmentMessage {
                let chatMessageAttachment = log as! ChatAttachmentMessage
                
                var logChatAttachmentMessage = [String: Any]()
                
                let id = chatMessageAttachment.id
                let url = chatMessageAttachment.url?.absoluteString
                
                logChatAttachmentMessage["id"] = id
                logChatAttachmentMessage["url"] = url
                
                let attachment = chatMessageAttachment.attachment
                var logChatAttachmentAttachmentMessage = [String: Any]()
                
                let attachmentName = attachment.name
                let attachmentError = attachment.attachmentError
                let attachmentLocalUrl = attachment.localURL
                let attachmentMimeType = attachment.mimeType
                let attachmentSize = attachment.size
                let attachmentUrl = attachment.url
                
                switch attachmentError {
                case .none:
                    logChatAttachmentAttachmentMessage["error"] = "NONE"
                case .sizeLimit:
                    logChatAttachmentAttachmentMessage["error"] = "SIZE_LIMIT"
                default:
                    logChatAttachmentAttachmentMessage["error"] = "NONE"
                }
                
                logChatAttachmentAttachmentMessage["name"] = attachmentName
                logChatAttachmentAttachmentMessage["localUrl"] = attachmentLocalUrl?.absoluteString
                logChatAttachmentAttachmentMessage["mimeType"] = attachmentMimeType
                logChatAttachmentAttachmentMessage["size"] = attachmentSize
                logChatAttachmentAttachmentMessage["url"] = attachmentUrl
                
                logChatAttachmentMessage["chatAttachmentAttachment"] = logChatAttachmentAttachmentMessage
                logT["chatAttachment"] = logChatAttachmentMessage
                
            } else if log is ChatRating {
                let chatRating = log as! ChatRating
                
                var logChatRating = [String: Any]()
                
                let rating = chatRating.rating
                switch rating {
                case .good:
                    logChatRating["rating"] = "GOOD"
                case .bad:
                    logChatRating["rating"] = "BAD"
                default:
                    logChatRating["rating"] = "NONE"
                }
                
                logT["chatRating"] = logChatRating
            } else if log is ChatComment {
                let chatComment = log as! ChatComment
                
                var logChatComment = [String: Any]()
                
                let comment = chatComment.comment
                let newComment = chatComment.newComment
                
                logChatComment["comment"] = comment
                logChatComment["newComment"] = newComment
                
                logT["chatComment"] = logChatComment
            } else if log is ChatOptionsMessage {
                let chatOptionsMessage = log as! ChatOptionsMessage
                
                var logChatOptionsMessage = [String: Any]()

                let message = chatOptionsMessage.message
                let options = chatOptionsMessage.options
                
                logChatOptionsMessage["message"] = message
                logChatOptionsMessage["options"] = options
                
                logT["chatOptionsMessage"] = logChatOptionsMessage
            }
            
            logDict["participant"] = logCP
            logDict["deliveryStatus"] = logDS
            logDict["type"] = logT
            logsList.append(logDict)
        }
        
        dictionary["agents"] = agentsList
        dictionary["logs"] = logsList
        
        return dictionary
    }
    
    func sendRatingComment(_ arguments: Dictionary<String, Any>?) -> Void {
        let comment: String = (arguments?["comment"] ?? "") as! String
        Chat.chatProvider?.sendChatComment(comment, completion: { (result) in
            switch result {
            case .failure(let error):
                print(error)
            case .success(let success):
                print(success)
            }
        })
    }
    
    func sendRatingReview(_ arguments: Dictionary<String, Any>?) -> Void {
        let rate: String = (arguments?["rating"] ?? "") as! String
        
        
        var rating: Rating
        switch rate {
        case "GOOD":
            rating = .good
        case "BAD":
            rating = .bad
        default:
            rating = .none
        }
        
        Chat.chatProvider?.sendChatRating(rating, completion: { (result) in
            switch result {
            case .failure(let error):
                print(error)
            case .success(let success):
                print(success)
            }
        })
    }
    
    func endChat() -> Void {
        Chat.chatProvider?.endChat({ (result) in
            switch result {
            case .failure(let error):
                print(error)
            case .success(let success):
                self.chatSessionStatus =  "ENDED"
                print(success)
            }
        })
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

//
//  SwiftZendesk2Chat.swift
//  zendesk2
//
//  Created by Adrian Kohls on 07/01/21.
//

import ChatProvidersSDK
import Flutter

public class SwiftZendesk2Chat {
    
    private var channel: FlutterMethodChannel? = nil
    private var zendeskPlugin: SwiftZendesk2Plugin? = nil
    
    init(channel: FlutterMethodChannel, flutterPlugin: SwiftZendesk2Plugin) {
        self.channel = channel
        self.zendeskPlugin = flutterPlugin
    }
    
    func initialize(_ arguments: Dictionary<String, Any>?) -> Void {
        let accountKey = (arguments?["accountKey"] ?? "") as? String
        let appId = (arguments?["appId"] ?? "") as? String
        
        Chat.initialize(accountKey: accountKey!, appId: appId!)
    }
    
    func dispose() -> Void {
        endChat()
        Chat.instance?.resetIdentity({
            NSLog("Identity reseted")
        })
        Chat.instance?.clearCache()
    }
    
    /// setVisitorInfo Zendesk API
    func setVisitorInfo(_ arguments: Dictionary<String, Any>?) -> Void {
        
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
    
    /// startChat v2 Zendesk API Providers
    func startChatProviders() -> Void {
        startProviders()
    }
    
    func connect(){
        Chat.connectionProvider?.connect()
    }
    func disconnect(){
        Chat.connectionProvider?.disconnect()
    }
    
    private func startProviders() -> Void {
        NSLog("zendesk_chat_start_providers")
        chatProviderStart()
        accountProviderStart()
        settingsProviderStart()
        connectionProviderStart()
    }
    
    private func sendChatProvidersResult(_ arguments: Dictionary<String, Any>?) -> Void {
        self.channel?.invokeMethod("sendChatProvidersResult", arguments: arguments)
    }
    private func sendChatConnectionStatusResult(_ arguments: Dictionary<String, Any>?) -> Void {
        self.channel?.invokeMethod("sendChatConnectionStatusResult", arguments: arguments)
    }
    private func sendChatSettingsResult(_ arguments: Dictionary<String, Any>?) -> Void {
        self.channel?.invokeMethod("sendChatSettingsResult", arguments: arguments)
    }
    private func sendChatIsOnlineResult(_ arguments: Dictionary<String, Any>?) -> Void {
        self.channel?.invokeMethod("sendChatIsOnlineResult", arguments: arguments)
    }
    
    private func chatProviderStart() -> Void {
        zendeskPlugin?.chatStateObservationToken = Chat.chatProvider?.observeChatState { (chatState) in
            
            let isChatting = chatState.isChatting
            let chatId = chatState.chatId
            let agents = chatState.agents
            let logs = chatState.logs
            
            let mQueuePosition = chatState.queuePosition
            let queuePosition = mQueuePosition.queue
            let queueId = mQueuePosition.id
            
            let chatSessionStatus = chatState.chatSessionStatus.description
            
            var dictionary = [String:Any]()
            dictionary["isChatting"] = isChatting
            dictionary["chatId"] = chatId
            dictionary["agents"] = agents
            dictionary["queuePosition"] = queuePosition
            dictionary["queueId"] = queueId
            dictionary["chatSessionStatus"] = chatSessionStatus
            
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
                logDict["chatParticipant"] = log.participant.description
                
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
                    logDS["status"] = "FAILED"
                    NSLog("MessageLog delivery error: ",reason.localizedDescription)
                default:
                    logDS["status"] = "FAILED"
                }
                
                var logT = [String: Any]()
                let chatLogType = log.type
                switch chatLogType {
                case .attachmentMessage:
                    logT["type"] = "ATTACHMENT_MESSAGE"
                case .memberJoin:
                    logT["type"] = "MEMBER_JOIN"
                case .memberLeave:
                    logT["type"] = "MEMBER_LEAVE"
                case .message:
                    logT["type"] = "MESSAGE"
                case .optionsMessage:
                    logT["type"] = "OPTIONS_MESSAGE"
                default:
                    logT["type"] = "OPTIONS_MESSAGE"
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
                    let attachmentError = attachment.attachmentError
                    var logChatAttachmentAttachmentMessage = [String: Any]()
                    
                    var mError: String? = nil
                    if attachmentError != nil {
                        switch attachmentError {
                        case .none:
                            mError = "none"
                        case .unsupportedType:
                            mError = attachmentError!.localizedDescription
                        case .sizeLimit:
                            mError = attachmentError!.localizedDescription
                        case .some(let error):
                            let code = error.errorCode
                            let userInfo = error.errorUserInfo.description
                            let description = error.errorDescription ?? ""
                            let reason = error.failureReason ?? ""
                            mError = "code: \(code)\nuserInfo: \(userInfo)\ndescription: \(description)\nreason: \(reason)"
                        }
                    }
                    
                    logChatAttachmentAttachmentMessage["error"] = mError
                    logChatAttachmentAttachmentMessage["name"] = attachment.name
                    logChatAttachmentAttachmentMessage["localUrl"] = attachment.localURL?.absoluteString
                    logChatAttachmentAttachmentMessage["mimeType"] = attachment.mimeType
                    logChatAttachmentAttachmentMessage["size"] = attachment.size
                    logChatAttachmentAttachmentMessage["url"] = attachment.url
                    
                    logChatAttachmentMessage["chatAttachmentAttachment"] = logChatAttachmentAttachmentMessage
                    logT["chatAttachment"] = logChatAttachmentMessage
                    
                } else if log is ChatOptionsMessage {
                    let chatOptionsMessage = log as! ChatOptionsMessage
                    
                    var logChatOptionsMessage = [String: Any]()
                    
                    let message = chatOptionsMessage.message
                    let options = chatOptionsMessage.options
                    
                    logChatOptionsMessage["message"] = message
                    logChatOptionsMessage["options"] = options
                    
                    logT["chatOptionsMessage"] = logChatOptionsMessage
                }
                
                logDict["deliveryStatus"] = logDS
                logDict["type"] = logT
                logsList.append(logDict)
            }
            
            dictionary["agents"] = agentsList
            dictionary["logs"] = logsList
            
            self.sendChatProvidersResult(dictionary)
        }
    }
    
    private func accountProviderStart() -> Void {
        zendeskPlugin?.accountObservationToken = Chat.accountProvider?.observeAccount { (account) in
            let accountStatus = account.accountStatus
            let departments = account.departments ?? []
            let isOnline = accountStatus == .online
            
            var dictionary = [String: Any]()
            var departmentsList = Array<Dictionary<String, Any>>()
            
            for department in departments {
                var departmentDictionary = [String: Any]()
                
                let id = department.id
                let name = department.name
                let status = department.status.description
                
                departmentDictionary["id"] = id
                departmentDictionary["name"] = name
                departmentDictionary["status"] = status
                
                departmentsList.append(departmentDictionary)
            }
            
            dictionary["isOnline"] = isOnline
            dictionary["departments"] = departmentsList
            
            self.sendChatIsOnlineResult(dictionary)
        }
    }
    
    private func settingsProviderStart() -> Void {
        zendeskPlugin?.settingsObservationToken = Chat.settingsProvider?.observeChatSettings { (settings) in
            let isFileSendingEnabled = settings.isFileSendingEnabled
            let supportedFileTypes = settings.supportedFileTypes
            let fileSizeLimit = settings.fileSizeLimit
            
            var dictionary = [String: Any]()
            dictionary["isFileSendingEnabled"] = isFileSendingEnabled
            dictionary["supportedFileTypes"] = supportedFileTypes
            dictionary["fileSizeLimit"] = fileSizeLimit
            
            self.sendChatSettingsResult(dictionary)
        }
    }
    
    private func connectionProviderStart() -> Void {
        zendeskPlugin?.statusObservationToken = Chat.connectionProvider?.observeConnectionStatus { (status) in
            let connectionStatus = status.description
            
            var dictionary = [String: Any]()
            dictionary["connectionStatus"] = connectionStatus
            
            self.sendChatConnectionStatusResult(dictionary)
        }
    }
    
    func sendMessage(_ arguments: Dictionary<String, Any>?) -> Void {
        let message: String = (arguments?["message"] ?? "") as! String
        
        Chat.chatProvider?.sendMessage(message) { (result) in
            switch result {
            case .success(let messageId):
                NSLog("Message sent: %@", messageId)
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
                NSLog("success")
            case .failure(let error):
                NSLog("Send attachment failed, resending...")
                let messageId = error.messageId
                if(messageId != nil && !(messageId?.isEmpty ?? false)){
                    Chat.chatProvider?.resendFailedFile(withId: messageId!, onProgress: { (progress) in
                        NSLog(progress.description)
                    }, completion: nil)
                }
            }
        })
    }
    
    func sendTyping(_ arguments: Dictionary<String, Any>?) -> Void {
        let isTyping: Bool = (arguments?["isTyping"] ?? false) as! Bool
        Chat.chatProvider?.sendTyping(isTyping: isTyping)
    }
    
    func endChat() -> Void {
        Chat.chatProvider?.endChat({ (result) in
            switch result {
            case .success(let success):
                NSLog(success.description)
            case .failure(let error):
                NSLog(error.localizedDescription)
            }
        })
    }
}

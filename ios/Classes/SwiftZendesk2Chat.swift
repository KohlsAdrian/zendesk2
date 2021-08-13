//
//  SwiftZendesk2Chat.swift
//  zendesk2
//
//  Created by Adrian Kohls on 07/01/21.
//

import ChatProvidersSDK
import Flutter

public class SwiftZendesk2Chat {
    
    private var channel: FlutterMethodChannel

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
    
    private var messageId: String? = nil
    private var messageIds: Array<String> = []
    
    init(channel: FlutterMethodChannel) {
        self.channel = channel
    }
    
    /// Logging  Zendesk API
    func logger(_ arguments: Dictionary<String, Any>?) -> Void {
        let enabled: Bool = (arguments?["enabled"] ?? false) as! Bool
        Logger.isEnabled = enabled
        Logger.defaultLevel = .verbose
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
    
    /// Closes Zendesk Chat
    @objc func dispose() -> Void {
        
        let chat = Chat.instance
        
        chat?.clearCache()
        chat?.resetIdentity({
            NSLog("Identity reseted")
        })
        
        endChat()
        
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
        NSLog("zendesk_chatProviderStart")
        chatProviderStart()
        /// Account providers
        NSLog("zendesk_accountProviderStart")
        accountProviderStart()
        /// Settings providers
        NSLog("zendesk_settingsProviderStart")
        settingsProviderStart()
        /// Connection providers
        NSLog("zendesk_connectionProviderStart")
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
                NSLog(error.localizedDescription)
            }

            self.sendChatProvidersResult()

        }
        
        observeChatStateToken = Chat.chatProvider?.observeChatState { (chatState) in
            self.isChatting = chatState.isChatting
            self.chatId = chatState.chatId
            self.agents = chatState.agents
            self.hasAgents = !chatState.agents.isEmpty
            self.logs = chatState.logs
            self.queuePosition = chatState.queuePosition
            
            switch chatState.chatSessionStatus {
            case .configuring:
                self.chatSessionStatus = "CONFIGURING"
            case .ended:
                self.chatSessionStatus = "ENDED"
            case .ending:
                self.chatSessionStatus = "ENDING"
            case .initializing:
                self.chatSessionStatus = "INITIALIZING"
            case .started:
                self.chatSessionStatus = "STARTED"
            default:
                self.chatSessionStatus = "UNKNOWN"
            }
            
            self.sendChatProvidersResult()
        }
    }
    
    private func accountProviderStart() -> Void {
        observeAccoutToken = Chat.accountProvider?.observeAccount { (account) in
            let accountStatus = account.accountStatus
            self.isOnline = accountStatus == .online
            self.hasAgents = !self.agents.isEmpty
            self.sendChatProvidersResult()
        }
        
        Chat.accountProvider?.getAccount { (result) in
            switch result {
            case .success(let account):
                self.hasAgents = true
                self.isOnline = account.accountStatus == .online
            case .failure(let error):
                NSLog(error.localizedDescription)
            }
            self.sendChatProvidersResult()

        }
    }
    
    private func settingsProviderStart() -> Void {
        observeChatSettingsToken = Chat.settingsProvider?.observeChatSettings { (settings) in
            self.isFileSendingEnabled = settings.isFileSendingEnabled
            self.sendChatProvidersResult()

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

            self.sendChatProvidersResult()
        }
    }

    private func sendChatProvidersResult() -> Void{
        channel.invokeMethod("sendChatProvidersResult", arguments: getChatProviders())
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
                NSLog("success")
            case .failure(let error):
                NSLog("Send attachment failed, resending...")
                let messageId = error.messageId
                if(messageId != nil && !(messageId?.isEmpty ?? false)){
                    Chat.chatProvider?.resendFailedFile(withId: messageId!, onProgress: { (progress) in
                        NSLog(progress.description)
                    }, completion: { (result) in
                        //
                    })
                }
            }
        })
    }
    
    func getAttachmentsExtension() -> Array<String> {
        var array = Array<String>()
        let settingsProvider = Chat.settingsProvider
        let types = settingsProvider?.settings.supportedFileTypes
        for type in types ?? [] {
            array.append(type)
        }
        return array
    }
    
    func sendTyping(_ arguments: Dictionary<String, Any>?) -> Void {
        let isTyping: Bool = (arguments?["isTyping"] ?? false) as! Bool
        Chat.chatProvider?.sendTyping(isTyping: isTyping)
    }
    
    func getChatProviders() -> Dictionary<String, Any>? {
        var dictionary = [String: Any]()
        dictionary["isOnline"] = self.isOnline
        dictionary["isChatting"] = self.isChatting
        dictionary["hasAgents"] = self.hasAgents
        dictionary["isFileSendingEnabled"] = self.isFileSendingEnabled
        dictionary["connectionStatus"] = self.connectionStatus
        dictionary["chatSessionStatus"] = self.chatSessionStatus
        
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
                NSLog(reason.localizedDescription)
            default:
                logDS["status"] = "UNKNOWN"
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
                
                switch attachment.attachmentError {
                case .none:
                    logChatAttachmentAttachmentMessage["error"] = "NONE"
                case .sizeLimit:
                    logChatAttachmentAttachmentMessage["error"] = "SIZE_LIMIT"
                default:
                    logChatAttachmentAttachmentMessage["error"] = "NONE"
                }
                
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
            
            logDict["participant"] = logCP
            logDict["deliveryStatus"] = logDS
            logDict["type"] = logT
            logsList.append(logDict)
        }
        
        dictionary["agents"] = agentsList
        dictionary["logs"] = logsList
        
        return dictionary
    }
    
    func endChat() -> Void {
        Chat.chatProvider?.endChat({ (result) in
            switch result {
            case .success(let success):
                self.chatSessionStatus =  "ENDED"
                NSLog(success.description)
            case .failure(let error):
                NSLog(error.localizedDescription)
            }
        })
    }
}

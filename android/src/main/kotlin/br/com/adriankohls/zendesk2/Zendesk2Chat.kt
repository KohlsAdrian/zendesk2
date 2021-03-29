package br.com.adriankohls.zendesk2

import android.app.Activity
import com.zendesk.logger.Logger
import com.zendesk.service.ErrorResponse
import com.zendesk.service.ZendeskCallback
import io.flutter.plugin.common.MethodCall
import zendesk.chat.*
import zendesk.messaging.MessagingActivity
import java.io.File


class Zendesk2Chat(private val activity: Activity?) {

    private var chatConfiguration: ChatConfiguration? = null
    private var isOnline: Boolean = false
    private var isChatting: Boolean = false
    private var hasAgents: Boolean = false
    private var isFileSendingEnabled: Boolean = false
    private var connectionStatus: String = "UNKNOWN";
    private var chatSessionStatus: String = "UNKNOWN";
    private var chatId: String? = null
    private var agents: List<Agent> = listOf()
    private var logs: List<ChatLog> = listOf()
    private var queuePosition: Int = 0
    private var rating: ChatRating? = null
    private var comment: String? = null

    private var chatProviderObservationToken: ObservationScope? = null
    private var accountProviderObservationToken: ObservationScope? = null
    private var settingsProviderObservationToken: ObservationScope? = null
    private var connectionProviderObservationToken: ObservationScope? = null

    fun customize(call: MethodCall): Map<String, Any>? {
        val agentAvailability = call.argument<Boolean>("agentAvailability") ?: false
        val transcript = call.argument<Boolean>("transcript") ?: false
        val preChatForm = call.argument<Boolean>("preChatForm") ?: false
        val offlineForms = call.argument<Boolean>("offlineForms") ?: false
        val nameFieldStatus = call.argument<String>("nameFieldStatus")
        val emailFieldStatus = call.argument<String>("emailFieldStatus")
        val phoneFieldStatus = call.argument<String>("phoneFieldStatus")
        val departmentFieldStatus = call.argument<String>("departmentFieldStatus")
        val endChatEnabled = call.argument<Boolean>("endChatEnabled") ?: true
        val transcriptChatEnabled = call.argument<Boolean>("transcriptChatEnabled") ?: true

        val nameFieldEnum = getPreChatEnumByString(nameFieldStatus)
        val emailFieldEnum = getPreChatEnumByString(emailFieldStatus)
        val phoneFieldEnum = getPreChatEnumByString(phoneFieldStatus)
        val departmentFieldEnum = getPreChatEnumByString(departmentFieldStatus)

        val chatConfigurationBuilder = ChatConfiguration.builder()

        chatConfigurationBuilder.withAgentAvailabilityEnabled(agentAvailability)
        chatConfigurationBuilder.withTranscriptEnabled(transcript)
        chatConfigurationBuilder.withPreChatFormEnabled(preChatForm)
        chatConfigurationBuilder.withOfflineFormEnabled(offlineForms)
        chatConfigurationBuilder.withNameFieldStatus(nameFieldEnum)
        chatConfigurationBuilder.withEmailFieldStatus(emailFieldEnum)
        chatConfigurationBuilder.withPhoneFieldStatus(phoneFieldEnum)
        chatConfigurationBuilder.withDepartmentFieldStatus(departmentFieldEnum)

        if (!endChatEnabled && !transcriptChatEnabled)
            chatConfigurationBuilder.withChatMenuActions()
        else if (!transcriptChatEnabled)
            chatConfigurationBuilder.withChatMenuActions(ChatMenuAction.END_CHAT)
        else if (!endChatEnabled)
            chatConfigurationBuilder.withChatMenuActions(ChatMenuAction.CHAT_TRANSCRIPT)

        chatConfiguration = chatConfigurationBuilder.build()

        if (!Logger.isLoggable()) {
            return null
        }

        return mapOf<String, Any>(
                "zendesk_agent_availability" to agentAvailability
        )
    }

    private fun getPreChatEnumByString(preChatName: String?): PreChatFormFieldStatus =
            when (preChatName) {
                "OPTIONAL" -> PreChatFormFieldStatus.OPTIONAL
                "HIDDEN" -> PreChatFormFieldStatus.HIDDEN
                "REQUIRED" -> PreChatFormFieldStatus.REQUIRED
                else -> PreChatFormFieldStatus.HIDDEN
            }

    fun init(call: MethodCall) {
        val accountKey = call.argument<String>("accountKey")!!
        val appId = call.argument<String>("appId")!!

        Chat.INSTANCE.init(activity!!, accountKey, appId)
    }

    fun logger(call: MethodCall) {
        var enabled = call.argument<Boolean>("enabled")
        enabled = enabled ?: false
        Logger.setLoggable(enabled)
    }

    fun startChat(call: MethodCall) {
        val botLabel = call.argument<String>("botLabel") ?: ""
        val toolbarTitle = call.argument<String>("toolbarTitle") ?: ""
        if (chatConfiguration != null)
            MessagingActivity
                    .builder()
                    .withEngines(ChatEngine.engine())
                    .withBotLabelString(botLabel)
                    .withToolbarTitle(toolbarTitle)
                    .withMultilineResponseOptionsEnabled(false)
                    .show(activity!!, chatConfiguration)
    }

    fun dispose() {
        clearTokens()
        chatConfiguration = null
        Chat.INSTANCE.providers()?.connectionProvider()?.disconnect()
    }

    fun setVisitorInfo(call: MethodCall) {
        val name = call.argument<String>("name")
        val email = call.argument<String>("email")
        val phoneNumber = call.argument<String>("phoneNumber")
        val departmentName = call.argument<String>("departmentName")

        val tags = call.argument<List<String>>("tags")?.toList() ?: listOf()

        val profileProvider = Chat.INSTANCE.providers()?.profileProvider()
        profileProvider?.addVisitorTags(tags, null)

        val visitorInfoBuilder = VisitorInfo.builder()
                .withName(name ?: "")
                .withEmail(email ?: "")
                .withPhoneNumber(phoneNumber)

        val visitorInfo = visitorInfoBuilder.build()

        val chatProvidersConfigurationBuilder = ChatProvidersConfiguration.builder()
                .withVisitorInfo(visitorInfo)
                .withDepartment(departmentName)

        val chatProvidersConfiguration = chatProvidersConfigurationBuilder.build()

        Chat.INSTANCE.chatProvidersConfiguration = chatProvidersConfiguration
        Chat.INSTANCE.providers()?.profileProvider()?.setVisitorInfo(visitorInfo, object : ZendeskCallback<Void>() {
            override fun onSuccess(success: Void?) {
                print("sucess")
            }

            override fun onError(error: ErrorResponse?) {
                print(error)
            }
        })
    }

    fun startChatProviders() {
        if (chatConfiguration == null) {
            throw Exception("You must call '.customize' and add more information")
        }
        startProviders()

        val providers = Chat.INSTANCE.providers()
        providers?.connectionProvider()?.connect()
    }

    private fun startProviders() {
        if (chatProviderObservationToken == null)
            chatProviderStart()
        if (accountProviderObservationToken == null)
            accountProviderStart()
        if (settingsProviderObservationToken == null)
            settingsProviderStart()
        if (connectionProviderObservationToken == null)
            connectionProviderStart()
    }

    private fun chatProviderStart() {
        chatProviderObservationToken = ObservationScope()
        Chat.INSTANCE.providers()?.chatProvider()?.observeChatState(chatProviderObservationToken!!) {
            this.agents = it.agents
            this.hasAgents = it.agents.isNotEmpty()
            this.logs = it.chatLogs
            this.chatId = it.chatId
            this.rating = it.chatRating
            this.queuePosition = it.queuePosition
            this.isChatting = it.isChatting
            this.chatSessionStatus = it.chatSessionStatus.name.split('.').last()
            this.comment = it.chatComment
        }
    }

    private fun accountProviderStart() {
        accountProviderObservationToken = ObservationScope()
        Chat.INSTANCE.providers()?.accountProvider()?.observeAccount(accountProviderObservationToken!!) {
            when (it.status) {
                AccountStatus.ONLINE -> {
                    this.isOnline = it.status == AccountStatus.ONLINE
                    this.hasAgents = this.agents.isNotEmpty()
                }
                AccountStatus.OFFLINE -> {
                    this.isOnline = false
                    this.hasAgents = this.agents.isNotEmpty()
                }
            }
        }

        Chat.INSTANCE.providers()?.accountProvider()?.getAccount(object : ZendeskCallback<Account>() {
            override fun onSuccess(a: Account?) {
                hasAgents = true
                isOnline = a?.status == AccountStatus.ONLINE
            }

            override fun onError(e: ErrorResponse?) {
                print(e)
            }
        })
    }

    private fun settingsProviderStart() {
        settingsProviderObservationToken = ObservationScope()
        Chat.INSTANCE.providers()?.settingsProvider()?.observeChatSettings(settingsProviderObservationToken!!) {
            this.isFileSendingEnabled = it.isFileSendingEnabled
        }
    }

    private fun connectionProviderStart() {
        connectionProviderObservationToken = ObservationScope()
        Chat.INSTANCE.providers()?.connectionProvider()?.observeConnectionStatus(connectionProviderObservationToken!!) {
            this.connectionStatus = it.name.split('.').last()
        }
    }

    fun sendMessage(call: MethodCall) {
        val message = call.argument<String>("message")

        if (message != null) {
            val sent = Chat.INSTANCE.providers()?.chatProvider()?.sendMessage(message)
            if (sent?.deliveryStatus != DeliveryStatus.DELIVERED)
                if (sent?.id != null)
                    Chat.INSTANCE.providers()?.chatProvider()?.resendFailedMessage(sent.id)
        }
    }

    fun sendFile(call: MethodCall) {
        val file = call.argument<String>("file") ?: ""

        val fileObject = File(file)

        val attachmentMessage = Chat.INSTANCE.providers()?.chatProvider()?.sendFile(fileObject, null)

        if (attachmentMessage != null && attachmentMessage.deliveryStatus != DeliveryStatus.DELIVERED)
            Chat.INSTANCE.providers()?.chatProvider()?.resendFailedMessage(attachmentMessage.id)
    }

    fun getAttachmentsExtension(): List<String> {
        val types = Chat.INSTANCE.providers()?.settingsProvider()?.chatSettings?.allowedFileTypes
        val array = types?.toList<String>()
        return array ?: listOf()
    }

    fun sendTyping(call: MethodCall) {
        val isTyping = call.argument<Boolean>("isTyping") ?: false
        Chat.INSTANCE.providers()?.chatProvider()?.setTyping(isTyping)
    }

    fun getChatProviders(): Map<String, Any?> {
        val dictionary = mutableMapOf<String, Any?>()
        dictionary["isOnline"] = this.isOnline
        dictionary["isChatting"] = this.isChatting
        dictionary["hasAgents"] = this.hasAgents
        dictionary["isFileSendingEnabled"] = this.isFileSendingEnabled
        dictionary["connectionStatus"] = this.connectionStatus
        dictionary["chatSessionStatus"] = this.chatSessionStatus

        dictionary["rating"] = this.rating?.name?.split(".")?.last()
        dictionary["queuePosition"] = this.queuePosition

        val agentsList = mutableListOf<MutableMap<String, Any?>>()
        for (agent in this.agents) {
            val agentDict = mutableMapOf<String, Any?>()

            val avatar = agent.avatarPath
            val displayName = agent.displayName
            val isTyping = agent.isTyping
            val nick = agent.nick

            agentDict["avatar"] = avatar
            agentDict["displayName"] = displayName
            agentDict["isTyping"] = isTyping
            agentDict["nick"] = nick

            agentsList.add(agentDict)
        }

        val logsList = mutableListOf<MutableMap<String, Any?>>()
        for (log in this.logs) {
            val logDict = mutableMapOf<String, Any?>()
            logDict["id"] = log.id
            logDict["createdTimestamp"] = log.createdTimestamp
            logDict["displayName"] = log.displayName
            logDict["lastModifiedTimestamp"] = log.lastModifiedTimestamp
            logDict["nick"] = log.nick

            val logCP = mutableMapOf<String, Any?>()
            val chatParticipant = log.chatParticipant
            logCP["chatParticipant"] = chatParticipant.name.split(".").last()

            val logDS = mutableMapOf<String, Any?>()
            val deliveryStatus = log.deliveryStatus
            val isFailed = deliveryStatus.name.contains("FAILED")
            logDS["isFailed"] = isFailed
            logDS["status"] = deliveryStatus.name.split(".").last()

            val logT = mutableMapOf<String, Any?>()
            val chatLogType = log.type
            logT["type"] = chatLogType.name.split(".").last()

            when (log) {
                is ChatLog.Message -> {
                    val logChatMessage = mutableMapOf<String, Any?>()

                    val id = log.id
                    val message = log.message

                    logChatMessage["id"] = id
                    logChatMessage["message"] = message

                    logT["chatMessage"] = logChatMessage
                }
                is ChatLog.AttachmentMessage -> {
                    val logChatAttachmentMessage = mutableMapOf<String, Any?>()

                    val id = log.id
                    val url = log.attachment.url

                    logChatAttachmentMessage["id"] = id
                    logChatAttachmentMessage["url"] = url

                    val attachment = log.attachment
                    val logChatAttachmentAttachmentMessage = mutableMapOf<String, Any?>()

                    val attachmentName = attachment.name
                    val attachmentMimeType = attachment.mimeType
                    val attachmentSize = attachment.size
                    val attachmentUrl = attachment.url

                    logChatAttachmentAttachmentMessage["name"] = attachmentName
                    logChatAttachmentAttachmentMessage["mimeType"] = attachmentMimeType
                    logChatAttachmentAttachmentMessage["size"] = attachmentSize
                    logChatAttachmentAttachmentMessage["url"] = attachmentUrl

                    logChatAttachmentMessage["chatAttachmentAttachment"] = logChatAttachmentAttachmentMessage
                    logT["chatAttachment"] = logChatAttachmentMessage
                }
                is ChatLog.Rating -> {
                    val logChatRating = mutableMapOf<String, Any?>()

                    val rating = log.newChatRating.name.split(".").last()
                    logChatRating["rating"] = rating

                    logT["chatRating"] = logChatRating
                }
                is ChatLog.Comment -> {
                    val logChatComment = mutableMapOf<String, Any?>()

                    val comment = log.chatComment
                    val newComment = log.newChatComment

                    logChatComment["comment"] = comment
                    logChatComment["newComment"] = newComment

                    logT["chatComment"] = logChatComment
                }
                is ChatLog.OptionsMessage -> {
                    val logChatOptionsMessage = mutableMapOf<String, Any?>()

                    val message = log.messageQuestion
                    val options = log.messageOptions.toList<String>()

                    logChatOptionsMessage["message"] = message
                    logChatOptionsMessage["options"] = options

                    logT["chatOptionsMessage"] = logChatOptionsMessage
                }
            }

            logDict["participant"] = logCP
            logDict["deliveryStatus"] = logDS
            logDict["type"] = logT
            logsList.add(logDict)
        }

        dictionary["agents"] = agentsList
        dictionary["logs"] = logsList

        return dictionary
    }

    fun sendRatingComment(call: MethodCall) {
        val comment = call.argument<String>("comment") ?: ""
        if (comment.isNotEmpty())
            Chat.INSTANCE.providers()?.chatProvider()?.sendChatComment(comment, null)
    }

    fun sendRatingReview(call: MethodCall) {
        val rating: ChatRating? = when (call.argument<String>("rating") ?: "") {
            "GOOD" -> ChatRating.GOOD
            "BAD" -> ChatRating.BAD
            else -> null
        }
        if (rating != null)
            Chat.INSTANCE.providers()?.chatProvider()?.sendChatRating(rating, null)
    }

    private fun releaseTokens() {
        val pushProvider = Chat.INSTANCE.providers()?.pushNotificationsProvider()
        pushProvider?.unregisterPushToken()
        Chat.INSTANCE.resetIdentity {
            Chat.INSTANCE.clearCache()
            clearTokens()
        }
    }

    private fun clearTokens() {
        chatProviderObservationToken?.cancel()
        accountProviderObservationToken?.cancel()
        settingsProviderObservationToken?.cancel()
        connectionProviderObservationToken?.cancel()

        chatProviderObservationToken = null
        accountProviderObservationToken = null
        settingsProviderObservationToken = null
        connectionProviderObservationToken = null
    }

    fun endChat() {
        Chat.INSTANCE.providers()?.chatProvider()?.endChat(object : ZendeskCallback<Void>() {
            override fun onSuccess(v: Void?) {
                print("success")
                releaseTokens()
            }

            override fun onError(e: ErrorResponse?) {
                print(e)
            }
        })
    }

}
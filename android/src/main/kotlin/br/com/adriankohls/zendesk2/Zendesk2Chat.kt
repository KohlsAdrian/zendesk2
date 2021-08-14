package br.com.adriankohls.zendesk2

import android.app.Activity
import android.content.Context
import com.zendesk.logger.Logger
import com.zendesk.service.ErrorResponse
import com.zendesk.service.ZendeskCallback
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import zendesk.chat.*
import java.io.File


class Zendesk2Chat(private val plugin: Zendesk2Plugin, private val channel: MethodChannel) {

    fun logger(call: MethodCall) {
        var enabled = call.argument<Boolean>("enabled")
        enabled = enabled ?: false
        Logger.setLoggable(enabled)
    }

    fun dispose() {
        Chat.INSTANCE.providers()?.chatProvider()?.endChat(null)
        Chat.INSTANCE.providers()?.connectionProvider()?.disconnect()
    }

    fun setVisitorInfo(call: MethodCall) {
        val name = call.argument<String>("name")
        val email = call.argument<String>("email")
        val phoneNumber = call.argument<String>("phoneNumber")
        val departmentName = call.argument<String>("departmentName")

        val tags = call.argument<List<String>>("tags")?.toList() ?: listOf()

        val providers = Chat.INSTANCE.providers()?.chatProvider()
        val profileProvider = Chat.INSTANCE.providers()?.profileProvider()
        profileProvider?.addVisitorTags(tags, null)

        val visitorInfoBuilder = VisitorInfo.builder()
                .withName(name ?: "")
                .withEmail(email ?: "")
                .withPhoneNumber(phoneNumber ?: "")

        val visitorInfo = visitorInfoBuilder.build()

        profileProvider?.setVisitorInfo(visitorInfo, null)
        providers?.setDepartment(departmentName ?: "", null)
    }

    fun startChatProviders() {
        startProviders()
    }

    fun connect() {
        Chat.INSTANCE.providers()?.connectionProvider()?.connect()
    }

    fun disconnect() {
        Chat.INSTANCE.providers()?.connectionProvider()?.disconnect()
    }

    private fun startProviders() {
        chatProviderStart()
        accountProviderStart()
        settingsProviderStart()
        connectionProviderStart()
    }

    private fun chatProviderStart() {
        Chat.INSTANCE.providers()?.chatProvider()?.observeChatState(plugin.chatStateObservationScope) {
            val agents = it.agents
            val logs = it.chatLogs
            val chatId = it.chatId
            val queuePosition = it.queuePosition
            val isChatting = it.isChatting
            val chatSessionStatus = it.chatSessionStatus.name.split('.').last()


        }
    }

    private fun accountProviderStart() {
        Chat.INSTANCE.providers()?.accountProvider()?.observeAccount(plugin.accountObservationScope) {
            val isOnline = it.status == AccountStatus.ONLINE
            val deparments = it.departments ?: listOf<Department>()
            for (deparment in deparments) {

            }
        }

        Chat.INSTANCE.providers()?.accountProvider()?.getAccount(object : ZendeskCallback<Account>() {
            override fun onSuccess(a: Account?) {
                hasAgents = agents.isNotEmpty()
                isOnline = a?.status == AccountStatus.ONLINE

            }

            override fun onError(e: ErrorResponse?) {
                print(e)
            }
        })
    }

    private fun settingsProviderStart() {
        Chat.INSTANCE.providers()?.settingsProvider()?.observeChatSettings(plugin.settingsObservationScope) {
            this.isFileSendingEnabled = it.isFileSendingEnabled

        }
    }

    private fun connectionProviderStart() {
        Chat.INSTANCE.providers()?.connectionProvider()?.observeConnectionStatus(plugin.connectionStatusObservationScope) {
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
        dictionary["queuePosition"] = this.queuePosition

        val agentsList = mutableListOf<MutableMap<String, Any?>>()
        for (agent in agents) {
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
        for (log in logs) {
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

    fun registerToken(call: MethodCall) {
        val token = call.argument<String>("token")
        val pushProvider = Chat.INSTANCE.providers()?.pushNotificationsProvider()
        if (pushProvider != null && token != null) {
            pushProvider.registerPushToken(token)
        }
    }

    fun endChat() {
        Chat.INSTANCE.providers()?.chatProvider()?.endChat(object : ZendeskCallback<Void>() {
            override fun onSuccess(v: Void?) {
                print("success")
            }

            override fun onError(e: ErrorResponse?) {
                print(e)
            }
        })
    }

}
package br.com.adriankohls.zendesk2

import com.zendesk.logger.Logger
import com.zendesk.service.ErrorResponse
import com.zendesk.service.ZendeskCallback
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import zendesk.chat.*
import java.io.File


class Zendesk2Chat(private val plugin: Zendesk2Plugin, private val channel: MethodChannel) {

    fun initialize(call: MethodCall) {
        val accountKey = call.argument<String>("accountKey")!!
        val appId = call.argument<String>("appId")!!

        if (plugin.activity != null) {
            Chat.INSTANCE.init(plugin.activity!!, accountKey, appId)
            plugin.streamingChatSDK = true
        } else {
            print("Plugin Context is NULL!")
        }
    }

    fun logger(call: MethodCall) {
        var enabled = call.argument<Boolean>("enabled")
        enabled = enabled ?: false
        Logger.setLoggable(enabled)
    }

    fun dispose() {
        Chat.INSTANCE.clearCache()
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
        val observationScope = plugin.chatStateObservationScope
        Chat.INSTANCE.providers()?.chatProvider()?.observeChatState(observationScope) {
            val isChatting = it.isChatting
            val chatId = it.chatId
            val agents = it.agents
            val logs = it.chatLogs

            val queuePosition = it.queuePosition

            val department = it.department
            val chatSessionStatus = it.chatSessionStatus.name.uppercase()

            val dictionary = mutableMapOf<String, Any?>()

            dictionary["isChatting"] = isChatting
            dictionary["chatId"] = chatId
            dictionary["agents"] = agents
            dictionary["queuePosition"] = queuePosition
            dictionary["chatSessionStatus"] = chatSessionStatus
            dictionary["department"] = null

            if (department != null) {
                val departmentDict = mutableMapOf<String, Any?>()

                val id = department.id
                val name = department.name
                val status = department.status.name.uppercase()

                departmentDict["id"] = id
                departmentDict["name"] = name
                departmentDict["status"] = status

                dictionary["department"] = departmentDict
            }

            val mAgents = arrayListOf<Map<String, Any?>>()
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

                mAgents.add(agentDict)
            }
            dictionary["agents"] = mAgents.toList()

            val mLogs = arrayListOf<Map<String, Any?>>()
            for (log in logs) {
                val logDict = mutableMapOf<String, Any?>()
                logDict["id"] = log.id
                logDict["createdByVisitor"] = log.chatParticipant == ChatParticipant.VISITOR
                logDict["createdTimestamp"] = log.createdTimestamp
                logDict["displayName"] = log.displayName
                logDict["lastModifiedTimestamp"] = log.lastModifiedTimestamp
                logDict["nick"] = log.nick
                logDict["chatParticipant"] = log.chatParticipant.name.uppercase()


                val logDS = mutableMapOf<String, Any?>()
                val deliveryStatus = log.deliveryStatus.name.uppercase()
                val isFailed = when (log.deliveryStatus) {
                    DeliveryStatus.FAILED_FILE_SENDING_DISABLED -> true
                    DeliveryStatus.FAILED_FILE_SIZE_TOO_LARGE -> true
                    DeliveryStatus.FAILED_INTERNAL_SERVER_ERROR -> true
                    DeliveryStatus.FAILED_RESPONSE_TIMEOUT -> true
                    DeliveryStatus.FAILED_UNKNOWN_REASON -> true
                    DeliveryStatus.FAILED_UNSUPPORTED_FILE_TYPE -> true
                    else -> false
                }
                logDS["isFailed"] = isFailed
                logDS["status"] = deliveryStatus
                logDS["messageId_failed"] = if (isFailed) log.id else null


                val logT = mutableMapOf<String, Any?>()
                logT["type"] = log.type.name.uppercase()

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
                    is ChatLog.OptionsMessage -> {
                        val logChatOptionsMessage = mutableMapOf<String, Any?>()

                        val message = log.messageQuestion
                        val options = log.messageOptions.toList<String>()

                        logChatOptionsMessage["message"] = message
                        logChatOptionsMessage["options"] = options

                        logT["chatOptionsMessage"] = logChatOptionsMessage
                    }
                }

                logDict["deliveryStatus"] = logDS
                logDict["type"] = logT

                mLogs.add(logDict)
            }
            dictionary["logs"] = mLogs
            channel.invokeMethod("sendChatProvidersResult", dictionary)
        }
    }

    private fun accountProviderStart() {
        val observationScope = plugin.accountObservationScope
        Chat.INSTANCE.providers()?.accountProvider()?.observeAccount(observationScope) {
            val isOnline = it.status == AccountStatus.ONLINE
            val deparments = it.departments ?: listOf<Department>()

            val dictionary = mutableMapOf<String, Any?>()

            val mDepartments = arrayListOf<Map<String, Any?>>()
            for (deparment in deparments) {
                val departmentDict = mutableMapOf<String, Any?>()

                val id = deparment.id
                val name = deparment.name
                val status = deparment.status.name.uppercase()

                departmentDict["id"] = id
                departmentDict["name"] = name
                departmentDict["status"] = status

                mDepartments.add(departmentDict)
            }

            dictionary["isOnline"] = isOnline
            dictionary["departments"] = mDepartments

            channel.invokeMethod("sendChatIsOnlineResult", dictionary)
        }
    }

    private fun settingsProviderStart() {
        val observationScope = plugin.settingsObservationScope
        Chat.INSTANCE.providers()?.settingsProvider()?.observeChatSettings(observationScope) {
            val isFileSendingEnabled = it.isFileSendingEnabled
            val supportedFileTypes = it.allowedFileTypes
            val fileSizeLimit = it.maxFileSize

            val dictionary = mutableMapOf<String, Any?>()

            dictionary["isFileSendingEnabled"] = isFileSendingEnabled
            dictionary["supportedFileTypes"] = supportedFileTypes.toList()
            dictionary["fileSizeLimit"] = fileSizeLimit

            channel.invokeMethod("sendChatSettingsResult", dictionary)
        }
    }

    private fun connectionProviderStart() {
        val observationScope = plugin.connectionStatusObservationScope
        Chat.INSTANCE.providers()?.connectionProvider()?.observeConnectionStatus(observationScope) {
            val connectionStatus = it.name.uppercase()

            val dictionary = mutableMapOf<String, Any?>()
            dictionary["connectionStatus"] = connectionStatus

            channel.invokeMethod("sendChatConnectionStatusResult", dictionary)
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

    fun sendTyping(call: MethodCall) {
        val isTyping = call.argument<Boolean>("isTyping") ?: false
        Chat.INSTANCE.providers()?.chatProvider()?.setTyping(isTyping)
    }

    fun registerToken(call: MethodCall) {
        val token = call.argument<String>("token")
        val pushProvider = Chat.INSTANCE.providers()?.pushNotificationsProvider()
        if (pushProvider != null && token != null) {
            pushProvider.registerPushToken(token)
        }
    }

    fun endChat() {
        Chat.INSTANCE.resetIdentity()
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
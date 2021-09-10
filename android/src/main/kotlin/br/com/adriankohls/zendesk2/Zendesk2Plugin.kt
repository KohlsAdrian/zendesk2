package br.com.adriankohls.zendesk2

import android.app.Activity
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import zendesk.chat.*
import zendesk.talk.android.AudioDevice
import zendesk.talk.android.Talk
import zendesk.talk.android.TalkCall

class Zendesk2Plugin : ActivityAware, FlutterPlugin, MethodCallHandler {

    private lateinit var channel: MethodChannel

    var activity: Activity? = null

    val chatStateObservationScope: ObservationScope = ObservationScope()
    val accountObservationScope: ObservationScope = ObservationScope()
    val settingsObservationScope: ObservationScope = ObservationScope()
    val connectionStatusObservationScope: ObservationScope = ObservationScope()

    var talk: Talk? = null
    var talkCall: TalkCall? = null
    var availableAudioDevices: List<Map<String, Any?>>? = null

    var streamingChatSDK: Boolean = false
    var streamingAnswerSDK: Boolean = false

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        val zendesk2Chat = Zendesk2Chat(this, channel)
        val zendesk2Answer = Zendesk2Answer(this, channel)
        val zendesk2Talk = Zendesk2Talk(this, channel)


        var mResult: Any? = null
        when (call.method) {
            "init_chat" -> {
                if (streamingChatSDK) {
                    print("Chat SDK is already running!")
                } else {
                    zendesk2Chat.initialize(call)
                }
            }
            // chat sdk method channels
            "dispose" -> {
                chatStateObservationScope.cancel()
                accountObservationScope.cancel()
                settingsObservationScope.cancel()
                connectionStatusObservationScope.cancel()
                zendesk2Chat.dispose()
            }
            "logger" -> zendesk2Chat.logger(call)
            "setVisitorInfo" -> zendesk2Chat.setVisitorInfo(call)
            "startChatProviders" -> zendesk2Chat.startChatProviders()
            "chat_dispose" -> zendesk2Chat.dispose()
            "sendMessage" -> zendesk2Chat.sendMessage(call)
            "sendFile" -> zendesk2Chat.sendFile(call)
            "endChat" -> zendesk2Chat.endChat()
            "sendIsTyping" -> zendesk2Chat.sendTyping(call)
            "registerToken" -> zendesk2Chat.registerToken(call)
            "chat_connect" -> zendesk2Chat.connect()
            "chat_disconnect" -> zendesk2Chat.disconnect()
            "sendChatProvidersResult" -> mResult = call.arguments
            "sendChatConnectionStatusResult" -> mResult = call.arguments
            "sendChatSettingsResult" -> mResult = call.arguments
            "sendChatIsOnlineResult" -> mResult = call.arguments
            // answer sdk method channels
            "init_answer" -> {
                if (streamingAnswerSDK) {
                    print("Answer SDK is already running!")
                } else {
                    zendesk2Answer.initialize(call)
                }
            }
            "query" -> zendesk2Answer.deflectionQuery(call)
            "resolve_article" -> zendesk2Answer.resolveArticleDeflection(call)
            "reject_article" -> zendesk2Answer.rejectArticleDeflection(call)
            "sendAnswerProviderModel" -> mResult = call.arguments
            "sendResolveArticleDeflection" -> mResult = call.arguments
            "sendRejectArticleDeflection" -> mResult = call.arguments
            // talk sdk method channels
            "init_talk" -> {
                if (talk == null) {
                    zendesk2Talk.initialize(call)
                } else {
                    print("Talk SDK is already running!")
                }
            }
            "talk_recording_permission" -> mResult = zendesk2Talk.recordingPermission()
            "talk_check_availability" -> zendesk2Talk.checkAvailability(call)
            "talk_call" -> zendesk2Talk.call(call)
            "talk_disconnect" -> zendesk2Talk.disconnect()
            "talk_toggle_mute" -> mResult = zendesk2Talk.toggleMute()
            "talk_toggle_output" -> mResult = zendesk2Talk.toggleOutput()
            "talk_available_audio_routing_options" -> {
                val dictionary = mutableMapOf<String, Any?>()
                dictionary["availableAudioRoutingOptions"] = availableAudioDevices
                mResult = dictionary
            }
            "sendTalkAvailability" -> mResult = call.arguments
            "sendTalkCall" -> mResult = call.arguments
            else -> print("method not implemented")
        }

        if (mResult != null) {
            result.success(mResult)
        } else {
            result.success(0)
        }
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "zendesk2")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

}

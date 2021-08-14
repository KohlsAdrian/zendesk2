package br.com.adriankohls.zendesk2

import android.app.Activity
import android.content.Context
import android.content.SharedPreferences
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import zendesk.chat.*

class Zendesk2Plugin : ActivityAware, FlutterPlugin, MethodCallHandler {

    private lateinit var channel: MethodChannel
    private var activity: Activity? = null

    val chatStateObservationScope : ObservationScope = ObservationScope()
    val accountObservationScope : ObservationScope = ObservationScope()
    val settingsObservationScope : ObservationScope = ObservationScope()
    val connectionStatusObservationScope : ObservationScope = ObservationScope()

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        val zendesk2Chat = Zendesk2Chat(this, channel)


        var mResult: Any? = null
        when (call.method) {
            "init_answer" -> {
                val appId = call.argument<String>("appId")!!
                val clientId = call.argument<String>("clientId")!!
                val zendeskUrl = call.argument<String>("clientId")!!

            }
            "init_chat" -> {
                val accountKey = call.argument<String>("accountKey")!!
                val appId = call.argument<String>("appId")!!
                Chat.INSTANCE.init(activity!!, accountKey, appId)
            }
            // chat sdk method channels
            "logger" -> zendesk2Chat.logger(call)
            "setVisitorInfo" -> zendesk2Chat.setVisitorInfo(call)
            "startChatProviders" -> zendesk2Chat.startChatProviders()
            "chat_dispose" -> zendesk2Chat.dispose()
            "getChatProviders" -> mResult = zendesk2Chat.getChatProviders()
            "sendMessage" -> zendesk2Chat.sendMessage(call)
            "sendFile" -> zendesk2Chat.sendFile(call)
            "compatibleAttachmentsExtensions" -> mResult = zendesk2Chat.getAttachmentsExtension()
            "endChat" -> zendesk2Chat.endChat()
            "sendIsTyping" -> zendesk2Chat.sendTyping(call)
            "registerToken" -> zendesk2Chat.registerToken(call)
            "connect" -> zendesk2Chat.connect()
            "disconnect" -> zendesk2Chat.disconnect()
            // answer sdk method channels
            else -> print("method not implemented")
        }

        if(mResult != null){
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

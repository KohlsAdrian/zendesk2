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

class Zendesk2Plugin : ActivityAware, FlutterPlugin, MethodCallHandler {

    private lateinit var channel: MethodChannel
    private var zendesk2Chat: Zendesk2Chat? = null
    private var zendesk2Answer: Zendesk2Answer? = null
    private var activity: Activity? = null

    private var accountKey: String? = null
    private var appId: String? = null

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        var mResult: Any? = null
        when (call.method) {
            "init" -> {
                accountKey = call.argument<String>("accountKey")!!
                appId = call.argument<String>("appId")!!
            }
            "init_chat" -> {
                if (accountKey != null && appId != null) {
                    if (zendesk2Chat == null) {
                        zendesk2Chat = Zendesk2Chat(channel)
                        Chat.INSTANCE.init(activity!!, accountKey!!, appId!!)
                    } else {
                        print("Chat Already Initialized")
                    }
                } else {
                    print("You should call Zendesk.instance.init first!")
                }
            }
            "init_answer" -> {
                if (accountKey != null && appId != null) {
                    if (zendesk2Answer == null) {
                        zendesk2Answer = Zendesk2Answer(channel)
                    } else {
                        print("Answer Already Initialized")
                    }
                } else {
                    print("You should call Zendesk.instance.init first!")
                }
            }
            // chat sdk method channels
            "logger" -> zendesk2Chat?.logger(call)
            "setVisitorInfo" -> zendesk2Chat?.setVisitorInfo(call)
            "startChatProviders" -> zendesk2Chat?.startChatProviders()
            "chat_dispose" -> zendesk2Chat?.dispose()
            "getChatProviders" -> mResult = zendesk2Chat?.getChatProviders()
            "sendMessage" -> zendesk2Chat?.sendMessage(call)
            "sendFile" -> zendesk2Chat?.sendFile(call)
            "compatibleAttachmentsExtensions" -> mResult = zendesk2Chat?.getAttachmentsExtension()
            "endChat" -> zendesk2Chat?.endChat()
            "sendIsTyping" -> zendesk2Chat?.sendTyping(call)
            "registerToken" -> zendesk2Chat?.registerToken(call)
            "connect" -> zendesk2Chat?.connect()
            "disconnect" -> zendesk2Chat?.disconnect()
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

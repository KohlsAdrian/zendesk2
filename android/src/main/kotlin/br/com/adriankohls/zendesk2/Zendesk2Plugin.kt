package br.com.adriankohls.zendesk2

import android.app.Activity
import androidx.annotation.NonNull
import com.zendesk.logger.Logger
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import zendesk.chat.*
import zendesk.messaging.MessagingActivity

class Zendesk2Plugin: ActivityAware, FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private var zendesk2Chat: Zendesk2Chat? = null
  private var activity: Activity? = null

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if(zendesk2Chat == null){
      zendesk2Chat = Zendesk2Chat(activity, channel)
    }

    val data: Any? =
            when (call.method) {
              "init" -> zendesk2Chat?.init(call)
              "logger" -> zendesk2Chat?.logger(call)
              "setVisitorInfo" -> zendesk2Chat?.setVisitorInfo(call)
              "startChat" -> zendesk2Chat?.startChat(call)
              "startChatProviders" -> zendesk2Chat?.startChatProviders()
              "dispose" -> zendesk2Chat?.dispose()
              "customize" -> zendesk2Chat?.customize(call)
              "getChatProviders" -> zendesk2Chat?.getChatProviders()!!
              "sendMessage" -> zendesk2Chat?.sendMessage(call)
              "sendFile" -> zendesk2Chat?.sendFile(call)
              "compatibleAttachmentsExtensions" -> result.success(zendesk2Chat?.getAttachmentsExtension())
              "endChat" -> zendesk2Chat?.endChat()
              "sendRatingComment" -> zendesk2Chat?.sendRatingComment(call)
              "sendRatingReview" -> zendesk2Chat?.sendRatingReview(call)
              "sendIsTyping" -> zendesk2Chat?.sendTyping(call)
              else -> print("method not implemented")
            }
    if(data is Map<*, *> || data is Array<*>)
        result.success(data)
    else
        result.success(this.hashCode())
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

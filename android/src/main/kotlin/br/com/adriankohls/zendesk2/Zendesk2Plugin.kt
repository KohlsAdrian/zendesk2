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


/** Zendesk2Plugin */
class Zendesk2Plugin: ActivityAware, FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private var activity: Activity? = null
  private var chatConfiguration: ChatConfiguration? = null

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "init" -> init(call)
      "logger" -> logger(call)
      "setVisitorInfo" -> setVisitorInfo(call)
      "startChat" -> startChat(call)
      "dispose" -> dispose()
      "customize" -> customize(call)
      else -> print("method not implemented")
    }
    result.success(null)
  }

  private fun customize(call: MethodCall){
    val agentAvailability = call.argument<Boolean>("agentAvailability") ?: false
    val transcript = call.argument<Boolean>("transcript") ?: false
    val preChatForm = call.argument<Boolean>("preChatForm") ?: false
    val offlineForms = call.argument<Boolean>("offlineForms") ?:false
    val nameFieldStatus = call.argument<String>("nameFieldStatus")
    val emailFieldStatus = call.argument<String>("emailFieldStatus")
    val phoneFieldStatus = call.argument<String>("phoneFieldStatus")
    val departmentFieldStatus =  call.argument<String>("departmentFieldStatus")
    val endChatEnabled = call.argument<Boolean>("endChatEnabled") ?: true
    val transcriptChatEnabled = call.argument<Boolean>("transcriptChatEnabled")?: true

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

    if(!endChatEnabled && !transcriptChatEnabled)
      chatConfigurationBuilder.withChatMenuActions()
    else if(!transcriptChatEnabled)
      chatConfigurationBuilder.withChatMenuActions(ChatMenuAction.END_CHAT)
    else if(!endChatEnabled)
      chatConfigurationBuilder.withChatMenuActions(ChatMenuAction.CHAT_TRANSCRIPT)

    chatConfiguration = chatConfigurationBuilder.build()
  }

  private fun getPreChatEnumByString(preChatName: String?): PreChatFormFieldStatus =
          when(preChatName){
            "OPTIONAL" -> PreChatFormFieldStatus.OPTIONAL
            "HIDDEN" -> PreChatFormFieldStatus.HIDDEN
            "REQUIRED" -> PreChatFormFieldStatus.REQUIRED
            else -> PreChatFormFieldStatus.HIDDEN
          }

  private fun init(call: MethodCall){
    val accountKey = call.argument<String>("accountKey")!!
    val appId = call.argument<String>("appId")!!
    val firebaseToken = call.argument<String>("firebaseToken")
    Chat.INSTANCE.init(activity!!, accountKey, appId)

    val pushProvider = Chat.INSTANCE.providers()?.pushNotificationsProvider()
    if(firebaseToken!= null)
      pushProvider?.registerPushToken(firebaseToken)

    val chatConfigurationBuilder = ChatConfiguration.builder()
    chatConfiguration = chatConfigurationBuilder.build()
  }

  private fun logger(call: MethodCall){
    var enabled = call.argument<Boolean>("enabled")
    enabled = enabled ?: false
    Logger.setLoggable(enabled)
  }

  private fun startChat(call: MethodCall){
    val botLabel = call.argument<String>("botLabel") ?: ""
    val toolbarTitle = call.argument<String>("toolbarTitle") ?: ""
    if(chatConfiguration != null)
      MessagingActivity
              .builder()
              .withEngines(ChatEngine.engine())
              .withBotLabelString(botLabel)
              .withToolbarTitle(toolbarTitle)
              .withMultilineResponseOptionsEnabled(false)
              .show(activity!!, chatConfiguration)
  }

  private  fun dispose(){
    val pushProvider = Chat.INSTANCE.providers()?.pushNotificationsProvider()
    pushProvider?.unregisterPushToken()
    Chat.INSTANCE.resetIdentity()
    Chat.INSTANCE.clearCache()
  }

  private fun setVisitorInfo(call: MethodCall){
    val name = call.argument<String>("name")
    val email = call.argument<String>("email")
    val phoneNumber = call.argument<String>("phoneNumber")
    val departmentName = call.argument<String>("departmentName")

    val tags = call.argument<List<String>>("tags")?.toMutableList() ?: mutableListOf()

    val profileProvider = Chat.INSTANCE.providers()?.profileProvider()
    profileProvider?.addVisitorTags(tags, null)

    val visitorBuilder = VisitorInfo.builder()

    visitorBuilder.withName(name ?: "")
    visitorBuilder.withEmail(email ?: "")
    visitorBuilder.withPhoneNumber(phoneNumber ?: "")


    val visitorInfo = visitorBuilder.build()

    val chatProviderConfigurationBuilder = ChatProvidersConfiguration.builder()
            .withVisitorInfo(visitorInfo)

    chatProviderConfigurationBuilder.withDepartment(departmentName ?: "")

    val chatProviderConfiguration = chatProviderConfigurationBuilder.build()

    Chat.INSTANCE.chatProvidersConfiguration = chatProviderConfiguration
  }

  /**
   * Flutter resources engine handler
   */

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

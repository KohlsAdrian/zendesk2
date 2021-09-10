package br.com.adriankohls.zendesk2

import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import zendesk.core.AnonymousIdentity
import zendesk.core.Identity
import zendesk.core.JwtIdentity
import zendesk.core.Zendesk
import zendesk.talk.android.*
import zendesk.talk.android.compat.CallDataBuilder

class Zendesk2Talk(private val plugin: Zendesk2Plugin, private val channel: MethodChannel) {

    fun initialize(call: MethodCall) {
        val appId = call.argument<String>("appId")!!
        val clientId = call.argument<String>("clientId")!!
        val zendeskUrl = call.argument<String>("zendeskUrl")!!

        val token = call.argument<String>("token")
        val name = call.argument<String>("name")
        val email = call.argument<String>("email")

        if (plugin.activity != null) {
            val zendesk = Zendesk.INSTANCE

            zendesk.init(plugin.activity!!, zendeskUrl, appId, clientId)

            val identity: Identity =
                    if (token != null) {
                        JwtIdentity(token)
                    } else {
                        val builder = AnonymousIdentity.Builder()
                        if (name != null) builder.withNameIdentifier(name)
                        if (email != null) builder.withEmailIdentifier(email)
                        builder.build()
                    }
            zendesk.setIdentity(identity)

            plugin.talk = Talk.create(zendesk)

        } else {
            print("Plugin Context is NULL!")
        }
    }

    fun recordingPermission(): Map<String, Any?> {
        val permissionGranted = plugin.talk?.arePermissionsGranted() ?: false

        val talkPermission = if (permissionGranted) {
            "GRANTED"
        } else {
            "UNKNOWN"
        }

        val dictionary = mutableMapOf<String, Any?>()
        dictionary["talkPermission"] = talkPermission
        return dictionary
    }

    fun checkAvailability(call: MethodCall) {
        val digitalLineName = call.argument<String>("digitalLineName")!!

        GlobalScope.launch {
            var isAgentAvailable = false
            var recordingConsent: RecordingConsent? = null
            var error: String? = null

            when (val lineStatusResult = plugin.talk?.lineStatus(digitalLineName)) {
                is LineStatusResult.Success -> {
                    isAgentAvailable = lineStatusResult.agentAvailable
                    recordingConsent = lineStatusResult.recordingConsent
                }
                LineStatusResult.Failure.DigitalLineNotFound -> {
                    error = "DigitalLineNotFound"
                }
                LineStatusResult.Failure.Unknown -> {
                    error = "UNKNOWN"
                }
                null -> error = "UNKNOWN"
            }


            val consent = when (recordingConsent) {
                RecordingConsent.OPT_IN -> "OPT_IN"
                RecordingConsent.OPT_OUT -> "OPT_OUT"
                null -> "UNKNOWN"
            }
            val dictionary = mutableMapOf<String, Any?>()
            dictionary["error"] = error
            dictionary["isAgentAvailable"] = isAgentAvailable
            dictionary["recordingConsent"] = consent

            plugin.activity?.runOnUiThread {
                channel.invokeMethod("sendTalkAvailability", dictionary)
            }
        }
    }

    fun call(call: MethodCall) {
        val digitalLineName = call.argument<String>("digitalLineName")!!
        val recordingConsentAnswer = call.argument<String>("recordingConsentAnswer")!!

        val consent = when (recordingConsentAnswer) {
            "OPT_IN" -> RecordingConsentAnswer.OPTED_IN
            "OPT_OUT" -> RecordingConsentAnswer.OPTED_OUT
            else -> null
        }

        val callData = CallDataBuilder.create(digitalLineName)
                .recordingConsentAnswer(consent)
                .build()

        if (
                ContextCompat.checkSelfPermission(
                        plugin.activity!!,
                        Manifest.permission.RECORD_AUDIO) !=
                PackageManager.PERMISSION_GRANTED
        ) {
            ActivityCompat.requestPermissions(
                    plugin.activity!!,
                    arrayOf(Manifest.permission.RECORD_AUDIO),
                    0
            )

        }



        GlobalScope.launch {
            var error: String? = null

            when (val result = plugin.talk?.createCall(callData)) {
                is TalkCallResult.Success -> {
                    plugin.talkCall = result.talkCall

                    result.availableAudioDevices.collect { its ->
                        val mAvailableAudioDevices = mutableListOf<Map<String, Any?>>()

                        its.forEach {
                            val name = it.audioOutput.name.uppercase()
                            val type = when (it.audioOutput) {
                                AudioOutput.SPEAKERS -> "BUILT_IN"
                                AudioOutput.HEADSET -> "BUILT_IN"
                                AudioOutput.BLUETOOTH -> "BLUETOOTH"
                                else -> "UNKNOWN"
                            }
                            val audioDict = mutableMapOf<String, Any?>()
                            audioDict["name"] = name
                            audioDict["type"] = type
                            mAvailableAudioDevices.add(audioDict)
                        }
                        plugin.availableAudioDevices = mAvailableAudioDevices
                    }
                    
                    result.statusChanges.collect {
                        val callStatus = when (it) {
                            CallStatus.CALL_CONNECTED -> "CONNECTED"
                            CallStatus.CALL_DISCONNECTED -> "DISCONNECTED"
                            CallStatus.CALL_DISCONNECTED_CONNECTION_ERROR -> "FAILED"
                            CallStatus.CALL_FAILED -> "FAILED"
                            CallStatus.CALL_RECONNECTING -> "RECONNECTING"
                            CallStatus.CALL_RECONNECTED -> "RECONNECTED"
                            else -> "UNKNOWN"
                        }
                        print(it)

                        val dictionary = mutableMapOf<String, Any?>()
                        dictionary["error"] = null
                        dictionary["callStatus"] = callStatus

                        plugin.activity?.runOnUiThread {
                            channel.invokeMethod("sendTalkCall", dictionary)
                        }
                    }

                }
                TalkCallResult.Failure.DigitalLineNotFound -> error = "DigitalLineNotFound"
                else -> error = "UNKNOWN"
            }

            if(error != null) {
                val dictionary = mutableMapOf<String, Any?>()
                dictionary["error"] = error
                dictionary["callStatus"] = "UNKNOWN"
                plugin.activity?.runOnUiThread {
                    channel.invokeMethod("sendTalkCall", dictionary)
                }
            }
        }
    }

    fun toggleMute(): Map<String, Any?> {
        var isMuted = plugin.talkCall?.isMuted() ?: false
        isMuted = !isMuted
        plugin.talkCall?.mute(isMuted)

        val dictionary = mutableMapOf<String, Any?>()
        dictionary["isMuted"] = isMuted
        return dictionary
    }

    fun toggleOutput(): Map<String, Any?> {
        var isSpeaker = plugin.talkCall?.getAudioOutput() == AudioOutput.SPEAKERS

        val audioOutput = if (isSpeaker) AudioOutput.BLUETOOTH else AudioOutput.SPEAKERS
        plugin.talkCall?.setAudioOutput(audioOutput)

        isSpeaker = !isSpeaker

        val dictionary = mutableMapOf<String, Any?>()
        dictionary["isSpeaker"] = isSpeaker
        return dictionary
    }

    fun disconnect() {
        plugin.talkCall?.disconnect()
        plugin.talkCall = null
    }


}
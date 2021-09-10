//
//  SwiftZendesk2Talk.swift
//  zendesk2
//
//  Created by Adrian Kohls on 08/09/21.
//

import Flutter
import Foundation
import AVFoundation
import ZendeskCoreSDK
import TalkSDK

public class SwiftZendesk2Talk {
    
    private var channel: FlutterMethodChannel? = nil
    private var zendeskPlugin: SwiftZendesk2Plugin? = nil
    
    init(channel: FlutterMethodChannel, flutterPlugin: SwiftZendesk2Plugin) {
        self.channel = channel
        self.zendeskPlugin = flutterPlugin
    }
    
    func initialize(_ arguments: Dictionary<String, Any>?) -> Void {
        var success = false
        let appId = (arguments?["appId"] ?? "") as? String
        let clientId = (arguments?["clientId"] ?? "") as? String
        let zendeskUrl = (arguments?["zendeskUrl"] ?? "") as? String
        
        let token = arguments?["token"] as? String
        let name = arguments?["name"] as? String
        let email = arguments?["email"] as? String
        
        if appId != nil && clientId != nil && zendeskUrl != nil {
            Zendesk.initialize(appId: appId!, clientId: clientId!, zendeskUrl: zendeskUrl!)
            
            let zendesk = Zendesk.instance
            
            let identity: Identity = token != nil ?
                Identity.createJwt(token: token!) :
                Identity.createAnonymous(name: name, email: email)
            
            zendesk?.setIdentity(identity)
            
            if zendesk != nil {
                zendeskPlugin?.talk = Talk(zendesk: zendesk!)
                
                success = true
            }
        }
        if !success {
            NSLog("Could not initialize Talk SDK")
        }
    }
    
    func recordingPermission() -> Dictionary<String, Any?> {
        
        var talkPermission: String? = nil
        switch AVAudioSession.sharedInstance().recordPermission {
        case .undetermined:
            talkPermission = "UNDETERMINED"
            break;
        case .denied:
            talkPermission = "DENIED"
            break;
        case .granted:
            talkPermission = "GRANTED"
            break;
        @unknown default:
            talkPermission = "UNKNOWN"
        }
        
        var dictionary = [String:Any]()
        dictionary["talkPermission"] = talkPermission
        return dictionary
    }
    
    func checkAvailability(_ arguments: Dictionary<String, Any>?) -> Void {
        let digitalLineName = (arguments?["digitalLineName"] ?? "") as! String
        
        zendeskPlugin?.talk?.lineStatus(digitalLine: digitalLineName, completion: { (result) in
            let isAgentAvailable: Bool
            let recordingConsent: RecordingConsent
            var error: String? = nil
            
            switch result {
            
            case .success(let lineStatus):
                isAgentAvailable = lineStatus.agentAvailable
                recordingConsent = lineStatus.recordingConsent
            case .failure(let agentStatusError):
                isAgentAvailable = false
                recordingConsent = .unknown
                error = agentStatusError.description
            }
            
            let consent: String
            switch recordingConsent {
            case .optIn:
                consent = "OPT_IN"
            case .optOut:
                consent = "OPT_OUT"
            case .unknown:
                consent = "UNKNOWN"
            @unknown default:
                consent = "UNKNOWN"
            }
            
            var dictionary = [String:Any]()
            
            dictionary["error"] = error
            dictionary["isAgentAvailable"] = isAgentAvailable
            dictionary["recordingConsent"] = consent
            
            self.channel?.invokeMethod("sendTalkAvailability", arguments: dictionary)
        })
    }
    
    func call(_ arguments: Dictionary<String, Any>?) -> Void {
        let digitalLineName = (arguments?["digitalLineName"] ?? "") as! String
        let recordingConsentAnswer = (arguments?["recordingConsentAnswer"] ?? "") as! String
        
        let consent: RecordingConsentAnswer
        
        switch recordingConsentAnswer {
        case "OPT_IN":
            consent = RecordingConsentAnswer.optedIn
        case "OPT_OUT":
            consent = RecordingConsentAnswer.optedOut
        default:
            consent = RecordingConsentAnswer.unknown
        }
        
        let callData = TalkCallData(digitalLine: digitalLineName, recordingConsentAnswer: consent)
        
        zendeskPlugin?.talkCall = zendeskPlugin?.talk?.call(callData: callData, statusChangeHandler: { (status, error) in
            
            let callStatus: String
            switch status {
            case .connecting:
                callStatus = "CONNECTING"
                break
            case .connected:
                callStatus = "CONNECTED"
                break
            case .disconnected:
                callStatus = "DISCONNECTED"
                break
            case .failed:
                callStatus = "FAILED"
                break
            case .reconnecting:
                callStatus = "RECONNECTING"
                break
            case .reconnected:
                callStatus = "RECONNECTED"
                break
            default:
                callStatus = "UNKNOWN"
                break
            }
            
            var dictionary = [String:Any]()
            
            dictionary["error"] = error?.description
            dictionary["callStatus"] = callStatus
            
            self.channel?.invokeMethod("sendTalkCall", arguments: dictionary)
        })
    }
    
    func toggleMute() -> Dictionary<String, Any?> {
        let isMuted = zendeskPlugin?.talkCall?.muted ?? false
        zendeskPlugin?.talkCall?.muted = !isMuted
        
        var dictionary = [String:Any]()
        dictionary["isMuted"] = zendeskPlugin?.talkCall?.muted ?? false
        return dictionary
    }
    
    func toggleOutput() -> Dictionary<String, Any?> {
        let isSpeaker = zendeskPlugin?.talkCall?.audioOutput == .speaker
        zendeskPlugin?.talkCall?.audioOutput = isSpeaker ? .headset : .speaker
        
        var dictionary = [String:Any]()
        dictionary["isSpeaker"] = zendeskPlugin?.talkCall?.audioOutput == .speaker
        return dictionary
    }
    
    func availableAudioRoutingOptions() -> Dictionary<String, Any?> {
        
        var mAvailableRoutingOptions = Array<Dictionary<String, Any>>()
        
        for option in zendeskPlugin?.talkCall?.availableAudioRoutingOptions ?? [] {
    
            let name = option.name
            
            let type: String
            switch option.type {
            case .bluetooth:
                type = "BLUETOOTH"
                break;
            case .builtIn:
                type = "BUILT_IN"
                break;
            default:
                type = "UNKNOWN"
                break
            }
    
            var optionDict = [String:Any]()
            
            optionDict["name"] = name
            optionDict["type"] = type
            
            mAvailableRoutingOptions.append(optionDict)
        }
        
        
        var dictionary = [String:Any]()
        
        dictionary["availableAudioRoutingOptions"] = mAvailableRoutingOptions
        
        return dictionary
    }
    
    
    func disconnect() -> Void {
        zendeskPlugin?.talkCall?.disconnect()
        zendeskPlugin?.talkCall = nil
    }
}

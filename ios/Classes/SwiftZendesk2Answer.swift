//
//  SwiftZendesk2Answer.swift
//  zendesk2
//
//  Created by Adrian Kohls on 12/08/21.
//
import Flutter
import Foundation
import ZendeskCoreSDK
import SupportProvidersSDK
import AnswerBotProvidersSDK

public class SwiftZendesk2Answer {
    
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
        
        if appId != nil && clientId != nil && zendeskUrl != nil {
            Zendesk.initialize(appId: appId!, clientId: clientId!, zendeskUrl: zendeskUrl!)
                
            let zendesk = Zendesk.instance
            
            if zendesk != nil {
                Support.initialize(withZendesk: zendesk)
                
                let support = Support.instance
                
                if support != nil {
                    Support.initialize(withZendesk: zendesk!)
                    AnswerBot.initialize(withZendesk: zendesk!, support: support!)
                    success = true
                }
            }
        }
        if !success {
            NSLog("Could not initialize Answer SDK")
        }
    }
    
    private func sendAnswerProviderModel(_ arguments: Dictionary<String, Any>?) -> Void {
        self.channel?.invokeMethod("sendAnswerProviderModel", arguments: arguments)
    }
    private func sendResolveArticleDeflection(_ arguments: Dictionary<String, Any>?) -> Void {
        self.channel?.invokeMethod("sendResolveArticleDeflection", arguments: arguments)
    }
    private func sendRejectArticleDeflection(_ arguments: Dictionary<String, Any>?) -> Void {
        self.channel?.invokeMethod("sendRejectArticleDeflection", arguments: arguments)
    }
    
    func deflectionQuery(_ arguments: Dictionary<String, Any>?) -> Void {
        let query: String = (arguments?["query"] ?? "") as! String
        
        let answerBotProvider: AnswerBotProvider? = AnswerBot.instance?.provider
        answerBotProvider?.getDeflectionForQuery(query: query, callback: { result in
            switch result {
            case .success(let deflectionResponse):
                
                var dictionary = [String: Any]()
                
                let deflection = deflectionResponse.deflection
                let articles = deflectionResponse.deflectionArticles
                
                dictionary["interactionAccessToken"] = deflectionResponse.interactionAccessToken
                dictionary["deflectionId"] = deflection.deflectionID
                dictionary["description"] = deflectionResponse.description
                
                var mArticles = Array<Dictionary<String, Any>>()
                
                for article in articles {
                    var mArticle = [String: Any]()
                    
                    mArticle["deflectionArticleId"] = article.id
                    mArticle["brandId"] = article.brandId
                    mArticle["articleId"] = article.articleId
                    mArticle["body"] = article.body
                    mArticle["htmlURL"] = article.htmlURL
                    mArticle["labels"] = article.labelNames
                    mArticle["locale"] = article.locale
                    mArticle["score"] = article.score
                    mArticle["snippet"] = article.snippet
                    mArticle["title"] = article.title
                    mArticle["url"] = article.url
                    
                    mArticles.append(mArticle)
                }
                
                dictionary["articles"] = mArticles
                
                self.sendAnswerProviderModel(dictionary)
            case .failure(let error):
                NSLog(error.localizedDescription)
            }
        })
    }
    
    private func resolveArticleDeflection(_ arguments: Dictionary<String, Any>?) -> Void {
        let deflectionId = arguments?["deflectionId"]
        let articleId = arguments?["articleId"]
        let interactionAccessToken = arguments?["interactionAccessToken"]
        
        if deflectionId != nil && articleId != nil && interactionAccessToken != nil {
            if(deflectionId is Int64 && articleId is Int64 && interactionAccessToken is String){
                let answerBotProvider: AnswerBotProvider? = AnswerBot.instance?.provider
                answerBotProvider?.resolveWithArticle(deflectionId: deflectionId as! Int64, articleId: articleId as! Int64, interactionAccessToken: interactionAccessToken as! String, callback: { result in
                    var dictionary = [String: Any]()
                    switch result {
                    case .success(let response):
                        dictionary["success"] = true
                        NSLog("Success resolved article deflection: %@", response)
                    case .failure(let error):
                        dictionary["success"] = false
                        NSLog("Error resolving article deflection: %@", error.localizedDescription)
                    }
                    self.sendResolveArticleDeflection(dictionary)
                })}
        }
    }
    
    private func rejectArticleDeflection(_ arguments: Dictionary<String, Any>?) -> Void {
        let deflectionId = arguments?["deflectionId"]
        let articleId = arguments?["articleId"]
        let interactionAccessToken = arguments?["interactionAccessToken"]
        let reason = (arguments?["reason"] ?? "") as! String
        
        let mReason: RejectionReason = {
            switch reason {
            case "notRelated": return RejectionReason.notRelated
            case "relatedButDidntAnswer": return RejectionReason.relatedButDidntAnswer
            default: return RejectionReason.unknown
            }
        }()
        
        if deflectionId != nil && articleId != nil && interactionAccessToken != nil {
            if(deflectionId is Int64 && articleId is Int64 && interactionAccessToken is String){
                let answerBotProvider: AnswerBotProvider? = AnswerBot.instance?.provider
                answerBotProvider?.rejectWithArticle(deflectionId: deflectionId as! Int64, articleId: articleId as! Int64, interactionAccessToken: interactionAccessToken as! String, reason: mReason, callback: { result in
                    var dictionary = [String: Any]()
                    switch result {
                    case .success(let response):
                        dictionary["success"] = true
                        NSLog("Success rejecting article deflection: %@", response)
                    case .failure(let error):
                        dictionary["success"] = false
                        NSLog("Error rejecting article deflection: %@", error.localizedDescription)
                    }
                    self.sendRejectArticleDeflection(arguments)
                })
            }
        }
    }
}

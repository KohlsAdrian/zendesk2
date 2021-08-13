//
//  SwiftZendesk2Answer.swift
//  zendesk2
//
//  Created by Adrian Kohls on 12/08/21.
//
import AnswerBotProvidersSDK
import Flutter
import Foundation
import ZendeskCoreSDK
import SupportProvidersSDK

public class SwiftZendesk2Answer {
    
    private var channel: FlutterMethodChannel
    
    private let answerBotProvider: AnswerBotProvider? = AnswerBot.instance?.provider
    
    private var dictionaryAnswerProviderModel: Dictionary<String, Any>? = nil
    private var resolveArticleDeflection: Bool? = nil
    private var rejectArticleDeflection: Bool? = nil
    
    init(channel: FlutterMethodChannel) {
        self.channel = channel
    }
    
    func initialize(_ arguments: Dictionary<String, Any>?) -> Void {
        let appId = (arguments?["appId"] ?? "") as? String
        let clientId = (arguments?["clientId"] ?? "") as? String
        let zendeskUrl = (arguments?["zendeskUrl"] ?? "") as? String
        
        if clientId != nil && zendeskUrl != nil {
            Zendesk.initialize(appId: appId!, clientId: clientId!, zendeskUrl: zendeskUrl!)
            Support.initialize(withZendesk: Zendesk.instance!)
            AnswerBot.initialize(withZendesk: Zendesk.instance, support: Support.instance!)
        }
    }
    
    func dispose() -> Void {
        self.dictionaryAnswerProviderModel = nil
        self.resolveArticleDeflection = nil
        self.rejectArticleDeflection = nil
    }
    
    func getAnswerProviders() -> Dictionary<String, Any>? {
        let mDictionary = self.dictionaryAnswerProviderModel
        self.dictionaryAnswerProviderModel = nil
        return mDictionary
    }
    
    func getResolveArticleDeflection() -> Dictionary<String, Any>? {
        var dictionary = [String: Any]()
        let success = Bool(self.resolveArticleDeflection ?? false)
        self.resolveArticleDeflection = nil
        dictionary["success"] = success
        return dictionary
    }
    
    func getRejectArticleDeflection() -> Dictionary<String, Any>? {
        var dictionary = [String: Any]()
        let success = Bool(self.rejectArticleDeflection ?? false)
        self.rejectArticleDeflection = nil
        dictionary["success"] = success
        return dictionary
    }
    
    private func sendAnswerProviderModel() -> Void {
        channel.invokeMethod("sendAnswerProviderModel", arguments: nil)
    }
    private func sendResolveArticleDeflection() -> Void {
        channel.invokeMethod("sendResolveArticleDeflection", arguments: nil)
    }
    private func sendRejectArticleDeflection() -> Void {
        channel.invokeMethod("sendRejectArticleDeflection", arguments: nil)
    }
    
    func deflectionQuery(_ arguments: Dictionary<String, Any>?) -> Void {
        let query: String = (arguments?["query"] ?? "") as! String
        
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
                
                self.dictionaryAnswerProviderModel = dictionary
            case .failure(let error):
                NSLog(error.localizedDescription)
                self.dictionaryAnswerProviderModel = nil
            }
            self.sendAnswerProviderModel()
        })
    }
    
    private func resolveArticleDeflection(_ arguments: Dictionary<String, Any>?) -> Void {
        let deflectionId = arguments?["deflectionId"]
        let articleId = arguments?["articleId"]
        let interactionAccessToken = arguments?["interactionAccessToken"]
        
        if deflectionId != nil && articleId != nil && interactionAccessToken != nil {
            if(deflectionId is Int64 && articleId is Int64 && interactionAccessToken is String){
                answerBotProvider?.resolveWithArticle(deflectionId: deflectionId as! Int64, articleId: articleId as! Int64, interactionAccessToken: interactionAccessToken as! String, callback: { result in
                    switch result {
                    case .success(let response):
                        self.resolveArticleDeflection = true
                        NSLog("Success resolved article deflection: %@", response)
                    case .failure(let error):
                        self.resolveArticleDeflection = false
                        NSLog("Error resolving article deflection: %@", error.localizedDescription)
                    }
                    self.sendResolveArticleDeflection()
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
                answerBotProvider?.rejectWithArticle(deflectionId: deflectionId as! Int64, articleId: articleId as! Int64, interactionAccessToken: interactionAccessToken as! String, reason: mReason, callback: { result in
                    switch result {
                    case .success(let response):
                        self.rejectArticleDeflection = true
                        NSLog("Success rejecting article deflection: %@", response)
                    case .failure(let error):
                        self.rejectArticleDeflection = false
                        NSLog("Error rejecting article deflection: %@", error.localizedDescription)
                    }
                    self.sendRejectArticleDeflection()
                })
            }
        }
    }
}

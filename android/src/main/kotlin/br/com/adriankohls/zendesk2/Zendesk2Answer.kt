package br.com.adriankohls.zendesk2

import com.zendesk.service.ErrorResponse
import com.zendesk.service.ZendeskCallback
import io.flutter.plugin.common.MethodChannel
import zendesk.answerbot.AnswerBot
import zendesk.answerbot.DeflectionResponse

class Zendesk2Answer(private val channel: MethodChannel) {
    val provider = AnswerBot.INSTANCE.provider();

    fun deflectionQuery(query: String){
        provider?.getDeflectionForQuery(query, object : ZendeskCallback<DeflectionResponse>(){
            override fun onSuccess(success: DeflectionResponse?) {
                val deflection = success?.deflection
                val articles = success?.deflectionArticles

            }

            override fun onError(error: ErrorResponse?) {
                TODO("Not yet implemented")
            }
        })
    }
}
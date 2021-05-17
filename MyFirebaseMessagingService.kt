package br.com.adriankohls.zendesk2.fcm

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.media.RingtoneManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import br.com.adriankohls.zendesk2.R
import zendesk.chat.Chat
import zendesk.chat.PushData


class MyFirebaseMessagingService : FirebaseMessagingService() {


    override fun onNewToken(token: String) {
        Chat.INSTANCE.providers()?.pushNotificationsProvider()?.registerPushToken(token)
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {

        val pushProvider = Chat.INSTANCE.providers()?.pushNotificationsProvider()

        if (pushProvider != null) {
            val pushData = pushProvider.processPushNotification(remoteMessage.data)

            pushData?.let {

                when (it.type) {
                    PushData.Type.MESSAGE -> {
                        val builder = NotificationCompat.Builder(this, createNotificationChannel())
                                .setSmallIcon(android.R.drawable.stat_notify_chat)
                                .setContentTitle(it.author)
                                .setContentText(it.message)
                                .setPriority(NotificationCompat.PRIORITY_HIGH)
                                .setAutoCancel(true)
                                .setVibrate(longArrayOf(0, 500, 100, 500))
                                .setSound(RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION))
                        with(NotificationManagerCompat.from(this)) {
                            // notificationId is a unique int for each notification that you must define
                            notify(101, builder.build())
                        }
                    }
                    else -> {
                    }
                }
            }
        }
    }

    private fun createNotificationChannel(): String {
        val supportChannel = "support_channel"
        // Create the NotificationChannel, but only on API 26+ because
        // the NotificationChannel class is new and not in the support library
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {

            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(supportChannel, "chat", importance)
            // Register the channel with the system
            val notificationManager: NotificationManager =
                    getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
        return supportChannel
    }
}
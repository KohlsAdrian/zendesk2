![](zendesk2.jpg)

```text
An Android and iOS SDK port of Zendesk for Flutter

Android min SDK 16 and iOS min OS Version 10.0

Easy and fast to use
````

# Setup ( `yourdomain` - your company zendesk domain)

* AccountKey - https://yourdomain.zendesk.com/chat/agent#home > Profile Picture > Check Connection

* AppId - https://yourdomain.zendesk.com/agent/admin/mobile_sdk
 
* Update Cocoapods to latest version


## Initialize the Zendesk SDK

```dart
await Zendesk2.instance.init(accountKey, appId);
```

````dart
final z = Zendesk2.instance; // General Zendesk

await z.initChatSDK(); // initialize the Chat SDK
await z.initAnswerSDK(); // initialize the Answer SDK

final zChat = Zendesk2Chat.instance; // Zendesk Chat Providers
final zAnswer = Zendesk2Answer.instance; // Zendesk Answer Providers
````

<details><summary>How to use - Chat SDK V2</summary>

```dart
/// Zendesk Chat instance
Zendesk2Chat zChat = Zendesk2Chat.instance;

/// Optional Visitor Info information
await zChat.setVisitorInfo(
    name: name,
    email: email,
    phoneNumber: phoneNumber,
  );

/// Very important, for custom UI, prepare Stream for ProviderModel
await zChat.startChatProviders();

/// Get the updated provider Model from the SDK
_subscription = zChat.providersStream.listen((providerModel) {
  /// this stream retrieve all Chat data and Logs from the SDK
  /// in ONE unique reliable object :)
  _providerModel = providerModel;
});

/// It is also important to disconnect and reconnect 
/// and when the app enters and exits background, 
/// to do this you can simply calll
await zChat.disconnect();
/// or
await zChat.connect(); 

/// After you release resources
await zChat.dispose();
```
</details>

<details><summary>How to use - Answer SDK</summary>

```dart

```
</details>


# Push Notifications

To configure chat notifications, you will need to do the following configuration per platform

<details><summary> iOS </summary>

  Inside your `AppDelegate.swift` import the ChatSDK as 
  
  ```swift
  import ChatProvidersSDK
  ```

  Add the following method
  ``` swift
    override func application(
      _ application: UIApplication, 
      didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // You might already have this if you are using firebase messaging
        // Messaging.messaging().apnsToken = deviceToken  
        
        Chat.registerPushToken(deviceToken)
    }
  ```
</details>

<details><summary> Android </summary>

Using FCM messaging, get your FCM token and register it as follows:

``` dart
Zendesk2Chat zChat = Zendesk2Chat.instance;
await zChat.registerFCMToken(fcmToken);
```
(calling this function has no effect on iOS)

To display the notifications, you will need to register your own `FirebaseMessagingService` as a service inside the `application`. You can follow the Firebase Android Docs for this. An example file that you can copy and customize can be found in the main github repo. Overally you will add the file to your application and register the service as follows:

``` xml
<service
    android:name="{your package name}"
    android:stopWithTask="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</service>
```
</details>
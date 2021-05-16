![](zendesk2.jpg)

An Android and iOS SDK port of Zendesk for Flutter

Easy and fast to use

# Setup for Native Chat

<details>
  <summary>Android Min SDK - 21</summary>


  android/app/src/main/res/values/styles.xml
  
  Add the following style

        <style name="ZendeskTheme" parent="ZendeskSdkTheme.Light">    
          <item name="colorPrimary">#FF5148</item>
          <item name="colorPrimaryDark">#FF5148</item>
          <item name="colorAccent">#FF5148</item>
        </style>


  android/app/src/main/AndroidManifest.xml

  Inside <application> tag, insert the following Activity


        <activity android:name="zendesk.messaging.MessagingActivity"
            android:theme="@style/ZendeskTheme" />

</details>

<details>
  <summary>iOS Min OS Version - 10.0</summary>
  
  In AppDelegate.swift should look like this
  
    override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
      GeneratedPluginRegistrant.register(with: self)
    
      //Snippet to make rootView as navigatable
      let flutterViewController = window?.rootViewController as! FlutterViewController
      let navigationController = UINavigationController.init(rootViewController: flutterViewController)
      navigationController.isNavigationBarHidden = true
      window.rootViewController = navigationController
      window.makeKeyAndVisible()

      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
  
  You can have pre loaded localization with "Localizable.string"
  
  See [example/ios/Runnner/Localizable.string](https://github.com/KohlsAdrian/zendesk2/blob/main/example/ios/Runner)
  
  See: https://developer.zendesk.com/embeddables/docs/ios_support_sdk/localize_text
  
</details>

# Setup for custom UI

    /// Zendesk Chat instance
    Zendesk2Chat z = Zendesk2Chat.instance;

    /// Initialize Zendesk SDK
    await z.init(
      accountKey,
      appId,
      iosThemeColor: Constants.IZA_YELLOW,
    );
    
    /// Optional Visitor Info information
    await z.setVisitorInfo(
        name: name,
        email: email,
        phoneNumber: phoneNumber,
      );
      
    /// Very important, for custom UI, prepare Stream for ProviderModel
    await z.startChatProviders();
    
    /// Get the updated provider Model from SDK
    z.providersStream.listen((providerModel) {
      /// this stream retrieve all Chat data and Logs from SDK
      _providerModel = providerModel;
    });
    /// It is also important to disconnect and reconnect and when the app enters  and exits background, to do this you can simply calll
    z.disconnect() 
    z.connect()
# Push Notifications
   To configure chat notifications, you will need to do the following configuration per platform

## iOS
  Inside your AppDelegate.swift import the ChatSdk
  `import ChatProvidersSDK`

  Add the following method
  ``` swift
    override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        //Messaging.messaging().apnsToken = deviceToken  /// You might already have this if you are using firebase messaging
        
        Chat.registerPushToken(deviceToken)
    }
  ```
### Android

Using FCM messaging, get your FCM token and register it as follows:
``` dart
Zendesk2Chat z = Zendesk2Chat.instance;
await z.registerFCMToken(fcmToken);
```
(calling this function has no effect on iOS)

To display the notifications, you will need to register your own `FirebaseMessagingService` as a service inside the `application` tag of android/app/src/main/AndroidManifest.xml

``` xml
<service
    android:name="br.com.adriankohls.zendesk2.fcm"
    android:stopWithTask="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</service>
```
You can use the one mentioned above or you can copy the file to create your own service that better fits your needs.


# What you need

 * AccountKey

 * AppId
 
 * Update Cocoapods to latest version

# STATUS

  Chat SDK

    Live Chat, Customization and Providers for custom UI
  
    Live Chat - OK
    Support SDK - OK
    Customization - OK
    
# Far development

  Unified SDK

  Answer BOT SDK
  
  Talk SDK

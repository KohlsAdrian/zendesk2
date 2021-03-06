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

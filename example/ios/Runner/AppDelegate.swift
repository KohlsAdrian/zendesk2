import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    private var navigationController: UINavigationController? = nil
    
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    //Snippet to make rootView as navigatable
    let flutterViewController = window?.rootViewController as! FlutterViewController
    let navigationController = UINavigationController.init(rootViewController: flutterViewController)
    navigationController.isNavigationBarHidden = true
    window.rootViewController = navigationController
    window.makeKeyAndVisible()
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

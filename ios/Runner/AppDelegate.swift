import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // تأخير تسجيل Plugins حتى يكتمل تهيئة FlutterEngine
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    
    // تهيئة النافذة وإظهارها
    self.window?.makeKeyAndVisible()
    
    // تسجيل الـ plugins بشكل آمن
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      GeneratedPluginRegistrant.register(with: self)
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

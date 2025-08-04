import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var googleMapsApiKey: String = "YOUR KEY HERE"
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // Flutter MethodChannel 설정
    let controller = window?.rootViewController as! FlutterViewController
    let envChannel = FlutterMethodChannel(
      name: "com.moonspace.pj_trip/env",
      binaryMessenger: controller.binaryMessenger
    )
    
    envChannel.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "setEnvData":
        if let args = call.arguments as? [String: Any] {
          self?.handleEnvData(args)
          result(true)
        } else {
          result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func handleEnvData(_ data: [String: Any]) {
    // Google Maps API 키 설정
    if let apiKey = data["googleMapsApiKey"] as? String, !apiKey.isEmpty {
      self.googleMapsApiKey = apiKey
      GMSServices.provideAPIKey(apiKey)
      NSLog("Google Maps API 키가 Flutter에서 전달받았습니다: \(apiKey)")
    } else {
      // 기본값 사용
      GMSServices.provideAPIKey(googleMapsApiKey)
      NSLog("Google Maps API 키가 전달되지 않아 기본값을 사용합니다.")
    }
    
    // 다른 환경변수들도 필요에 따라 사용
    if let naverClientKey = data["naverMapClientKey"] as? String {
      NSLog("Naver Map Client Key: \(naverClientKey)")
    }
  }
}

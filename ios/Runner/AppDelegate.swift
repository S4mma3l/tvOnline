import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    excludePreferencesFromiCloudBackup()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  // Prevents SharedPreferences (NSUserDefaults) from being backed up to iCloud.
  // Without this, credentials could be restored when the app is reinstalled from iCloud.
  private func excludePreferencesFromiCloudBackup() {
    guard let bundleID = Bundle.main.bundleIdentifier,
          let libraryURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first else {
      return
    }
    let prefsURL = libraryURL.appendingPathComponent("Preferences/\(bundleID).plist")
    var resourceValues = URLResourceValues()
    resourceValues.isExcludedFromBackup = true
    var mutableURL = prefsURL
    try? mutableURL.setResourceValues(resourceValues)
  }
}

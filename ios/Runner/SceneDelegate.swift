import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  private var cover: UIView?

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    // iOS cannot block screenshots, but it can tell us when the screen is being recorded/mirrored.
    NotificationCenter.default.addObserver(
      self, selector: #selector(updateCover), name: UIScreen.capturedDidChangeNotification, object: nil)
    // Also hide content in the app switcher.
    NotificationCenter.default.addObserver(
      self, selector: #selector(updateCover), name: UIApplication.willResignActiveNotification, object: nil)
    NotificationCenter.default.addObserver(
      self, selector: #selector(updateCover), name: UIApplication.didBecomeActiveNotification, object: nil)
    updateCover()
  }

  @objc private func updateCover() {
    let shouldCover = UIScreen.main.isCaptured || UIApplication.shared.applicationState != .active
    guard let window = self.window else { return }
    if shouldCover {
      if cover == nil {
        let v = UIView(frame: window.bounds)
        v.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        v.backgroundColor = UIColor(red: 0.06, green: 0.16, blue: 0.36, alpha: 1)
        cover = v
      }
      if let v = cover, v.superview == nil { window.addSubview(v) }
    } else {
      cover?.removeFromSuperview()
    }
  }
}

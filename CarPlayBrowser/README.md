# CarPlay Browser — Hướng Dẫn Tích Hợp & Chạy Dự Án Trong Xcode

Dự án iOS Swift hoàn chỉnh tích hợp Apple CarPlay, cho phép xem video YouTube và duyệt web Google trực tiếp trên màn hình ô tô với giao diện cảm ứng tối ưu, chặn quảng cáo và điều khiển qua phím vô lăng.

---

## 📁 Cấu Trúc Mã Nguồn

```
CarPlayBrowser/
├── App/
│   ├── AppDelegate.swift                       # Vòng đời ứng dụng & khởi tạo AudioSession
│   ├── SceneDelegate.swift                      # Điều phối màn hình iPhone Companion
│   └── CarPlaySceneDelegate.swift              # Quản lý CPTemplateApplicationScene & CPWindow
├── CarPlay/
│   ├── Menu/
│   │   ├── CarPlayMenuCoordinator.swift        # Điều phối sự kiện chọn YouTube / Google
│   │   └── CarPlayMenuTarget.swift             # Định nghĩa điểm đến & URL
│   ├── Templates/
│   │   └── CarPlayTemplateFactory.swift        # Khởi tạo CPGridTemplate chuẩn ô tô
│   └── Window/
│       └── CarPlayWindowManager.swift          # Gắn/Gỡ CarPlayWebViewController trên CPWindow
├── Browser/
│   ├── Configuration/
│   │   ├── CarPlayUserAgentManager.swift       # Chuyển đổi User-Agent Desktop Safari / Mobile
│   │   └── InCarWebViewConfiguration.swift     # WKWebViewConfiguration (inline media, adblock)
│   ├── ContentFilter/
│   │   ├── AdBlockRuleManager.swift            # Biên dịch WKContentRuleListStore chặn network ads
│   │   ├── YouTubeAdFilterScripts.swift        # UserScript CSS hiding & JS auto-skip video ads
│   │   └── Resources/adblock_rules.json        # 12 rule chặn domain quảng cáo & tracker
│   ├── Controllers/
│   │   └── CarPlayWebViewController.swift      # Trình duyệt web ô tô cảm ứng toàn màn hình
│   ├── Views/
│   │   └── InCarNavigationToolbar.swift        # Thanh điều hướng cảm ứng (Back/Fwd/Reload/Desktop/Close)
│   └── Scripts/
│       └── YouTubeAdHider.js                   # Script DOM injection xử lý YouTube Ads
├── Media/
│   ├── AudioSessionManager.swift               # Quản lý AVAudioSession .playback, interruption & route
│   ├── RemoteCommandCenterManager.swift        # Xử lý phím bấm vô lăng (Play/Pause/Skip/Seek)
│   ├── NowPlayingInfoManager.swift             # Đồng bộ thông tin video lên MPNowPlayingInfoCenter
│   └── YouTubeMediaBridge.swift                # Cầu nối JavaScript 2 chiều giữa WebView và Swift
├── PhoneUI/
│   └── PhoneMainViewController.swift           # Màn hình điều khiển đồng hành trên iPhone
├── Shared/
│   ├── Constants.swift                         # URLs, User-Agent, Scene Roles, Notifications
│   └── Extensions/
│       ├── UIImage+CarPlayIcons.swift          # Bộ icon xe hơi độ tương phản cao
│       └── UIView+Autolayout.swift             # Helper AutoLayout
└── Configuration/
    ├── Info.plist                              # Khai báo Multi-Scene và Background Audio
    └── CarPlayBrowser.entitlements             # Entitlement com.apple.developer.carplay-audio
```

---

## 🚀 Các Bước Thiết Lập Trong Xcode Trên macOS

1. **Tạo Xcode Project mới**:
   - Mở Xcode -> **File -> New -> Project...**
   - Chọn template **iOS -> App**.
   - Đặt Product Name: `CarPlayBrowser`.
   - Interface: **Storyboard** (hoặc UIKit App Delegate).
   - Language: **Swift**.

2. **Thêm các tệp nguồn vào Xcode**:
   - Kéo toàn bộ thư mục `CarPlayBrowser` vừa tạo thả vào thanh Project Navigator của Xcode.
   - Chọn mục **Copy items if needed** và **Create groups**.
   - Đảm bảo target `CarPlayBrowser` được tick chọn.

3. **Thiết lập Capabilities & Entitlements**:
   - Chọn Target `CarPlayBrowser` -> Tab **Signing & Capabilities**.
   - Nhấn **+ Capability** -> Chọn **Background Modes** -> Tick vào **Audio, AirPlay, and Picture in Picture**.
   - Chọn file `CarPlayBrowser.entitlements` trong mục Code Signing Entitlements của Build Settings.

4. **Kiểm tra Info.plist**:
   - Đảm bảo mục `UIApplicationSceneManifest` trong Build Settings trỏ đúng vào `Configuration/Info.plist`.

---

## 🚘 Hướng Dẫn Kiểm Thử Trên Xcode Simulator

1. **Khởi chạy iPhone Simulator**:
   - Chọn thiết bị (ví dụ: *iPhone 15 Pro* hoặc *iPhone 16 Pro* chạy iOS 17+).
   - Nhấn **Cmd + R** để build & run.

2. **Mở Màn Hình Apple CarPlay Simulator**:
   - Trên thanh menu của Xcode Simulator, chọn: **I/O -> External Displays -> CarPlay**.
   - Cửa sổ màn hình xe hơi độc lập sẽ xuất hiện.

3. **Trải nghiệm tính năng**:
   - Trên màn hình CarPlay: Nhấn vào icon **CarPlay Browser**.
   - `CPGridTemplate` sẽ xuất hiện với 2 nút lớn: **YouTube** và **Google Search**.
   - Nhấn vào **YouTube**: Trình duyệt sẽ xuất hiện trên màn hình CarPlay, tự động áp dụng User-Agent Desktop Safari, tải video inline, chặn quảng cáo banner và nút bỏ qua quảng cáo tự động kích hoạt.
   - Dùng thanh điều hướng trên cùng để quay lại menu (`✕ Menu`), lùi trang, hoặc chuyển đổi giữa chế độ Desktop và Mobile.
   - Mở Control Center trên iPhone để kiểm tra phím điều khiển Play / Pause / Skip ±10s đồng bộ tức thì với video YouTube trên xe.

# 🎯 NotchBar

MacBook 노치 영역을 활용한 유틸리티 앱 (NotchNook 클론)

## ✨ Features

- **노치 팝업**: 마우스 호버 시 확장 메뉴
- **미디어 컨트롤**: 현재 재생 중인 음악 표시/제어
- **캘린더**: 오늘 일정 표시
- **날씨**: 현재 날씨 + 예보
- **시스템 모니터**: CPU/메모리/배터리
- **빠른 설정**: 밝기, 볼륨, 다크모드

## 🛠️ Requirements

- macOS 12.0+ (Monterey)
- MacBook with Notch (M1 Pro/Max/M2+)
- Xcode 14+

## 📦 Installation

```bash
# Clone
git clone https://github.com/Hbin77/NotchBar.git

# Open in Xcode
open NotchBar.xcodeproj

# Build & Run (⌘R)
```

## 🏗️ Architecture

```
NotchBar/
├── App/
│   ├── NotchBarApp.swift      # 앱 엔트리
│   └── AppDelegate.swift      # 앱 델리게이트
├── Core/
│   ├── NotchDetector.swift    # 노치 영역 감지
│   ├── HoverManager.swift     # 마우스 호버 관리
│   └── WindowManager.swift    # 팝업 윈도우 관리
├── Features/
│   ├── Media/                 # 미디어 컨트롤
│   ├── Calendar/              # 캘린더 위젯
│   ├── Weather/               # 날씨 위젯
│   ├── System/                # 시스템 모니터
│   └── Settings/              # 빠른 설정
├── Views/
│   ├── NotchPopupView.swift   # 메인 팝업 뷰
│   └── Components/            # 재사용 컴포넌트
└── Resources/
    └── Assets.xcassets        # 아이콘/이미지
```

## 📄 License

MIT

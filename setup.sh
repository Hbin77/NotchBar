#!/bin/bash
#
# NotchBar Xcode 프로젝트 생성 스크립트
#
# 사용법:
#   chmod +x setup.sh
#   ./setup.sh
#

set -e

echo "🚀 NotchBar Xcode 프로젝트 생성"
echo "================================"

# Xcode 확인
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode가 설치되어 있지 않습니다."
    exit 1
fi

# 프로젝트 디렉토리
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

echo "📁 프로젝트 경로: $PROJECT_DIR"

# xcodegen 사용 (설치되어 있는 경우)
if command -v xcodegen &> /dev/null; then
    echo "✅ XcodeGen 사용"
    cat > project.yml << 'EOF'
name: NotchBar
options:
  bundleIdPrefix: com.hbin77
  deploymentTarget:
    macOS: "12.0"
  developmentLanguage: ko
  xcodeVersion: "14.0"

settings:
  base:
    PRODUCT_NAME: NotchBar
    MARKETING_VERSION: 1.0.0
    CURRENT_PROJECT_VERSION: 1
    SWIFT_VERSION: "5.9"
    MACOSX_DEPLOYMENT_TARGET: "12.0"

targets:
  NotchBar:
    type: application
    platform: macOS
    sources:
      - NotchBar
    info:
      path: NotchBar/Info.plist
    entitlements:
      path: NotchBar/NotchBar.entitlements
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.hbin77.NotchBar
        CODE_SIGN_STYLE: Automatic
        INFOPLIST_FILE: NotchBar/Info.plist
        CODE_SIGN_ENTITLEMENTS: NotchBar/NotchBar.entitlements
        LD_RUNPATH_SEARCH_PATHS: "@executable_path/../Frameworks"
        ENABLE_HARDENED_RUNTIME: YES
EOF
    xcodegen generate
    echo "✅ NotchBar.xcodeproj 생성 완료"
else
    echo "⚠️ XcodeGen이 설치되어 있지 않습니다."
    echo ""
    echo "📝 수동으로 Xcode 프로젝트 생성:"
    echo "   1. Xcode 열기"
    echo "   2. File > New > Project"
    echo "   3. macOS > App 선택"
    echo "   4. Product Name: NotchBar"
    echo "   5. Interface: SwiftUI"
    echo "   6. Language: Swift"
    echo "   7. 생성 후 NotchBar/ 폴더의 파일들을 프로젝트에 추가"
    echo ""
    echo "🔧 XcodeGen 설치:"
    echo "   brew install xcodegen"
    echo "   ./setup.sh"
fi

echo ""
echo "================================"
echo "✅ 완료!"
echo ""
echo "다음 단계:"
echo "  1. open NotchBar.xcodeproj"
echo "  2. ⌘R로 빌드 및 실행"

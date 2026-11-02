# 내 PC(Windows)에서 FOCUS JESUS 쓰기

이 프로젝트를 Windows 10/11 PC에서 열고, 실행하고, APK를 직접 만드는 방법입니다.
처음 한 번만 1–5단계를 하고, 그다음부터는 6단계의 스크립트만 쓰면 됩니다.

## 0. 받은 패키지 풀기

`FOCUS-JESUS-local-<버전>.zip`을 **영문·공백 없는 경로**에 풉니다. 예: `C:\dev\focus-jesus`
(한글이나 공백이 들어간 경로는 Android 빌드 도구가 실패하는 경우가 있습니다.)

패키지 안에는 다음이 들어 있습니다.

| 경로 | 내용 |
|---|---|
| 프로젝트 전체 | 앱 코드, 원고(시즌 1–3), 테스트, 문서. GitHub 브랜치 `claude/fervent-babbage-2sw71k`와 같은 커밋 |
| `android\key.properties`, `android\app\focusjesus-signing.keystore` | 지금까지 보내 드린 APK와 **같은 서명 키**. 이 PC에서 만든 APK가 폰에 깔린 앱 위에 업데이트로 설치되게 합니다(기록·메모 유지) |
| `release\FOCUS-JESUS-<버전>-arm64-debugsigned.apk` | 바로 설치할 수 있는 완성 APK |

> 서명 키 두 파일은 저장소(GitHub)에 올리지 않습니다(`.gitignore`). 다른 사람과 공유하지 마세요.
> 지금 키는 내부 테스트용 디버그 키입니다. Google Play 출시 때는 정식 업로드 키를 새로 만들어 `key.properties`만 바꾸면 됩니다.

## 1. Git 설치

https://git-scm.com/download/win 에서 설치(기본 옵션 그대로).

## 2. Flutter 설치 (3.47.6 stable)

1. https://docs.flutter.dev/get-started/install/windows 에서 Flutter SDK zip을 받아 `C:\dev\flutter`에 풉니다.
   이 프로젝트는 **Flutter 3.47.6 / Dart 3.13.5**에서 검증했습니다. 다른 버전이 설치되어 있으면
   `C:\dev\flutter` 폴더에서 `git checkout 3.47.6` 으로 맞출 수 있습니다.
2. 시작 메뉴 → "환경 변수" → 사용자 변수 `Path`에 `C:\dev\flutter\bin` 추가.
3. 새 명령 프롬프트에서 `flutter --version` 이 나오면 됩니다.

## 3. Android Studio 설치

1. https://developer.android.com/studio 에서 설치. 처음 실행할 때 나오는 설정 마법사를 끝까지 진행합니다.
2. Android Studio → More Actions → SDK Manager:
   - SDK Platforms: **Android 16 (API 36)**
   - SDK Tools: **Android SDK Build-Tools**, **Android SDK Command-line Tools**, **Android SDK Platform-Tools**
3. 명령 프롬프트에서 `flutter doctor --android-licenses` 를 실행하고 모두 `y`.
   (JDK는 Android Studio에 들어 있는 것을 Flutter가 자동으로 씁니다. 프로젝트는 Java 17 기준입니다.)

## 4. 서명 키 확인

패키지를 풀었다면 이미 들어 있습니다: `android\key.properties`, `android\app\focusjesus-signing.keystore`.
GitHub에서 직접 내려받은 경우에는 이 두 파일이 없으니, 패키지에서 같은 위치로 복사해 넣으세요.
없어도 빌드는 되지만, 그 APK는 폰에 이미 깔린 앱과 서명이 달라 **업데이트 설치가 거부**됩니다.
키 없이 `run_on_phone.bat`(`flutter run`)을 쓰면 Flutter가 기존 앱을 **지우고** 다시 설치하므로 읽은 기록과 메모가 사라집니다.

## 5. 처음 설정

프로젝트 폴더에서 `scripts\windows\setup.bat` 을 더블클릭합니다.
Git·Flutter 확인 → 패키지 내려받기(`flutter pub get`) → 서명 키 확인 → `flutter doctor` 순서로 진행합니다.
`flutter doctor`에서 Android 항목에 ✗가 있으면 3단계를 다시 확인하세요(Visual Studio·Chrome 항목은 이 앱에 필요 없습니다).

## 6. 매일 쓰는 스크립트 (`scripts\windows\`)

| 파일 | 하는 일 |
|---|---|
| `run_on_phone.bat` | USB로 연결한 폰에서 앱 실행(`flutter run --release`) |
| `build_apk.bat` | arm64 APK 빌드 → `release\FOCUS-JESUS-local-arm64.apk` |
| `install_apk.bat` | 만든 APK를 폰에 **업데이트로** 설치(`adb install -r`, 기록·메모 유지) |
| `test.bat` | 코드 분석 + 테스트 + 원고 검증 |

폰 준비: 설정 → 휴대전화 정보 → 소프트웨어 정보 → **빌드번호 7번 탭**(개발자 모드) →
개발자 옵션 → **USB 디버깅** 켜기 → USB로 연결 후 폰에 뜨는 허용 창에서 "허용".

> `flutter install` 은 쓰지 마세요. 기존 앱을 지운 뒤 설치해서 읽은 기록과 메모가 사라질 수 있습니다.

## 7. 최신 작업 받아오기

클라우드에서 작업한 내용은 GitHub 브랜치 `claude/fervent-babbage-2sw71k`에 올라갑니다.

- 처음 한 번 (GitHub 로그인 필요, 비공개 저장소):
  `git clone -b claude/fervent-babbage-2sw71k https://github.com/digilogd-cmd/Focus-Jesus.git`
  → 4단계의 서명 키 두 파일을 복사해 넣기
- 그다음부터: 프로젝트 폴더에서 `git pull` 후 `scripts\windows\setup.bat`

## 8. 이 PC에서 Claude와 함께 작업하려면

지금 클라우드 세션은 Windows PC 폴더에 직접 접근할 수 없습니다(원격 폴더 연결은 Mac·Linux만 지원).
이 PC에서 Claude와 작업하려면 **Claude 데스크톱 앱의 Claude Code**에서 이 프로젝트 폴더를 열면 됩니다.
문서 `docs/YEAR_PLAN.md`(1년 계획·진행 단계), `docs/MASTER_STATE.md`(버전별 기록)를 보면 이어서 작업할 수 있습니다.

## 문제 해결

| 증상 | 해결 |
|---|---|
| `flutter` 를 찾을 수 없음 | 2단계의 Path 추가 후 **새** 명령 프롬프트 열기 |
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | 서명 키가 다름 → 4단계의 두 파일 확인 |
| `Android license status unknown` | `flutter doctor --android-licenses` |
| 빌드가 경로 오류로 실패 | 프로젝트를 `C:\dev\focus-jesus` 같은 영문·공백 없는 경로로 옮기기 |
| 기기가 안 보임 | USB 디버깅 허용 창 확인, 케이블을 데이터 전송용으로, `flutter devices` 로 확인 |

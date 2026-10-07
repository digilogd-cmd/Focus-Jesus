# MASTER_STATE — FOCUS JESUS MVP

마지막 검증 완료 지점에서 다시 시작할 수 있도록 Phase별 실제 결과만 기록합니다.

## 개발 환경 (Phase 0에서 실측)

| 항목 | 값 |
|---|---|
| OS | Ubuntu 24.04.5 LTS, x86_64, 4 vCPU, 15 GB RAM (클라우드 컨테이너) |
| Flutter | 3.47.6 stable (framework 5fc346839b, engine 692136cb65) |
| Dart | 3.13.5 |
| Java | OpenJDK 21.0.12 |
| Android SDK | platform android-36, build-tools 36.0.0, NDK 28.2.13676358 (Gradle이 자동 설치), cmdline-tools 23.0.0 |
| Gradle / AGP / Kotlin | Gradle 9.3.1 wrapper, AGP 9.1.0, Kotlin 2.4.0 |
| SDK 설치 경로 | `/opt/sdk/flutter`, `/opt/sdk/android` (`source /opt/sdk/env.sh`) |
| KVM | **없음** (`/dev/kvm` 부재) → Android 에뮬레이터 하드웨어 가속 불가 |
| 물리 Android 기기 | 없음 (클라우드 컨테이너) |

## Phase 0 — 환경 조사 및 프로젝트 준비 ✅

- 구현: Flutter 프로젝트 생성(android/ios/linux), 패키지 ID `com.focusjesus.story`, minSdk 26, targetSdk 36, compileSdk 36.
  의존성 버전 고정(pubspec에 정확한 버전): flutter_riverpod 3.4.3, go_router 18.0.2, sqflite 2.4.4+1, sqflite_common_ffi 2.4.3,
  shared_preferences 2.5.6, flutter_local_notifications 22.3.1, timezone 0.11.1, flutter_timezone 5.1.1, url_launcher 6.3.3,
  intl 0.20.3, path 1.9.1. 모두 pub.dev 점수 140–160/160, 라이선스 MIT/BSD/Apache-2.0.
- 폰트: Noto Serif KR(OFL, Reserved Font Name 없음) 400/600 정적 인스턴스를 KS X 1001 한글 2,350자 + 라틴/문장부호로 서브셋(각 1.5 MB).
  Pretendard(OFL, Reserved Font Name "Pretendard")는 RFN 조항 때문에 **수정하지 않은 원본** Regular/Medium/SemiBold 사용(각 1.6 MB).
  라이선스 전문: `docs/licenses/`.
- 성경 데이터: 66권 장·절 수 표(KJV 체계, 1,189장 / 31,102절)를 `tool/generate_bible_books.py`로 생성 → `lib/core/bible/bible_books.g.dart`.
  외부 링크: 대한성서공회 개역개정 읽기 페이지(`bskorea.or.kr`), 66권 코드 중 15권 샘플을 실제 요청으로 확인.
- 테스트(실행 결과):
  - `flutter doctor -v`: Flutter ✓, Android toolchain ✓ (licenses accepted). Chrome ✗(웹 미사용), Linux toolchain은 GTK 설치 후 테스트용으로 사용.
  - `flutter pub get`: 성공.
  - `flutter build apk --debug`: **성공** (4분 2초, 150 MB debug APK). `aapt dump badging`: package `com.focusjesus.story`, sdkVersion 26, targetSdkVersion 36.
- 차단 사항: KVM 없음 → 에뮬레이터 구동 검증 불가 가능성 높음(Phase 6에서 실제 시도 후 기록). 물리 기기 없음.
  대안: Linux 데스크톱 타깃(Xvfb)에서 동일 Flutter 코드의 통합 테스트를 실제 실행.
- 다음: Phase 1 디자인 시스템.

## 진행 중 메모
- 콘텐츠(Phase 3) 원고 작성은 일정 단축을 위해 Phase 1–2와 병렬로 시작. 검증 게이트는 Phase 순서대로 통과시킴.

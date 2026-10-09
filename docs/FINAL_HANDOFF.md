# FOCUS JESUS MVP 1.0 — 최종 완료 보고 (FINAL HANDOFF)

작성일: 2026-10-08 · 브랜치: `claude/fervent-babbage-2sw71k`

> **한눈에 보는 완료 상태** — 명세 12장의 원칙대로 다섯 가지 완료 조건을 따로 판정합니다.
>
> | 완료 조건 | 상태 |
> |---|---|
> | 기능 구현 | ✅ 완료 (MVP 범위 전부) |
> | 자동 테스트 | ✅ 단위·위젯 93개 + 통합 2개 전부 통과 |
> | APK 생성 | ✅ Release APK 빌드 성공 (디버그 키 서명 — 출시용 아님) |
> | Android 기기 구동 검증 | ❌ **미완료** — 실기기 없음, 에뮬레이터는 하드웨어 가속 부재로 시스템이 반복 종료(아래 6장) |
> | 신학 검수 | ❌ **미완료** — 전 원고 "신학 검수 대기" (자동 검증만 통과) |

## 1. 최종 구현 기능

- **온보딩**: 이해 수준(입문/성장/심화) → 하루 독서 시간(5/10/15/20분) → 매일 알림 시간(또는 알림 없이 시작). 권한 거부 시에도 정상 진행.
- **오늘**: 날짜, 오늘의 이야기 제목·소개·예상 시간, 단 하나의 주요 행동(`오늘의 이야기 읽기` / `이어서 읽기`), 절제된 진행 문구.
  오늘 읽었으면 "오늘의 이야기를 마쳤습니다" + 조용한 `다음 이야기 읽기 →`(추가 읽기). 놓친 날은 벌점·경고 없이 가장 앞선 미완료 이야기로 이어짐.
- **읽기**: 세로 스크롤 몰입형. 스크롤하면 숨는 상단 바(뒤로·DAY·읽기 설정), 항상 보이는 2dp 진행선, 어절 단위 줄바꿈,
  강조 문장·수준별 곁 설명·본문 안내 블록, 오늘의 핵심, 성경 본문 링크(대한성서공회 성경플랫폼 개역개정, 모바일 화면용, 실패 시 안내), 묵상 질문 3개와 자동 저장 메모,
  마지막의 `오늘의 이야기 완료하기`(재독이면 `다시 읽기 마치기` + 처음 읽은 날). 읽던 위치 자동 저장·복원(백그라운드 전환 시 즉시 저장).
  읽는 중에 시간·수준 변경 가능(현재 위치 비율 유지).
- **완료 화면**: 핵심 문장을 다시 보여 주고 `오늘은 여기까지` / `다음 이야기 읽기`.
- **여정**: 월간 캘린더(완료 챕터 수만큼 작은 점, 미완료일 무표시), 날짜별 읽은 이야기, 7개 이야기 목록(읽은 날짜 / 다음에 읽을 이야기), 재독.
- **시즌 완료**: 7일을 마치면 차분한 회고 화면. DAY 8–30은 "준비 중" 문장으로만 언급하고 읽을 수 있는 항목으로 노출하지 않음.
- **설정**: 이해 수준, 하루 독서 시간, 매일 읽기 알림(켜기/끄기·시간), 화면 테마(라이트/다크/시스템), 콘텐츠 안내(검수 상태 고지), 오픈소스 라이선스, 버전.
- **알림**: 오늘 1회 + 내일부터 매일 반복, 그날 읽으면 오늘 알림 취소, 비정확 예약(정확 알람 권한 미요청), Android 13+ 권한 요청,
  재부팅·앱 업데이트 시 재예약(플러그인 Boot 리시버), 시간대 변경은 앱 복귀 시 감지·재예약, 알림 탭 → 다음 이야기.
- **데이터**: 오프라인 동작, 로그인·서버·광고 없음. **INTERNET 권한 없음**(본문 링크는 외부 브라우저가 엶). 기록과 메모는 기기에만 저장.

## 2. 실제 사용한 버전

| 항목 | 버전 |
|---|---|
| Flutter | 3.47.6 stable (framework 5fc346839b, engine 692136cb65) |
| Dart | 3.13.5 |
| Android SDK | compileSdk 36, build-tools 36.0.0, NDK 28.2.13676358 |
| Gradle / AGP / Kotlin | 9.3.1 / 9.1.0 / 2.4.0, JDK 21 |
| 주요 패키지 | flutter_riverpod 3.4.3, go_router 18.0.2, sqflite 2.4.4+1, shared_preferences 2.5.6, flutter_local_notifications 22.3.1, timezone 0.11.1, flutter_timezone 5.1.1, url_launcher 6.3.3, intl 0.20.3 |

## 3. 지원 Android 버전

minSdk **26 (Android 8.0)** ~ targetSdk **36 (Android 16)**. (2026-08-31 이후 Google Play 신규 앱 요건 API 36 충족)
ABI: arm64-v8a, armeabi-v7a, x86_64 (유니버설 APK).

## 4. APK

| 항목 | 값 |
|---|---|
| 경로 | `build/app/outputs/flutter-apk/app-release.apk` |
| 크기 | 66,555,072 bytes (Flutter 표기 66.6MB) |
| SHA-256 | `a996645f76d26e1286dc0a4de71aa8a0e00d7f0f1f5b7e40c31e04564d4bc4ac` |
| 패키지 / 버전 | `com.focusjesus.story` / 1.0.0 (versionCode 1) |
| 서명 | **Android Debug 인증서**(`CN=Android Debug`) — 내부 설치·테스트용. 스토어 출시 불가 |
| 권한 | POST_NOTIFICATIONS, RECEIVE_BOOT_COMPLETED, VIBRATE (+ Android 13 이상 내부 리시버 보호용 자동 권한) |

같은 커밋에서 두 번 빌드한 APK의 SHA-256이 동일함을 확인했습니다(재현 가능한 빌드).
갤럭시용 arm64 전용 APK도 같은 커밋에서 만들었습니다(사용자 전달용, 30MB 전송 제한 때문):
`flutter build apk --release --split-per-abi --target-platform android-arm64` →
`app-arm64-v8a-release.apk`, 26,125,178 bytes, SHA-256 `d1dc53cb3a4e075c4486bc429f437772ecf4dcfa571271c9932ed011dc559770`,
versionCode 2001(ABI 분할 시 Flutter가 자동으로 1000×ABI를 더함), 같은 디버그 키 서명.

**1.0.1 (2026-10-09, 성경 링크를 모바일 플랫폼으로 교체)** — 위 1.0.0 기록은 롤백용으로 그대로 둡니다.
`app-arm64-v8a-release.apk`, 26,125,178 bytes, SHA-256 `0f260fba721d2f26a46a2683b74e7e7b87932cd05604d35ca61dec8388f1744c`,
versionName 1.0.1 / versionCode 2002, 1.0.0과 같은 디버그 키(인증서 SHA-256 `540ff875…3ec15677`)로 서명 → 기존 설치 위에 업데이트 설치되며 데이터 유지.

## 5. 자동 테스트 실행 결과

`scripts/verify.sh` 최종 실행: **exit 0** (5분 28초) — 포맷 무변경, `flutter analyze` 무오류, `flutter test` **93개 통과**, 콘텐츠 검증 OK, Release APK 빌드.

| 묶음 | 파일 | 내용 |
|---|---|---|
| 콘텐츠 | `test/content/content_test.dart` | JSON 파싱·오류 경로, 검증기, 모드 조합 단조 증가, 문장 중간 절단 없음, 수준 레이어, 성경 참조·링크, 커리큘럼 |
| 저장 | `test/data/storage_test.dart` | 설정 저장·로드·손상값, 완료 기록·재독·중복·하루 2개, 시간대 독립 날짜, 읽기 위치, 메모, DB 파일 재오픈 |
| 로직 | `test/core/logic_test.dart` | 놓친 날 다음 챕터, 오늘 상태, 알림 시각 계산(경계·변경), 가짜 시계, 어절 줄바꿈 |
| 알림 채널 | `test/core/notification_channel_test.dart` | Android 플러그인에 전달되는 실제 인자(inexact, 매일 반복, 취소), 권한 응답, 플랫폼 오류 내성 |
| 화면 | `test/widgets/app_widgets_test.dart` | 온보딩, 홈, 읽기, 모드·수준 변경, 링크 성공·실패, 메모, 빈 메모 완료, 캘린더, 하루 2개, 위치 복원, 테마, 알림 설정, 소형·큰 글꼴(2.0배)·다크·긴 제목 |
| 생명주기 | `test/widgets/lifecycle_test.dart` | 알림으로 실행, 실행 중 알림 탭, 시간대 변경 복귀, 자정 넘김, 백그라운드 위치 저장 |
| 접근성 | `test/widgets/accessibility_test.dart` | WCAG 명암비, 48dp 터치 영역, 라벨, 텍스트 대비(라이트·다크), 애니메이션 감소 |
| 통합 | `integration_test/app_test.dart` | 명세 9장 10단계 사용자 흐름 — **통과**(Linux 데스크톱 빌드, 실제 부트스트랩·디스크 DB) |
| 통합(재시작) | `integration_test/app_restart_test.dart` | 별도 프로세스로 실제 재시작 후 기록·설정·메모 유지 — **통과** |

시간·알림 테스트는 모두 주입한 가짜 시계·스케줄러로 실행했습니다(시스템 시각 변경 없음).

## 6. Android 기기 검증 환경과 결과 — ❌ 미완료

- 물리 Android 기기: **없음**(클라우드 컨테이너).
- 에뮬레이터: 이 환경은 KVM이 없어(`KVM requires a CPU that supports vmx or svm`) 소프트웨어 에뮬레이션만 가능.
  - Android 16 Google APIs x86_64: 부팅 완료까지 **31.9분**, 이후 설치 시도 시 `Can't find service: package` / `Broken pipe`.
  - Android 16 AOSP ATD x86_64(경량 테스트 이미지): 부팅 **16.5분**, 설치 시도 시 `StorageManager` null → `Broken pipe`.
  - 근본 원인(로그 확인): 너무 느린 실행 때문에 Android **Watchdog이 system_server를 약 4분마다 강제 종료**
    (`WATCHDOG KILLING SYSTEM PROCESS: Blocked in handler on main thread (main) for 64s` → `*** GOODBYE!`, 01:45 / 01:49 / 01:55 반복).
    앱과 무관한 환경 한계이며, Watchdog을 끄는 우회는 결과를 신뢰할 수 없게 만들어 하지 않았습니다.
- 대신 실제로 검증한 것: 같은 Flutter 코드의 Linux 데스크톱 빌드로 10단계 통합 흐름과 실제 재시작 유지 통과,
  Android 알림 경로는 플랫폼 채널 수준에서 인자 검증, APK 메타데이터(`aapt`, `apksigner`) 확인.
- **사람이 해야 할 일**: 갤럭시 기기를 USB 디버깅으로 연결한 PC에서
  1. `scripts/verify.sh`
  2. `scripts/device_smoke.sh` (설치·실행·크래시 확인, 스크린샷 `build/device_smoke_launch.png`)
  3. `flutter test integration_test/app_test.dart -d <기기>` → `flutter test integration_test/app_restart_test.dart -d <기기>`
  4. 수동 확인: 알림 권한 팝업, 알림 수신(설정 시간 1–2분 뒤로), 재부팅 후 알림, 외부 성경 링크, 시스템 글꼴 크게.

## 7. 주요 스크린샷 (`docs/screenshots/`, 실제 폰트 렌더링)

| 파일 | 화면 |
|---|---|
| `01–04_onboarding_*.png` (+ `_dark`) | 온보딩 4단계 |
| `10_today.png` (+ `_dark`) | 오늘 |
| `11_reader_top.png` · `12_reader_body.png` · `13_reader_bar_returns.png` | 읽기 시작·본문(바 숨김)·바 복귀 |
| `14_reader_key_message.png` · `15_reader_reflection.png` · `16_reader_settings_sheet.png` | 오늘의 핵심·묵상·읽기 설정 |
| `20_today_continue.png` · `21_journey.png` · `22_settings.png` · `23_completion.png` (+ `_dark`) | 이어 읽기·여정 캘린더·설정·완료 |
| `30_today_small_large_text.png` · `31_reader_small_large_text.png` | 360dp + 글꼴 1.3배 |
| `32_reader_tablet.png` | 태블릿(읽기 폭 560dp 제한) |

앱 아이콘: `docs/design/app_icon_1024.png`, `docs/design/play_store_icon_512.png`.

## 8. 미해결 결함 및 제한사항

1. **실기기 구동·알림 수신·재부팅 후 재예약 미검증**(6장).
2. **신학 검수 미완료**(9장).
3. 시간대를 바꾼 뒤 앱을 열지 않으면 알림은 이전 시간대 기준으로 울립니다(앱을 열면 즉시 재계획). 시간대 변경 브로드캐스트 수신은 다음 버전 과제.
4. 앱을 2주 이상 열지 않아도 매일 반복 알림은 계속됩니다(설계 의도). "오늘 이미 읽음" 판단은 앱을 연 날에만 반영됩니다.
5. 본문 폰트(Noto Serif KR)는 KS X 1001 한글 2,350자만 포함 → 드문 음절은 시스템 글꼴로 표시됩니다(메모 입력은 Pretendard 전체 한글).
6. 읽기 시간은 공백 제외 500자/분 가정의 추정치이며, 실제 독자 측정은 하지 않았습니다. 15·20분 모드는 입문·성장 수준에서 목표보다 약 1–2분 짧습니다.
7. 스크롤 성능 수치는 실기기에서 측정하지 않았습니다.
8. 디자인 명세와 다른 점 1건: 라이트 보조 텍스트 `#707770` → `#6B726B`(WCAG AA 충족 목적, `tokens.dart` 한 줄로 복구 가능).
9. iOS 프로젝트는 구조만 포함되어 있고 빌드·검증하지 않았습니다.
10. 패키지 ID `com.focusjesus.story`는 임시 식별자입니다.

## 9. 콘텐츠의 신학적 검수 상태

- 7개 원고 모두 `reviewStatus: theologyReviewPending`. 앱 화면(읽기 화면 하단, 설정 > 콘텐츠 안내)에 그대로 표시.
- 자동 검증 통과: 구조·분량·참조 실재·중복·더미 문구·인용 길이, 개역개정 54개 장과 12음절 n-gram 대조(고유 용어 1건 외 일치 없음).
- 검수자가 확인할 항목(창 3:15 해석의 성격, 행 2와 바벨의 관계, 벧전 3:19–21의 여러 견해, 원어·고대 근동 사실 등)은
  **`docs/THEOLOGY_REVIEW.md`**에 챕터별로 정리되어 있습니다.

## 10. 앱스토어 출시 전 필요한 작업

1. 신학 검수 완료 → `reviewStatus: approved` + 검수 기록 필드 추가(검증기의 approved 차단 규칙 완화).
2. 실기기 검증(6장의 절차) — 최소 갤럭시 2종(Android 13 이상 1대 포함).
3. 정식 업로드 키 생성·보관(Play App Signing), `build.gradle.kts`의 release `signingConfig` 교체, `flutter build appbundle --release`.
4. 상표·이름: KIPRIS 상표 검색, 앱스토어·도메인 중복 확인, 패키지 ID 확정(출시 후 변경 불가).
5. Play Console: 개인정보처리방침(수집 데이터 없음 명시), 데이터 보안 양식, 콘텐츠 등급, 스토어 등록정보·스크린샷(`docs/screenshots/` 활용).
6. 법률 확인: 성경 본문 외부 링크(대한성서공회 성경플랫폼 — 본문을 앱에 싣지 않고 공식 사이트로 연결만 함) 사용 조건, 폰트 라이선스 고지(앱 내 포함됨).
7. 버전·빌드 번호 정책, 크래시 수집 도구 도입 여부 결정(현재 없음 — 수집 시 개인정보 고지 필요).

## 11. 다음 버전 개발 권고

1. DAY 8–30 원고 작성(커리큘럼 개요·작성 가이드·검증기 그대로 사용), 신학 검수 워크플로 도입.
2. 시간대 변경·날짜 변경 브로드캐스트 수신으로 앱을 열지 않아도 알림 재계획.
3. 실제 독자 읽기 속도 측정(로컬 통계만) → 모드별 분량 보정.
4. 본문 폰트 전체 한글 커버리지(용량과 균형) 검토.
5. 백업·복원(기기 변경 대비, 로컬 파일 내보내기) — 서버 없이.
6. iOS 빌드·검증, 태블릿 가로 모드 레이아웃 다듬기.

## 12. 재현 방법

```bash
git checkout main
scripts/verify.sh
dart run tool/check_bible_links.dart   # 성경 링크 실제 확인(인터넷 필요)
```
Phase별 상세 기록: `docs/MASTER_STATE.md`.

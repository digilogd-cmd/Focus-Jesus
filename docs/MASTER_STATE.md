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
  라이선스 전문: `assets/licenses/` (앱의 오픈소스 라이선스 화면에도 표시).
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

## Phase 1 — 디자인 시스템 ✅

- 구현: `lib/core/design/tokens.dart`(색상 `FjColors` 라이트/다크 — 명세 팔레트 그대로, 타입 스케일 `FjText`, 간격 `FjSpace`, 모션 `FjMotion` — 시스템 애니메이션 감소 설정 시 0ms),
  `lib/app/theme.dart`(Material 3 기반 커스텀 테마, 그림자·스플래시 제거), `lib/core/design/widgets.dart`(워드마크, 읽기 칼럼 최대 560dp + 좌우 26dp,
  주요 버튼 54dp, 조용한 텍스트 버튼 48dp 이상, 옵션 타일, 설정 행), 하단 텍스트 내비게이션(아이콘 없음), 앱 아이콘(FJ 모노그램, 적응형 아이콘 포함),
  상태바 알림 아이콘(벡터), 런치 배경(종이색/다크).
- 한국어 조판: Flutter는 한글을 음절 단위로 줄바꿈해 "합니/다"처럼 단어가 잘림 → `keepAll()`(U+2060 WORD JOINER)로 어절 단위 줄바꿈 적용.
  한글 라벨에는 넓은 자간을 쓰지 않도록 조정.
- 검증: 실제 폰트로 렌더링한 스크린샷 33장(`test_screenshots/`, 라이트/다크, 360dp 소형, 1.3배 글꼴, 820dp 태블릿)을 직접 확인.
  발견·수정한 결함 3건: (1) 어절 중간 줄바꿈, (2) 상단 바 아래로 본문이 잘려 보임 → 스크롤 시 헤어라인 추가, (3) 한글 라벨 과한 자간.
- 통과 조건: 한글 폰트 정상 렌더링 ✓, 오버플로 없음(위젯 테스트로 360dp·2.0배까지 검증) ✓, 다크 모드 가독성 ✓, 본문 장식 없음 ✓.

## Phase 2 — 코어 앱 ✅

- 구현: 부트스트랩(`lib/app/bootstrap.dart`), Riverpod 프로바이더(`lib/app/providers.dart`), go_router(온보딩 리다이렉트, 하단 탭 3개, 읽기/완료 화면),
  온보딩 4단계, 오늘 화면, 몰입형 읽기 화면(스크롤 시 상단 바 숨김, 2dp 진행선, 읽기 설정 시트), 묵상 메모(600ms 디바운스 자동 저장),
  읽기 위치 자동 저장·복원(오프셋 + 비율 + 레이아웃 키: 시간·수준·글꼴 배율·화면 폭이 달라지면 비율로 복원),
  SQLite 스키마 v1(`reading_progress`, `completion_event`, `reflection_note`) + 마이그레이션 틀, 외부 성경 링크(실패 시 안내).
- 테스트: 단위 49개 + 위젯 28개 = **77개 전부 통과** (`flutter test`), `flutter analyze` 무오류, `dart format` 변경 없음.
  - 온보딩 설정 저장·로드, 권한 거부 시에도 온보딩 완료, 앱 재시작(같은 DB 파일 재오픈) 후 기록·메모 유지,
    읽던 위치 복원(오프셋 ±1px), 외부 링크 성공/실패, 챕터 간 이동(다음 이야기 → DAY 02).
- 테스트 중 발견·수정한 결함: sqflite 단일 인스턴스 캐시 때문에 테스트 간 `:memory:` DB가 공유되던 문제 → `singleInstance` 옵션 추가.

## Phase 3 — 콘텐츠 및 학습 엔진 ✅ (신학 검수는 별도 미완료)

- 구현: DAY 01–07 완성 원고(`assets/content/season1/day01–07.json`, 챕터당 10–12개 섹션, 공백 제외 약 9–10천 자),
  30일 커리큘럼(`curriculum.json`: 1–7일 available, 8–30일 planned — 본문 파일 없음, 앱에서 읽을 수 있는 항목으로 노출하지 않음),
  작성 가이드(`docs/CONTENT_GUIDE.md`), 검증기(`lib/data/content/content_validator.dart`, CLI `tool/validate_content.dart`),
  신학 검수 요청서(`docs/THEOLOGY_REVIEW.md`).
- 작성 방식: 공통 가이드와 챕터별 신학 브리프를 주고 7개 원고를 병렬 작성 → 각 원고 검증기 통과 → 직접 편집 검토(DAY 07 5분 모드 통독 등).
- 시간 모드: 확장 모듈 방식(tier 5/10/15/20). 모든 모드에서 시작·결말·그리스도 연결·본문 안내 유지. 수준: 같은 섹션 + 수준별 곁 설명 레이어.
- 테스트: 콘텐츠 단위 테스트(파싱, 모드 조합 단조 증가, 문장 중간 절단 없음, 수준 레이어, 참조 유효성, 커리큘럼 교차 검증) 포함 전체 77개 통과.
- 저작권: 개역개정 54개 장과 12음절 n-gram 대조 → 첫 검사 18문장 일치 발견 → 전부 재서술 → 남은 1건은 두 나무의 고유 명칭.
- **남은 위험: 신학 검수 미완료(Theology Review Pending).** 확인 요청 항목은 `docs/THEOLOGY_REVIEW.md` 4장.

## Phase 4 — 여정 및 알림 ✅ (실기기 알림 수신은 미검증)

- 구현: 월간 캘린더(일요일 시작, 완료일 작은 점 — 챕터 수만큼 최대 3개, 미완료일은 아무 표시 없음),
  날짜별 읽은 이야기 목록, 7개 챕터 목록(읽음 날짜/다음에 읽을 이야기), 재독(첫 완료 기록 보존 + 재독 날짜 캘린더 표시),
  놓친 날 이어보기(가장 앞선 미완료 챕터), 같은 날 추가 읽기, 시즌 완료 화면.
  알림: 오늘 1회(아직 안 읽었고 시간이 남았을 때) + 내일부터 매일 반복 — 그날 읽으면 오늘 알림만 취소.
  `inexactAllowWhileIdle`(정확 알람 권한 요구 안 함), Android 13+ 권한 요청, 거부 시 앱 정상 동작 + 안내 문구.
  재부팅·앱 업데이트: 플러그인 `ScheduledNotificationBootReceiver`(BOOT_COMPLETED, MY_PACKAGE_REPLACED) 등록.
  시간대 변경: 앱 복귀 시 기기 시간대를 다시 읽고(`TimeZoneName.refresh`) 알림 재계획. 알림 탭 → 다음 읽을 이야기로 바로 이동.
- 빌드: 알림 플러그인 포함 debug APK 빌드 성공(2분 20초). core library desugaring 적용.
- 환경 이슈: Maven Central이 공유 egress IP에 HTTP 429(Too Many Requests) → 이 빌드 환경에만 `~/.gradle/init.d/central-mirror.gradle`
  (Google 공식 Maven Central 미러로 리다이렉트) 추가. 프로젝트 파일은 변경하지 않음.
- 테스트: 생명주기 위젯 테스트 5개(알림으로 실행 시 다음 이야기, 실행 중 알림 탭, 시간대 변경 후 복귀, 자정 넘어 복귀, 백그라운드 전환 시 위치 즉시 저장),
  알림 플랫폼 채널 테스트 5개(취소→예약 순서, ID, inexact 모드, 매일 반복, 권한 응답 매핑, 플랫폼 오류 시 크래시 없음). 전체 **87개 통과**.
- 남은 위험: 실제 Android 기기에서의 알림 수신·재부팅 후 재예약은 기기가 없어 미검증(Phase 6 참고).

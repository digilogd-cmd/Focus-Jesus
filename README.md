# FOCUS JESUS

**모든 이야기는 그리스도께로** · Quiet reading. Deeper understanding.

예수 그리스도를 중심으로 성경 전체의 흐름을 이해하도록 돕는, 텍스트 중심 성경 스토리 스터디 앱입니다.
먼저 이해하기 쉬운 해설형 이야기를 읽고, 그다음 실제 성경 본문으로 연결합니다.
오프라인으로 동작하고, 로그인·서버·광고가 없습니다.

> MVP 1.0 · 7일 파일럿 시즌(DAY 01–07) · Android 우선 (Flutter)

## 기능

- 첫 실행 온보딩: 이해 수준(입문/성장/심화), 하루 독서 시간(5/10/15/20분), 매일 알림 시간
- 오늘의 이야기 홈: 단 하나의 주요 행동, 놓친 날은 벌점 없이 다음 이야기로 이어 읽기, 같은 날 추가 읽기
- 몰입형 읽기 화면: 스크롤하면 숨는 상단 바, 얇은 진행선, 읽던 위치 자동 저장·복원, 한국어 어절 단위 줄바꿈
- 읽기 시간 모드는 내용을 잘라내지 않고 확장 모듈을 더하는 방식, 수준은 같은 이야기에 곁 설명의 깊이만 바꾸는 방식
- 오늘의 핵심, 대한성서공회 개역개정 본문 링크, 묵상 질문 3개와 개인 메모(기기에만 저장)
- 직접 누르는 완료 버튼, 월간 캘린더(하루 여러 이야기 정확히 표시, 미완료일은 실패처럼 표시하지 않음)
- 라이트/다크/시스템 테마, 시스템 글자 크기 확대 지원
- 매일 읽기 알림(비정확 예약, 정확 알람 권한 요구 없음), 그날 읽었으면 그날 알림 생략, 재부팅·업데이트·시간대 변경 시 재예약

## 기술 구성

| 항목 | 내용 |
|---|---|
| Flutter / Dart | 3.47.6 stable / 3.13.5 |
| Android | minSdk 26 (Android 8.0), targetSdk 36, compileSdk 36 |
| 상태관리 / 라우팅 | flutter_riverpod 3.4.3 / go_router 18.0.2 |
| 저장소 | sqflite 2.4.4+1 (진도·완료 기록·메모, 스키마 v1), shared_preferences 2.5.6 (설정) |
| 알림 / 시간대 | flutter_local_notifications 22.3.1, timezone 0.11.1, flutter_timezone 5.1.1 |
| 기타 | url_launcher 6.3.3, intl 0.20.3 |
| 폰트 | Noto Serif KR(본문·제목, OFL, KS X 1001 서브셋), Pretendard(UI, OFL, 원본 그대로) |

모든 의존성은 `pubspec.yaml`에 정확한 버전으로 고정되어 있습니다.

```
lib/
  app/        진입점·부트스트랩, 라우터, 테마, 프로바이더
  core/       디자인 시스템, 성경 참조, 시간, 알림, 저장소 스키마
  data/       콘텐츠 모델·조합·검증, 여정 로직, 리포지토리
  features/   onboarding · today · reader · reflection · journey · settings
assets/content/season1/   챕터 JSON(day01–07), 30일 커리큘럼
test/                     단위·위젯 테스트
integration_test/         실제 앱 사용자 흐름 테스트
test_screenshots/         실제 폰트 렌더링 스크린샷 생성
tool/                     콘텐츠 검증기, 성경 장·절 표 생성기, 아이콘 생성기
scripts/                  verify.sh, device_smoke.sh
docs/                     명세, 상태 기록, 디자인 시스템, 콘텐츠 가이드, 신학 검수 요청서, 최종 보고
```

## 빌드와 검증

```bash
flutter pub get
scripts/verify.sh                 # 포맷 → 분석 → 테스트 → 콘텐츠 검증 → Release APK
scripts/device_smoke.sh           # 연결된 Android 기기에 설치·실행·크래시 확인 (기기 없으면 exit 2)
flutter test integration_test/app_test.dart -d <device-id>
flutter test integration_test/app_restart_test.dart -d <device-id>   # 앱 재시작 후 데이터 유지 확인
dart run tool/validate_content.dart                                  # 원고만 검증
flutter test test_screenshots --update-goldens                       # 스크린샷 다시 만들기
```

Release APK는 현재 **디버그 키로 서명**됩니다(내부 테스트용). Google Play 출시에는 정식 업로드 키가 필요합니다
(`docs/FINAL_HANDOFF.md`의 출시 전 작업 참고).

## 콘텐츠와 신학 검수

- 원고 작성 기준: `docs/CONTENT_GUIDE.md`
- 모든 원고는 현재 **신학 검수 대기(Theology Review Pending)** 상태입니다. 자동 검증 통과는 신학적 승인이 아닙니다.
  검수 요청 항목: `docs/THEOLOGY_REVIEW.md`
- 현대 한국어 성경 번역문을 앱에 포함하지 않습니다. 본문은 외부 링크로 연결합니다.

## 문서

- `docs/MASTER_SPEC.md` — 마스터 개발 명세
- `docs/MASTER_STATE.md` — Phase별 실제 진행·테스트 기록
- `docs/DESIGN_SYSTEM.md` — 디자인 시스템 v2 (Ink & Paper · 모션), 이전 v1은 `docs/DESIGN_SYSTEM_v1.md`
- `docs/FINAL_HANDOFF.md` — 최종 완료 보고

패키지 ID `com.focusjesus.story`는 내부 MVP용 임시 식별자입니다.

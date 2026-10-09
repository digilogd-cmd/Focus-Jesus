# FOCUS JESUS — 디자인 시스템 v2 (Ink & Paper · Motion Editorial)

따뜻한 종이색 바탕에 먹색 글자, 가는 선과 넉넉한 여백. 색과 카드 대신 **타이포그래피와 선**으로 질서를 만들고,
그 글자와 선이 **움직이며 등장**해 앱 전체가 하나의 조용한 모션그래픽처럼 읽히게 합니다.
참고: Custom Times 디자인 가이드(신문의 질서 + 현대 산업디자인)를 성경 읽기 앱에 맞게 옮겼습니다.

- 구현: `lib/core/design/tokens.dart`(색·글자·움직임 토큰), `motion.dart`(모션 부품), `editorial.dart`(큰 숫자·진행 막대·인용),
  `widgets.dart`(버튼·라벨·목록), `lib/app/theme.dart`.
- 이전 디자인(v1 Quiet Editorial, 초록 강조색)은 `docs/DESIGN_SYSTEM_v1.md`, 스크린샷은 `docs/screenshots/v1/`.
  v1 색은 코드에도 `FjColors.classicLight/classicDark`로 남아 있어, `buildTheme`가 이를 쓰게 바꾸면 색을 되돌릴 수 있습니다.
  화면 전체를 되돌리려면 1.0.1 APK 또는 그 커밋(`c8d10d4`)을 쓰면 됩니다.

## 1. 색 — 흑백만 씁니다

| 토큰 | Light | Dark | 쓰임 |
|---|---|---|---|
| background | `#F4F0E7` 종이 | `#121110` 밤의 종이 | 화면 바탕 |
| textPrimary / accent | `#171714` 먹 | `#EDE8DC` | 본문·제목·주요 버튼·선택 표시·진행선 |
| inkSoft | `#4B4A44` | `#C9C3B6` | 부제, 곁 설명 등 한 톤 옅은 읽기 글자 |
| textSecondary | `#6B675E` ※ | `#9C978B` | 날짜, 메타, 한글 라벨 |
| rule | `#B9B4A9` | `#4A473F` | 구조선(그어지는 선, 미완료 숫자) |
| divider | `#D9D4C9` | `#2C2A26` | 가는 구분선, 진행 막대의 빈칸 |
| surface | `#FBF8F1` | `#1A1917` | 겹 표면 |

※ 참고 가이드의 Muted `#77736A`는 종이색 대비 4.15:1로 WCAG AA(4.5:1)에 못 미쳐, 같은 색조로 `#6B675E`(4.95:1)를 씁니다.

명암비(실측): 본문 15.8:1(라이트)·15.4:1(다크), 보조 글자 4.95:1·6.48:1, 옅은 먹 7.8:1·10.8:1.
`test/widgets/accessibility_test.dart`가 본문 7:1, 보조·버튼 4.5:1 이상인지 검사합니다.

**쓰지 않는 것:** 초록·파랑 같은 강조색, 그라데이션, 그림자(모달 제외), 카드 UI, 캡슐 칩, 원형 스피너, 이모지.

## 2. 타이포그래피

| 역할 | 글꼴 | 크기 / 행간 / 자간 | 쓰임 |
|---|---|---|---|
| wordmark | Cormorant Garamond 600 | 17–26, 자간 0.24em | FOCUS JESUS |
| numeral | Cormorant Garamond 400, 라이닝 숫자 | 72–120 / 0.92, -3 | **큰 날짜 숫자 "01"** — 앱의 핵심 그래픽 |
| latinItalic | Cormorant Garamond Italic | 19 | "/ 07", 섹션 번호 I·II·III, 영문 한 줄 |
| displayTitle | Noto Serif KR 600 | 31 / 1.36, -0.8 | 오늘의 제목, 화면 제목(36) |
| chapterTitle | Noto Serif KR 600 | 29 / 1.38, -0.8 | 읽기·완료 화면 제목 |
| heading | Noto Serif KR 600 | 21 / 1.5, -0.5 | 소제목 |
| body | Noto Serif KR 400 | 17.5 / 1.85, -0.2 | 본문 |
| emphasis | Noto Serif KR 600 | 21 / 1.62 | 강조 문장(왼쪽 먹선 인용) |
| keyMessage | Noto Serif KR 600 | 24 / 1.55 | 오늘의 핵심 |
| subtitle / note | Noto Serif KR 400, 옅은 먹 | 16.5 / 15.5 | 부제, 곁 설명 |
| label | Pretendard 600 | 11, 영문 자간 0.18em | TODAY, KEY MESSAGE 등 |
| meta / ui / button | Pretendard | 13 / 16 / 15.5 | 메타, 목록, 버튼 |

- **이중 라벨**(`FjDualLabel`): 영문 대문자(넓은 자간, 먹색) + 한글(자간 없음, 보조색). 예: `KEY MESSAGE 오늘의 핵심`,
  `READ THE BIBLE 성경 본문 읽기`, `REFLECT 묵상`, `JOURNEY`, `SETTINGS`.
- 한글에는 자간을 넓히지 않습니다. 넓은 자간은 영문 라벨에만 씁니다.
- **어절 단위 줄바꿈**은 v1과 같습니다(`keepAll()`).
- 시스템 글자 크기를 따릅니다. 장식용 큰 숫자(numeral)만 1.2배까지 커지고 좁으면 축소됩니다(의미는 화면 읽기 라벨이 전달).
  2.0배 글꼴·360dp 화면에서 넘침이 없는지 위젯 테스트로 확인합니다.
- 폰트 라이선스: `assets/licenses/`. Cormorant Garamond(OFL, Reserved Font Name 없음)는 가변 폰트에서 400/500/600/이탤릭 정적
  인스턴스를 만들고 라틴 문자로 서브셋했습니다(파일당 약 150KB).

## 3. 공간과 선

- 좌우 여백 24dp, 읽기 폭 최대 560dp. 문단 20dp, 섹션 56dp.
- 구분선 0.8dp(목록), 1dp(구조선), 1.5dp(먹 강조선). 홈 상단은 **이중선**(먹 1dp + 회색 1dp).
- 모서리: 주요 버튼 6dp, 시트 8dp, 그 외 0.
- 터치 영역 최소 48dp(주요 버튼 58dp).

## 4. 컴포넌트

- **주요 버튼**: 먹색 면 + 종이색 글자 + 오른쪽 "→". 누르면 살짝 눌리고(98.5%) 화살표가 앞으로 기웁니다.
- **조용한 버튼**: 먹색 텍스트 "다음 이야기 읽기 →".
- **옵션 타일**: 오른쪽 가는 원 안에 먹 점이 차오르며 선택 표시. 면을 칠하지 않습니다.
- **하단 내비게이션**: 텍스트 3개, 위쪽 선을 따라 먹 막대가 현재 탭으로 미끄러집니다.
- **진행 막대**(`SeasonProgress`): 이야기 수만큼 가는 칸, 읽은 칸이 차례로 먹으로 채워집니다.
- **인용**(`PullQuote`): 왼쪽 먹선이 위에서 아래로 그어지고 문장이 번집니다. 상자 배경 없음.
- **곁 설명**: 왼쪽 가는 세로선 + 라벨, 배경 없음.
- **섹션 머리**: 이탤릭 로마 숫자(I, II…) → 제목 → 32dp 선.
- **캘린더**: 오늘은 먹으로 칠한 원, 선택일은 가는 원, 읽은 날은 먹 점.

## 5. 움직임 — "글자와 선이 등장한다"

| 부품 | 효과 | 쓰는 곳 |
|---|---|---|
| `MaskRise` | 보이지 않는 기준선 아래에서 글자가 떠오름(900ms) | 큰 숫자, 소제목, 화면 제목, 묵상 번호 |
| `InkText` | 단어가 앞에서부터 차례로 먹처럼 번짐(단어당 ≤55ms, 전체 ≤1.4초). 줄바꿈은 처음부터 고정 | 제목, 오늘의 핵심, 강조 문장 |
| `DrawnRule` | 선이 왼쪽(또는 위)에서부터 그어짐(1초) | 이중선, 구분선, 인용선, 진행 막대 |
| `Reveal` | 18dp 아래에서 떠오르며 나타남(720ms) | 문단, 메타, 버튼, 목록 행 |
| `Wordmark(animate)` | 넓게 퍼진 글자가 모여듦(1.4초) | 홈, 첫 화면, 여정 완료 |
| 페이지 전환 | 새 화면이 3.5% 아래에서 올라오고 이전 화면은 물러남 | 모든 화면 이동 |

- 곡선: 등장은 `Cubic(0.16, 1, 0.3, 1)`(길고 부드러운 감속), 짧은 상태 변화는 `easeOutCubic`. 바운스·반복 애니메이션 없음.
- 순서(stagger 70ms): 화면 머리 → 큰 숫자 → 제목 → 부제 → 선 → 메타 → 버튼. 화면이 열릴 때 보이는 본문은 560ms 늦게 시작해 머리를 앞세웁니다.
- 읽기 화면 본문은 **스크롤로 화면에 들어올 때** 등장합니다. 이어 읽기로 건너뛴 위쪽 내용은 다시 재생하지 않고 바로 보입니다.
- OS의 "애니메이션 줄이기"가 켜지면 모든 등장이 첫 프레임부터 완성된 상태로 그려집니다(`test/widgets/motion_test.dart`).
- 시간대별 프레임: `docs/screenshots/motion/`. 다시 만들기: `flutter test test_screenshots/motion_frames_test.dart --update-goldens`.

## 6. 앱 아이콘

먹색 바탕에 종이색 Cormorant Garamond "FJ" 모노그램과 짧은 헤어라인. `python3 tool/generate_icons.py`로 생성.

## 7. 스크린샷

`docs/screenshots/`(v2, 라이트/다크·소형+큰 글꼴·태블릿), `docs/screenshots/motion/`(등장 모션 프레임), `docs/screenshots/v1/`(이전 디자인).
다시 만들기: `flutter test test_screenshots --update-goldens` 후 `test_screenshots/goldens/*.png`를 복사.

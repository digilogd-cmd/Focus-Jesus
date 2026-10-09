# FOCUS JESUS — 디자인 시스템 (Quiet Editorial Minimalism)

조용한 서재, 잘 만든 문학책의 편집 디자인. 배경보다 텍스트, 장식보다 여백, 그래픽보다 타이포그래피.
구현: `lib/core/design/tokens.dart`, `lib/core/design/widgets.dart`, `lib/app/theme.dart`.

## 1. 색

| 토큰 | Light | Dark | 쓰임 |
|---|---|---|---|
| background | `#F8F7F3` | `#171D1A` | 화면 바탕(종이) |
| textPrimary | `#202722` | `#ECEFE9` | 본문, 제목 |
| textSecondary | `#6B726B` ※ | `#A2ABA3` | 날짜, 메타 정보, 곁 설명 |
| accent | `#365B4C` | `#ADC5B5` | 주요 버튼, 선택 표시, 완료 점, 진행선 |
| divider | `#E5E6DF` | `#343D36` | 헤어라인, 목록 구분선 |
| surface | `#FFFFFF` | `#202823` | 시간 선택기 등 겹 표면 |
| onAccent | `#F8F7F3` | `#171D1A` | 주요 버튼 글자 |

※ 명세 값 `#707770`은 배경 대비 4.29:1로 WCAG AA(4.5:1)에 못 미쳐 같은 색상에서 명도만 낮춘 `#6B726B`(4.62:1)를 사용합니다.
명세 값으로 되돌리려면 `tokens.dart`의 해당 줄 하나만 바꾸면 됩니다.

명암비(실측, 테스트 `test/widgets/accessibility_test.dart`): 본문 14.3:1(라이트)·14.7:1(다크), 강조색 7.1:1·9.3:1, 버튼 글자 7.1:1·9.3:1.

색은 의미가 있는 곳에만 씁니다. 그라데이션, 그림자, 배경 이미지, 장식 패턴은 없습니다. 미완료일에 빨간색 같은 경고색을 쓰지 않습니다.

## 2. 타이포그래피

| 스타일 | 글꼴 | 크기 / 행간 | 쓰임 |
|---|---|---|---|
| wordmark | Noto Serif KR 600 | 24 (홈 15), 자간 0.175em | FOCUS JESUS |
| displayTitle | Noto Serif KR 600 | 30 / 1.42 | 홈·여정·설정 제목 |
| chapterTitle | Noto Serif KR 600 | 28 / 1.45 | 읽기 화면 제목 |
| heading | Noto Serif KR 600 | 20 / 1.55 | 소제목 |
| body | Noto Serif KR 400 | 17.5 / 1.8 | 본문 |
| emphasis | Noto Serif KR 600 | 19.5 / 1.72 | 강조 문장(위에 24dp 강조색 선) |
| note | Noto Serif KR 400 | 15.5 / 1.75, 보조색 | 수준별 곁 설명(왼쪽 2dp 구분선) |
| keyMessage | Noto Serif KR 600 | 22 / 1.6 | 오늘의 핵심 |
| subtitle | Noto Serif KR 400 | 16.5 / 1.7, 보조색 | 부제, 안내 문단 |
| label | Pretendard 500 | 12, 라틴 자간 1.6 / 한글 0.3 | DAY 01, 섹션 라벨 |
| meta | Pretendard 400 | 13.5 / 1.55, 보조색 | 날짜, 예상 시간 |
| ui / uiStrong / button | Pretendard 400 / 600 / 600 | 16 | 목록, 버튼 |

- 양쪽 정렬을 쓰지 않습니다(왼쪽 정렬).
- **어절 단위 줄바꿈**: Flutter는 한글을 음절마다 줄바꿈하므로, 읽기용 텍스트에는 `keepAll()`(`lib/core/design/korean_text.dart`)로
  글자 사이에 보이지 않는 WORD JOINER(U+2060)를 넣어 띄어쓰기에서만 줄이 바뀌게 합니다.
- 시스템 글자 크기를 그대로 따릅니다(제한하지 않음). 2.0배까지 오버플로 없이 동작하는지 위젯 테스트로 확인합니다.
- 폰트 라이선스: `assets/licenses/` (앱의 설정 > 오픈소스 라이선스에서도 표시).
  Noto Serif KR은 KS X 1001 한글 2,350자 + 라틴·문장부호로 서브셋했습니다(굵기당 1.5MB). 범위 밖 글자는 시스템 글꼴로 표시됩니다.
  Pretendard는 Reserved Font Name 조항 때문에 수정하지 않은 원본 파일을 씁니다.

## 3. 공간

- 좌우 여백 26dp, 읽기 폭 최대 560dp(태블릿에서는 가운데 정렬).
- 문단 간격 20dp, 섹션 간격 56dp, 큰 여백 40/64dp.
- 터치 영역 최소 48dp(주요 버튼 54dp). `androidTapTargetGuideline` 테스트로 확인.

## 4. 컴포넌트

- **주요 버튼**(`FjPrimaryButton`): 화면당 하나. 강조색 면, 모서리 6dp, 그림자 없음.
- **조용한 버튼**(`FjQuietButton`): 강조색 텍스트. "다음 이야기 읽기 →" 같은 보조 행동.
- **옵션 타일**(`FjOptionTile`): 선택 시 왼쪽 3dp 강조선 + 굵기 + 체크. 면을 칠하지 않습니다.
- **목록 행**(`FjListRow`): 왼쪽 제목, 오른쪽 값, 아래 헤어라인.
- **하단 내비게이션**: 아이콘 없는 텍스트 3개(오늘·여정·설정), 선택은 굵기와 4dp 점.
- **읽기 화면 상단 바**: 뒤로가기 · DAY 번호 · 현재 읽기 설정. 아래로 읽으면 숨고 위로 올리면 나타남. 2dp 진행선은 항상 보임.
- **캘린더**: 일요일 시작, 오늘은 강조색 숫자, 선택일은 얇은 원, 완료 챕터 수만큼 4dp 점(최대 3).

## 5. 움직임

- 짧고 부드럽게: 180ms / 260ms, `easeOutCubic`. 바운스 없음. 페이지 전환은 페이드.
- OS의 "애니메이션 줄이기"가 켜지면 0ms(`FjMotion.of`).
- 스플래시(물결) 효과 없음.

## 6. 앱 아이콘

강조색 바탕에 종이색 세리프 "FJ" 모노그램과 짧은 헤어라인. Android 적응형 아이콘(전경 + 배경색 + 단색 테마 아이콘) 포함.
생성: `python3 tool/generate_icons.py` → `android/app/src/main/res/mipmap-*`, `docs/design/app_icon_1024.png`, `play_store_icon_512.png`.
알림 아이콘은 펼친 책 모양 벡터(`ic_stat_notify`).

## 7. 스크린샷

`docs/screenshots/` — 실제 폰트로 렌더링한 주요 화면(라이트/다크, 360dp 소형 + 1.3배 글꼴, 태블릿).
다시 만들기: `flutter test test_screenshots --update-goldens` 후 `test_screenshots/goldens/*.png`를 복사.

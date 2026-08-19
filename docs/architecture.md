# 아키텍처 · 기술 설계

**버전** v1.1 · 2026-08-19
**전제** Figma `Challenge5`의 12개 화면(`design-source.md`)과 `땀_날씨앱_구간화_UI_멘트_개발가이드.md`가 구현 기준.
**헌법** `constitution.md` — 충돌 시 헌법이 우선한다.

---

## 1. 제품 한 줄 요약

기상청 관측값으로 **오늘의 땀 체감 등급(1~6단계)** 을 산출하고, 그 등급에 맞는 **실내·그늘 위주 도보 경로**를 안내한 뒤, 사용자의 **자가 기록**으로 다음 예측 기준을 보정한다.

```
관측 → 등급 예측 → 경로 추천 → 이동 중 개입 → 자가 기록 → 기준 보정
```

---

## 2. 타깃과 툴체인

| 항목 | 값 |
|---|---|
| 최소 지원 | **iOS 26.5** (프로젝트 설정값) |
| 언어 | **Swift 6.0**, strict concurrency `complete` |
| IDE | Xcode 26.x (`objectVersion 77`) |
| UI | SwiftUI 100%. UIKit 미사용 |
| 디바이스 | iPhone 전용, Portrait 고정 |
| Bundle ID | `com.spctutorial.app.ADA-Challenge5-Norton` |

Portrait 고정 근거 — 홈의 마스코트·예보 그리드가 402pt 폭 세로 스크롤 전제로 설계됨.

---

## 3. 사용할 Apple 프레임워크

| 영역 | 프레임워크 | 용도 | 선택 이유 |
|---|---|---|---|
| UI | **SwiftUI** | 전 화면 | 디자인이 선언적 스택 레이아웃과 1:1 대응 |
| 상태 | **Observation** (`@Observable`) | Store | 뷰 무효화 범위가 좁아 예보 그리드 리렌더 비용이 낮음 |
| 영속화 | **SwiftData** | 기록·프로필 | 스키마가 단순, CloudKit 동기화를 설정만으로 확장 |
| 위치 | **CoreLocation** | 현재 지점, 이동 추적 | `CLLocationUpdate.liveUpdates()` + `CLBackgroundActivitySession` |
| 지도·경로 | **MapKit** | 지도, 도보 경로 | `MKDirections`(walking), SwiftUI `Map`/`MapPolyline` |
| 날씨 보완 | **WeatherKit** | 시간별·주간 예보, 폴백 | 격자 변환 없이 좌표로 조회 |
| 실시간 표시 | **ActivityKit** | 이동 중 Live Activity | 앱을 나가도 진행률·경고 노출 |
| 알림 | **UserNotifications** | 아침·이동 중·기록 | 전부 로컬. 서버 불필요 |
| 백그라운드 | **BackgroundTasks** | 아침 알림 직전 예보 갱신 | `BGAppRefreshTask` |
| 차트 | **Swift Charts** | 예측 vs 실제 | 막대쌍 차트를 선언형으로 |
| 위젯 | **WidgetKit** + **App Intents** | 오늘의 등급 | 2차 마일스톤 |
| 테스트 | **Swift Testing** | 단위 테스트 | 경계값 파라미터 테스트에 적합 |

### 채택하지 않은 것

| | 이유 |
|---|---|
| UIKit / Storyboard | 신규 프로젝트에 섞을 이유 없음 |
| HealthKit | 권한 심사 비용 대비 이번 스코프 이득 없음. 3차 재검토 |
| CoreMotion | 이동수단 자동 판별 → 온보딩 직접 선택으로 대체 |
| **Foundation Models** | 이 앱의 문구는 설계표로 확정된 결정적 텍스트다. 생성형으로 바꾸면 QA 대상이 폭증하고 폭염 안전 문구의 일관성이 깨진다 (헌법 III) |

---

## 4. 아키텍처

### 4.1 레이어

```
┌─────────────────────────────────────────────┐
│ Features   SwiftUI View + @Observable Store │
├─────────────────────────────────────────────┤
│ Domain     순수 Swift, 의존성 0              │
│   SweatStageEngine   등급 산출               │
│   CalibrationEngine  기록 → 기준 보정         │
│   ExposureEstimator  실내외·그늘 추정         │
├─────────────────────────────────────────────┤
│ Data       actor 기반 Repository             │
│   WeatherRepository  KMA + WeatherKit        │
│   RouteRepository    MKDirections + 공공데이터 │
│   LogRepository      SwiftData               │
├─────────────────────────────────────────────┤
│ Platform   Location · Notification · Activity│
└─────────────────────────────────────────────┘
```

**규칙**
- Domain은 `Foundation`만 import (헌법 I)
- Repository는 `actor`. 캐시와 재시도가 그 안에 갇힌다 (헌법 X)
- View는 Repository를 직접 부르지 않는다. 항상 Store 경유

### 4.2 모듈 (로컬 SPM 패키지)

```
ADA_Challenge5_Norton/
├── Packages/
│   ├── DesignSystem/       Figma 토큰 미러 + 컴포넌트
│   ├── SweatDomain/        등급·보정·노출 추정
│   ├── WeatherData/        기상청 클라이언트, WeatherKit 어댑터, 격자 변환
│   ├── RouteData/          경로 계산, 실내외 세그먼트화
│   ├── SweatPersistence/   SwiftData 스키마
│   └── SweatFeatures/      화면
└── ADA_Challenge5_Norton/  앱 타깃 (얇게 유지)
```

**분리 이유** — Live Activity 확장과 위젯 확장이 `SweatDomain`·`DesignSystem`을 링크해야 한다. 앱 타깃에 로직이 들어가면 확장에서 재사용할 수 없다.

---

## 5. 땀 등급 엔진

### 5.1 구간 — 잠정값 (헌법 V)

| 단계 | 체감온도 | 상태 |
|---|---|---|
| 1 | < 28℃ | 땀 부담 낮음 |
| 2 | 28–33℃ | 땀이 날 수 있음 |
| 3 | 33–35℃ | 땀 불편 높음 |
| 4 | 35–36℃ | 땀·더위 부담 매우 높음 |
| 5 | 36–43℃ | 매우 높은 땀·더위 부담 |
| 6 | ≥ 43℃ | 안전 경고 중심 |

근거: 한국인 열감 연구(28·36·43℃) + 국내 폭염특보 기준(33·35℃). **확정된 의학 기준이 아니다.**

### 5.2 개인 보정

```swift
public struct SweatStageEngine {
    public static func stage(
        apparentTemp: Double,
        sensitivity: Sensitivity,
        calibration: Double = 0
    ) -> SweatStage {
        let adjusted = apparentTemp + sensitivity.offset + calibration
        return SweatStage.allCases.first { $0.range.contains(adjusted) } ?? .six
    }
}

public enum Sensitivity: String, CaseIterable, Codable, Sendable {
    case low, normal, high
    var offset: Double {
        switch self {
        case .low:  -1.2
        case .normal: 0
        case .high: +1.2
        }
    }
}
```

### 5.3 습도·풍속

**단계를 바꾸지 않는다** (헌법 IV). 설명 문구와 추천 강도만 보정한다.
체감온도 산식에 습도가 이미 반영되어 있어 이중 계산이 되기 때문이다.

### 5.4 체감온도 산출

기상청 여름철 체감온도는 습구온도 `Tw`와 기온 `Ta`로 계산한다.

```
체감온도 = -0.2442 + 0.55399·Tw + 0.45535·Ta − 0.0022·Tw² + 0.00278·Tw·Ta + 3.0
```

`Tw`는 기온·상대습도로부터 Stull 근사식으로 구한다.

> ⚠️ **착수 전 검증 필요 — 최우선**
> 위 계수는 기상청 공개 자료 기준으로 기재했다. 구현 전 기상청 「여름철 체감온도 산출식」 원문과 대조하고, 검증 케이스(기온 31.5℃ / 습도 78% → 체감 34.2℃ 근방)를 단위 테스트로 고정할 것.
> 값이 다르면 **디자인의 34.2℃가 아니라 산식을 신뢰한다.**

WeatherKit의 `apparentTemperature`는 계산식이 다르므로 **혼용하지 않는다.** 폴백 상황에서만 쓰고 출처를 다르게 표기한다.

---

## 6. 날씨 데이터 파이프라인

### 6.1 이중 소스

| 데이터 | 1순위 | 2순위 |
|---|---|---|
| 현재 기온·습도·풍속 | 기상청 **초단기실황** `getUltraSrtNcst` | WeatherKit `currentWeather` |
| 시간별 예보 (10시간) | 기상청 초단기·단기예보 | WeatherKit `hourlyForecast` |
| 주간 예보 (7일) | 기상청 단기예보(3일) + WeatherKit(4일~) | WeatherKit 전체 |

**출처 표기** — 화면에는 `관측 · 기상청`으로 쓴다. WeatherKit 데이터가 섞이면 **Apple Weather 어트리뷰션과 링크가 법적으로 필수**다. 주간 예보 섹션 하단에 넣고, 기상청만 쓰는 홈 상단 헤더와 구분한다.

### 6.2 기상청 API 구현 주의점

1. **격자 변환** — 위경도가 아니라 `nx, ny`. Lambert Conformal Conic 변환식을 `WeatherData`에 넣고 알려진 좌표쌍(서울시청 → 60,127)으로 테스트 고정
2. **발표 시각** — 초단기실황은 매시 40분 이후 갱신. 40분 이전 호출은 직전 시각으로 요청해야 빈 응답을 피한다
3. **인증키** — `Secrets.xcconfig`로 주입, 커밋 금지
4. **쿼터** — 개발 계정 일 10,000회. 위치+시각 캐시(TTL 10분)로 방어
5. **파싱** — 카테고리 코드(`T1H` 기온 / `REH` 습도 / `WSD` 풍속)를 enum으로. 미지 코드는 무시하되 로깅

### 6.3 캐싱과 실패 처리

```
메모리 캐시(10분) → 디스크 캐시(1시간, stale 허용) → 기상청 → WeatherKit
```

- 전부 실패하면 **마지막 성공 값 + "n분 전 관측" 배지**. 빈 화면을 만들지 않는다
- 기상청 지연 임계 3초. 초과 시 WeatherKit를 병렬로 태우고 먼저 도착한 쪽 사용

---

## 7. 경로와 실내외 노출

### 7.1 파이프라인

```
출발/도착 (MKLocalSearchCompleter)
  → MKDirections(.walking) 후보 경로 N개
  → 20~50m 세그먼트로 분해
  → 세그먼트 라벨링
      ① 지하 연결 데이터 매칭 → 실내·지하
      ② 건물 그림자 추정 → 그늘
      ③ 나머지 → 실외(직사광선)
  → 실외 노출 시간 = Σ(실외 길이) / 보행속도
  → 등급이 높을수록 실외 노출 가중치를 키운 비용 함수로 재정렬
```

### 7.2 그림자 추정

- 태양 방위각·고도각은 좌표와 출발 시각의 순수 함수 (외부 의존 없음)
- 건물 높이는 공공데이터(건축물대장·국가공간정보) 또는 OSM `building:levels`
- 그늘 판정: 건물 그림자 폴리곤이 세그먼트를 덮는지

### 7.3 정확도 — 헌법 VII

가로수·캐노피·육교 하부는 반영되지 않는 **근사치다.**

- 근사 표기(`약 12분`) + 고지 문구 노출
- 분 단위 절대값보다 **두 경로의 상대 비교** 강조
- 지하 연결 데이터가 없는 지역은 비율 섹션을 **숨긴다.** 0%로 표시하지 않는다

### 7.4 무더위쉼터

행정안전부 무더위쉼터 표준데이터를 번들 스냅샷으로 넣고 주기 갱신.
이동 중 화면의 `무더위쉼터 들르기` 카드는 반경 200m 내 최근접 지점을 찾는다.

---

## 8. 이동 중 — Live Activity + 백그라운드 위치

```swift
@Observable
final class MoveTracker {
    private var session: CLBackgroundActivitySession?

    func start() async throws {
        session = CLBackgroundActivitySession()   // 파란 인디케이터
        for try await update in CLLocationUpdate.liveUpdates(.fitness) {
            guard let location = update.location else { continue }
            await handle(location)
            if update.stationary { /* 정지 감지 → 휴식 제안 */ }
        }
    }

    func stop() { session?.invalidate(); session = nil }
}
```

**When In Use 권한으로 충분하다.** `CLBackgroundActivitySession`이 파란 인디케이터를 대가로 백그라운드 갱신을 허용한다. `Always`는 요구하지 않는다 — 심사 마찰과 거부율이 크게 다르다.

```swift
struct MoveActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var progress: Double
        var remainingMinutes: Int
        var outdoorMinutesLeft: Int
        var alert: HeatAlert?
    }
    let from: String
    let to: String
}
```

**업데이트 예산** — 위치 콜백마다 갱신하지 말고 **최소 30초 간격 또는 진행률 5% 변화 시**로 스로틀. 예산 초과 시 정적 표시로 강등.

`Info.plist` — `NSLocationWhenInUseUsageDescription`, `UIBackgroundModes: location, processing`, `NSSupportsLiveActivities: YES`

---

## 9. 알림

전부 **로컬 알림**. 푸시 서버를 만들지 않는다.

| 알림 | 트리거 | 조건 |
|---|---|---|
| 아침 브리핑 | `UNCalendarNotificationTrigger` (기본 07:30) | 예측 등급 ≥ 3 |
| 이동 중 더위 경고 | 앱 내부 이벤트 → 즉시 | 그늘 없는 구간 4분 이상 진입 |
| 기록 리마인드 | 이동 종료 후 30분 | 당일 기록 없음 |

**아침 브리핑의 함정** — 로컬 알림은 예약 시점 내용으로 고정된다. 전날 밤 예약하면 아침 예보와 어긋난다.
→ `BGAppRefreshTask`를 알림 30~60분 전에 예약해 본문을 재작성한다. 백그라운드 실행은 보장되지 않으므로 **실행되지 않았으면 등급을 언급하지 않는 일반 문구로 폴백**한다.

---

## 10. 데이터 모델

**프로필은 SwiftData가 아니다.** 스칼라 몇 개뿐이라 키-값 저장이 맞다.
SwiftData는 날짜별 레코드를 쌓고 조회·집계해야 하는 `SweatLog`에만 쓴다.
이렇게 나누면 001에서 005로 넘어갈 때 마이그레이션이 생기지 않는다.
*(결정 2026-08-19 — 001 착수 시. 이전 판에는 UserProfile도 `@Model`이었다.)*

```swift
// 키-값 저장. 소유는 SweatPersistence.
struct UserProfile: Codable, Sendable {
    var sensitivity: Sensitivity
    var transport: Transport
    var outdoorDuration: OutdoorDuration
    var calibrationOffset: Double
    var humidityBoost: Double
    var notificationHour: Int
    var hasCompletedOnboarding: Bool
}

@Model final class SweatLog {
    var date: Date
    var predictedStage: Int
    var actualScore: Int          // 1...5
    var tags: [String]
    var apparentTemp: Double
    var humidity: Double
    var windSpeed: Double
    var routeOutdoorMinutes: Int?
}
```

### 보정 알고리즘

```swift
func updateCalibration(logs: [SweatLog], profile: UserProfile) {
    let alpha = 0.25
    let highHumidity = logs.filter { $0.humidity >= 70 }
    guard highHumidity.count >= 5 else { return }          // 헌법 VI
    let error = highHumidity.map { Double($0.actualScore - $0.predictedStage) }
    let mean = error.reduce(0, +) / Double(error.count)
    let next = (1 - alpha) * profile.humidityBoost + alpha * mean
    profile.humidityBoost = min(max(next, -1.5), 1.5)      // 헌법 VI
}
```

화면 12의 `평균 0.6단계 높았습니다` 문구는 이 값에서 생성한다.

---

## 11. 디자인 시스템

매핑 규칙은 `design-source.md`. 강제 사항은 헌법 VIII.

**마스코트** — 6단계 캐릭터는 이미지로 굽지 말고 **SwiftUI `Shape`/`Path`로 구현**한다. 단계 전환 시 색·표정·땀방울 개수가 보간되어야 자연스럽다.

---

## 12. 접근성 (헌법 IX)

- **Dynamic Type** — 예보 그리드가 가장 취약. 접근성 크기에서 시간별 예보를 세로 리스트로 전환
- **색상 단독 전달 금지** — 실내(시안)/실외(핑크) 구간 바에 라벨 병기. 색각 이상 사용자에게 66%/34%가 구분되지 않는다
- **VoiceOver** — 마스코트는 정보다. `accessibilityLabel("3단계, 땀 불편 높음")` 필수
- **대비** — `ink/400`(#9B9797) 위 흰 배경은 4.5:1 미달. 12px 캡션 전수 점검 후 필요 시 `ink/500`으로

---

## 13. 권한과 프라이버시

| 키 | 문구 방향 |
|---|---|
| `NSLocationWhenInUseUsageDescription` | 현재 위치의 관측값과 이동 경로의 그늘·실내 구간을 계산하는 데 사용합니다 |
| `UIBackgroundModes` | `location`, `processing` |
| `NSSupportsLiveActivities` | `YES` |

- 위치·기록은 **기기에만 저장.** 서버 전송 없음
- CloudKit 동기화는 2차. 켤 때 개인정보 처리방침 갱신
- ATT 불필요 — 광고 식별자 미사용

---

## 14. 성능·배터리 예산

| 항목 | 목표 |
|---|---|
| 콜드 스타트 → 첫 등급 표시 | 1.5초 (캐시 히트 시 즉시) |
| 이동 중 위치 갱신 | `.fitness`, 30초 스로틀 |
| Live Activity 갱신 | 30초 간격 상한 |
| 30분 이동 배터리 | 8% 이내 |
| 기상청 호출 | 사용자당 일 50회 이하 |

---

## 15. 테스트 전략

| 레이어 | 방식 |
|---|---|
| 등급 엔진 | 경계값 전수 (27.9/28.0/32.9/33.0/34.9/35.0/35.9/36.0/42.9/43.0) |
| 체감온도 산식 | 기상청 공표 사례 대조 (§5.4) |
| 격자 변환 | 알려진 좌표쌍 고정 |
| 보정 엔진 | 합성 로그로 수렴·클램프 검증 |
| 날씨 리포지토리 | JSON 픽스처 + 장애 주입(타임아웃·빈 응답·미지 카테고리) |
| 카피 | 헌법 III 금지 패턴 정규식 린트 |
| UI | 주요 5개 화면 스냅샷 (Dynamic Type 3단계) |

---

## 16. 리스크

| 리스크 | 영향 | 대응 |
|---|---|---|
| 체감온도 산식이 디자인 수치와 불일치 | 전 화면 수치 재조정 | 착수 첫 주에 검증 완료 |
| 그늘 추정 정확도 미달 | 핵심 가치 훼손 | 상대 비교 UI + 데모 지역 실측 |
| 지하 연결 데이터 지역 편차 | 실내 비율 0% | 해당 지역은 섹션 숨김 |
| Live Activity 예산 초과 | 갱신 중단 | 스로틀 + 정적 강등 |
| 백그라운드 리프레시 미실행 | 아침 알림 부정확 | 등급 미언급 폴백 문구 |
| 기상청 장애 | 홈 공백 | WeatherKit 폴백 + stale 배지 |

---

## 17. 마일스톤

| M | 기간 | 내용 | 스펙 |
|---|---|---|---|
| M0 | 3일 | Swift 6 전환, 패키지 분리, 디자인 토큰, 등급 엔진 | 000 |
| M1 | 2주 | 날씨 파이프라인, 홈, 등급 상세, 온보딩 | 001, 002 |
| M2 | 2주 | 지도, 경로 입력, 실내외 비율. 그늘 추정 v1 | 003 |
| M3 | 2주 | 이동 중 + Live Activity, 기록, 마이페이지, 지수 개선 | 004, 005 |
| M4 | 1주 | 접근성 전수, Dynamic Type, 알림 스케줄링, TestFlight | — |

이후 — 위젯, CloudKit 동기화, HealthKit 재검토

---

## 부록 A. 착수 전 확인 (→ GitHub 이슈로 이관)

1. 기상청 체감온도 산식 원문 대조 — **최우선**, `research` 라벨
2. 공공데이터포털 인증키 발급 및 일일 쿼터 확인
3. WeatherKit capability 활성화 (Apple Developer 계정)
4. 지하 연결통로·무더위쉼터 데이터셋 커버리지 확인 (데모 지역 포함 여부)
5. 구간 경계값의 과학적 근거 재검토 — 개발가이드 §10, `research` 라벨

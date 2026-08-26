# 출시 준비 체크리스트

마지막 점검: 2026-08-26

이 문서는 TestFlight 배포 직전의 단일 체크리스트다. 자동 검증과 실기기 검증을
구분하며, 실기기에서 확인하지 않은 항목은 완료로 취급하지 않는다.

## 자동 검증

- [x] 앱과 Live Activity 타깃을 iPhone 전용으로 설정했다 (`UIDeviceFamily = 1`).
- [x] 지원 방향을 Portrait로 고정했다.
- [x] 1024×1024, 알파 채널 없는 기본 App Icon을 Asset Catalog에 포함했다.
- [x] `PrivacyInfo.xcprivacy`에 앱 내부 `UserDefaults` 사용 사유 `CA92.1`을 선언했다.
- [x] 추적을 사용하지 않고 자체 수집 데이터가 없음을 Privacy Manifest에 선언했다.
- [x] 자체 비면제 암호화를 사용하지 않음을 `ITSAppUsesNonExemptEncryption = false`로 선언했다.
- [x] 작은 사용자 조작 요소를 44×44pt 이상으로 보정했다.
- [x] 시간별 예보 VoiceOver 문구에 땀 단계·기온·습도 명칭과 값을 포함했다.
- [x] 접근성 글자 크기에서 홈 헤더·주간 예보·경로 지점 행이 다시 배치되도록 했다.
- [x] Primary 버튼의 흰 글자 대비를 4.5:1 이상으로 올렸다.
- [x] 토큰 린트와 `git diff --check`를 통과했다.
- [x] 테스트 타깃이 있는 7개 Swift 패키지의 154개 테스트를 통과했다.
- [x] Debug/Release iOS Simulator 빌드를 통과했다.
- [x] Release iPhone Archive를 생성했다.
- [x] Archive에 App Icon, Privacy Manifest, iPhone/Portrait/버전 설정이 포함됨을 확인했다.

## 배포 전 결정

- [ ] 사용자에게 표시할 앱 이름을 정하고 `CFBundleDisplayName`에 반영한다.
- [ ] App Store Connect에 같은 Bundle ID의 앱 레코드가 있는지 확인한다.
- [ ] TestFlight의 베타 앱 설명과 피드백 이메일을 준비한다.
- [ ] Figma `Style=Primary` 컴포넌트도 코드와 같은 `accent/deep`으로 동기화한다.

현재 Archive는 로컬의 `Apple Development` ID로 생성됐다. 키체인에는 배포 ID가
없으므로 App Store Connect용 내보내기 시 Xcode가 배포 인증서 또는 클라우드 관리
인증서를 준비해야 한다. 이는 계정 상태를 변경할 수 있어 업로드 직전에 진행한다.

## 실기기 접근성

- [ ] VoiceOver로 온보딩 → 홈 → 경로 → 이동 종료까지 순서대로 조작한다.
- [ ] VoiceOver 포커스 순서와 버튼·선택 상태·마스코트 설명을 확인한다.
- [ ] 가장 큰 접근성 글자 크기에서 텍스트 잘림과 가로 스크롤이 없는지 확인한다.
- [ ] 굵은 텍스트, 대비 증가, 동작 줄이기 설정에서 정보가 사라지지 않는지 확인한다.
- [ ] 모든 주요 조작 영역이 한 손 조작과 44×44pt 터치에 충분한지 확인한다.

## 실기기 기능

- [ ] 위치 권한의 허용·거부·설정에서 재허용 흐름을 각각 확인한다.
- [ ] 실제 위치에서 현재 날씨와 출처 표기가 맞는지 확인한다.
- [ ] 도보 경로 검색 성공·빈 결과·네트워크 실패·재시도를 확인한다.
- [ ] 앱을 잠그거나 백그라운드로 보낸 뒤 이동 추적이 이어지는지 확인한다.
- [ ] 잠금 화면과 Dynamic Island에서 Live Activity 시작·갱신·종료를 확인한다.
- [ ] 이동 중 배터리 소모와 위치 갱신 빈도가 허용 가능한지 측정한다.
- [ ] 앱 강제 종료·재실행 뒤 진행 중 이동 복원과 취소를 확인한다.

## TestFlight 순서

1. 앱 이름과 App Store Connect 앱 레코드를 확정한다.
2. 빌드 번호를 이전 업로드보다 큰 값으로 올린다.
3. Xcode Organizer에서 Archive를 Validate한다.
4. 배포 서명과 프로비저닝을 준비한다.
5. `Distribute App` → `App Store Connect` → `Upload`를 실행한다.
6. 처리 완료 후 내부 테스터 그룹에 빌드를 연결한다.
7. 실기기 체크리스트를 통과한 뒤 외부 테스트 여부를 결정한다.

참고:

- [TestFlight 개요](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/)
- [빌드 업로드](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/)
- [Privacy Manifest](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files)
- [Required Reason API](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)

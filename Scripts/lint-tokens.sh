#!/bin/bash
#
# 디자인 토큰 강제 검사 (규칙 「색과 글꼴은 토큰으로」)
#
# 화면 코드는 색상·폰트를 리터럴로 쓰지 않고 DesignSystem 토큰을 경유해야 한다.
# 이 스크립트는 그 규칙을 기계적으로 검사한다.
#
#   ./Scripts/lint-tokens.sh
#
# DesignSystem 패키지 자체는 검사하지 않는다. 토큰이 정의되는 곳이므로
# 리터럴이 있는 것이 정상이다.
#
# 대상 경로는 Features 패키지가 생기는 001부터 늘려간다.

set -uo pipefail
cd "$(dirname "$0")/.."

TARGETS=(
  "ADA_Challenge5_Norton/ADA_Challenge5_Norton"
  # 001부터 추가:
  # "ADA_Challenge5_Norton/Packages/SweatFeatures/Sources"
)

errors=0
warnings=0

report() {          # report <심각도> <설명> <대안> <패턴>
  local level="$1" what="$2" instead="$3" pattern="$4"
  local hits
  hits=$(grep -rnE --include="*.swift" "$pattern" "${TARGETS[@]}" 2>/dev/null | grep -v "^\s*//")
  [ -z "$hits" ] && return 0

  local count
  count=$(echo "$hits" | wc -l | tr -d ' ')
  if [ "$level" = "error" ]; then
    echo "✖ $what — $count건"
    errors=$((errors + count))
  else
    echo "△ $what — $count건 (경고)"
    warnings=$((warnings + count))
  fi
  echo "$hits" | sed 's/^/    /'
  echo "    → $instead"
  echo
}

echo "디자인 토큰 검사 — 규칙 「색과 글꼴은 토큰으로」"
echo "대상: ${TARGETS[*]}"
echo

report error "색상 리터럴" \
  "Ink · Accent · Magenta · Surface · BorderColor · StageColor 를 쓴다" \
  '(Color\(red:|Color\(hex:|Color\(\.sRGB|UIColor\(|NSColor\()'

report error "SwiftUI 기본 색상" \
  "토큰 팔레트에서 가장 가까운 색을 쓴다" \
  '\.(foregroundStyle|foregroundColor|background|fill|tint|stroke|strokeBorder)\(\s*\.(red|orange|yellow|green|mint|teal|cyan|blue|indigo|purple|pink|brown|gray|black|white)\b'

report error "폰트 리터럴" \
  ".sweatType(.body15) 처럼 텍스트 스타일 토큰을 쓴다" \
  '\.font\(\s*\.(system|custom)\('

report warning "숫자 모서리 반경" \
  "Radius.sm · md · lg · xl · pill 을 쓴다" \
  'cornerRadius:\s*[0-9]'

report warning "숫자 간격" \
  "Space.x1 ~ x7 · Space.gutter 를 쓴다" \
  '\.(padding|spacing:)\s*\(?\s*[0-9]+'

echo "────────────────────────────"
if [ "$errors" -gt 0 ]; then
  echo "실패: 오류 $errors건, 경고 $warnings건"
  echo
  echo "리터럴을 써야만 하는 이유가 있다면 규칙 「색과 글꼴은 토큰으로」을 먼저 개정한다."
  exit 1
fi

if [ "$warnings" -gt 0 ]; then
  echo "통과 (경고 $warnings건)"
else
  echo "통과"
fi

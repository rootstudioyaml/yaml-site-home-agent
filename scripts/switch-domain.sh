#!/usr/bin/env bash
# 커스텀 도메인 전환 — DEPLOY.md 의 5·7·8 단계를 한 번에 수행한다.
#
# 전제(사용자가 먼저 끝내야 하는 것): DEPLOY.md 1~4 단계
#   도메인 등록 → Cloudflare 사이트 추가 → 네임서버 변경 → A/CNAME 레코드 등록(DNS only).
#
# 이 스크립트는 DNS 가 GitHub Pages 를 가리키는지 먼저 확인하고, 아니면 아무것도 바꾸지 않는다.
# CNAME 파일을 먼저 올리면 github.io 주소가 새 도메인으로 리다이렉트되는데, 그때 DNS 가
# 준비돼 있지 않으면 사이트 전체가 접속 불가가 된다. 그 사고를 막는 것이 이 가드의 목적이다.
#
# Usage: bash scripts/switch-domain.sh [도메인]        (기본값 j-housing.co.kr)
#        bash scripts/switch-domain.sh --check         (전환 없이 준비 상태만 점검)
set -euo pipefail
cd "$(dirname "$0")/.."

DOMAIN="${1:-j-housing.co.kr}"
[ "$DOMAIN" = "--check" ] && { DOMAIN="j-housing.co.kr"; CHECK_ONLY=1; } || CHECK_ONLY="${CHECK_ONLY:-0}"
OLD_URL="https://rootstudioyaml.github.io/yaml-site-home-agent"
NEW_URL="https://${DOMAIN}"
PAGES_IPS="185.199.108.153 185.199.109.153 185.199.110.153 185.199.111.153"

say() { printf '%s\n' "$*"; }
fail() { printf '✖ %s\n' "$*" >&2; exit 1; }

say "▶ 대상 도메인: ${DOMAIN}"

# ── 1. DNS 준비 확인 ─────────────────────────────────────────────
A_RECORDS="$(dig +short A "$DOMAIN" 2>/dev/null | sort || true)"
[ -z "$A_RECORDS" ] && fail "A 레코드가 없습니다. 도메인 등록과 Cloudflare DNS 설정(DEPLOY.md 1~4단계)을 먼저 끝내세요."

MATCHED=0
for ip in $A_RECORDS; do
  case " $PAGES_IPS " in *" $ip "*) MATCHED=$((MATCHED+1));; esac
done
say "  A 레코드: $(echo $A_RECORDS | tr '\n' ' ')"
[ "$MATCHED" -eq 0 ] && fail "A 레코드가 GitHub Pages IP(185.199.108~111.153)를 가리키지 않습니다. Cloudflare 프록시가 켜져 있으면 회색 구름(DNS only)으로 내리세요."
say "  ✔ GitHub Pages IP ${MATCHED}개 확인"

if [ "$CHECK_ONLY" = "1" ]; then
  say "▶ --check 모드이므로 여기서 종료합니다. 전환하려면 인자 없이 다시 실행하세요."
  exit 0
fi

# ── 2. CNAME 파일 ────────────────────────────────────────────────
printf '%s\n' "$DOMAIN" > CNAME
say "  ✔ CNAME 파일 작성"

# ── 3. 사이트 내부 절대 URL 교체 ─────────────────────────────────
BEFORE="$(grep -c "$OLD_URL" index.html || true)"
sed -i '' "s|${OLD_URL}|${NEW_URL}|g" index.html
AFTER="$(grep -c "$NEW_URL" index.html || true)"
say "  ✔ 절대 URL 교체: ${BEFORE}곳 → ${NEW_URL} (${AFTER}곳 확인)"
grep -c "$OLD_URL" index.html >/dev/null 2>&1 && say "  ⚠ 옛 URL 이 아직 남아 있습니다. 직접 확인하세요."

# ── 4. 커밋·푸시 ─────────────────────────────────────────────────
git add CNAME index.html
git commit -q -m "chore: 커스텀 도메인 ${DOMAIN} 연결

CNAME 추가 및 canonical·OG·JSON-LD 절대 URL 교체."
git push -q origin main
say "  ✔ 커밋·푸시 완료"

# ── 5. GitHub Pages 커스텀 도메인 지정 ───────────────────────────
if command -v gh >/dev/null 2>&1; then
  gh api -X PUT repos/rootstudioyaml/yaml-site-home-agent/pages \
    -f "cname=${DOMAIN}" >/dev/null 2>&1 && say "  ✔ Pages 커스텀 도메인 설정" \
    || say "  ⚠ Pages 설정 실패 — Settings → Pages 에서 수동 입력하세요."
fi

# ── 6. 검증 ──────────────────────────────────────────────────────
say "▶ 인증서 발급 대기(최대 10분)…"
for i in $(seq 1 40); do
  sleep 15
  CODE="$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "https://${DOMAIN}/" || echo 000)"
  say "  [$i] https://${DOMAIN} → ${CODE}"
  [ "$CODE" = "200" ] && break
done

say ""
say "▶ 최종 확인"
curl -sI "https://${DOMAIN}/" | head -3 || true
curl -s "https://${DOMAIN}/" | grep -E 'og:image|canonical' || true
say ""
say "남은 작업: Settings → Pages 에서 Enforce HTTPS 체크, 그리고 공유 썸네일 캐시 갱신"
say "  카카오 https://developers.kakao.com/tool/clear/og"

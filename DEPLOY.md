# 배포 가이드 — j-housing.co.kr

제이하우징 홈페이지를 GitHub Pages에 올리고 `j-housing.co.kr` 도메인을 연결하는 절차입니다.

| 항목 | 값 |
| --- | --- |
| 대표 도메인 | `j-housing.co.kr` |
| 저장소 | `rootstudioyaml/yaml-site-home-agent` |
| 호스팅 | GitHub Pages (`main` 브랜치 루트) |
| DNS·CDN | Cloudflare (무료 플랜) |
| 도메인 등록 | 국내 등록대행자 (가비아 등) |

도메인 가용성은 2026-08-30에 KISA whois로 확인했으며, 그 시점에 `j-housing.co.kr`은 미등록 상태였습니다.

---

## 1. 도메인 등록

Cloudflare Registrar는 `.kr` 및 `.co.kr`을 취급하지 않기 때문에 국내 등록대행자에서 등록해야 합니다.

1. 가비아(또는 후이즈)에서 `j-housing.co.kr` 검색 후 등록합니다. 비용은 연 2만 원 안팎입니다.
2. 등록인 정보에는 국내 주소와 연락처를 입력합니다. `.kr` 계열은 국내 주소가 요건입니다.
3. 자동 갱신을 켜 둡니다. 만료로 도메인을 잃으면 복구 비용이 훨씬 큽니다.

등록 직후에는 네임서버가 등록대행자 기본값으로 잡혀 있습니다. 3단계에서 Cloudflare 네임서버로 바꿉니다.

## 2. Cloudflare에 사이트 추가

1. Cloudflare 대시보드에서 **Add a site**를 눌러 `j-housing.co.kr`을 입력하고 Free 플랜을 선택합니다.
2. Cloudflare가 네임서버 두 개를 배정합니다. 예시 형태는 `xxx.ns.cloudflare.com`이며, 계정마다 다르므로 화면에 나온 값을 그대로 사용합니다.

## 3. 등록대행자에서 네임서버 변경

가비아 기준으로 **My가비아 → 도메인 → 관리 → 네임서버 설정**에서 2단계에서 받은 네임서버 두 개를 입력하고 저장합니다.

반영에는 보통 몇 분에서 수 시간이 걸립니다. 확인 명령은 다음과 같습니다.

```bash
dig NS j-housing.co.kr +short
```

출력에 `ns.cloudflare.com`이 포함되면 위임이 끝난 것입니다.

## 4. Cloudflare DNS 레코드 등록

Apex 도메인(`j-housing.co.kr`)은 GitHub Pages의 A 레코드 네 개를 그대로 넣습니다. Cloudflare의 CNAME flattening으로도 되지만, GitHub이 인증서를 발급하는 과정에서 문제가 적은 쪽은 A 레코드 방식입니다.

| 유형 | 이름 | 값 | 프록시 |
| --- | --- | --- | --- |
| A | `@` | `185.199.108.153` | DNS only |
| A | `@` | `185.199.109.153` | DNS only |
| A | `@` | `185.199.110.153` | DNS only |
| A | `@` | `185.199.111.153` | DNS only |
| CNAME | `www` | `rootstudioyaml.github.io` | DNS only |

**프록시는 반드시 처음에 회색 구름(DNS only)으로 둡니다.** 주황색 구름(프록시 켜짐) 상태에서는 GitHub이 도메인 소유를 검증하지 못해 HTTPS 인증서 발급이 실패합니다. 인증서가 발급된 뒤에 프록시를 켜고 싶다면 6단계를 따릅니다.

## 5. GitHub Pages 연결

1. 저장소 루트에 `CNAME` 파일을 만들고 내용을 `j-housing.co.kr` 한 줄로 채운 다음 커밋합니다.

   ```bash
   echo "j-housing.co.kr" > CNAME
   git add CNAME && git commit -m "chore: 커스텀 도메인 CNAME 추가"
   git push
   ```

2. 저장소 **Settings → Pages**에서 Source를 `main` 브랜치 루트로 지정합니다.
3. 같은 화면의 Custom domain에 `j-housing.co.kr`을 입력합니다. DNS 검증이 통과하면 초록색 체크가 뜹니다.
4. 인증서 발급이 끝나면 **Enforce HTTPS**를 체크합니다. 발급까지 보통 10분에서 1시간이 걸리며, 그 전에는 이 항목이 회색으로 비활성화되어 있습니다.

확인 명령은 다음과 같습니다.

```bash
curl -sI https://j-housing.co.kr | head -5
```

## 6. (선택) Cloudflare 프록시 켜기

HTTPS가 정상 동작하는 것을 확인한 뒤에만 진행합니다.

1. **SSL/TLS → Overview**에서 암호화 모드를 **Full (strict)** 로 설정합니다. Flexible로 두면 무한 리다이렉트가 발생합니다.
2. 4단계의 A 레코드와 `www` CNAME을 주황색 구름으로 전환합니다.
3. **Rules → Redirect Rules**에서 `www.j-housing.co.kr` 요청을 apex로 301 리다이렉트하는 규칙을 추가합니다.

프록시를 켜면 캐시와 이미지 최적화를 쓸 수 있지만, GitHub Pages 단독으로도 이 규모의 정적 사이트에는 충분합니다. 급하지 않다면 5단계에서 멈춰도 무방합니다.

## 7. 사이트 내부 URL 교체

도메인 연결이 끝나면 `index.html`에 하드코딩된 절대 URL 여덟 곳을 새 도메인으로 바꿉니다. 현재 값은 `https://rootstudioyaml.github.io/yaml-site-home-agent/` 기준입니다.

```bash
sed -i '' 's|https://rootstudioyaml.github.io/yaml-site-home-agent|https://j-housing.co.kr|g' index.html
grep -n "j-housing.co.kr" index.html
```

교체 대상은 다음과 같습니다.

- 8행 `canonical`
- 18행 `og:url`
- 19행 `og:image`
- 26행 `twitter:image`
- 32행 JSON-LD `@id`
- 36행 JSON-LD `url`
- 38행 JSON-LD `image`
- 39행 JSON-LD `logo`

경로 끝의 슬래시가 중복되지 않았는지 확인한 다음 커밋하고 푸시합니다.

## 8. 배포 검증

```bash
# DNS 위임
dig NS j-housing.co.kr +short

# apex A 레코드
dig A j-housing.co.kr +short

# HTTPS 응답과 인증서
curl -sI https://j-housing.co.kr | head -5
curl -sv https://j-housing.co.kr 2>&1 | grep -i "subject\|issuer" | head -4

# www 리다이렉트
curl -sI https://www.j-housing.co.kr | head -3

# 메타 태그 반영 여부
curl -s https://j-housing.co.kr | grep -E "og:image|canonical"
```

공유 썸네일은 캐시가 오래 남습니다. 도메인 교체 후에는 아래 도구로 강제 갱신합니다.

- 카카오톡: <https://developers.kakao.com/tool/debugger/sharing>
- 페이스북: <https://developers.facebook.com/tools/debug/>
- 네이버 서치어드바이저: 사이트 등록 후 수집 요청

## 9. 후속 작업

- 네이버 서치어드바이저와 Google Search Console에 새 도메인을 등록하고 소유권을 확인합니다.
- 네이버 플레이스, 숨고 프로필, 명함, 견적서에 적힌 주소를 새 도메인으로 통일합니다.
- 방어용으로 `jhousing.co.kr`을 함께 등록해 apex로 301 리다이렉트를 걸어 두면 오타 유입을 잡을 수 있습니다.

## 알려진 함정

- **프록시를 먼저 켜면 인증서 발급이 막힙니다.** GitHub Pages의 Custom domain 검증이 실패하면 4단계의 프록시 상태부터 확인합니다.
- **`CNAME` 파일이 사라지는 경우가 있습니다.** 빌드 산출물로 배포 브랜치를 덮어쓰는 워크플로를 나중에 도입하면 `CNAME`이 지워집니다. 이 저장소는 현재 정적 파일을 직접 서빙하므로 해당하지 않지만, 워크플로를 추가할 때 유의합니다.
- **`.co.kr`은 Cloudflare에서 이전 관리가 되지 않습니다.** 갱신과 등록인 정보 변경은 계속 등록대행자 쪽에서 해야 하며, Cloudflare는 DNS만 담당합니다.

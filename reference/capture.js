const puppeteer = require('puppeteer');
const path = require('path');
const fs = require('fs');

const ROOT = __dirname;
const OUT = path.join(ROOT, 'screenshots');
fs.mkdirSync(OUT, { recursive: true });

const jobs = [
  // 메인 1장 — 1304×976 (2x of 652×488, kmong 한도 내)
  { src: 'thumb/main.html',          out: 'main.png',           w: 1304, h: 976,  full: false, wait: 200 },
  { src: 'thumb/profile.html',       out: 'profile.png',        w: 1000, h: 1000, full: false, wait: 200 },

  // 상세 9장 — 가로 1304, 세로는 풀페이지 (자동)
  { src: 'details/01-hero.html',       out: 'detail-01-hero.png',       w: 1304, full: true, wait: 200 },
  { src: 'details/02-pain.html',       out: 'detail-02-pain.png',       w: 1304, full: true, wait: 200 },
  { src: 'details/about.html',         out: 'detail-about.png',         w: 1304, full: true, wait: 200 },
  { src: 'details/03-portfolio.html',  out: 'detail-03-portfolio.png',  w: 1304, full: true, wait: 200 },
  { src: 'details/04-process.html',    out: 'detail-04-process.png',    w: 1304, full: true, wait: 200 },
  { src: 'details/05-pricing.html',    out: 'detail-05-pricing.png',    w: 1304, full: true, wait: 200 },
  { src: 'details/06-tech.html',       out: 'detail-06-tech.png',       w: 1304, full: true, wait: 200 },
  { src: 'details/07-comparison.html', out: 'detail-07-comparison.png', w: 1304, full: true, wait: 200 },
  { src: 'details/08-testimonial.html',out: 'detail-08-testimonial.png',w: 1304, full: true, wait: 200 },
  { src: 'details/09-cta.html',        out: 'detail-09-cta.png',        w: 1304, full: true, wait: 200 },

  // 동영상 포스터 5장 — 1920×1080 (애니메이션 정점에서 캡처)
  { src: 'videos/01-hero-loop.html',        out: 'video-01-poster.png', w: 1920, h: 1080, full: false, wait: 1500 },
  { src: 'videos/02-typing.html',           out: 'video-02-poster.png', w: 1920, h: 1080, full: false, wait: 8500 },
  { src: 'videos/03-portfolio-scroll.html', out: 'video-03-poster.png', w: 1920, h: 1080, full: false, wait: 3000 },
  { src: 'videos/04-process-anim.html',     out: 'video-04-poster.png', w: 1920, h: 1080, full: false, wait: 9500 },
  { src: 'videos/05-stats.html',            out: 'video-05-poster.png', w: 1920, h: 1080, full: false, wait: 4000 },
];

(async () => {
  const browser = await puppeteer.launch({
    headless: 'new',
    executablePath: '/usr/bin/chromium-browser',
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--font-render-hinting=none'],
  });

  for (const j of jobs) {
    const page = await browser.newPage();
    const h = j.h ?? 800;
    await page.setViewport({ width: j.w, height: h, deviceScaleFactor: 1 });
    const url = 'file://' + path.join(ROOT, j.src);
    await page.goto(url, { waitUntil: 'networkidle0', timeout: 30000 });
    await new Promise(r => setTimeout(r, j.wait));

    const outPath = path.join(OUT, j.out);
    await page.screenshot({
      path: outPath,
      fullPage: !!j.full,
      type: 'png',
      omitBackground: false,
    });

    const { size } = fs.statSync(outPath);
    console.log(`✓ ${j.out.padEnd(32)} ${(size / 1024).toFixed(0).padStart(6)} KB`);
    await page.close();
  }

  await browser.close();
})();

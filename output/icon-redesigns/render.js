// Usage: node render.js <in.svg> <out.png> [size]
const { chromium } = require(require('child_process').execSync('npm root -g').toString().trim() + '/playwright');
const fs = require('fs');
(async () => {
  const [inp, out, size = '1024'] = process.argv.slice(2);
  const s = parseInt(size);
  const svg = fs.readFileSync(inp, 'utf8');
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: s, height: s } });
  await page.setContent(`<html><body style="margin:0;background:transparent">${svg.replace('<svg', `<svg width="${s}" height="${s}"`)}</body></html>`);
  await page.screenshot({ path: out, omitBackground: true, clip: { x: 0, y: 0, width: s, height: s } });
  await browser.close();
})();

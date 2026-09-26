// Usage: node contact.js  → contact-sheet.png (all redesigns, masked as rounded icons, large + small)
const { chromium } = require(require('child_process').execSync('npm root -g').toString().trim() + '/playwright');
const fs = require('fs');
(async () => {
  const files = fs.readdirSync(__dirname).filter(f => /^\d\d-.*\.png$/.test(f)).sort();
  const cell = f => {
    const src = 'data:image/png;base64,' + fs.readFileSync(__dirname + '/' + f).toString('base64');
    return `<div class="c"><img class="big" src="${src}"><div class="row"><img class="s" src="${src}" style="width:64px;height:64px"><img class="s" src="${src}" style="width:32px;height:32px"><img class="s" src="${src}" style="width:16px;height:16px"></div><p>${f.replace('.png', '')}</p></div>`;
  };
  const html = `<html><body style="margin:0;background:#e9ebf0;font:600 15px -apple-system,Helvetica,sans-serif;color:#223">
  <style>.g{display:grid;grid-template-columns:repeat(5,240px);gap:28px;padding:32px}.c{text-align:center}.big{width:220px;height:220px;border-radius:22.4%;box-shadow:0 6px 18px #0003}.row{display:flex;gap:12px;justify-content:center;align-items:end;height:70px;margin-top:10px}.s{border-radius:22.4%}p{margin:6px 0 0}</style>
  <div class="g">${files.map(cell).join('')}</div></body></html>`;
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 1432, height: 800 } });
  await p.setContent(html);
  await p.screenshot({ path: __dirname + '/contact-sheet.png', fullPage: true });
  await b.close();
})();

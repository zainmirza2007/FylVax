// Run against a local server: PLAYWRIGHT_MODULE points to an installed Playwright package.
// Optional: BASE_URL and SCREENSHOT_DIR. No app dependency is required.
const {chromium}=require(process.env.PLAYWRIGHT_MODULE||'playwright');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const base=process.env.BASE_URL||'http://localhost:3100';

(async()=>{
 const browser=await chromium.launch({channel:'chrome',headless:true});
 try{
  const page=await browser.newPage();
  const errors=[];
  page.on('pageerror',e=>errors.push(e.message));
  const sitemap=await (await page.request.get(base+'/sitemap.xml')).text();
  const urls=[...sitemap.matchAll(/<loc>(.*?)<\/loc>/g)].map(m=>m[1]);
  assert.equal(urls.length,63);
  const titles=new Set();
  for(const url of urls){
   const response=await page.request.get(url);
   assert.equal(response.status(),200,url);
   const html=await response.text();
   assert.equal((html.match(/<h1[ >]/g)||[]).length,1,url+' heading');
   assert.ok(html.includes(`<link rel="canonical" href="${url}">`),url+' canonical');
   assert.match(html,/<meta name="description" content="[^"]+"/);
   assert.ok(!html.includes('content="noindex'),url+' indexable');
   assert.ok(!html.includes('pagead2.googlesyndication.com'),url+' ads disabled');
   const title=html.match(/<title>(.*?)<\/title>/)[1];
   assert.ok(!titles.has(title),url+' unique title');titles.add(title);
   for(const block of html.matchAll(/<script type="application\/ld\+json">(.*?)<\/script>/gs)) JSON.parse(block[1]);
  }
  for(const pathname of ['/process/invalid','/download/invalid','/result/invalid']){
   const response=await page.request.get(base+pathname);
   assert.equal(response.status(),404);
   assert.match(response.headers()['x-robots-tag'],/noindex/);
  }
  const routes=['/','/tools/','/image/','/image/compress-image','/pdf/compress-pdf','/guides/','/privacy/'];
  for(const width of [375,768,1024,1440]){
   await page.setViewportSize({width,height:900});
   for(const pathname of routes){
    await page.goto(base+pathname);
    assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),`${pathname} overflow at ${width}`);
    for(const href of await page.locator('a[href^="/"]').evaluateAll(nodes=>nodes.map(n=>n.getAttribute('href')))){
     assert.ok(urls.includes(base+href),`${pathname}: unknown link ${href}`);
    }
    if(process.env.SCREENSHOT_DIR&&['/','/image/compress-image','/tools/'].includes(pathname)){
     fs.mkdirSync(process.env.SCREENSHOT_DIR,{recursive:true});
     await page.screenshot({path:path.join(process.env.SCREENSHOT_DIR,`${pathname==='/'?'home':pathname.split('/').filter(Boolean).join('-')}-${width}.png`),fullPage:true});
    }
   }
  }
  await page.setViewportSize({width:375,height:900});
  await page.goto(base);
  await page.getByRole('button',{name:'Open menu'}).click();
  assert.equal(await page.locator('.menuBtn').getAttribute('aria-expanded'),'true');
  assert.ok(await page.locator('#mobile-nav').isVisible());
  await page.keyboard.press('Escape');
  assert.equal(await page.locator('.menuBtn').getAttribute('aria-expanded'),'false');
  assert.ok(!await page.locator('#mobile-nav').isVisible());
  const search=page.locator('[data-tool-search]');
  await search.fill('pdf compress');
  assert.equal(await page.locator('[data-search-item]:visible').count(),1);
  assert.equal(await page.locator('[data-search-item]:visible').getAttribute('href'),'/pdf/compress-pdf');
  await search.press('ArrowDown');
  assert.equal(await page.evaluate(()=>document.activeElement.getAttribute('href')),'/pdf/compress-pdf');
  await page.keyboard.press('Escape');
  assert.ok(!await page.locator('[data-search-results]').isVisible());
  await search.fill('zzzznonexistent');
  assert.ok(await page.locator('[data-search-empty]').isVisible());
  assert.equal(await page.locator('[data-search-item]:visible').count(),0);
  await search.fill('');
  assert.ok(!await page.locator('[data-search-results]').isVisible());
  await page.goto(base+'/image/compress-image');
  const input=page.locator('input[type=file]');
  await input.focus();
  assert.equal(await input.evaluate(el=>getComputedStyle(el.nextElementSibling).outlineStyle),'solid');
  await input.setInputFiles(path.join(__dirname,'fixtures/test.png'));
  assert.match(await page.locator('.fileName').innerText(),/test\.png/);
  await page.getByText('Smaller file',{exact:true}).click();
  assert.equal(await page.locator('input[name=quality]:checked').inputValue(),'65');
  await page.locator('.advanced summary').click();
  await page.locator('select[name=output]').selectOption('webp');
  await page.locator('.faqList summary').first().click();
  assert.ok(await page.locator('.faqList details').first().evaluate(e=>e.open));
  let submitted=false;
  await page.route('**/process/compress-image',async route=>{
   const body=route.request().postDataBuffer().toString();
   assert.match(body,/filename="test.png"/);
   assert.match(body,/name="quality"\r\n\r\n65/);
   assert.match(body,/name="output"\r\n\r\nwebp/);
   submitted=true;
   await route.fulfill({status:200,contentType:'text/html',body:'<!doctype html><title>Form verified</title><p>Form verified</p>'});
  });
  await page.locator('button[type=submit]').click();
  await page.waitForURL('**/process/compress-image');
  assert.ok(submitted,'multipart form submission');
  await page.goBack();
  assert.ok(await page.locator('button[type=submit]').isEnabled(),'back navigation allows retry');
  assert.deepEqual(errors,[]);
  console.log('PASS: 63 public pages; titles, canonical URLs, descriptions, JSON-LD; private route noindex; 28 responsive page checks; internal links; mobile menu; search; keyboard upload; settings; FAQ; multipart submission and back navigation. Conversion engine not covered.');
 }finally{await browser.close();}
})().catch(error=>{console.error(error);process.exitCode=1;});

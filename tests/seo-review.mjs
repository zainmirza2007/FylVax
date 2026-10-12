import assert from 'node:assert/strict';

const base=process.env.BASE_URL||'http://localhost:3100';
const read=async path=>{const response=await fetch(base+path);assert.equal(response.status,200,path);return response.text();};
const sitemap=await read('/sitemap.xml');
const urls=[...sitemap.matchAll(/<loc>(.*?)<\/loc>/g)].map(match=>match[1]);
assert.equal(new Set(urls).size,urls.length,'unique sitemap entries');
assert.equal(urls.length,63,'public route inventory remains unchanged');
const pages=new Map();
for(const url of urls){
 const path=new URL(url).pathname;
 const html=await read(path);
 pages.set(path,html);
 const schemas=[...html.matchAll(/<script type="application\/ld\+json">(.*?)<\/script>/gs)].map(match=>JSON.parse(match[1]));
 const websites=schemas.filter(schema=>schema['@type']==='WebSite');
 assert.equal(websites.length,1,path+' has one website identity');
 assert.equal(websites[0]['@id'],base+'/#website');
 assert.ok(!html.includes('hello@example.com'),path+' no placeholder email');
 assert.ok(!html.includes('made for the task, not just the keyword'));
 for(const match of html.matchAll(/href="(\/[^"#?]*)(?:[?#][^"]*)?"/g)){
  if(/\.(css|js|svg|ico|png)$/.test(match[1]))continue;
  assert.ok(urls.includes(base+match[1]),path+' links to '+match[1]);
 }
}
assert.match(pages.get('/'),/<h1>Convert and compress files\./);
for(const route of ['/contact/','/privacy/','/copyright/'])assert.match(pages.get(route),/mailto:fylvax@gmail\.com/);
assert.ok(!pages.get('/privacy/').includes('Last updated:'),'no automatic update date');
const pairs={
 'webp-vs-png':['/image/png-to-webp','/image/jpg-to-webp','/image/webp-to-png'],
 'how-pdf-compression-works':['/pdf/compress-pdf'],
 'mp4-vs-webm':['/video/convert-video','/video/mp4-to-webm','/video/webm-to-mp4'],
 'heic-to-jpg-guide':['/image/heic-to-jpg'],
 'video-compression-guide':['/video/compress-video','/video/resize-video']
};
for(const [guide,tools] of Object.entries(pairs)){
 const route='/guides/'+guide;
 for(const tool of tools){
  assert.ok(pages.get(route).includes(`href="${tool}"`),route+' contextual tool link');
  assert.ok(pages.get(tool).includes(`href="${route}"`),tool+' relevant guide link');
 }
}
assert.ok(!sitemap.includes('lastmod'),'do not fabricate modification dates');
for(const route of ['/process/unknown','/result/unknown','/download/unknown']){
 const response=await fetch(base+route);
 assert.equal(response.status,404);
 assert.match(response.headers.get('x-robots-tag'),/noindex/);
 assert.ok(!(await response.text()).includes('adsbygoogle'));
}
console.log('PASS: 63 pages, valid internal links, consistent website identity, confirmed contact email, stable date handling, reciprocal guide/tool links, unchanged sitemap and private-route noindex.');

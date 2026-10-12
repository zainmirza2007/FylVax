import { spawnSync } from 'node:child_process';
const isWin=process.platform==='win32';
function has(cmd){
  const r=spawnSync(isWin?'where':'which',[cmd],{stdio:'ignore'});
  return r.status===0;
}
const commands=['ffmpeg','ffprobe','gs','pdftoppm','pdfseparate','pdfunite','libreoffice','python3','file','zip','heif-convert'];
const checks=Object.fromEntries(commands.map(c=>[c,has(c)]));
const imageMagick=has('magick')?'magick':(has('convert')?'convert':null);
let pythonPackages=false;
if(checks.python3){
  const r=spawnSync('python3',['-c','import PIL, fitz'],{stdio:'ignore'});
  pythonPackages=r.status===0;
}
const ok=Object.values(checks).every(Boolean)&&Boolean(imageMagick)&&pythonPackages;
console.log(JSON.stringify({ok,commands:checks,imageMagick,pythonPackages},null,2));
if(!ok){
  console.error('\nRuntime is incomplete. The easiest supported setup is: docker compose up --build');
  process.exit(1);
}

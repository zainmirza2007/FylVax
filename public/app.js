const menuBtn=document.querySelector('.menuBtn');
const mobileNav=document.querySelector('.mobileNav');
if(menuBtn&&mobileNav){
  const setMenu=open=>{mobileNav.classList.toggle('open',open);menuBtn.setAttribute('aria-expanded',String(open));menuBtn.setAttribute('aria-label',open?'Close menu':'Open menu');};
  menuBtn.addEventListener('click',()=>setMenu(!mobileNav.classList.contains('open')));
  mobileNav.querySelectorAll('a').forEach(a=>a.addEventListener('click',()=>setMenu(false)));
  document.addEventListener('keydown',e=>{if(e.key==='Escape'&&mobileNav.classList.contains('open')){setMenu(false);menuBtn.focus();}});
}

function humanSize(bytes){if(!Number.isFinite(bytes))return '';if(bytes<1024)return `${bytes} B`;if(bytes<1024*1024)return `${(bytes/1024).toFixed(1)} KB`;return `${(bytes/1024/1024).toFixed(1)} MB`;}

document.querySelectorAll('.dropzone').forEach(z=>{
  const input=z.querySelector('input[type=file]');
  const label=z.querySelector('.fileName');
  if(!input)return;
  ['dragenter','dragover'].forEach(e=>z.addEventListener(e,ev=>{ev.preventDefault();z.classList.add('drag');}));
  ['dragleave','drop'].forEach(e=>z.addEventListener(e,ev=>{ev.preventDefault();z.classList.remove('drag');}));
  z.addEventListener('drop',e=>{if(e.dataTransfer?.files?.length){input.files=e.dataTransfer.files;input.dispatchEvent(new Event('change',{bubbles:true}));}});
  input.addEventListener('change',()=>showSelected(input,label));
});
function showSelected(input,label){if(!label)return;if(!input.files.length){label.textContent='';return;}const files=[...input.files];label.textContent=files.length===1?`${files[0].name} · ${humanSize(files[0].size)}`:`${files.length} files selected · ${humanSize(files.reduce((n,f)=>n+f.size,0))}`;}

document.querySelectorAll('[data-paste-file]').forEach(btn=>btn.addEventListener('click',async()=>{
  const input=document.getElementById(btn.dataset.target); if(!input)return;
  try{
    if(!navigator.clipboard?.read)throw new Error('Clipboard file access is not available in this browser. Use Ctrl/Cmd+V on the page or choose a file.');
    const items=await navigator.clipboard.read(); const dt=new DataTransfer();
    for(const item of items){const type=item.types.find(t=>t.startsWith('image/'));if(type){const blob=await item.getType(type);const ext=(type.split('/')[1]||'png').replace('jpeg','jpg');dt.items.add(new File([blob],`pasted-image.${ext}`,{type}));break;}}
    if(!dt.files.length)throw new Error('No image was found in your clipboard.');
    input.files=dt.files;input.dispatchEvent(new Event('change',{bubbles:true}));
  }catch(err){alert(err.message||'Could not read an image from the clipboard.');}
}));

document.addEventListener('paste',e=>{
  const input=document.querySelector('.dropzone input[type=file]');
  if(!input||!e.clipboardData?.files?.length)return;
  const images=[...e.clipboardData.files].filter(f=>f.type.startsWith('image/'));if(!images.length)return;
  const dt=new DataTransfer();images.forEach(f=>dt.items.add(f));input.files=dt.files;input.dispatchEvent(new Event('change',{bubbles:true}));e.preventDefault();
});


document.querySelectorAll('form[data-processing]').forEach(f=>f.addEventListener('submit',e=>{
  const input=f.querySelector('input[type=file]');
  if(input&&!input.files.length){e.preventDefault();input.focus();return;}
  const b=f.querySelector('button[type=submit]');if(b){b.disabled=true;b.dataset.original=b.textContent;b.textContent='Processing files…';}
}));
window.addEventListener('pageshow',()=>document.querySelectorAll('button[data-original]').forEach(b=>{b.disabled=false;b.textContent=b.dataset.original;}));

const search=document.querySelector('[data-tool-search]');
const results=document.querySelector('[data-search-results]');
if(search&&results){
  const items=[...results.querySelectorAll('[data-search-item]')];
  const empty=results.querySelector('[data-search-empty]');
  const status=document.querySelector('[data-search-status]');
  const apply=()=>{
    const q=search.value.trim().toLowerCase();
    if(!q){results.hidden=true;if(status)status.textContent='';return;}
    let shown=0;
    const words=q.split(/\s+/);
    items.forEach(i=>{const match=words.every(word=>i.dataset.search.includes(word));i.hidden=!match||shown>=7;if(!i.hidden)shown++;});
    if(empty)empty.hidden=shown>0;
    results.hidden=false;
    if(status)status.textContent=shown?`${shown} matching tools shown. Tab to explore results.`:'No matching tools.';
  };
  search.addEventListener('input',apply);search.addEventListener('focus',apply);
  search.addEventListener('keydown',e=>{if(e.key==='ArrowDown'&&!results.hidden){const first=items.find(i=>!i.hidden);if(first){e.preventDefault();first.focus();}}});
  document.addEventListener('click',e=>{if(!results.contains(e.target)&&e.target!==search)results.hidden=true;});
  document.addEventListener('keydown',e=>{
    if(e.key==='Escape'&&!results.hidden){search.focus();results.hidden=true;}
    if(e.key==='/'&&!/input|textarea|select/i.test(document.activeElement?.tagName||'')&&!document.activeElement?.isContentEditable){e.preventDefault();search.focus();}
  });
  document.addEventListener('focusin',e=>{if(e.target!==search&&!results.contains(e.target))results.hidden=true;});
}

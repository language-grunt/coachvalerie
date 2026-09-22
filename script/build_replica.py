"""Build the isolated staging reference; usage: python build_replica.py ARCHIVE.
Requires beautifulsoup4 only at import time, not in the Rails runtime.
"""
import hashlib,json,re,shutil,sys,urllib.request
from pathlib import Path
from urllib.parse import urljoin,urlparse
from bs4 import BeautifulSoup
ROOT=Path(__file__).resolve().parents[1]
ARCHIVE=Path(sys.argv[1]);OUT=ROOT/'replica';ASSETS=ROOT/'public/replica-assets'
OUT.mkdir(exist_ok=True);ASSETS.mkdir(parents=True,exist_ok=True)
routes=json.loads((ARCHIVE/'routes.json').read_text())
media=json.loads((ARCHIVE/'media-inventory.json').read_text())
cache={}; failures=[];downloads=[]
if (OUT/'import-report.json').exists():
 for old in json.loads((OUT/'import-report.json').read_text()).get('downloaded_assets',[]):
  if (ROOT/'public'/old['file'].lstrip('/')).exists():cache[old['url']]=old['file'];downloads.append(old)
for m in media:
 if m.get('file'):
  source=ARCHIVE/m['file'];target=ASSETS/source.name
  shutil.copy2(source,target);cache[m['url']]='/replica-assets/'+target.name

def asset(value,base):
 if not value or value.startswith(('data:','#','/replica-assets/')):return value
 url=urljoin(base,value)
 if url in cache:return cache[url]
 u=urlparse(url)
 if u.scheme!='https':return ''
 # Only publicly referenced presentation assets; never fetch scripts or private APIs.
 allowed=['kajabi-cdn.com','fonts.googleapis.com','fonts.gstatic.com','use.fontawesome.com','kajabi.com','cdn.jsdelivr.net']
 if not any(u.hostname==d or u.hostname.endswith('.'+d) for d in allowed):
  failures.append({'url':url,'reason':'asset host not allowlisted'});return ''
 try:
  req=urllib.request.Request(url,headers={'User-Agent':'Mozilla/5.0 CoachValerieStagingMigration'})
  with urllib.request.urlopen(req,timeout=25) as r:
   data=r.read();mime=r.headers.get_content_type()
  ext=Path(u.path).suffix.lower()
  if mime=='text/css':ext='.css'
  if not ext or len(ext)>8:ext={'image/png':'.png','image/jpeg':'.jpg','font/woff2':'.woff2'}.get(mime,'.bin')
  name=hashlib.sha256(url.encode()).hexdigest()[:24]+ext
  local='/replica-assets/'+name;cache[url]=local
  if mime=='text/css':data=css(data.decode(),url).encode()
  (ASSETS/name).write_bytes(data);downloads.append({'url':url,'file':local,'bytes':len(data)})
  return local
 except Exception as e:
  failures.append({'url':url,'reason':type(e).__name__});return ''

def css(text,base):
 text=re.sub(r'url\(\s*([\'\"]?)(.*?)\1\s*\)',lambda m:'url("'+asset(m[2],base)+'")',text,flags=re.S)
 text=re.sub(r'@import\s+([\'\"])(.*?)\1',lambda m:'@import "'+asset(m[2],base)+'"',text)
 return text

pages={};aliases={}
for r in routes:
 if r.get('http_status')!=200 or not r.get('files',{}).get('html'):continue
 path=urlparse(r['final_url']).path or '/';source_path=urlparse(r['url']).path or '/'
 if path!=source_path:aliases[source_path]=path
 if path in pages:continue
 soup=BeautifulSoup((ARCHIVE/r['files']['html']).read_text(),'html.parser')
 for tag in list(soup.select('script,iframe,object,embed,base,noscript,meta[name^="csrf"],meta[http-equiv="refresh"]')):tag.decompose()
 for tag in list(soup.select('link')):
  rel=tag.get('rel',[])
  if any(x in rel for x in ['stylesheet','icon','shortcut','apple-touch-icon']):
   tag['href']=asset(tag.get('href',''),r['final_url']);tag.attrs.pop('integrity',None);tag.attrs.pop('crossorigin',None)
  else:tag.decompose()
 for tag in soup.select('style'):tag.string=css(tag.get_text(),r['final_url'])
 for tag in soup.find_all(True):
  for attr in list(tag.attrs):
   if attr.lower().startswith('on') or attr in ['nonce','ping','integrity','data-controller','data-action','formaction']:del tag[attr]
  if tag.has_attr('style'):tag['style']=css(tag['style'],r['final_url'])
  if tag.name in ['img','source','video','audio','input']:
   for attr in ['src','poster']:
    if tag.has_attr(attr):tag[attr]=asset(tag[attr],r['final_url'])
   if tag.get('data-src'):tag['src']=asset(tag['data-src'],r['final_url'])
   for attr in ['srcset','data-src','data-srcset']:tag.attrs.pop(attr,None)
  if tag.name=='a':
   href=tag.get('href','');u=urlparse(urljoin(r['final_url'],href))
   if href in cache:tag['href']=cache[href]
   elif 'coach-valerie-mirto.mykajabi.com/site/about' in href:tag['href']='/Meet-Valerie'
   elif u.hostname in ['www.coachvalerie.com','coachvalerie.com'] and not href.startswith('#'):
    tag['href']=u.path or '/'
    if u.fragment:tag['href']+='#'+u.fragment
   elif href.startswith(('javascript:','data:')):tag['href']='#'
   elif u.scheme=='https' and u.hostname not in ['www.coachvalerie.com','coachvalerie.com']:
    tag['rel']='noopener noreferrer';tag['target']='_blank'
 for form in soup.select('form'):
  form['action']='/preview-submission';form['method']='post';form.attrs.pop('data-remote',None)
  for x in list(form.select('input[type="hidden"]')):x.decompose()
  note=soup.new_tag('p',attrs={'class':'replica-form-note','role':'status'})
  note.string='Preview only — this form does not send or save your information.';form.append(note)
 for modal in soup.select('.modal'):
  modal.attrs.pop('style',None);modal['aria-hidden']='true'
 for hamburger in soup.select('.hamburger'):
  hamburger['role']='button';hamburger['tabindex']='0';hamburger['aria-label']='Open navigation';hamburger['aria-expanded']='false'
 meta=soup.new_tag('meta',attrs={'name':'robots','content':'noindex,nofollow,noarchive'});soup.head.append(meta)
 link=soup.new_tag('link',attrs={'rel':'stylesheet','href':'/replica-assets/preview.css'});soup.head.append(link)
 script=soup.new_tag('script',attrs={'src':'/replica-assets/preview.js','defer':''});soup.body.append(script)
 name=hashlib.sha256(path.encode()).hexdigest()[:20]+'.html';(OUT/name).write_text(str(soup))
 pages[path]=name
 print('Built '+path,flush=True)
# Approved only as preview usability repairs, not the launch redirect map.
aliases.update({'/services-page':'/true-assestment','/site/groups_and_workshops':'/groups-and-workshops','/Boundaries-Bandwidth-and-Burnout':'/Boundary-setting'})
(OUT/'routes.json').write_text(json.dumps({'pages':pages,'aliases':aliases},indent=2)+'\n')
(OUT/'import-report.json').write_text(json.dumps({'source':'www.coachvalerie.com archived 2026-09-19','pages':len(pages),'aliases':len(aliases),'downloaded_assets':downloads,'asset_failures':failures,'limitations':['Forms are preview-only; no persistence or delivery','Assessment scoring and results not implemented','No CMS yet; replace reference snapshots through later migration','Third-party scripts, embeds and analytics removed']},indent=2)+'\n')
print(json.dumps({'pages':len(pages),'aliases':len(aliases),'asset_failures':failures}))

"""Split sanitized reference HTML into content, templates and per-page CSS.
Run after build_replica.py; deterministic output, no network access.
"""
import hashlib,json,re
from pathlib import Path
from bs4 import BeautifulSoup,Comment,NavigableString
ROOT=Path(__file__).resolve().parents[1];BASE=ROOT/'replica'
manifest=json.loads((BASE/'routes.json').read_text())
for name in ['content','templates','styles','schemas']:(BASE/name).mkdir(exist_ok=True)
for path,filename in manifest['pages'].items():
 source=BASE/filename
 if not source.exists():continue
 soup=BeautifulSoup(source.read_text(),'html.parser')
 fields={};schema={};sections={};counter=0;markers={};backgrounds={}
 def slot(value,kind,tag=None):
  global counter
  counter+=1;key=kind+'_'+str(counter).zfill(4)
  section=tag.find_parent(attrs={'data-section-id':True}) if tag else None
  section_id=section.get('data-section-id') if section else 'page'
  fields[key]=str(value);schema[key]={'kind':kind,'section':section_id,'element':tag.name if tag else None}
  sections.setdefault(section_id,[]).append(key)
  marker='REPLICASLOT'+str(counter).zfill(6)+'END';markers[marker]='{{content:'+key+'}}'
  return marker,key
 def css_assets(text):
  def replace(m):
   url=m[2]
   if not url.startswith('/replica-assets/'):return m[0]
   marker,key=slot(url,'background')
   var='--replica-'+key;backgrounds[var]=marker
   return 'var('+var+')'
  return re.sub(r'url\(\s*([\'\"]?)(.*?)\1\s*\)',replace,text)
 styles=[]
 for style in list(soup.select('style')):
  styles.append(css_assets(style.get_text()));style.decompose()
 for i,tag in enumerate(soup.select('[style]')):
  name='inline-'+str(i);tag['data-replica-style']=name
  styles.append('[data-replica-style="'+name+'"]{'+css_assets(tag['style'])+'}')
  del tag['style']
 for node in list(soup.find_all(string=True)):
  if isinstance(node,Comment):node.extract();continue
  if not node.strip() or node.parent.name in ['script','style']:continue
  # Keep the document type as template syntax, not editorial content.
  if node.parent.name=='[document]':continue
  marker,key=slot(str(node),'text',node.parent);node.replace_with(NavigableString(marker))
 for tag in soup.find_all(True):
  for attr in ['alt','title','placeholder','href','src','poster','aria-label']:
   if not tag.has_attr(attr):continue
   if tag.name in ['script','link']:continue
   value=tag[attr]
   if not value:continue
   kind='asset' if attr in ['src','poster'] else 'link' if attr=='href' else 'text'
   marker,key=slot(value,kind,tag);tag[attr]=marker
  if tag.name=='meta' and (tag.get('name')=='description' or tag.get('property','').startswith('og:') or tag.get('name','').startswith('twitter:')):
   marker,key=slot(tag.get('content',''),'text',tag);tag['content']=marker
 stem=Path(filename).stem
 style_name='/replica-assets/page-'+stem+'.css'
 (ROOT/'public'/style_name.lstrip('/')).write_text('\n'.join(styles))
 link=soup.new_tag('link',attrs={'rel':'stylesheet','href':style_name});soup.head.append(link)
 if backgrounds:
  dynamic=soup.new_tag('style');dynamic.string=':root{'+''.join(k+':url("'+v+'");' for k,v in backgrounds.items())+'}'
  soup.head.append(dynamic)
 template=str(soup)
 for marker,token in markers.items():template=template.replace(marker,token)
 (BASE/'templates'/(stem+'.html')).write_text(template)
 (BASE/'content'/(stem+'.json')).write_text(json.dumps({'path':path,'fields':fields,'sections':sections},indent=2,ensure_ascii=False)+'\n')
 (BASE/'schemas'/(stem+'.json')).write_text(json.dumps(schema,indent=2)+'\n')
 source.unlink()
print('Separated '+str(len(manifest['pages']))+' pages: content JSON, presentation templates and CSS.')

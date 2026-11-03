"""Fast, explainable keyword indexing; never grants publication or age certification."""
import copy,json,re,unicodedata
from functools import lru_cache
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
def norm(s):return ''.join(c for c in unicodedata.normalize('NFD',str(s or '')) if unicodedata.category(c)!='Mn').lower()
@lru_cache(maxsize=4096)
def pattern(value):return re.compile(value)
def has(text,word):return pattern(r'(?<![a-z0-9])'+re.escape(norm(word))+r'(?![a-z0-9])').search(text) is not None
@lru_cache(maxsize=1)
def resources():return json.loads((ROOT/'dados/biblioteca/regras-indexacao.json').read_text()),json.loads((ROOT/'dados/biblioteca/taxonomia.json').read_text())
def enrich(record,snippet=None,protected=()):
 r=copy.deepcopy(record);rules,tax=resources();title=norm(r.get('titulo'));description=norm(r.get('descricao'));sn=snippet or {};tags=' '.join(str(x) for x in (sn.get('tags') or []));text=' '.join([title,description,norm(tags)]);suggestions={};primary=[];characters=[]
 negative=any(has(text,x) for x in ['nao e para criancas','nao indicado para criancas','nao recomendado para criancas','not for kids','not for children','no es para ninos'])
 for rule in rules['personagens']:
  if rule['nome']=='Jó' and not re.search(r'(?i)(?<![a-z])jó(?![a-z])',str(r.get('titulo',''))+' '+str(r.get('descricao',''))) and not any(has(text,x) for x in ['book of job','story of job','livro de jo']):continue
  if any(has(text,a) for a in rule['aliases']):characters.append(rule['nome'])
  if any(has(title,a) for a in rule['aliases']):primary.append(rule)
 # Generic José/João/Maria do not disambiguate testaments on their own.
 primary=[x for x in primary if x['nome'] not in ['José','João','Maria']]
 suggestions['personagens']=characters;suggestions['temas']=[x['nome'] for x in rules['temas'] if any(has(text,a) for a in x['aliases'])]
 suggestions['livros']=[]
 for book in tax['livros']:
  if book['nome']=='Jó' and not re.search(r'(?i)(?<![a-z])jó(?![a-z])',str(r.get('titulo',''))+' '+str(r.get('descricao',''))) and not has(text,'livro de jo'):continue
  name=norm(book['nome']);match=pattern(r'(?<![a-z0-9])'+re.escape(name)+r'\s+\d{1,3}(?::\d+)?(?!\d)').search(text) or any(has(text,prefix+name) for prefix in ['livro de ','evangelho de ','evangelho segundo '])
  if match:suggestions['livros'].append(book['id'])
 testaments={x['testamento'] for x in primary}|{b['testamento'] for b in tax['livros'] if b['id'] in suggestions['livros']}
 if has(title,'antigo testamento'):testaments.add('antigo')
 if has(title,'novo testamento'):testaments.add('novo')
 if len(testaments)==1:suggestions['testamento']=next(iter(testaments))
 if not negative and any(has(text,x) for x in ['criancas','infantil','for kids','children','ninos']):suggestions['publico']='infantil'
 elif has(text,'adultos'):suggestions['publico']='adulto'
 elif has(text,'toda a familia'):suggestions['publico']='familia'
 if any(has(title,x) for x in ['filme completo','full movie','pelicula completa']):suggestions['formato']='filme-completo'
 elif any(has(title,x) for x in ['animacao','animation','desenho']):suggestions['formato']='animacao'
 elif has(title,'documentario'):suggestions['formato']='documentario'
 elif has(title,'curta metragem'):suggestions['formato']='curta-metragem'
 season=re.search(r'\b(?:temporada|season)\s*[:#.-]?\s*(\d{1,3})\b',title);episode=re.search(r'\b(?:episodio|episode|ep)\s*[:#.-]?\s*(\d{1,4})\b',title);combo=re.search(r'\bs(\d{1,2})\s*e(\d{1,3})\b',title)
 if combo:season,episode=combo,combo
 if season or episode:
  position=min(m.start() for m in [season,episode] if m);name=r.get('titulo','')[:position].strip(' -|:–—')
  if name:
   suggestions['serieId']=name
   if season:suggestions['temporada']=int(season.group(1))
   if episode:suggestions['episodio']=int(episode.group(2) if combo else episode.group(1))
 if not r.get('categoria'):
  if suggestions.get('formato')=='animacao':suggestions['categoria']='desenho'
  elif season or episode:suggestions['categoria']='serie'
  elif suggestions.get('formato')=='filme-completo':suggestions['categoria']='filme'
 inferred={}
 for key,value in suggestions.items():
  if key in protected or not value:continue
  if isinstance(value,list):
   current=r.get(key) or [];extra=[v for v in value if v not in current]
   if extra:r[key]=current+extra;inferred[key]=extra
  elif not r.get(key):r[key]=value;inferred[key]=value
 if protected:r['camposEditoriais']=[x for x in protected if x in ['personagens','temas','livros','testamento','publico','formato','serieId','temporada','episodio','categoria']]
 if inferred:r['catalogacaoAutomatica']={**r.get('catalogacaoAutomatica',{}),'versao':1,'campos':{**r.get('catalogacaoAutomatica',{}).get('campos',{}),**inferred},'origem':'palavras-chave e metadados; não é análise do vídeo'}
 return r

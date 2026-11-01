#!/usr/bin/env python3
"""Validação local, sem dependências e sem consultas externas."""
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlsplit, unquote
from datetime import date
import json, sys, re
ROOT=Path(__file__).resolve().parents[1]
errors=[]
class Page(HTMLParser):
    def __init__(self):
        super().__init__(); self.ids=[]; self.hashes=[]; self.files=[]
    def handle_starttag(self,tag,attrs):
        attrs=dict(attrs)
        if 'id' in attrs:self.ids.append(attrs['id'])
        if attrs.get('href','').startswith('#'):self.hashes.append(attrs['href'][1:])
        for field in (['src'] if tag in ['script','img'] else ['href'] if tag=='link' else []):
            value=attrs.get(field,'')
            if value and not urlsplit(value).scheme and not value.startswith('//'):self.files.append(value)
def check(condition,message):
    if not condition:errors.append(message)
data={}
for f in sorted((ROOT/'dados').rglob('*.json')):
    try:data[f.relative_to(ROOT).as_posix()]=json.loads(f.read_text(encoding='utf-8'))
    except (ValueError,OSError) as exc:errors.append(str(f.relative_to(ROOT))+': '+str(exc))
try:
    p=Page();p.feed((ROOT/'index.html').read_text(encoding='utf-8'))
    check(len(p.ids)==len(set(p.ids)),'index.html: IDs duplicados')
    for h in set(p.hashes):check(unquote(h) in p.ids,'Âncora inexistente: #'+h)
    for f in p.files:check((ROOT/urlsplit(f).path).is_file(),'Arquivo local ausente: '+f)
except OSError as exc:errors.append(str(exc))
shared=['planejamento.json','projetos.json','ideias-sociais.json','catalogo-conteudos.json','prestacao-contas.json','comunidades.json']
for lang in ['en','es']:
    for path in (ROOT/'dados').glob('*.json'):
        if path.name not in shared:check((ROOT/'dados'/lang/path.name).is_file(),'Tradução ausente: '+lang+'/'+path.name)
for name in ['projetos.json','ideias-sociais.json','catalogo-conteudos.json']:
    d=data.get('dados/'+name)
    if not isinstance(d,dict) or not isinstance(d.get('itens'),list):errors.append(name+': esperado objeto com lista itens');continue
    ids=[]
    for item in d['itens']:
        if not isinstance(item,dict):errors.append(name+': item não é objeto');continue
        ids.append(item.get('id'))
        check(isinstance(item.get('titulo'),str) and bool(item.get('titulo')),name+': título ausente')
        check(item.get('status','auto') in ['auto','proposta','em-desenvolvimento','em-producao','gravado','pausado','concluido','disponivel','publicado'],name+': status inválido')
        for key in ['link','repositorio','documentacao']:
            url=item.get(key,'')
            if url:check(isinstance(url,str) and urlsplit(url).scheme=='https' and bool(urlsplit(url).netloc),name+': '+key+' deve ser HTTPS')
    check(all(isinstance(x,str) and x for x in ids),name+': ID ausente')
    check(len(ids)==len(set(ids)),name+': IDs repetidos')
for lang in ['', 'en/', 'es/']:
    d=data.get('dados/'+lang+'leituras.json')
    check(isinstance(d,dict),lang+'leituras.json deve ser objeto')
    if isinstance(d,dict):
        for day,item in d.items():
            try:date.fromisoformat(day)
            except (ValueError,TypeError):errors.append(lang+'leituras.json: data inválida '+str(day))
            check(bool(re.fullmatch(r'\d{4}-\d{2}-\d{2}',day)),lang+'leituras.json: formato AAAA-MM-DD necessário')
            check(isinstance(item,dict) and isinstance(item.get('reading'),str),lang+'leituras.json: reading obrigatório')
            if isinstance(item,dict):
                for field in ['passagens','reflectionPassages']:
                    if field in item:check(isinstance(item[field],list),lang+'leituras.json: '+field+' deve ser lista')
if errors:
    print('Corrija os seguintes pontos:')
    for e in errors:print('- '+e)
    sys.exit(1)
print('OK: JSONs, traduções, IDs, âncoras, arquivos locais, catálogos e datas conferidos.')
print('Não foram verificados destinos externos, pagamentos ou serviços de integração.')

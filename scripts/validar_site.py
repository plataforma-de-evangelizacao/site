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
shared=['planejamento.json','projetos.json','ideias-sociais.json','catalogo-conteudos.json','prestacao-contas.json','comunidades.json','agenda-solidaria.json','atividades-parcerias.json','rede-parceiros.json','formacoes.json']
agenda=data.get('dados/agenda-solidaria.json',{})
check(isinstance(agenda,dict) and isinstance(agenda.get('acoes'),list),'Agenda: esperado objeto com lista acoes')
seen=set()
for action in agenda.get('acoes',[]) if isinstance(agenda,dict) else []:
    check(isinstance(action,dict),'Agenda: registro inválido')
    if not isinstance(action,dict):continue
    ident=action.get('id');check(isinstance(ident,str) and bool(ident) and ident not in seen,'Agenda: id ausente/duplicado');seen.add(str(ident))
    check(isinstance(action.get('titulo'),str) and bool(action.get('titulo')),'Agenda: título ausente')
    check(action.get('status') in ['rascunho','planejada','confirmada','concluida','cancelada'],'Agenda: status inválido')
    if action.get('data'):
        try:date.fromisoformat(action['data'])
        except (ValueError,TypeError):errors.append('Agenda: data inválida')
    for field in ['itens_solicitados','itens_recebidos','pontos_coleta']:check(isinstance(action.get(field,[]),list),'Agenda: '+field+' deve ser lista')
activity_data=data.get('dados/atividades-parcerias.json',{})
check(isinstance(activity_data,dict) and isinstance(activity_data.get('instituicoes'),list),'Atividades: esperado objeto com instituicoes')
activity_ids=[]
for item in activity_data.get('instituicoes',[]) if isinstance(activity_data,dict) else []:
    check(isinstance(item,dict),'Atividades: instituição inválida')
    if not isinstance(item,dict):continue
    activity_ids.append(item.get('id'));check(item.get('id') in ['catolica','batista','vicentinos'],'Atividades: instituição desconhecida')
    for language in ['pt','en','es']:
        record=item if language=='pt' else item.get('traducoes',{}).get(language,{})
        check(isinstance(record.get('titulo'),str) and bool(record.get('titulo')),'Atividades: título ausente em '+language)
        check(isinstance(record.get('contribuicoes_possiveis'),list) and all(isinstance(x,str) for x in record.get('contribuicoes_possiveis',[])),'Atividades: contribuições inválidas em '+language)
        activities=record.get('atividades_propostas',[]);check(isinstance(activities,list),'Atividades: lista inválida em '+language)
        if isinstance(activities,list):
            for activity in activities:check(isinstance(activity,dict) and all(isinstance(activity.get(k),str) for k in ['titulo','descricao']),'Atividades: proposta inválida em '+language)
check(len(activity_ids)==len(set(activity_ids)),'Atividades: instituições duplicadas')
network=data.get('dados/rede-parceiros.json',{})
check(isinstance(network,dict) and isinstance(network.get('unidades'),list),'Parceiros: esperado objeto com unidades')
unit_ids=[]
for unit in network.get('unidades',[]) if isinstance(network,dict) else []:
    check(isinstance(unit,dict),'Parceiros: unidade inválida')
    if not isinstance(unit,dict):continue
    unit_ids.append(unit.get('id'));check(all(isinstance(unit.get(k),str) and bool(unit.get(k)) for k in ['id','nome','cidade','uf']),'Parceiros: identificação ou cidade ausente')
    check(unit.get('status') in ['a-propor','em-conversa','confirmada','pausada'],'Parceiros: status inválido')
    check(unit.get('zona','a-informar') in ['a-informar','urbana','rural'],'Parceiros: zona inválida')
    for location in [unit]+(unit.get('comunidades',[]) if isinstance(unit.get('comunidades'),list) else []):
        check(isinstance(location,dict),'Parceiros: comunidade inválida')
        if not isinstance(location,dict):continue
        if location.get('instagram'):check(urlsplit(location['instagram']).scheme=='https' and urlsplit(location['instagram']).hostname in ['instagram.com','www.instagram.com'],'Parceiros: Instagram inválido')
        for field in ['site','mapa']:
            if location.get(field):check(urlsplit(location[field]).scheme=='https','Parceiros: '+field+' deve usar HTTPS')
        if location.get('whatsapp'):check(bool(re.fullmatch(r'\d{10,15}',location['whatsapp'])),'Parceiros: WhatsApp inválido')
        if location.get('telefone'):check(bool(re.fullmatch(r'\+\d{10,15}',re.sub(r'[\s()-]','',location['telefone']))),'Parceiros: telefone deve incluir + e código do país')
    check(isinstance(unit.get('comunidades',[]),list),'Parceiros: comunidades deve ser lista')
check(len(unit_ids)==len(set(unit_ids)),'Parceiros: IDs de unidade duplicados')
training_ids=[]
for parent in data.get('dados/projetos.json',{}).get('itens',[]):
    for training in parent.get('cursos_propostos',[])+parent.get('formacoes_propostas',[]):
        check(isinstance(training,dict),'Formações: registro inválido')
        if not isinstance(training,dict):continue
        training_ids.append(training.get('id'));check(training.get('tipo') in ['curso','palestra'],'Formações: tipo inválido')
        check(training.get('gratuito') is True,'Formações: proposta deve permanecer gratuita')
        for language in ['pt','en','es']:
            record=training if language=='pt' else training.get('traducoes',{}).get(language,{})
            check(all(isinstance(record.get(k),str) and bool(record.get(k)) for k in ['titulo','descricao','publico']),'Formações: texto ausente em '+language)
            for field in ['conteudos','materiais']:check(isinstance(record.get(field),list),'Formações: '+field+' inválido em '+language)
check(len(training_ids)==len(set(training_ids)),'Formações: IDs duplicados')
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

#!/usr/bin/env python3
"""Importa CSV UTF-8 para a agenda pública. Não faz upload, commit ou push."""
import argparse,csv,json,os,tempfile,io
from pathlib import Path
from datetime import date
COLUNAS=['id','titulo','status','data','horario','descricao','itens_solicitados','item_recebido','quantidade_recebida','unidade','coleta_nome','coleta_endereco','coleta_horarios','distribuicao_local','distribuicao_horario','distribuicao_descricao','contato_nome','whatsapp','email','link']
def converter(path):
    raw=Path(path).read_text(encoding='utf-8-sig');dialect=csv.Sniffer().sniff(raw[:8192],delimiters=',;\t');rows=csv.DictReader(io.StringIO(raw),dialect=dialect);actions=[];ids=set()
    if not {'id','titulo','status'}.issubset(rows.fieldnames or []):raise ValueError('Colunas obrigatórias: id, titulo, status')
    for number,row in enumerate(rows,2):
        r={k:(v or '').strip()for k,v in row.items()if k};get=lambda k:r.get(k,'')
        if not get('id') and not get('titulo'):continue
        if not get('id') or get('id') in ids:raise ValueError(f'Linha {number}: id ausente ou duplicado')
        if not get('titulo') or get('status') not in ['rascunho','planejada','confirmada','concluida','cancelada']:raise ValueError(f'Linha {number}: título ou status inválido')
        if get('data'):date.fromisoformat(get('data'))
        phone=get('whatsapp')
        if phone and (not phone.isdigit() or not 10<=len(phone)<=15):raise ValueError(f'Linha {number}: WhatsApp deve conter somente dígitos e código do país')
        received=[]
        if get('item_recebido'):
            qty=float(get('quantidade_recebida').replace(',','.'))
            if not 0<=qty<float('inf'):raise ValueError(f'Linha {number}: quantidade inválida')
            received=[{'item':get('item_recebido'),'quantidade':qty,'unidade':get('unidade')}]
        contact={'nome':get('contato_nome'),'whatsapp':phone,'email':get('email')}
        action={'id':get('id'),'titulo':get('titulo'),'status':get('status'),'data':get('data'),'horario':get('horario'),'descricao':get('descricao'),'itens_solicitados':[x.strip()for x in get('itens_solicitados').split('|')if x.strip()],'itens_recebidos':received,'pontos_coleta':[{'nome':get('coleta_nome'),'endereco':get('coleta_endereco'),'horarios':get('coleta_horarios'),'contato':contact}]if get('coleta_nome')or get('coleta_endereco')else [],'distribuicao':{'local':get('distribuicao_local'),'horario':get('distribuicao_horario'),'descricao':get('distribuicao_descricao')},'contato':contact,'link':get('link')};ids.add(action['id']);actions.append(action)
    return {'versao':1,'atualizado_em':date.today().isoformat(),'acoes':actions}
if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('csv');p.add_argument('--saida',default='dados/agenda-solidaria.json');a=p.parse_args();data=converter(a.csv);dest=Path(a.saida);dest.parent.mkdir(parents=True,exist_ok=True)
    with tempfile.NamedTemporaryFile('w',encoding='utf-8',dir=dest.parent,delete=False)as f:json.dump(data,f,ensure_ascii=False,indent=2);f.write('\n');temp=f.name
    os.replace(temp,dest);print(f'Agenda validada: {len(data["acoes"])} ação(ões). Arquivo: {dest}')

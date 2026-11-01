#!/usr/bin/env python3
"""Importa o modelo XLSX mensal; gera JSON, cópia pública e PDF opcional. Não envia arquivos à rede."""
from pathlib import Path
from decimal import Decimal, ROUND_HALF_UP
from datetime import date, datetime, timedelta
from xml.etree import ElementTree as ET
from urllib.parse import urlsplit
import zipfile, json, argparse, shutil, sys, re, tempfile, os
ROOT=Path(__file__).resolve().parents[1]
NS={'m':'http://schemas.openxmlformats.org/spreadsheetml/2006/main'}
RNS='{http://schemas.openxmlformats.org/officeDocument/2006/relationships}id'
def sheets(path):
    result={}
    with zipfile.ZipFile(path) as z:
        strings=[]
        if 'xl/sharedStrings.xml' in z.namelist():
            strings=[''.join(t.itertext()) for t in ET.fromstring(z.read('xl/sharedStrings.xml')).findall('m:si',NS)]
        rels={n.attrib['Id']:n.attrib['Target'] for n in ET.fromstring(z.read('xl/_rels/workbook.xml.rels'))}
        for node in ET.fromstring(z.read('xl/workbook.xml')).findall('m:sheets/m:sheet',NS):
            target=rels[node.attrib[RNS]];target=target.lstrip('/') if target.startswith('/') else 'xl/'+target
            values={}
            for c in ET.fromstring(z.read(target)).findall('.//m:c',NS):
                if c.find('m:f',NS) is not None:values[c.attrib['r']]='=FORMULA';continue
                typ=c.attrib.get('t');v=c.find('m:v',NS)
                if typ=='inlineStr':value=''.join(c.find('m:is',NS).itertext())
                elif v is None:value=''
                elif typ=='s':value=strings[int(v.text)]
                elif typ in ['str','e','b']:value=v.text or ''
                else:value=Decimal(v.text or '0')
                values[c.attrib['r']]=value
            result[node.attrib['name']]=values
    return result
def amount(v,allow_negative=False):
    if v in ['',None]:return Decimal('0.00')
    if isinstance(v,str) and v.startswith('='):raise ValueError('Use valores numéricos de entrada, não fórmulas nos lançamentos.')
    try:n=Decimal(str(v)).quantize(Decimal('.01'),rounding=ROUND_HALF_UP)
    except Exception:raise ValueError('Valor monetário inválido: '+str(v))
    if not n.is_finite() or (n<0 and not allow_negative):raise ValueError('Valor monetário inválido: '+str(v))
    return n
def report_from(path):
    tabs=sheets(path)
    if not {'Resumo','Lancamentos'}<=tabs.keys():raise ValueError('Use o modelo com as abas Resumo e Lancamentos.')
    s,l=tabs['Resumo'],tabs['Lancamentos'];month=str(s.get('C4','')).strip()
    if not re.fullmatch(r'\d{4}-(0[1-9]|1[0-2])',month):raise ValueError('Preencha Resumo!C4 no formato AAAA-MM.')
    result={'mes':month,'saldo_inicial':float(amount(s.get('C5',0),True)),'resumo':str(s.get('C8','')),'entradas':[],'despesas':[],'indicadores':[],'arquivos':{}}
    rows=sorted({int(re.search(r'\d+',key).group()) for key in l if re.search(r'\d+',key)})
    for row in rows:
        if row<4:continue
        vals=[l.get(col+str(row),'') for col in 'ABCDE']
        if all(v in ['',None] for v in vals):continue
        if row>203:raise ValueError('O modelo comporta 200 lançamentos. Amplie as fórmulas e o importador antes de usar linhas além de 203.')
        day,typ,category,description,value=vals
        if isinstance(day,Decimal):day=(datetime(1899,12,30)+timedelta(days=float(day))).date().isoformat()
        day=str(day).strip();typ=str(typ).strip().lower();category=str(category).strip()
        try:date.fromisoformat(day)
        except ValueError:raise ValueError('Data inválida na linha '+str(row))
        if not day.startswith(month+'-'):raise ValueError('Lançamento fora do mês na linha '+str(row))
        if typ not in ['entrada','despesa'] or not category or value in ['',None]:raise ValueError('Tipo, categoria ou valor ausente na linha '+str(row))
        result['entradas' if typ=='entrada' else 'despesas'].append({'data':day,'categoria':category,'descricao':str(description),'valor':float(amount(value))})
    for row in range(26,1001):
        name=s.get('B'+str(row),'');value=s.get('C'+str(row),'');unit=s.get('D'+str(row),'')
        if not name:continue
        if value in ['',None] or str(value).startswith('='):raise ValueError('Indicador sem valor numérico na linha '+str(row))
        try:number=float(value)
        except ValueError:raise ValueError('Indicador inválido na linha '+str(row))
        if not Decimal(str(number)).is_finite():raise ValueError('Indicador não finito')
        result['indicadores'].append({'nome':str(name),'valor':number,'unidade':str(unit)})
    for cell,key in [('C6','planilha'),('C7','pdf')]:
        v=str(s.get(cell,'')).strip()
        if v:
            if urlsplit(v).scheme!='https':raise ValueError('Links externos devem usar HTTPS: '+cell)
            result['arquivos'][key]=v
    return result
def totals(report):
    incoming=sum((amount(x['valor']) for x in report['entradas']),Decimal(0));spent=sum((amount(x['valor']) for x in report['despesas']),Decimal(0));return incoming,spent,amount(report['saldo_inicial'],True)+incoming-spent
def pdf_report(report,path):
    try:
        from reportlab.platypus import SimpleDocTemplate,Paragraph,Spacer,Table,TableStyle
        from reportlab.lib.styles import getSampleStyleSheet
        from reportlab.lib import colors
        from reportlab.lib.pagesizes import A4
    except ImportError:raise ValueError('Para gerar PDF, instale reportlab no ambiente Python conforme o README ou forneça um PDF já revisado.')
    from xml.sax.saxutils import escape
    styles=getSampleStyleSheet();story=[]
    def p(text,style='BodyText'):return Paragraph(escape(str(text)).replace('\n','<br/>'),styles[style])
    fmt=lambda n:'R$ '+f'{n:,.2f}'.replace(',','X').replace('.',',').replace('X','.')
    incoming,spent,closing=totals(report)
    story.extend([p('Plataforma Global de Evangelização','Title'),p('Prestação de contas - '+report['mes'],'Heading1'),p(report.get('resumo','')),Spacer(1,15)])
    table=Table([[p('Saldo inicial'),p('Entradas'),p('Despesas'),p('Saldo final')],[p(fmt(amount(report['saldo_inicial'],True))),p(fmt(incoming)),p(fmt(spent)),p(fmt(closing))]],colWidths=[125]*4)
    table.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),colors.HexColor('#EEF0E8')),('VALIGN',(0,0),(-1,-1),'TOP'),('LEFTPADDING',(0,0),(-1,-1),9),('BOTTOMPADDING',(0,0),(-1,-1),10)]));story.append(table)
    categories={}
    for x in report['despesas']:categories[x['categoria']]=categories.get(x['categoria'],Decimal(0))+amount(x['valor'])
    story.extend([p('Distribuição das despesas','Heading2'),p('Percentuais calculados sobre as despesas do mês. Saldo final = saldo inicial + entradas - despesas.')])
    rows=[[p('Categoria'),p('Valor'),p('% das despesas')]]
    for category,value in categories.items():rows.append([p(category),p(fmt(value)),p(f'{value/spent*100:.1f}%' if spent else 'Sem despesas')])
    table=Table(rows,colWidths=[280,110,110],repeatRows=1);table.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),colors.HexColor('#EEF0E8')),('VALIGN',(0,0),(-1,-1),'TOP'),('BOTTOMPADDING',(0,0),(-1,-1),9)]));story.append(table)
    if report['indicadores']:
        story.append(p('Indicadores informados','Heading2'))
        for x in report['indicadores']:story.append(p(f"{x['nome']}: {x['valor']:g} {x.get('unidade','')}"))
    for key,title in [('entradas','Entradas registradas'),('despesas','Despesas registradas')]:
        story.append(p(title,'Heading2'));rows=[[p('Data'),p('Categoria / descrição pública'),p('Valor')]]
        for x in report[key]:rows.append([p(x.get('data','')),p(x['categoria']+' - '+x.get('descricao','')),p(fmt(amount(x['valor'])))])
        table=Table(rows,colWidths=[80,310,110],repeatRows=1);table.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),colors.HexColor('#EEF0E8')),('VALIGN',(0,0),(-1,-1),'TOP'),('BOTTOMPADDING',(0,0),(-1,-1),8)]));story.append(table)
    story.extend([Spacer(1,16),p('Relatório elaborado com os dados informados pelo responsável. Revise antes de publicar. Não substitui documentos fiscais ou conciliação bancária.')])
    def footer(canvas,doc):canvas.setFont('Helvetica',9);canvas.drawString(45,28,'Nova Bandeirantes - MT');canvas.drawRightString(A4[0]-45,28,str(doc.page))
    SimpleDocTemplate(str(path),pagesize=A4,rightMargin=45,leftMargin=45,topMargin=40,bottomMargin=45).build(story,onFirstPage=footer,onLaterPages=footer)
def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('planilha',type=Path);parser.add_argument('--raiz',type=Path,default=ROOT);parser.add_argument('--pdf',action='store_true');parser.add_argument('--substituir',action='store_true');args=parser.parse_args()
    root=args.raiz.resolve();target=root/'dados/prestacao-contas.json';report=report_from(args.planilha)
    data=json.loads(target.read_text()) if target.exists() else {'versao':1,'moeda':'BRL','meses':[]}
    if any(x['mes']==report['mes'] for x in data['meses']) and not args.substituir:raise ValueError('Mês já existe. Revise a correção e use --substituir se deseja atualizar esse mês.')
    out=root/'relatorios';out.mkdir(parents=True,exist_ok=True)
    # Prepare PDF before committing data. No network calls and no automatic Git push.
    with tempfile.TemporaryDirectory() as tmp:
        pdf=Path(tmp)/'relatorio.pdf'
        if args.pdf:pdf_report(report,pdf)
        xlsx_rel='relatorios/'+report['mes']+'.xlsx';pdf_rel='relatorios/'+report['mes']+'.pdf'
        shutil.copy2(args.planilha,root/xlsx_rel);report['arquivos'].setdefault('planilha',xlsx_rel)
        if args.pdf:shutil.copy2(pdf,root/pdf_rel);report['arquivos']['pdf']=pdf_rel
        data['meses']=[x for x in data['meses'] if x['mes']!=report['mes']]+[report];data['meses'].sort(key=lambda x:x['mes'],reverse=True)
        target.parent.mkdir(parents=True,exist_ok=True);target.write_text(json.dumps(data,ensure_ascii=False,indent=2,allow_nan=False)+'\n')
    incoming,spent,closing=totals(report);print(f"Mês {report['mes']} preparado. Entradas: {incoming:.2f}; despesas: {spent:.2f}; saldo final: {closing:.2f}.");print('Revise os arquivos, valide e faça commit/push para publicar. Nenhum arquivo foi enviado automaticamente.')
if __name__=='__main__':
    try:main()
    except (ValueError,OSError,zipfile.BadZipFile) as exc:print('Não foi possível importar: '+str(exc),file=sys.stderr);sys.exit(1)

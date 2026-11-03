"""Report real workflow stages to the authenticated admin queue, without log/secret exports."""
import argparse,json,os,re,sys,datetime as dt
from pathlib import Path
from sync import Client

def main():
 p=argparse.ArgumentParser();p.add_argument('--progress',type=int,default=0);p.add_argument('--phase',default='');p.add_argument('--processing-finished',action='store_true');p.add_argument('--publication-finished',action='store_true');a=p.parse_args()
 id=os.getenv('ADMIN_REQUEST','')
 if not id:return 0
 if not re.fullmatch(r'[0-9a-f-]{36}',id):return 1
 client=Client()
 if not client.url or not client.key:return 1
 try:
  query='id=eq.'+id
  rows=client.call('pge_commands',query+'&select=action,status,result,payload')
  if not rows or rows[0]['action']!='run_sync':return 1
  row=rows[0]
  if row['status'] in ['applied','failed','conflict']:return 0
  old=json.loads(row.get('result') or '{}');progress=a.progress;phase=a.phase;status='processing'
  if a.processing_finished or a.publication_finished:
   if os.getenv('JOB_RESULT')!='success':status='failed';progress=old.get('progress',0);phase='Falha no workflow. Abra os detalhes no GitHub Actions.'
   elif a.processing_finished and os.getenv('NEEDS_PUBLISH')=='true':progress=80;phase='Dados processados. Aguardando publicação do site.'
   else:status='applied';progress=100;phase='Site publicado e processamento concluído' if a.publication_finished else 'Atualização concluída; não houve alteração pública a publicar'
  repo=os.getenv('GITHUB_REPOSITORY','');run=os.getenv('GITHUB_RUN_ID','')
  info={**old,'progress':max(old.get('progress',0),min(100,progress)),'phase':phase,'heartbeat':dt.datetime.now(dt.timezone.utc).isoformat(),'stage':'complete' if status=='applied' else 'failed' if status=='failed' else 'publishing' if a.processing_finished else 'runner'}
  if status in ['applied','failed']:info['finishedAt']=info['heartbeat']
  report=Path('.biblioteca-runtime/relatorio.json')
  if report.exists():
   final=json.loads(report.read_text());info['stats']={**old.get('stats',{}),**final}
   if os.getenv('JOB_RESULT')=='success':info['stats']['publishedTotal']=final.get('approvedPublic',0)
   if final.get('errors'):info['error']='; '.join(str(x) for x in final['errors'])
  if status=='failed' and not info.get('error'):info['error']='workflow_'+os.getenv('JOB_RESULT','unknown')
  if re.fullmatch(r'[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+',repo) and run.isdigit():info['url']='https://github.com/'+repo+'/actions/runs/'+run
  client.call('pge_commands',query,'PATCH',dict(status=status,result=json.dumps(info,ensure_ascii=False),updated_at=info['heartbeat']))
  return 0
 except Exception as ex:print('Falha ao informar progresso: '+type(ex).__name__);return 1
if __name__=='__main__':sys.exit(main())

"""Orquestrador CLI e persistência em branch isolada, sem alterar main."""
import argparse, hashlib, json, os, shutil, subprocess, sys, tempfile
from pathlib import Path
from core import Stop, Engine, atomic, fresh_state, validate_catalog, validate_state, public_catalog
ROOT=Path(__file__).resolve().parents[2]

def git(*args,env=None):
    p=subprocess.run(['git','-C',str(ROOT),*args],env=env,capture_output=True,text=True)
    if p.returncode:raise RuntimeError('git_operation_failed:'+args[0])
    return p.stdout.strip()

class Store:
    """One recoverable snapshot per confirmed batch; force-with-lease rejects races.
    No parent commits on operational branch: avoid a permanent metadata history.
    The branch is public if the repository is public; never store personal data.
    """
    def __init__(self,enabled):
        self.enabled=enabled;self.dir=ROOT/'.biblioteca-runtime';self.dir.mkdir(exist_ok=True);self.path=self.dir/'estado.json';self.ref='refs/heads/biblioteca-estado';self.sha='';self.last=''
        if enabled:
            self.sha=git('ls-remote','origin',self.ref).split('\t')[0]
            if self.sha:
                git('fetch','--no-tags','origin',self.ref)
                for name in ['estado.json','catalogo.json']:
                    raw=git('show','FETCH_HEAD:'+name);json.loads(raw);(self.dir/name).write_text(raw+'\n')
        if not self.path.exists():atomic(self.path,fresh_state())
        if not (self.dir/'catalogo.json').exists():atomic(self.dir/'catalogo.json',dict(versao=3,itens=[],validUntil=None))
    def checkpoint(self):
        raw=self.path.read_bytes();parsed=json.loads(raw);validate_state(parsed)
        digest=hashlib.sha256(raw).hexdigest()
        if not self.enabled or digest==self.last:return
        # Independent index; no staging/deleting source files or overwriting main.
        index=self.dir/'index';env={**os.environ,'GIT_INDEX_FILE':str(index),'GIT_WORK_TREE':str(self.dir),'GIT_AUTHOR_NAME':'Biblioteca automática','GIT_AUTHOR_EMAIL':'biblioteca@users.noreply.github.com','GIT_COMMITTER_NAME':'Biblioteca automática','GIT_COMMITTER_EMAIL':'biblioteca@users.noreply.github.com'}
        git('read-tree','--empty',env=env)
        names=['estado.json']+(['catalogo.json'] if (self.dir/'catalogo.json').exists() else [])
        git('add','--',*names,env=env);tree=git('write-tree',env=env);sha=git('commit-tree',tree,'-m','Snapshot recuperável da biblioteca',env=env)
        git('push','origin',sha+':'+self.ref,'--force-with-lease='+self.ref+':'+self.sha,env=env)
        self.sha=sha;self.last=digest

def build_site(root,out):
    out=Path(out)
    if out.exists():shutil.rmtree(out)
    out.mkdir(parents=True)
    # Explicit allowlist prevents control data, scripts, logs, prompts and credentials leaking into Pages.
    for name in ['index.html','favicon.ico','catalogo.txt','links-biblias-pdf.txt','CNAME']:
        if (root/name).is_file():shutil.copy2(root/name,out/name)
    for name in ['assets','dados','modelos']:
        if (root/name).exists():shutil.copytree(root/name,out/name,ignore=shutil.ignore_patterns('*.tmp','*.bak','__pycache__'))
    (out/'.nojekyll').touch()

def main():
    p=argparse.ArgumentParser();p.add_argument('--persist',action='store_true');p.add_argument('--smoke',action='store_true');p.add_argument('--build-only',action='store_true');p.add_argument('--ack-deploy',action='store_true');p.add_argument('--output',default='_site');args=p.parse_args()
    store=Store(args.persist);engine=Engine(ROOT,store.path)
    if args.ack_deploy:
        engine.s['deployedHash']=engine.s.get('lastPublishedHash','');engine.save();store.checkpoint();return 0
    original_save=engine.save
    def checkpoint():original_save();store.checkpoint()
    engine.save=checkpoint;engine.api.save=checkpoint
    previous=store.dir/'catalogo.json'
    if previous.exists():
        c=json.loads(previous.read_text());validate_catalog(c,engine.tax);atomic(ROOT/'dados/biblioteca/catalogo.json',c)
    report={};code=0
    try:
        if not args.build_only:report=engine.run(args.smoke)
        if not args.smoke:
            engine.apply_editorial()
            catalog=public_catalog(engine.s,engine.tax,engine.now,engine.cfg)
            old=json.loads((ROOT/'dados/biblioteca/catalogo.json').read_text())
            changed=catalog!=old
            if changed:atomic(ROOT/'dados/biblioteca/catalogo.json',catalog)
            atomic(store.dir/'catalogo.json',catalog)
            # Persist publication intent and catalog together. A failed deploy is retried next daily run.
            engine.s['lastPublishedHash']=hashlib.sha256(json.dumps(catalog,sort_keys=True).encode()).hexdigest();engine.save()
            build_site(ROOT,ROOT/args.output)
            report['publicChanged']=changed or engine.s.get('deployedHash')!=engine.s['lastPublishedHash']
        if report.get('errors'):code=1
    except Exception as ex:
        # Never emit raw URL/exceptions from transport: these may contain credentials.
        report={'result':'failed','reason':str(ex) if isinstance(ex,Stop) or str(ex) in ['configure_smokeVideoId_first','smoke_video_not_public'] else type(ex).__name__};code=1
    atomic(store.dir/'relatorio.json',report)
    summary=os.getenv('GITHUB_STEP_SUMMARY')
    if summary:
        with open(summary,'a') as f:f.write('## Biblioteca audiovisual\n\n```json\n'+json.dumps(report,ensure_ascii=False,indent=2)+'\n```\n')
    print(json.dumps(report,ensure_ascii=False));return code
if __name__=='__main__':sys.exit(main())

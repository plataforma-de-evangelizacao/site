import copy, datetime as dt, importlib.util, json, os, sys, tempfile, unittest
from pathlib import Path
from urllib import error
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'scripts/biblioteca'))
from core import *
NOW=dt.datetime(2026,11,2,12,tzinfo=UTC)
ID='abc123def45'
def video(id=ID,**kw):
    d=dict(id=id,snippet=dict(title='Jonas — desenho bíblico',description='Uma adaptação.',channelId='UCfixture',channelTitle='Canal teste',defaultAudioLanguage='pt-BR',thumbnails={'high':{'url':'https://i.ytimg.com/vi/'+id+'/hqdefault.jpg'}}),contentDetails=dict(duration='PT25M'),status=dict(privacyStatus='public',uploadStatus='processed',embeddable=True));d.update(kw);return d
ED=dict(revisado=True,aprovacao='approved',categoria='desenho',idioma='pt-BR',idiomaVerificado=True,livros=['jn'],testamento='antigo',referencias=[dict(livro='jn',capitulo=1,revisada=True)])
class Tests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup);self.root=Path(self.tmp.name)
        for name in ['biblioteca-controle','dados/biblioteca']:
            import shutil;shutil.copytree(ROOT/name,self.root/name)
        self.e=Engine(self.root,self.root/'state.json',now=NOW)
        self.e.cfg['autoApprovalEnabled']=False
        self.e.api.transport=lambda ep,p:{'items':[video(x) for x in p.get('id',ID).split(',')]};self.e.api.key='not-a-real-key';self.e.api.sleep=lambda x:None
    def approve(self,id=ID):
        self.e.editorial[id]=copy.deepcopy(ED);self.e.details([id]);return self.e.s['records'][id]
    def test_empty_catalog(self):self.assertEqual(public_catalog(self.e.s,self.e.tax,NOW,self.e.cfg)['itens'],[])
    def test_new_video(self):self.assertEqual(self.approve()['aprovacao'],'approved')
    def test_duplicate_video(self):
        self.e.details([ID,ID]);self.e.details([ID]);self.assertEqual(self.e.api.calls['videos'],1);self.assertEqual(len(self.e.s['records']),1)
    def test_private(self):self.assertEqual(technical(video(status={'privacyStatus':'private'}),'BR'),'unavailable')
    def test_removed_confirmation(self):
        self.approve();self.e.cfg['massUnavailablePercent']=100;self.e.api.transport=lambda *a:{'items':[]};self.e.details([ID],True)
        self.assertEqual(self.e.s['records'][ID]['disponibilidade'],'suspected_unavailable');self.assertEqual(len(public_catalog(self.e.s,self.e.tax,NOW,self.e.cfg)['itens']),1)
        self.e.details([ID],True);self.assertEqual(self.e.s['records'][ID]['disponibilidade'],'unavailable')
    def test_embed_restricted(self):self.assertEqual(technical(video(status={'privacyStatus':'public','embeddable':False}),'BR'),'embed_restricted')
    def test_region_restriction(self):self.assertEqual(technical(video(contentDetails={'regionRestriction':{'blocked':['BR']}}),'BR'),'region_restricted')
    def test_network_preserves(self):
        self.approve();before=copy.deepcopy(self.e.s['records']);self.e.api.transport=lambda *a:(_ for _ in ()).throw(error.URLError('offline'))
        with self.assertRaises(Temporary):self.e.details([ID],True)
        self.assertEqual(before,self.e.s['records'])
    def test_429_limited(self):
        self.e.api.transport=lambda *a:(_ for _ in ()).throw(error.HTTPError('redacted',429,'rate',{},None))
        with self.assertRaises(Temporary):self.e.details([ID])
        self.assertEqual(self.e.api.calls['videos'],4)
    def test_403_stops(self):
        self.e.api.transport=lambda *a:(_ for _ in ()).throw(error.HTTPError('redacted',403,'auth',{},None))
        with self.assertRaises(Stop):self.e.details([ID])
        self.assertEqual(self.e.api.calls['videos'],1)
    def test_quota_no_retry(self):
        import io
        body=io.BytesIO(json.dumps({'error':{'errors':[{'reason':'quotaExceeded'}]}}).encode())
        self.e.api.transport=lambda *a:(_ for _ in ()).throw(error.HTTPError('redacted',403,'quota',{},body))
        with self.assertRaisesRegex(Stop,'quota'):self.e.details([ID])
        self.assertEqual(self.e.api.calls['videos'],1)
    def test_partial_mass_guard(self):
        self.approve();self.e.api.transport=lambda *a:{'items':[]}
        with self.assertRaisesRegex(Temporary,'mass_change'):self.e.details([ID],True)
        self.assertEqual(self.e.s['records'][ID]['disponibilidade'],'available')
    def test_invalid_response(self):
        self.e.api.transport=lambda *a:{}
        with self.assertRaises(Temporary):self.e.details([ID])
    def test_invalid_json_not_overwritten(self):
        self.e.path.write_text('{bad')
        with self.assertRaises(json.JSONDecodeError):Engine(self.root,self.e.path)
        self.assertEqual(self.e.path.read_text(),'{bad')
    def test_recovery_processing(self):
        self.e.schedule();t=self.e.s['queues']['discovery'][0];t['state']='processing';t['lastAttempt']=(NOW-dt.timedelta(hours=2)).isoformat();self.e.schedule();self.assertEqual(t['state'],'pending')
    def test_uncertain_classification(self):self.assertEqual(classify(video(),{},self.e.cfg)['aprovacao'],'pending_review')
    def test_rejected_not_resurrected(self):
        self.approve();self.e.s['records'][ID]['aprovacao']='rejected';self.e.details([ID],True);self.assertEqual(self.e.s['records'][ID]['aprovacao'],'rejected')
    def test_cache_valid(self):
        self.e.schedule();t=self.e.s['queues']['discovery'][0];self.e.s['cache'][t['key']]={'at':NOW.isoformat(),'ids':[],'state':'completed'};self.e.discover(t);self.assertFalse(self.e.api.calls)
    def test_cache_expired(self):
        self.e.schedule();t=self.e.s['queues']['discovery'][0];self.e.s['cache'][t['key']]={'at':(NOW-dt.timedelta(days=11)).isoformat(),'ids':[],'state':'completed'}
        self.e.api.transport=lambda *a:{'items':[]};self.e.discover(t);self.assertEqual(self.e.api.calls['search'],1)
    def test_lost_schedule(self):
        self.e.schedule();t=self.e.s['queues']['discovery'][0];count=len(self.e.s['queues']['discovery']);self.e.now+=dt.timedelta(days=31);self.e.schedule();self.assertEqual(len(self.e.s['queues']['discovery']),count);self.assertGreater(instant(self.e.s['rounds']['discovery']['nextDue']),self.e.now)
    def test_no_change_public_record(self):
        self.approve();before=copy.deepcopy(self.e.s['records']);self.e.now+=dt.timedelta(days=15);self.e.details([ID],True);self.assertEqual(before,self.e.s['records']);self.assertNotEqual(self.e.s['checks'][ID]['verified'],NOW.isoformat())
    def test_insufficient_budget(self):
        self.e.api.cfg['maxOtherCallsPerRun']=0
        with self.assertRaises(Stop):self.e.details([ID])
        self.assertFalse(self.e.api.calls)
    def test_missing_key(self):
        self.e.api.key=''
        with self.assertRaisesRegex(Stop,'missing_credentials'):self.e.details([ID])
    def test_no_invented_references(self):self.assertEqual(classify(video(),{},self.e.cfg)['referencias'],[])
    def test_expired_metadata_removed(self):
        self.approve();self.e.now+=dt.timedelta(days=30);self.e.audit();self.assertIsNone(self.e.s['records'][ID]['titulo']);self.assertFalse(public_catalog(self.e.s,self.e.tax,self.e.now,self.e.cfg)['itens'])
    def test_taxonomy_66(self):self.assertEqual(len(self.e.tax['livros']),66)
    def test_queue_dedup(self):
        for _ in range(4):enqueue(self.e.s,'verification','verify',ID,{},NOW,'round')
        self.assertEqual(len(self.e.s['queues']['verification']),1)
    def test_10000_ids_batches(self):
        ids=[f'{i:011d}' for i in range(10000)];self.e.api.cfg['maxOtherCallsPerRun']=250
        sizes=[]
        def transport(ep,p):sizes.append(len(p['id'].split(',')));return {'items':[video(x) for x in p['id'].split(',')]}
        self.e.api.transport=transport;self.e.save=lambda:None;self.e.api.save=lambda:None
        self.e.details(ids);self.assertEqual(len(self.e.s['records']),10000);self.assertEqual(len(sizes),200);self.assertEqual(max(sizes),50)
    def test_atomic_last_valid(self):
        p=self.root/'last.json';atomic(p,{'ok':1});self.assertFalse(atomic(p,{'ok':1}));self.assertEqual(json.loads(p.read_text()),{'ok':1})
    def test_thumbnail_external_not_accepted(self):
        v=video();v['snippet']['thumbnails']['high']['url']='https://evil.invalid/x';self.assertIsNone(classify(v,{},self.e.cfg)['thumbnail'])
    def test_ed_reference_invalid_blocks(self):
        self.approve();self.e.s['records'][ID]['referencias'][0]['capitulo']=999
        with self.assertRaises(AssertionError):public_catalog(self.e.s,self.e.tax,NOW,self.e.cfg)
    def test_paid_services_forbidden(self):
        p=self.root/'biblioteca-controle/config.json';c=json.loads(p.read_text());c['allowPaidServices']=True;atomic(p,c)
        with self.assertRaises(ValueError):Engine(self.root,self.e.path)

class StoreTests(unittest.TestCase):
    def test_concurrent_commit_and_recovery(self):
        import run as runner,subprocess
        with tempfile.TemporaryDirectory() as d:
            root=Path(d)/'repo';root.mkdir();bare=Path(d)/'remote';subprocess.run(['git','init','--bare',str(bare)],capture_output=True,check=True);subprocess.run(['git','init',str(root)],capture_output=True,check=True);subprocess.run(['git','-C',str(root),'remote','add','origin',str(bare)],check=True)
            original=runner.ROOT;runner.ROOT=root
            try:
                a=runner.Store(True);a.checkpoint();b=runner.Store(True);b.sentinel=True
                state=json.loads(b.path.read_text());state['lastPublishedHash']='first';atomic(b.path,state);b.checkpoint()
                state['lastPublishedHash']='race';atomic(a.path,state)
                with self.assertRaises(RuntimeError):a.checkpoint()
                c=runner.Store(True);self.assertEqual(json.loads(c.path.read_text())['lastPublishedHash'],'first')
                # The operational branch has one reachable snapshot, no API metadata history.
                count=runner.git('rev-list','--count',c.sha);self.assertEqual(count,'1')
            finally:runner.ROOT=original
    def test_public_artifact_excludes_controls(self):
        from run import build_site
        with tempfile.TemporaryDirectory() as d:
            out=Path(d)/'site';build_site(ROOT,out)
            self.assertTrue((out/'index.html').exists());self.assertFalse((out/'biblioteca-controle').exists());self.assertFalse((out/'.github').exists());self.assertFalse((out/'scripts').exists())
if __name__=='__main__':unittest.main()

class DeployRecoveryTests(unittest.TestCase):
    def test_failed_deploy_remains_pending_until_ack(self):
        import run as runner,subprocess,shutil
        with tempfile.TemporaryDirectory() as d:
            root=Path(d)/'repo';root.mkdir();bare=Path(d)/'remote'
            for directory in ['biblioteca-controle','dados/biblioteca']:shutil.copytree(ROOT/directory,root/directory)
            (root/'index.html').write_text('<html></html>')
            subprocess.run(['git','init','--bare',str(bare)],capture_output=True,check=True);subprocess.run(['git','init',str(root)],capture_output=True,check=True);subprocess.run(['git','-C',str(root),'remote','add','origin',str(bare)],check=True)
            original=runner.ROOT;argv=sys.argv[:];runner.ROOT=root
            from unittest.mock import patch
            with patch.dict(os.environ,{"SUPABASE_URL":"","SUPABASE_SERVICE_ROLE_KEY":"","ADMIN_REQUEST":"","YOUTUBE_API_KEY":""}):
                try:
                    sys.argv=['run.py','--persist','--build-only'];self.assertEqual(runner.main(),0)
                    self.assertTrue(json.loads((root/'.biblioteca-runtime/relatorio.json').read_text())['publicChanged'])
                    # Simulate failed deploy: no acknowledgment. The next run must still request a deploy.
                    self.assertEqual(runner.main(),0);self.assertTrue(json.loads((root/'.biblioteca-runtime/relatorio.json').read_text())['publicChanged'])
                    sys.argv=['run.py','--persist','--ack-deploy'];self.assertEqual(runner.main(),0)
                    sys.argv=['run.py','--persist','--build-only'];self.assertEqual(runner.main(),0)
                    self.assertFalse(json.loads((root/'.biblioteca-runtime/relatorio.json').read_text())['publicChanged'])
                finally:runner.ROOT=original;sys.argv=argv
class AutomaticApprovalTests(unittest.TestCase):
    def setUp(self):
        Tests.setUp(self)
        # Deterministic test policy; never depend on the owner's live approval settings.
        self.e.cfg.update(autoApprovalEnabled=True,approvedRules=[dict(
            id='fixture-auto-approval',approved=True,channelId='UCfixture',
            requirePortugueseMetadata=True,requireBiblicalTitle=True,
            minDurationSeconds=240,titlePattern=r'desenho|filme|s[eé]rie',
            biblicalTitlePattern=r'b[ií]blic|jonas')],excludedTitleTerms=['trailer','teaser'])
    def test_auto_eligible(self):
        self.assertEqual(classify(video(),{},self.e.cfg)['aprovacao'],'approved')
    def test_production_can_disable_automatic_approval(self):
        cfg={**self.e.cfg,'autoApprovalEnabled':False,'approvedRules':[]}
        self.assertEqual(classify(video(),{},cfg)['aprovacao'],'pending_review')
    def test_auto_unknown_language_pending(self):
        v=video();v['snippet'].pop('defaultAudioLanguage');self.assertEqual(classify(v,{},self.e.cfg)['aprovacao'],'pending_review')
    def test_auto_nonbiblical_pending(self):
        v=video();v['snippet']['title']='Filme de aventura em português';self.assertEqual(classify(v,{},self.e.cfg)['aprovacao'],'pending_review')
    def test_auto_trailer_pending(self):
        v=video();v['snippet']['title']='Trailer de filme bíblico';self.assertEqual(classify(v,{},self.e.cfg)['aprovacao'],'pending_review')
    def test_auto_conflicting_audio_pending(self):
        v=video();v['snippet']['title']='Desenho bíblico em português';v['snippet']['defaultAudioLanguage']='en';self.assertEqual(classify(v,{},self.e.cfg)['aprovacao'],'pending_review')
    def test_auto_rejected_preserved(self):
        self.assertEqual(classify(video(),{'aprovacao':'rejected'},self.e.cfg)['aprovacao'],'rejected')
    def test_uncertain_classification(self):
        v=video();v['snippet']['title']='Conteúdo não identificado';self.assertEqual(classify(v,{},self.e.cfg)['aprovacao'],'pending_review')

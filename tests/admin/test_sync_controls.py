import importlib.util,json,os,unittest
from pathlib import Path
from unittest.mock import patch
ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('sync_controls',ROOT/'scripts/admin/sync.py');b=importlib.util.module_from_spec(spec);spec.loader.exec_module(b)
class Fake:
 def __init__(self):self.patches=[]
 def call(self,table,query='',method='GET',data=None):
  if method=='PATCH':self.patches.append(data)
  return []
class SyncControlTests(unittest.TestCase):
 def command(self,target):return {'id':'11111111-1111-4111-8111-111111111111','status':'pending','action':'run_sync','payload':{'target':target}}
 def test_arbitrary_workflow_target_rejected(self):
  with self.assertRaisesRegex(ValueError,'invalid_sync_target'):b.sync_command(Fake(),self.command('arbitrary-shell-command'))
 def test_discovery_is_retired(self):
  with self.assertRaisesRegex(ValueError,'invalid_sync_target'):b.sync_command(Fake(),self.command('video-discovery'))
 def test_publication_is_not_new_discovery(self):
  with patch.object(b,'dispatch_library') as dispatch:b.sync_command(Fake(),self.command('site-publication'));self.assertEqual(dispatch.call_args.args[1],'publicar-site')
 def test_panel_sync_does_not_dispatch_workflow(self):
  client=Fake()
  with patch.object(b,'export') as export,patch.object(b,'dispatch_library') as dispatch:b.sync_command(client,self.command('panel-sync'));export.assert_called_once();dispatch.assert_not_called()
  self.assertEqual(client.patches[-1]['status'],'applied');self.assertEqual(json.loads(client.patches[-1]['result'])['progress'],100)
 def test_processing_not_dispatched_twice(self):
  c=self.command('site-publication');c['status']='processing'
  with patch.dict(os.environ,{'GH_TOKEN':''}),patch.object(b,'dispatch_library') as dispatch:b.sync_command(Fake(),c);dispatch.assert_not_called()
 def test_migration_preserves_security(self):
  sql=(ROOT/'scripts/admin/atualizacao-painel.sql').read_text();self.assertIn("'run_sync'",sql);self.assertNotIn('disable row level security',sql.lower());self.assertNotIn('grant ',sql.lower())
 def test_dispatch_does_not_accept_credentials_from_browser(self):
  with patch.dict(os.environ,{'GH_TOKEN':'','GITHUB_REPOSITORY':''}),self.assertRaisesRegex(ValueError,'invalid_github'):b.dispatch_library(self.command('video-discovery'),'buscar-agora')

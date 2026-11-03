import importlib.util,json,os,sys,tempfile,unittest,io
from pathlib import Path
from unittest.mock import patch
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'scripts/admin'))
spec=importlib.util.spec_from_file_location('pge_update_backend',ROOT/'scripts/admin/update_backend.py');b=importlib.util.module_from_spec(spec);spec.loader.exec_module(b)
class Response:
 def __init__(self,body=None):self.body=body or {}
 def __enter__(self):return self
 def __exit__(self,*args):pass
 def read(self):return json.dumps(self.body).encode()
class BackendUpdateTests(unittest.TestCase):
 def test_manifest_matches_sources_and_frontend(self):
  release,items=b.load_release();self.assertEqual(release['version'],json.loads((ROOT/'admin/release.json').read_text())['version']);self.assertEqual([x['version'] for x in items],json.loads((ROOT/'admin/release.json').read_text())['migrations'])
 def test_bundle_is_atomic_guarded_and_versioned(self):
  _,items=b.load_release();sql=b.migration_bundle(items);self.assertTrue(sql.startswith('begin;'));self.assertTrue(sql.endswith('commit;'));self.assertIn('pg_advisory_xact_lock',sql);self.assertEqual(sql.count('migration_checksum_conflict'),len(items))
 def test_outer_transaction_strip_keeps_function_blocks(self):
  text='-- comment\nbegin;\ncreate function f() returns void as $$ begin null; end; $$ language plpgsql;\ncommit;\n';self.assertIn('begin null;',b.inner(text));self.assertFalse(b.inner(text).endswith('commit;'))
 def test_unwrapped_sql_is_rejected(self):
  with self.assertRaises(b.Failure):b.inner('drop table arbitrary;')
 def test_management_posts_fixed_migration_endpoint(self):
  calls=[]
  def transport(req,**kw):calls.append((req,kw));return Response()
  manager=b.Management('fixture','server-only-secret',transport);release,items=b.load_release();manager.migrate(release,items);req,kw=calls[0];self.assertEqual(req.full_url,'https://api.supabase.com/v1/projects/fixture/database/migrations');self.assertEqual(req.get_method(),'POST');self.assertEqual(kw['timeout'],180);self.assertNotIn('server-only-secret',req.data.decode())
 def test_secret_install_is_server_to_server(self):
  calls=[]
  def transport(req,**kw):calls.append(req);return Response()
  b.Management('fixture','management-secret',transport).secrets('github-secret');self.assertTrue(calls[0].full_url.endswith('/secrets'));self.assertEqual(json.loads(calls[0].data),[{'name':'GITHUB_DISPATCH_TOKEN','value':'github-secret'}])
 def test_deploy_multipart_has_source_and_explicit_auth(self):
  calls=[]
  def transport(req,**kw):calls.append(req);return Response()
  b.Management('fixture','secret',transport).deploy(b'// fixture source');self.assertIn(b'filename="index.ts"',calls[0].data);self.assertIn(b'"verify_jwt": false',calls[0].data);self.assertTrue(calls[0].full_url.endswith('functions/deploy?slug=admin-dispatch'))
 def test_management_error_does_not_leak_response(self):
  from urllib.error import HTTPError
  def transport(req,**kw):raise HTTPError(req.full_url,403,'secret private details',{},None)
  with self.assertRaisesRegex(b.Failure,'^supabase_management_http_403$'):b.Management('fixture','secret',transport).call('secrets',[])
 def test_unrelated_command_cannot_be_marked_failed(self):
  class Client:
   def __init__(self):self.writes=[]
   def call(self,table,q,method='GET',data=None):
    if method=='GET':return [dict(action='save_json',payload={'path':'dados/projetos.json'},status='pending')]
    self.writes.append(data)
  c=Client()
  with patch.dict(os.environ,{'ADMIN_REQUEST':'11111111-1111-4111-8111-111111111111'}):b.finish_command(c,False,'denied','version')
  self.assertFalse(c.writes)
 def test_revoked_admin_cannot_update_schema(self):
  class Client:
   def call(self,table,q):return [dict(action='run_sync',payload={'target':'platform-update'},status='pending',user_id='revoked')] if table=='pge_commands' else []
  with patch.dict(os.environ,{'ADMIN_REQUEST':'11111111-1111-4111-8111-111111111111'}),self.assertRaisesRegex(b.Failure,'administrator_revoked'):b.authorize_request(Client())
 def test_health_checks_migration_checksums(self):
  class Client:
   url='https://fixture.supabase.co';key='fixture'
   def call(self,*args):return []
  with self.assertRaisesRegex(b.Failure,'migration_verification_failed'):b.verify(Client(),'v',[{'version':'1','checksum':'x'}],sleep=lambda _:None)
 def test_health_requires_live_release_and_dispatch_readiness(self):
  class Client:
   url='https://fixture.supabase.co';key='fixture'
   def call(self,*args):return [{'version':'1','checksum':'x'}]
  class R(Response):
   def __init__(self):super().__init__({'release':'wrong','dispatchReady':True})
  with self.assertRaisesRegex(b.Failure,'backend_health_not_confirmed'):b.verify(Client(),'v',[{'version':'1','checksum':'x'}],transport=lambda *a,**k:R(),sleep=lambda _:None)
 def test_pipeline_runs_migrations_then_secrets_then_function(self):
  from unittest.mock import MagicMock
  client=MagicMock(url='https://fixture.supabase.co',key='fixture');manager=MagicMock();events=[]
  manager.migrate.side_effect=lambda *a:events.append('migrate');manager.secrets.side_effect=lambda *a:events.append('secrets');manager.deploy.side_effect=lambda *a:events.append('deploy')
  with patch.object(b,'Client',return_value=client),patch.object(b,'Reporter'),patch.object(b,'authorize_request'),patch.object(b,'Management',return_value=manager),patch.object(b,'set_state'),patch.object(b,'verify',side_effect=lambda *a:events.append('verify')),patch.object(b,'finish_command') as finish,patch('sys.stdout',new_callable=io.StringIO),patch.dict(os.environ,{'SUPABASE_ACCESS_TOKEN':'management-fixture','GITHUB_DISPATCH_TOKEN':'github-fixture'}):
   self.assertEqual(b.main(),0);self.assertEqual(events,['migrate','secrets','deploy','verify']);self.assertTrue(finish.call_args.args[1])
 def test_function_failure_is_not_reported_as_installed(self):
  from unittest.mock import MagicMock
  client=MagicMock(url='https://fixture.supabase.co',key='fixture');manager=MagicMock();manager.deploy.side_effect=b.Failure('supabase_management_http_403')
  with patch.object(b,'Client',return_value=client),patch.object(b,'Reporter'),patch.object(b,'authorize_request'),patch.object(b,'Management',return_value=manager),patch.object(b,'set_state') as state,patch.object(b,'verify') as verify,patch.object(b,'finish_command') as finish,patch('sys.stdout',new_callable=io.StringIO),patch.dict(os.environ,{'SUPABASE_ACCESS_TOKEN':'management-fixture','GITHUB_DISPATCH_TOKEN':'github-fixture'}):
   self.assertEqual(b.main(),1);verify.assert_not_called();self.assertFalse(finish.call_args.args[1]);self.assertFalse(any(call.args[2]=='ready' for call in state.call_args_list))

 def test_failure_callback_does_not_overwrite_another_run(self):
  from unittest.mock import MagicMock
  client=MagicMock(url='https://fixture.supabase.co',key='fixture');client.call.return_value=[{'status':'processing','run_url':'another-run'}]
  with patch.object(b,'Client',return_value=client),patch.object(b,'run_url',return_value='current-run'),patch.object(b,'set_state') as state,patch.object(b,'finish_command'):
   self.assertEqual(b.record_workflow_failure(),0);state.assert_not_called()
 def test_failure_callback_updates_own_running_installation(self):
  from unittest.mock import MagicMock
  client=MagicMock(url='https://fixture.supabase.co',key='fixture');client.call.return_value=[{'status':'processing','run_url':'current-run'}]
  with patch.object(b,'Client',return_value=client),patch.object(b,'run_url',return_value='current-run'),patch.object(b,'set_state') as state,patch.object(b,'finish_command') as finish:
   self.assertEqual(b.record_workflow_failure(),0);self.assertEqual(state.call_args.args[2],'failed');self.assertFalse(finish.call_args.args[1])

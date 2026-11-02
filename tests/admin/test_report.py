import importlib.util,json,os,sys,unittest
from pathlib import Path
from unittest.mock import patch
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'scripts/admin'))
spec=importlib.util.spec_from_file_location('workflow_report',ROOT/'scripts/admin/report.py');r=importlib.util.module_from_spec(spec);spec.loader.exec_module(r)
class Fake:
 url='https://fixture.supabase.co';key='fixture-not-real'
 def __init__(self):self.patches=[];self.row={'action':'run_sync','status':'processing','result':json.dumps({'progress':40}),'payload':{'target':'video-discovery'}}
 def call(self,table,query='',method='GET',data=None):
  if method=='GET':return [self.row]
  self.patches.append(data)
class WorkflowReportTests(unittest.TestCase):
 def run_report(self,args,env=None,row=None):
  fake=Fake()
  if row:fake.row.update(row)
  with patch.object(r,'Client',return_value=fake),patch.object(sys,'argv',['report.py',*args]),patch.dict(os.environ,{'ADMIN_REQUEST':'11111111-1111-4111-8111-111111111111','GITHUB_REPOSITORY':'fixture/site','GITHUB_RUN_ID':'123',**(env or {})}):code=r.main()
  return code,fake
 def test_wait_for_actual_publication(self):
  code,c=self.run_report(['--processing-finished'],{'JOB_RESULT':'success','NEEDS_PUBLISH':'true'});self.assertEqual(code,0);self.assertEqual(c.patches[-1]['status'],'processing');self.assertEqual(json.loads(c.patches[-1]['result'])['progress'],80)
 def test_success_after_deploy(self):
  code,c=self.run_report(['--publication-finished'],{'JOB_RESULT':'success'});self.assertEqual(c.patches[-1]['status'],'applied');self.assertEqual(json.loads(c.patches[-1]['result'])['progress'],100)
 def test_failure_does_not_fake_completion(self):
  code,c=self.run_report(['--processing-finished'],{'JOB_RESULT':'failure'});self.assertEqual(c.patches[-1]['status'],'failed');self.assertEqual(json.loads(c.patches[-1]['result'])['progress'],40)
 def test_terminal_result_not_overwritten_on_rerun(self):
  code,c=self.run_report(['--progress','20','--phase','test'],row={'status':'applied'});self.assertFalse(c.patches)
 def test_wrong_action_cannot_be_updated(self):
  code,c=self.run_report(['--progress','20'],row={'action':'save_json'});self.assertEqual(code,1);self.assertFalse(c.patches)

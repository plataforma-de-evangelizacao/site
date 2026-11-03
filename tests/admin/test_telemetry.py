import importlib.util,json,os,sys,unittest
from pathlib import Path
from unittest.mock import patch
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'scripts/admin'))
spec=importlib.util.spec_from_file_location('admin_telemetry',ROOT/'scripts/admin/telemetry.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
class Fake:
 url='https://test.supabase.co';key='private-not-real'
 def __init__(self,status='processing'):self.status=status;self.writes=[]
 def call(self,table,query='',method='GET',data=None):
  if method=='GET':return [dict(status=self.status,result=json.dumps({'progress':40,'stats':{'newVideos':2}}))]
  self.writes.append(data);return []
class TelemetryTests(unittest.TestCase):
 def reporter(self,status='processing'):
  client=Fake(status)
  with patch.object(m,'Client',return_value=client),patch.dict(os.environ,{'ADMIN_REQUEST':'11111111-1111-4111-8111-111111111111'}):r=m.Reporter()
  return r,client
 def test_real_progress_is_monotonic_and_counts_merge(self):
  r,c=self.reporter();r.emit('Consultando',progress=35,stats={'blockedIgnored':3},force=True);info=json.loads(c.writes[0]['result']);self.assertEqual(info['progress'],40);self.assertEqual(info['stats'],{'newVideos':2,'blockedIgnored':3});self.assertIn('heartbeat',info);self.assertNotIn('private-not-real',c.writes[0]['result'])
 def test_throttle_does_not_emit_a_second_write(self):
  r,c=self.reporter();r.emit('Primeiro',force=True);r.emit('Segundo');self.assertEqual(len(c.writes),1)
 def test_terminal_command_not_reopened(self):
  r,c=self.reporter('failed');r.emit('Tarde demais',force=True);self.assertFalse(c.writes)

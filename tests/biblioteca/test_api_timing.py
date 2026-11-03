import json,sys,unittest
from pathlib import Path
from unittest.mock import patch
from urllib.error import URLError
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'scripts/biblioteca'))
import core
class ApiTimingTests(unittest.TestCase):
 def api(self,transport):
  cfg=json.loads((ROOT/'biblioteca-controle/config.json').read_text());return core.API('fixture',cfg,core.fresh_state(),lambda:None,transport=transport,sleep=lambda _:None)
 def test_response_time_and_real_stage_order(self):
  api=self.api(lambda *a:{'items':[]});events=[];api.on_event=lambda event:events.append(event.copy())
  with patch.object(core.time,'monotonic',side_effect=[10,10.25]):api.call('videos',id='abc123def45')
  self.assertEqual(api.response_seconds,[.25]);self.assertEqual([e['stage'] for e in events],['api_request','api_response'])
 def test_failed_attempt_does_not_count_as_response(self):
  calls=[]
  def transport(*args):
   calls.append(1)
   if len(calls)==1:raise URLError('not-real')
   return {'items':[]}
  api=self.api(transport)
  with patch.object(core.time,'monotonic',side_effect=[10,11,11.5]):api.call('videos',id='abc123def45')
  self.assertEqual(api.response_seconds,[.5]);self.assertEqual(api.calls['videos'],2)
 def test_progress_callback_error_does_not_break_discovery(self):
  api=self.api(lambda *a:{'items':[]});api.on_event=lambda event:(_ for _ in ()).throw(ValueError('telemetry offline'))
  self.assertEqual(api.call('videos',id='abc123def45'),{'items':[]})

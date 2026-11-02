import test_core as fixtures
from test_core import ID,video,NOW,ED
import unittest
import copy
class EditorialBlockTests(unittest.TestCase):
 setUp=fixtures.Tests.setUp
 approve=fixtures.Tests.approve
 def test_editorial_blocks_before_metadata_request(self):
  self.e.editorial[ID]={'aprovacao':'rejected','revisado':True,'reabrir':False};self.e.details([ID],True);self.assertFalse(self.e.api.calls)
 def test_editorial_blocks_after_provider_record_is_gone(self):
  self.e.editorial[ID]={'aprovacao':'rejected'};self.e.s['records'].pop(ID,None);self.e.details([ID]);self.assertNotIn(ID,self.e.s['records']);self.assertFalse(self.e.api.calls)
 def test_explicit_pending_overrides_auto_approval(self):
  self.e.cfg['autoApprovalEnabled']=True;self.e.editorial[ID]={'aprovacao':'pending_review','revisado':True,'reabrir':True};self.e.details([ID]);self.assertEqual(self.e.s['records'][ID]['aprovacao'],'pending_review')
 def test_restore_rejected_id_returns_to_review(self):
  self.approve();self.e.s['records'][ID]['aprovacao']='rejected';self.e.editorial[ID]={'aprovacao':'pending_review','revisado':True,'reabrir':True};self.e.details([ID],False);self.e.apply_editorial();self.assertEqual(self.e.s['records'][ID]['aprovacao'],'pending_review')

 def test_explicit_review_overrides_automatic_title_heuristic(self):
  self.e.cfg['excludedTitleTerms']=['jonas'];self.e.details([ID]);self.e.editorial[ID]=copy.deepcopy(ED);self.e.apply_editorial();self.assertEqual(self.e.s['records'][ID]['aprovacao'],'approved')

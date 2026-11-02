import copy,importlib.util,json,tempfile,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('bulk_bridge',ROOT/'scripts/admin/sync.py');b=importlib.util.module_from_spec(spec);spec.loader.exec_module(b)
A='abc123def45';B='xyz123def45'
class BulkTests(unittest.TestCase):
 def setUp(self):
  self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup);self.root=Path(self.tmp.name);self.old=b.ROOT;b.ROOT=self.root;self.addCleanup(setattr,b,'ROOT',self.old)
  (self.root/'biblioteca-controle').mkdir();self.file=self.root/'biblioteca-controle/editorial.json';self.file.write_text('{}')
  self.records={k:{'sha':'v1','record':{'aprovacao':'pending_review','idioma':'pt-BR','idiomaVerificado':True}} for k in [A,B]}
 def item(self,id=A,decision='approved'):
  return dict(id=id,expected_sha='v1',decision=decision,categoria='desenho',portuguese_confirmed=True)
 def apply(self,items):return json.loads(b.apply_command({'action':'review_video','payload':{'items':items}},self.records)[1])
 def test_bulk_approval_one_document(self):
  out=self.apply([self.item(A),self.item(B)]);self.assertEqual(set(out),{A,B});self.assertTrue(all(x['aprovacao']=='approved' for x in out.values()));self.assertEqual(self.file.read_text(),'{}')
 def test_bulk_conflict_is_atomic(self):
  item=self.item(B);item['expected_sha']='old'
  with self.assertRaisesRegex(ValueError,'conflict'):self.apply([self.item(A),item])
  self.assertEqual(self.file.read_text(),'{}')
 def test_bulk_requires_language_confirmation_for_each(self):
  item=self.item(B);item['portuguese_confirmed']=False
  with self.assertRaisesRegex(ValueError,'confirm_portuguese'):self.apply([self.item(A),item])
 def test_duplicate_ids_rejected(self):
  with self.assertRaisesRegex(ValueError,'invalid_video_id'):self.apply([self.item(),self.item()])
 def test_batch_limits(self):
  for items in [[],[self.item()]*301,'bad']:
   with self.subTest(items=type(items)),self.assertRaisesRegex(ValueError,'invalid_batch_size'):self.apply(items)
 def test_category_preserves_approval(self):
  self.records[A]['record']['aprovacao']='approved';out=self.apply([dict(id=A,expected_sha='v1',operation='category',categoria='filme')]);self.assertEqual(out[A]['aprovacao'],'approved');self.assertEqual(out[A]['categoria'],'filme');self.assertTrue(out[A]['idiomaVerificado'])
 def test_category_does_not_approve_pending(self):
  out=self.apply([dict(id=A,expected_sha='v1',operation='category',categoria='serie')]);self.assertEqual(out[A]['aprovacao'],'pending_review');self.assertTrue(out[A]['revisado'])
 def test_block_persists_editorial_tombstone(self):
  out=self.apply([self.item(decision='rejected')]);self.assertEqual(out[A]['aprovacao'],'rejected');self.assertFalse(out[A]['reabrir'])
 def test_restore_without_provider_metadata(self):
  blocked={'aprovacao':'rejected','revisado':True,'reabrir':False};self.file.write_text(json.dumps({A:blocked}));self.records={}
  out=self.apply([dict(id=A,operation='restore',expected_block_sha=b.sha(b.canonical(blocked)))]);self.assertEqual(out[A]['aprovacao'],'pending_review');self.assertTrue(out[A]['reabrir'])
 def test_restore_conflict(self):
  self.file.write_text(json.dumps({A:{'aprovacao':'rejected'}}))
  with self.assertRaisesRegex(ValueError,'conflict_block_changed'):self.apply([dict(id=A,operation='restore',expected_block_sha='old')])
 def test_category_cannot_unblock(self):
  self.file.write_text(json.dumps({A:{'aprovacao':'rejected'}}))
  with self.assertRaisesRegex(ValueError,'conflict_video_blocked'):self.apply([dict(id=A,expected_sha='v1',operation='category',categoria='filme')])
 def test_history_retains_batch_ids(self):
  out=b.brief_payload({'payload':{'items':[dict(self.item(),private='no')]}});self.assertEqual(out['count'],1);self.assertNotIn('private',out['items'][0])
 def test_all_author_areas_allowlisted(self):
  for path in ['dados/youtube.json','dados/oracoes.txt','dados/formacoes.json','dados/en/louvores.json']:self.assertIn(path,b.ALLOWED)
  self.assertNotIn('admin/config.json',b.ALLOWED);self.assertNotIn('dados/biblioteca/catalogo.json',b.ALLOWED)

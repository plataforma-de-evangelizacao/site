import importlib.util,json,tempfile,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('direct_sync',ROOT/'scripts/admin/sync.py');b=importlib.util.module_from_spec(spec);spec.loader.exec_module(b)
SQL=(ROOT/'scripts/admin/publicacao-direta.sql').read_text()
class DirectTests(unittest.TestCase):
 def test_public_adapter_wired_before_locale_loader(self):
  html=(ROOT/'index.html').read_text();self.assertLess(html.index('assets/live-content.js'),html.index('assets/localization.js'));self.assertIn('assets/live-content.css',html)
  for asset in ['vitrine','biblioteca','partners']:
   self.assertIn('pge-live-changed',(ROOT/f'assets/{asset}.js').read_text())
 def test_server_checks_membership(self):
  for name in ['pge_review_videos','pge_publish_documents']:
   part=SQL.split('function public.'+name,1)[1].split('end; $$;',1)[0]
   for text in ['auth.uid()','administrator_required','public.pge_admins']:self.assertIn(text,part)
 def test_anonymous_grants_are_read_only(self):
  grants=[s for s in SQL.split(';') if 'grant execute' in s.lower() and 'to anon' in s.lower()];self.assertTrue(grants);self.assertFalse(any('pge_review_videos' in s or 'pge_publish_documents' in s for s in grants))
 def test_publication_eligibility(self):
  part=SQL.split('function public.pge_public_catalog()',1)[1].split('$$;',1)[0]
  for text in ["'approved'","'available'",'v.expires_at>now()',"'idiomaVerificado'"]:self.assertIn(text,part)
 def test_conflicts_and_limits(self):
  for text in ['conflict_document_changed','conflict_decision_changed','conflict_video_changed','not between 1 and 300','not between 1 and 3','for update']:self.assertIn(text,SQL)
 def test_relationship_tables_protected(self):
  for name in ['pge_live_documents','pge_video_decisions','pge_partner_entities','pge_project_entities','pge_project_partners']:self.assertIn('alter table public.'+name+' enable row level security',SQL)
 def test_foreign_keys(self):self.assertIn('references public.pge_partner_entities(id) on delete cascade',SQL);self.assertIn('invalid_unknown_partner',SQL)
 def test_restore_and_archive(self):self.assertIn("old.decision='archived' and old.portuguese_confirmed",SQL);self.assertIn("item->>'_admin_hidden'='true'",SQL)
 def test_hydrate_preserves_edits_and_blocks(self):
  with tempfile.TemporaryDirectory() as tmp:
   root=Path(tmp);(root/'dados').mkdir();(root/'biblioteca-controle').mkdir();(root/'dados/projetos.json').write_text('{"itens":[]}');(root/'biblioteca-controle/editorial.json').write_text('{}')
   class Client:
    url='https://fixture.supabase.co';key='fixture'
    def call(self,table,query='',method='GET',data=None):
     return [{'path':'dados/projetos.json','content':'{"itens":[{"id":"new","titulo":"Novo"}]}','sha':'live:1'}] if table=='pge_live_documents' else [{'id':'abc123def45','decision':'rejected','category':'filme','portuguese_confirmed':False}]
   changed=b.hydrate_live(root,Client());self.assertIn('dados/projetos.json',changed);self.assertEqual(json.loads((root/'dados/projetos.json').read_text())['itens'][0]['titulo'],'Novo');self.assertEqual(json.loads((root/'biblioteca-controle/editorial.json').read_text())['abc123def45']['aprovacao'],'rejected')
 def test_paths_protected(self):
  class Client:
   url='https://fixture.supabase.co';key='fixture'
   def call(self,*a,**k):return [{'path':'admin/config.json','content':'{}'}]
  with self.assertRaisesRegex(ValueError,'path_not_allowed'):b.hydrate_live(ROOT,Client())

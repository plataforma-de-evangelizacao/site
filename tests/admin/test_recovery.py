import importlib.util,tempfile,pathlib,unittest,json,os
from unittest.mock import patch
ROOT=pathlib.Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('recovery',ROOT/'scripts/backup/pge_backup.py');b=importlib.util.module_from_spec(spec);spec.loader.exec_module(b)
class RecoveryTests(unittest.TestCase):
 def setUp(self):
  self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup);self.root=pathlib.Path(self.tmp.name);self.password='frase de recuperacao de teste segura';self.plain=self.root/'plain';self.plain.mkdir();(self.plain/'sub').mkdir();(self.plain/'sub/config.txt').write_text('informação que deve ser cifrada');(self.plain/'empty').write_bytes(b'');self.enc=self.root/'backup'
 def test_roundtrip(self):
  b.encrypt_tree(self.plain,self.enc,self.password);out=self.root/'out';m=b.decrypt_tree(self.enc,out,self.password);self.assertEqual(len(m['files']),2);self.assertEqual((out/'sub/config.txt').read_bytes(),(self.plain/'sub/config.txt').read_bytes());self.assertEqual((out/'empty').stat().st_size,0);self.assertNotIn(b'informa',(self.enc/'sub/config.txt.part0.enc').read_bytes())
 def test_corruption_fails(self):
  b.encrypt_tree(self.plain,self.enc,self.password);(self.enc/'sub/config.txt.part0.enc').write_bytes(b'broken')
  with self.assertRaises(b.Failure):b.decrypt_tree(self.enc,self.root/'out',self.password)
 def test_bad_password(self):
  b.encrypt_tree(self.plain,self.enc,self.password)
  with self.assertRaises(b.Failure):b.decrypt_tree(self.enc,self.root/'out','outra frase diferente segura')
 def test_vault(self):
  p=self.root/'credentials.enc';cfg={'token':'fake-secret-test'};b.seal_credentials(p,cfg,self.password);self.assertEqual(b.load_credentials(p,self.password),cfg);self.assertNotIn(b'fake-secret',p.read_bytes())
 def test_production_guard(self):
  cfg={'site_repo':'owner/site','database_url':'postgres://user:secret@prod.example/postgres'}
  with self.assertRaises(b.Failure):b.restore(cfg,'missing',self.password,'OWNER/SITE','postgres://user:s@other/postgres')
  with self.assertRaises(b.Failure):b.restore(cfg,'missing',self.password,'owner/test','postgres://user:newpass@prod.example/postgres')
 def test_repository_private_required(self):
  gh=b.GitHub({'github_token':'fake'});gh.repo=lambda n:{'private':False}
  with self.assertRaises(b.Failure):gh.ensure('owner/backup')
 def test_reserved_secret(self):
  with self.assertRaises(b.Failure):b.GitHub({'github_token':'fake'}).secret('owner/repo','GITHUB_DISPATCH_TOKEN','value')
 def test_short_phrase(self):
  with self.assertRaises(b.Failure):b.derive('short',os.urandom(16))
if __name__=='__main__':unittest.main()

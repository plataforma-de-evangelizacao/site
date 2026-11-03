import sys,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'scripts/biblioteca'))
from metadata import enrich
class MetadataTests(unittest.TestCase):
 def record(self,title='',description='',**kw):return dict(titulo=title,descricao=description,aprovacao='pending_review',**kw)
 def test_elias(self):
  r=enrich(self.record('Elias — filme completo'));self.assertIn('Elias',r['personagens']);self.assertEqual(r['testamento'],'antigo');self.assertEqual(r['formato'],'filme-completo');self.assertEqual(r['aprovacao'],'pending_review')
 def test_esther_and_hashtags(self):self.assertIn('Ester',enrich(self.record('Uma história bíblica','#Ester #fé'))['personagens'])
 def test_full_word_boundaries(self):self.assertNotIn('Ester',enrich(self.record('Esterilização e bem-estar')).get('personagens',[]))
 def test_kids_explicit_only(self):self.assertNotIn('publico',enrich(self.record('Um desenho')));self.assertEqual(enrich(self.record('Desenho infantil'))['publico'],'infantil')
 def test_negated_audience(self):self.assertNotIn('publico',enrich(self.record('Não indicado para crianças')))
 def test_bible_book_requires_evidence(self):self.assertNotIn('livros',enrich(self.record('Ester filme')));self.assertEqual(enrich(self.record('Ester 4:12 — estudo'))['livros'],['et'])
 def test_season_and_episode(self):
  r=enrich(self.record('Histórias de Elias - Temporada 2 Episódio 3'));self.assertEqual((r['serieId'],r['temporada'],r['episodio']),('Histórias de Elias',2,3))
 def test_no_bogus_episode_without_series(self):self.assertNotIn('episodio',enrich(self.record('Episódio 2')))
 def test_manual_values_preserved(self):
  r=enrich(self.record('Elias filme completo',personagens=[],publico='adulto'),protected=['personagens','publico']);self.assertEqual(r['personagens'],[]);self.assertEqual(r['publico'],'adulto')
 def test_no_precise_scripture_inference(self):self.assertNotIn('referencias',enrich(self.record('João 3:16')))
 def test_ambiguous_testament(self):self.assertNotIn('testamento',enrich(self.record('Moisés e Jesus — histórias')))
 def test_idempotent(self):
  r=enrich(self.record('Elias — filme completo'));self.assertEqual(enrich(r),r)

 def test_ambiguous_jo_abbreviation_is_not_job(self):
  r=enrich(self.record('Jo 3:16'));self.assertNotIn('Jó',r.get('personagens',[]));self.assertNotIn('jo',r.get('livros',[]))

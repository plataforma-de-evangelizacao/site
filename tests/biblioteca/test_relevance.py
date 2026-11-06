import unittest
from test_core import discovery_relevant
class RelevanceTests(unittest.TestCase):
 def test_unrelated_series(self):self.assertFalse(discovery_relevant({'tituloOriginal':'Melhor série de todos os tempos #cortes #PeterJordan #EiNerd','descricaoOriginal':'Game of Thrones. Trecho Os Irmãos Dias Podcast.'}))
 def test_description_character(self):self.assertTrue(discovery_relevant({'tituloOriginal':'Uma história poderosa','descricaoOriginal':'','personagens':['Elias']}))
 def test_christian_inspiration(self):self.assertTrue(discovery_relevant({'tituloOriginal':'Filme gospel de superação e esperança','descricaoOriginal':''}))
 def test_keyword_boundary(self):self.assertFalse(discovery_relevant({'tituloOriginal':'Feira de tecidos','descricaoOriginal':''}))

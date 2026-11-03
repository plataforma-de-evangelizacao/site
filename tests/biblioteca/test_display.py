import unittest,sys,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'scripts/biblioteca'))
from core import classify
class DisplayTests(unittest.TestCase):
 def test_editorial_display_survives_provider_refresh(self):
  cfg=json.loads((ROOT/'biblioteca-controle/config.json').read_text());cfg['autoApprovalEnabled']=False
  video={'id':'abc123def45','snippet':{'title':'Uma história poderosa','description':'Sobre Ester','defaultAudioLanguage':'pt-BR'},'status':{'privacyStatus':'public','embeddable':True},'contentDetails':{'duration':'PT90M'}}
  ed={'revisado':True,'aprovacao':'approved','categoria':'filme','idioma':'pt-BR','idiomaVerificado':True,'tituloExibicao':'Ester — dublado','descricaoExibicao':'Descrição revisada'}
  for title in ['Uma história poderosa','Novo título do canal']:
   video['snippet']['title']=title;r=classify(video,ed,cfg)
   self.assertEqual(r['titulo'],'Ester — dublado');self.assertEqual(r['descricao'],'Descrição revisada');self.assertEqual(r['tituloOriginal'],title);self.assertEqual(r['descricaoOriginal'],'Sobre Ester');self.assertEqual(r['aprovacao'],'approved')
  ed.pop('tituloExibicao');ed.pop('descricaoExibicao');r=classify(video,ed,cfg);self.assertEqual(r['titulo'],'Novo título do canal');self.assertEqual(r['descricao'],'Sobre Ester')

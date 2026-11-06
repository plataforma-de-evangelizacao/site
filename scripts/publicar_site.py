"""Build the Pages artifact without running the retired discovery pipeline."""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts/biblioteca"))
from run import build_site

output = ROOT / "_site"
build_site(ROOT, output)
for name in ("biblioteca.js", "catalog-index.js"):
    (output / "assets" / name).unlink(missing_ok=True)
catalog = output / "dados/biblioteca"
catalog.mkdir(parents=True, exist_ok=True)
for path in catalog.glob("*.json"):
    path.unlink()
(catalog / "catalogo.json").write_text(json.dumps({"versao": 3, "itens": [], "validUntil": None}))
(output / "dados/fontes-legitimas.json").unlink(missing_ok=True)

# Keep unrelated entries in the shared catalogue.
shared = output / "dados/catalogo-conteudos.json"
if shared.is_file():
    document = json.loads(shared.read_text())
    if isinstance(document, dict) and isinstance(document.get("itens"), list):
        document["itens"] = [
            item for item in document["itens"]
            if not isinstance(item, dict) or item.get("tipo") not in {"filme", "desenho", "serie"}
        ]
        shared.write_text(json.dumps(document, ensure_ascii=False, indent=2) + "\n")

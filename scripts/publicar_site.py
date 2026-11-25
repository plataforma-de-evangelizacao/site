"""Build the Pages artifact without running the retired discovery pipeline."""
import json
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts/biblioteca"))
from run import build_site

output = ROOT / "_site"
build_site(ROOT, output)
# Promote Aurora Azul at the public entry point while preserving the entire
# prior page, its existing donation details, local assets and deep links.
if (output / "v49" / "index.html").is_file():
    shutil.copy2(output / "index.html", output / "legacy.html")
    shutil.copy2(ROOT / "deploy" / "index.html", output / "index.html")
    shutil.copy2(ROOT / "deploy" / "entrada-v49.js", output / "entrada-v49.js")

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

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
# Publish the approved interface at canonical root URLs. Keep former deep
# content links and the existing donation page intact on legacy.html.
aurora = output / "v49"
if (aurora / "index.html").is_file():
    shutil.copy2(output / "index.html", output / "legacy.html")
    pages = ["index.html", "biblioteca.html", "projetos.html",
             "atlas-solidario.html", "participar.html", "aluno.html", "aluno-acesso.html"]
    for source in (aurora / "assets").rglob("*"):
        if not source.is_file() or source.name.startswith("admin-preview"):
            continue
        target = output / "assets" / source.relative_to(aurora / "assets")
        if target.exists() and target.read_bytes() != source.read_bytes():
            raise RuntimeError("Conflito de ativo: " + str(target.relative_to(output)))
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
    for name in pages:
        html = (aurora / name).read_text(encoding="utf-8")
        html = html.replace('href="administracao.html"', 'href="admin/"')
        html = html.replace('href="../aluno/"', 'href="aluno/"')
        html = html.replace("https://plataforma-de-evangelizacao.github.io/site/#doacoes",
                            "legacy.html#doacoes")
        if name == "index.html":
            html = html.replace("</head>", '<script defer src="assets/legacy-links.js"></script></head>', 1)
        (output / name).write_text(html, encoding="utf-8")
    if (ROOT / "jogos").is_dir():
        shutil.copytree(ROOT / "jogos", output / "jogos", dirs_exist_ok=True)
    home_js = output / "assets" / "home.js"
    home_js.write_text(home_js.read_text(encoding="utf-8").replace(
        "https://plataforma-de-evangelizacao.github.io/site/#", "legacy.html#"), encoding="utf-8")
    # Old URLs are compatibility redirects, not a second application.
    shutil.rmtree(aurora)
    aurora.mkdir()
    def redirect(path, target):
        path.write_text(
            '<!doctype html><html lang="pt-BR"><meta charset="utf-8">'
            '<meta name="viewport" content="width=device-width,initial-scale=1">'
            '<script defer src="' + ('../' if path.parent == aurora else '') + 'assets/canonical-redirect.js"></script>'
            '<title>Plataforma Global de Evangelização</title>'
            '<p><a id="canonical-destination" href="' + target + '">Acessar a plataforma</a></p></html>',
            encoding="utf-8")
    for name in pages:
        redirect(aurora / name, "../" if name == "index.html" else "../" + name)
    redirect(aurora / "administracao.html", "../admin/")
    redirect(output / "administracao.html", "admin/")
    shutil.copy2(ROOT / "deploy" / "legacy-links.js", output / "assets" / "legacy-links.js")
    shutil.copy2(ROOT / "deploy" / "canonical-redirect.js", output / "assets" / "canonical-redirect.js")

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

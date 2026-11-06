(() => {
  const path = 'dados/rede-parceiros.json';
  const create = document.getElementById('new-partner');
  const list = document.getElementById('confirmed-partner-list');
  const status = document.getElementById('partner-admin-status');
  if (!create || !list || !status) return;

  const fields = [
    ['nome', 'Nome', 'text', true],
    ['cidade', 'Cidade', 'text', true],
    ['uf', 'Estado', 'text', true],
    ['descricao', 'Descrição', 'textarea', true],
    ['endereco', 'Endereço público', 'text'],
    ['capa', 'URL da foto autorizada', 'url'],
    ['alt', 'Descrição da foto', 'text'],
    ['site', 'Site oficial', 'url'],
    ['facebook', 'Facebook oficial', 'url'],
    ['youtube', 'YouTube oficial', 'url'],
    ['instagram', 'Instagram oficial', 'url'],
    ['mapa', 'Link no mapa', 'url']
  ];
  const bridge = () => window.pgeAdminBridge;
  const canWrite = () => window.PGEWorkspace?.can('content:rede-parceiros:write');
  const documentRow = () => bridge()?.documents().find(row => row.path === path);
  const isPublic = row => row.status === 'confirmada' && row.divulgacao_autorizada === true && !row._admin_hidden;

  function openEditor(partner = {}) {
    const source = documentRow();
    if (!source || !canWrite()) return;
    if (window.PGEForms?.dirty() && !confirm('Há uma edição de conteúdo aberta. Continuar com o cadastro?')) return;
    const dialog = document.createElement('dialog');
    const form = document.createElement('form');
    const heading = document.createElement('h2');
    heading.textContent = partner.id ? 'Editar parceiro' : 'Cadastrar novo parceiro';
    form.append(heading);
    for (const [name, title, type, required] of fields) {
      const label = document.createElement('label');
      const input = document.createElement(type === 'textarea' ? 'textarea' : 'input');
      if (type !== 'textarea') input.type = type;
      input.name = name;
      input.required = Boolean(required);
      input.value = partner[name] || '';
      label.append(title, input);
      form.append(label);
    }
    const approval = document.createElement('label');
    const authorized = document.createElement('input');
    authorized.type = 'checkbox';
    authorized.required = true;
    authorized.checked = partner.divulgacao_autorizada === true;
    approval.append(authorized, ' Confirmo a parceria e a autorização para divulgar os dados e a foto informados.');
    const save = document.createElement('button');
    save.type = 'submit';
    save.textContent = 'Salvar e publicar';
    const cancel = document.createElement('button');
    cancel.type = 'button';
    cancel.textContent = 'Cancelar';
    cancel.onclick = () => dialog.close();
    const feedback = document.createElement('p');
    feedback.setAttribute('role', 'status');
    form.append(approval, save, cancel, feedback);
    dialog.append(form);
    dialog.addEventListener('close', () => dialog.remove());
    document.body.append(dialog);
    dialog.showModal();

    form.addEventListener('submit', async event => {
      event.preventDefault();
      save.disabled = true;
      try {
        const values = Object.fromEntries([...new FormData(form)].map(([key, value]) => [key, value.trim()]));
        for (const [key, title, type, required] of fields) {
          if (required && !values[key]) throw Error('Preencha ' + title + '.');
          if (type === 'url' && values[key] && new URL(values[key]).protocol !== 'https:') {
            throw Error('Use HTTPS em ' + title + '.');
          }
        }
        if (values.instagram && !['instagram.com', 'www.instagram.com'].includes(new URL(values.instagram).hostname)) {
          throw Error('Informe uma URL oficial do Instagram.');
        }
        const data = JSON.parse(source.content);
        const record = {
          zona: 'a-informar', comunidades: [], ...partner, ...values,
          id: partner.id || crypto.randomUUID(), status: 'confirmada',
          divulgacao_autorizada: true, imagem_autorizada: Boolean(values.capa)
        };
        data.unidades = [...data.unidades.filter(row => row.id !== record.id), record];
        await bridge().publishDocuments([{ path, expected_sha: source.sha, content: JSON.stringify(data, null, 2) + '\n' }]);
        dialog.close();
        status.textContent = 'Parceiro publicado.';
      } catch (error) {
        feedback.textContent = error.message;
        save.disabled = false;
      }
    });
  }

  function render() {
    const source = documentRow();
    create.disabled = !source || !canWrite();
    list.replaceChildren();
    const rows = source ? JSON.parse(source.content).unidades.filter(isPublic) : [];
    if (!rows.length) list.textContent = 'Nenhum parceiro confirmado cadastrado.';
    for (const partner of rows) {
      const row = document.createElement('p');
      row.textContent = partner.nome + ' · ' + partner.cidade + ' ';
      if (canWrite()) {
        const edit = document.createElement('button');
        edit.type = 'button';
        edit.textContent = 'Editar';
        edit.onclick = () => openEditor(partner);
        row.append(edit);
      }
      list.append(row);
    }
  }
  create.onclick = () => openEditor();
  window.addEventListener('pge-admin-render', render);
})();

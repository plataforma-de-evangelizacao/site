'use strict';
(() => {
  const panel = document.getElementById('student-admin');
  const body = document.getElementById('student-admin-body');
  const create = (tag, text = '') => {
    const node = document.createElement(tag);
    node.textContent = text;
    return node;
  };
  const bridge = () => window.pgeAdminBridge;
  const table = (name, query = '', method = 'GET', data) =>
    bridge().call('/rest/v1/pge_student_' + name + query, method, data);
  const label = (form, title, input, name) => {
    const wrapper = create('label', title);
    input.name = name;
    wrapper.append(input);
    form.append(wrapper);
    return input;
  };
  function field(form, name, title, { value = '', type = 'text', required = false } = {}) {
    const input = label(form, title, create(type === 'textarea' ? 'textarea' : 'input'), name);
    if (type !== 'textarea') input.type = type;
    input.required = required;
    if (type === 'checkbox') input.checked = Boolean(value);
    else input.value = value ?? '';
    return input;
  }
  function select(form, name, title, rows, describe) {
    const input = label(form, title, create('select'), name);
    input.required = true;
    input.append(new Option('Selecione', ''));
    for (const row of rows) input.append(new Option(describe(row), row.id));
    return input;
  }
  function form(title, buttonText, save) {
    const section = create('details');
    const element = create('form');
    element.className = 'card';
    const button = create('button', buttonText);
    section.append(create('summary', title), element);
    body.append(section);
    element.onsubmit = async event => {
      event.preventDefault();
      button.disabled = true;
      try {
        await save(Object.fromEntries(new FormData(element)));
        await load();
        bridge().message('Alteração salva.');
      } catch {
        bridge().message('Não foi possível salvar. Confira os campos e as permissões.');
      } finally { button.disabled = false; }
    };
    return { element, finish: () => element.append(button) };
  }
  async function load() {
    body.replaceChildren(create('p', 'Carregando cadastro…'));
    try {
      const [settings, students, courses, enrollments, requests, submissions] = await Promise.all([
        table('settings', '?id=eq.true'), table('students', '?order=name'),
        table('courses', '?order=title'), table('enrollments'),
        table('requests', '?order=received_at.desc'), table('submissions')
      ]);
      body.replaceChildren();
      const visibility = form('Disponibilidade da Área do Aluno', 'Salvar disponibilidade', data =>
        table('settings', '?id=eq.true', 'PATCH', Object.fromEntries(
          ['visible', 'registration_open', 'login_open'].map(key => [key, data[key] === 'on']))));
      for (const [key, title] of [['visible', 'Exibir Área do Aluno'], ['registration_open', 'Aceitar inscrições públicas'], ['login_open', 'Permitir login dos alunos']])
        field(visibility.element, key, title, { type: 'checkbox', value: settings[0][key] });
      visibility.finish();

      function studentEditor(student = {}) {
        const editor = form(student.id ? student.name + ' · ' + student.enrollment_number : 'Cadastrar aluno', 'Salvar aluno', data =>
          table('students', student.id ? '?id=eq.' + student.id : '', student.id ? 'PATCH' : 'POST',
            { name: data.name.trim(), account_id: data.account_id.trim() || null }));
        field(editor.element, 'name', 'Nome', { required: true, value: student.name }).maxLength = 160;
        field(editor.element, 'account_id', 'UUID da conta Auth (opcional)', { value: student.account_id });
        editor.finish();
      }
      studentEditor();
      students.forEach(studentEditor);

      function courseEditor(course = {}) {
        const editor = form(course.id ? 'Curso · ' + course.title : 'Cadastrar curso', 'Salvar curso', data =>
          table('courses', course.id ? '?id=eq.' + course.id : '', course.id ? 'PATCH' : 'POST',
            { ...data, published: data.published === 'on' }));
        for (const [key, title] of [['title', 'Título do curso'], ['program', 'Nome do programa']])
          field(editor.element, key, title, { required: true, value: course[key] }).maxLength = 160;
        for (const [key, title] of [['description', 'Descrição pública'], ['material', 'Material privado em texto'], ['exam', 'Enunciado privado da prova']])
          field(editor.element, key, title, { type: 'textarea', value: course[key] });
        field(editor.element, 'published', 'Exibir no catálogo', { type: 'checkbox', value: course.published });
        editor.finish();
      }
      courseEditor();
      courses.forEach(courseEditor);

      const enrollment = form('Vincular aluno a curso', 'Vincular', data => table('enrollments', '', 'POST', data));
      select(enrollment.element, 'student_id', 'Aluno', students, row => row.name + ' · ' + row.enrollment_number);
      select(enrollment.element, 'course_id', 'Curso', courses, row => row.title);
      enrollment.finish();

      const studentName = id => students.find(row => row.id === id)?.name || 'Aluno';
      const courseName = id => courses.find(row => row.id === id)?.title || 'Curso';
      for (const row of enrollments) {
        const grade = form(studentName(row.student_id) + ' · ' + courseName(row.course_id), 'Salvar nota', data =>
          table('enrollments', '?id=eq.' + row.id, 'PATCH', { grade: data.grade === '' ? null : Number(data.grade) }));
        const score = field(grade.element, 'grade', 'Nota de 0 a 10', { type: 'number', value: row.grade });
        score.min = 0;
        score.max = 10;
        score.step = 'any';
        const submission = submissions.find(item => item.enrollment_id === row.id);
        grade.element.append(create('p', submission ? 'Resposta entregue:' : 'Sem resposta entregue.'));
        if (submission) {
          const answer = create('p', submission.answer);
          answer.style.whiteSpace = 'pre-wrap';
          grade.element.append(answer);
        }
        grade.finish();
      }
      const inbox = create('details');
      inbox.append(create('summary', 'Pedidos públicos de inscrição'));
      for (const request of requests) inbox.append(create('p', request.name + ' · ' + courseName(request.course_id)));
      if (!requests.length) inbox.append(create('p', 'Nenhum pedido recebido.'));
      body.append(inbox);
    } catch {
      body.replaceChildren(create('p', 'Cadastro indisponível. Confira a migração da V48 e a permissão de gerenciar usuários.'));
    }
  }
  panel.addEventListener('toggle', () => { if (panel.open) void load(); });
})();

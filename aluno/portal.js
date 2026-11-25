'use strict';
const $ = id => document.getElementById(id);
const node = (tag, text) => {
  const element = document.createElement(tag);
  element.textContent = text;
  return element;
};
let cfg;
let token;
async function api(path, data, method = 'POST') {
  const response = await fetch(cfg.supabaseUrl + path, {
    method, cache: 'no-store',
    headers: { apikey: cfg.publishableKey, 'Content-Type': 'application/json',
      ...(token ? { Authorization: 'Bearer ' + token } : {}) },
    body: data === undefined ? undefined : JSON.stringify(data)
  });
  if (!response.ok) throw Error('A solicitação não pôde ser concluída. Confira a disponibilidade e seus dados.');
  return response.status === 204 ? null : response.json();
}
const rpc = (name, body = {}) => api('/rest/v1/rpc/pge_student_' + name, body);
function lock() {
  token = undefined;
  $('portal').hidden = true;
  $('records').replaceChildren();
}
function action(form, work) {
  form.onsubmit = async event => {
    event.preventDefault();
    const button = form.querySelector('button');
    button.disabled = true;
    try { await work(new FormData(form)); }
    catch (error) { $('status').textContent = error.message; }
    finally { button.disabled = false; }
  };
}
function renderCatalog(state) {
  $('catalog').hidden = false;
  $('courses').replaceChildren();
  if (!state.courses.length) $('courses').append(node('p', 'Nenhum curso publicado.'));
  for (const course of state.courses) {
    const card = node('article', '');
    card.append(node('h3', course.title), node('p', course.program), node('p', course.description));
    if (state.registration_open) {
      const form = node('form', '');
      const label = node('label', 'Nome ');
      const input = node('input', '');
      input.name = 'name';
      input.required = true;
      input.maxLength = 160;
      label.append(input);
      form.append(node('p', 'Seu nome será usado pela equipe para avaliar o pedido de inscrição. O pedido não cria uma conta nem confirma matrícula.'), label, node('button', 'Solicitar inscrição'));
      action(form, async data => {
        await rpc('request', { p_name: data.get('name'), p_course: course.id });
        form.reset();
        $('status').textContent = 'Pedido recebido. A matrícula depende de confirmação da equipe.';
      });
      card.append(form);
    }
    $('courses').append(card);
  }
}
function renderRecords(data) {
  $('records').replaceChildren(node('p', data.name), node('p', 'Matrícula: ' + data.number));
  if (!data.courses.length) $('records').append(node('p', 'Nenhum curso vinculado.'));
  for (const course of data.courses) {
    const card = node('article', '');
    card.append(node('h3', course.title), node('p', course.program),
      node('p', course.grade == null ? 'Nota ainda não lançada.' : 'Nota: ' + course.grade));
    if (course.material) {
      const button = node('button', 'Baixar material em texto');
      button.onclick = () => {
        const url = URL.createObjectURL(new Blob([course.material], { type: 'text/plain;charset=utf-8' }));
        const link = node('a', '');
        link.href = url;
        link.download = 'material-do-curso.txt';
        link.click();
        setTimeout(() => URL.revokeObjectURL(url), 1000);
      };
      card.append(button);
    }
    if (course.exam) {
      card.append(node('h4', 'Prova'), node('pre', course.exam));
      if (course.submitted) card.append(node('p', 'Resposta entregue.'));
      else {
        const form = node('form', '');
        const label = node('label', 'Resposta');
        const answer = node('textarea', '');
        answer.name = 'answer';
        answer.required = true;
        answer.maxLength = 20000;
        label.append(answer);
        form.append(label, node('button', 'Entregar resposta'));
        action(form, async data => {
          await rpc('submit', { p_enrollment: course.enrollment, p_answer: data.get('answer') });
          form.replaceWith(node('p', 'Resposta entregue.'));
        });
        card.append(form);
      }
    }
    $('records').append(card);
  }
}
async function initialize() {
  cfg = await fetch('../admin/config.json', { cache: 'no-store' }).then(r => r.json());
  if (!/^https:\/\/[a-z0-9-]+\.supabase\.co$/.test(cfg.supabaseUrl)) throw Error();
  const state = await rpc('catalog', undefined);
  if (!state.visible) throw Error();
  renderCatalog(state);
  $('status').textContent = state.login_open ? '' : 'O acesso dos alunos ainda não foi liberado.';
  $('login').hidden = !state.login_open;
  action($('login'), async fields => {
    try {
      const session = await api('/auth/v1/token?grant_type=password', Object.fromEntries(fields));
      token = session.access_token;
      renderRecords(await rpc('portal'));
      $('login').hidden = true;
      $('portal').hidden = false;
      $('status').textContent = '';
    } catch (error) {
      lock();
      throw error;
    } finally { $('login').reset(); }
  });
  $('logout').onclick = async () => {
    try { await api('/auth/v1/logout'); } catch { /* Always clear local data. */ }
    lock();
    $('login').hidden = false;
  };
}
initialize().catch(() => {
  lock();
  $('status').textContent = 'Área do Aluno indisponível.';
});

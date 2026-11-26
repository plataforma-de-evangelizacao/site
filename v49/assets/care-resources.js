(() => {
  'use strict';
  const topics = {
  "corpo": {
    "title": "Corpo e descanso",
    "tip": "Escolha um momento tranquilo; observe se precisa de descanso, água ou alimento; reserve tempo para um movimento confortável, respeitando seus limites."
  },
  "escuta": {
    "title": "Escuta e acolhimento",
    "tip": "Pense em alguém com quem possa conversar. Escreva o que deseja compartilhar e peça um momento para falar sem interrupções."
  },
  "fe": {
    "title": "Fé e vida espiritual",
    "tip": "Leia Lucas 10:25–37. Reflita sobre quem precisa de cuidado e escolha um gesto de bondade."
  },
  "relacoes": {
    "title": "Relações e comunidade",
    "tip": "Pergunte como alguém está, escute sem interromper e ofereça ajuda que realmente possa realizar."
  },
  "alimentacao": {
    "title": "Alimentação e nutrição",
    "tip": "Faça uma lista de alimentos que já tem, planeje refeições variadas e regulares e mantenha água disponível."
  },
  "digital": {
    "title": "Bem-estar digital",
    "tip": "Escolha um momento para desligar notificações, organizar suas prioridades e fazer outra atividade de que goste."
  },
  "recomeco": {
    "title": "Recuperação e recomeço",
    "tip": "Identifique uma pessoa ou serviço que possa apoiar sua caminhada e prepare uma pergunta para iniciar a conversa."
  },
  "inclusao": {
    "title": "Inclusão e acessibilidade",
    "tip": "Pergunte quais condições facilitam a participação de cada pessoa, sem presumir suas necessidades."
  }
};
  const dialog = document.getElementById('care-preview');
  if (dialog) {
    const title = document.getElementById('care-preview-title');
    const tip = document.getElementById('care-preview-tip');
    const topicLinks = [...dialog.querySelectorAll('.care-preview-link')];
    const careLink = dialog.querySelector('.care-preview-actions a:first-child');
    const printLink = dialog.querySelector('.care-preview-actions a:last-child');
    let trigger;
    for (const link of document.querySelectorAll('[data-care-preview]')) {
      link.addEventListener('click', event => {
        if (event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return;
        const id = link.dataset.carePreview;
        const topic = topics[id];
        if (!topic) return;
        event.preventDefault();
        trigger = link;
        title.textContent = topic.title;
        tip.textContent = topic.tip;
        topicLinks.forEach(other => { other.hidden = !other.hash.endsWith('#' + id); });
        careLink.href = 'cuide-se.html#' + id;
        printLink.href = 'guia-cuidado.html?tema=' + id + '#' + id;
        printLink.textContent = 'Ficha para imprimir';
        dialog.showModal();
        document.body.classList.add('dialog-open');
      });
    }
    document.getElementById('care-preview-close').addEventListener('click', () => dialog.close());
    dialog.addEventListener('close', () => {
      document.body.classList.remove('dialog-open');
      trigger?.focus();
    });
  }
  function openTopic() {
    const card = document.getElementById(location.hash.slice(1));
    if (card?.matches('.care-card')) card.querySelector('details').open = true;
  }
  openTopic();
  addEventListener('hashchange', openTopic);
  const printButton = document.getElementById('care-print');
  if (printButton) {
    const id = new URLSearchParams(location.search).get('tema') || location.hash.slice(1);
    const topic = topics[id];
    if (topic && document.getElementById(id)?.matches('.guide-section')) {
      document.querySelectorAll('.guide-section').forEach(section => { section.hidden = section.id !== id; });
      document.querySelector('.care-guide h1').textContent = 'Ficha de cuidado · ' + topic.title;
      document.title = topic.title + ' · Ficha de cuidado · PGE';
      document.getElementById('care-all-link').hidden = false;
      document.querySelector('.care-guide-link a').href = 'cuide-se.html#' + id;
    }
    printButton.addEventListener('click', () => window.print());
  }
})();

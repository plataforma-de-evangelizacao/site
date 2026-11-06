(() => {
  const grid = document.getElementById('official-films');
  if (!grid) return;
  const films = [
    {
      title: 'O Príncipe do Egito (1998)',
      summary: 'Moisés descobre sua origem e enfrenta o faraó para libertar o povo hebreu.',
      page: 'https://www.universalpicturesathome.com/movies/the-prince-of-egypt'
    },
    {
      title: 'José: O Rei dos Sonhos (2000)',
      summary: 'Vendido pelos irmãos, José chega ao Egito, onde seu dom de interpretar sonhos muda sua história.',
      page: 'https://www.universalpicturesathome.com/movies/joseph-king-of-dreams'
    },
    {
      title: 'DAVID (2025)', type: 'Animação', provider: 'Angel',
      summary: 'O jovem pastor Davi enfrenta Golias em uma dramatização da narrativa bíblica.',
      page: 'https://www.angel.com/pt-BR/movies/david'
    },
    {
      title: 'The King of Kings (2025)', type: 'Animação', provider: 'Angel',
      summary: 'Um menino ouve do pai uma história sobre a vida de Jesus.',
      page: 'https://www.angel.com/pt-BR/movies/king-of-kings'
    },
    {
      title: 'His Only Son (2023)', type: 'Filme', provider: 'Angel',
      summary: 'Uma dramatização da jornada de Abraão e Isaque ao monte Moriá.',
      page: 'https://www.angel.com/pt-BR/movies/his-only-son'
    },
    {
      title: 'Testament', type: 'Série', provider: 'Angel',
      summary: 'Uma releitura dramática inspirada em Atos dos Apóstolos.',
      page: 'https://www.angel.com/pt-BR/shows/testament-series'
    }
  ];
  const filter = document.createElement('select');
  const label = document.createElement('label');
  label.textContent = 'Formato ';
  for (const type of ['Todos', 'Animação', 'Filme', 'Série']) {
    filter.append(new Option(type, type));
  }
  label.append(filter);
  grid.before(label);
  filter.addEventListener('change', () => {
    for (const card of grid.children) {
      card.hidden = filter.value !== 'Todos' && card.dataset.type !== filter.value;
    }
  });
  for (const film of films) {
    const card = document.createElement('article');
    card.className = 'card';
    const badge = document.createElement('p');
    badge.className = 'eyebrow';
    card.dataset.type = film.type || 'Animação';
    badge.textContent = card.dataset.type + ' · indicação editorial';
    const title = document.createElement('h2');
    title.textContent = film.title;
    const summary = document.createElement('p');
    summary.textContent = film.summary;
    const link = document.createElement('a');
    link.href = film.page;
    link.textContent = 'Consultar página oficial · ' + (film.provider || 'Universal Pictures');
    card.append(badge, title, summary, link);
    grid.append(card);
  }
})();

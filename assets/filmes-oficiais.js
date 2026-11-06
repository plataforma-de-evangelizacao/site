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
    }
  ];
  for (const film of films) {
    const card = document.createElement('article');
    card.className = 'card';
    const badge = document.createElement('p');
    badge.className = 'eyebrow';
    badge.textContent = 'Animação · indicação editorial';
    const title = document.createElement('h2');
    title.textContent = film.title;
    const summary = document.createElement('p');
    summary.textContent = film.summary;
    const link = document.createElement('a');
    link.href = film.page;
    link.textContent = 'Ver opções oficiais na Universal Pictures';
    card.append(badge, title, summary, link);
    grid.append(card);
  }
})();

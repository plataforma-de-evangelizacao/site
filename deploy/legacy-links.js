'use strict';
// Preserve historical bookmarks without moving the new Home off its canonical URL.
if (location.hash) {
  let id;
  try { id = decodeURIComponent(location.hash.slice(1)); } catch { id = ''; }
  if (id && !document.getElementById(id)) {
    const destination = new URL('legacy.html', location.href);
    destination.search = location.search;
    destination.hash = location.hash;
    location.replace(destination.href);
  }
}

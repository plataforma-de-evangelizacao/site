'use strict';
// Keep historical bookmarked sections, including the existing donation page.
// No destination is taken from a URL parameter.
const destination = new URL(location.hash ? 'legacy.html' : 'v49/', location.href);
destination.search = location.search;
destination.hash = location.hash;
location.replace(destination.href);

const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const script = fs.readFileSync(path.join(__dirname,'../../deploy/entrada-v49.js'),'utf8');
function route(input) {
  const location = new URL(input); let actual;
  location.replace = url => {actual = url;};
  vm.runInNewContext(script,{location,URL}); return actual;
}
const root='https://example.org/site/';
assert.equal(route(root),root+'v49/');
assert.equal(route(root+'index.html'),root+'v49/');
assert.equal(route(root+'?lang=en'),root+'v49/?lang=en');
assert.equal(route(root+'#doacoes'),root+'legacy.html#doacoes');
assert.equal(route(root+'?lang=es#estudos'),root+'legacy.html?lang=es#estudos');
console.log('5 verificações de navegação e preservação de links históricos aprovadas.');

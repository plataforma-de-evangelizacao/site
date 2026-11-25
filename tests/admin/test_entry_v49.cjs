const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm'),path=require('node:path');
const read=name=>fs.readFileSync(path.join(__dirname,'../../deploy',name),'utf8');
const root='https://example.org/site/';
function legacy(input,existing){
 const location=new URL(input);let actual;location.replace=url=>actual=url;
 vm.runInNewContext(read('legacy-links.js'),{location,URL,document:{getElementById:id=>existing.includes(id)?{}:null}});return actual;
}
function compat(input,target){
 const location=new URL(input);let actual;location.replace=url=>actual=url;
 vm.runInNewContext(read('canonical-redirect.js'),{location,URL,document:{getElementById:()=>({getAttribute:()=>target})}});return actual;
}
assert.equal(legacy(root,[]),undefined);
assert.equal(legacy(root+'#inicio',['inicio']),undefined);
assert.equal(legacy(root+'#doacoes',[]),root+'legacy.html#doacoes');
assert.equal(compat(root+'v49/projetos.html?lang=en#explorar','../projetos.html'),root+'projetos.html?lang=en#explorar');
assert.equal(compat(root+'v49/administracao.html','../admin/'),root+'admin/');
assert.equal(compat(root+'administracao.html','admin/'),root+'admin/');
assert.equal(compat(root+'administracao.html','https://example.net/'),undefined);
console.log('7 verificações de URLs canônicas e rotas administrativas aprovadas.');

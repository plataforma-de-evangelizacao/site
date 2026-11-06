const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const { execFileSync } = require('node:child_process');
const { PGlite } = require('@electric-sql/pglite');

const root = path.resolve(__dirname, '../../..');
const read = name => fs.readFileSync(path.join(root, name), 'utf8');

(async () => {
  const db = await PGlite.create();
  await db.exec(`create role anon;
    create role authenticated;
    create role service_role bypassrls;
    create schema auth;
    create table auth.users(id uuid primary key);
    create function auth.uid() returns uuid language sql stable as $$
      select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid
    $$;
    grant usage on schema public,auth to anon,authenticated,service_role;`);
  await db.exec(read('scripts/admin/schema.sql'));
  const bundle = execFileSync('python', ['-c',
    'from update_backend import load_release,migration_bundle; print(migration_bundle(load_release()[1][:-1]))'
  ], { env: { ...process.env, PYTHONPATH: path.join(root, 'scripts/admin') } }).toString();
  await db.exec(bundle);
  const filmId = 'abc123def45';
  await db.exec(`
    insert into pge_videos(id,record,sha,expires_at) values ('${filmId}','{}','v1',now());
    insert into pge_video_decisions(id,decision) values ('${filmId}','rejected');
    insert into pge_documents(path,content,sha) values
      ('dados/youtube.json','[{"titulo":"Playlist oficial"}]','music'),
      ('dados/catalogo-conteudos.json','{"itens":[{"tipo":"filme"},{"tipo":"artigo"}]}','old');
    insert into pge_live_documents(path,content,sha) values
      ('dados/catalogo-conteudos.json','{"itens":[{"tipo":"desenho"},{"tipo":"artigo"}]}','old');`);
  const migration = read('scripts/admin/platform-v44.sql');
  await db.exec(migration);
  await db.exec(migration);
  const { rows: [state] } = await db.query(`select
    (select count(*)::int from pge_videos) as videos,
    (select count(*)::int from pge_video_decisions) as decisions,
    (select content::jsonb from pge_documents where path='dados/youtube.json') as playlist,
    (select content::jsonb from pge_documents where path='dados/catalogo-conteudos.json') as documents,
    (select content::jsonb from pge_live_documents where path='dados/catalogo-conteudos.json') as live,
    pge_public_catalog() as catalog,
    has_function_privilege('authenticated','pge_review_videos(jsonb)','execute') as review,
    has_table_privilege('service_role','pge_videos','insert') as ingest`);
  assert.equal(state.videos, 0);
  assert.equal(state.decisions, 0);
  assert.deepEqual(state.playlist, [{ titulo: 'Playlist oficial' }]);
  assert.deepEqual(state.documents.itens, [{ tipo: 'artigo' }]);
  assert.deepEqual(state.live.itens, [{ tipo: 'artigo' }]);
  assert.deepEqual(state.catalog.itens, []);
  assert.equal(state.review, false);
  assert.equal(state.ingest, false);
  await db.close();
  console.log('v44: limpeza repetível, acervo vazio, moderação e ingestão desativadas, playlist e artigo preservados.');
})().catch(error => {
  console.error(error.message);
  process.exitCode = 1;
});

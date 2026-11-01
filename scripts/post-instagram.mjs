// Instagram API（Instagram ログイン版）で投稿する。GitHub Actions の「Post to Instagram」から手動で実行する。
// mode=check: トークン・投稿権限・画像 URL を確かめるだけ（投稿しない）
// mode=post : _ig/<投稿ID>.json の画像とキャプションで投稿し、結果をそのファイルに書き戻す
import { readFile, writeFile } from 'node:fs/promises';

const token = process.env.IG_TOKEN;
const mode = process.env.MODE || 'check';
const postId = (process.env.POST_ID || '').trim();
const API = 'https://graph.instagram.com';
const SITE = 'https://keitanino-beep.github.io/fctrident-tokyo/';

if (!token) throw new Error('IG_TOKEN が未登録です');

async function api(path, params = {}, method = 'GET') {
  const q = new URLSearchParams({ ...params, access_token: token });
  const res = method === 'GET'
    ? await fetch(`${API}/${path}?${q}`)
    : await fetch(`${API}/${path}`, { method: 'POST', body: q });
  const body = await res.json();
  if (!res.ok || body.error) {
    throw new Error(`Instagram API エラー（${path}）: ${JSON.stringify(body.error ?? body)}`);
  }
  return body;
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// トークンと投稿権限の確認（content_publishing_limit は投稿権限がないと読めない）
const me = await api('me', { fields: 'user_id,username' });
console.log(`アカウント: @${me.username}`);
try {
  const lim = await api(`${me.user_id}/content_publishing_limit`, { fields: 'quota_usage,config' });
  const d = lim.data?.[0] ?? {};
  console.log(`投稿権限: OK（直近24時間の投稿 ${d.quota_usage ?? 0} / ${d.config?.quota_total ?? '?'} 件）`);
} catch (e) {
  console.log('投稿権限: なし。Meta でトークンを作り直すとき「コンテンツの公開」を許可してください。');
  throw e;
}

if (!postId) {
  console.log('投稿ファイルの指定がないため、確認だけで終わります');
  process.exit(0);
}

const file = `_ig/${postId}.json`;
const spec = JSON.parse(await readFile(file, 'utf8'));
const urls = spec.images.map((p) => new URL(p, SITE).href);
if (urls.length < 1 || urls.length > 10) throw new Error('画像は1〜10枚にしてください');

// 画像が公開されていて JPEG かどうか
for (const u of urls) {
  const res = await fetch(u, { method: 'HEAD' });
  const type = res.headers.get('content-type') ?? '';
  if (!res.ok || !type.includes('jpeg')) throw new Error(`画像を読めません（${res.status} ${type}）: ${u}`);
}
console.log(`画像 ${urls.length} 枚: OK`);
console.log(`キャプション:\n${spec.caption}`);

if (mode !== 'post') {
  console.log('check モードのため、投稿はしていません');
  process.exit(0);
}
if (spec.posted) throw new Error(`この投稿は投稿済みです: ${spec.posted.permalink}`);

async function waitReady(id) {
  for (let i = 0; i < 30; i++) {
    const s = await api(id, { fields: 'status_code' });
    if (s.status_code === 'FINISHED') return;
    if (s.status_code === 'ERROR' || s.status_code === 'EXPIRED') throw new Error(`画像の準備に失敗しました: ${id} ${s.status_code}`);
    await sleep(3000);
  }
  throw new Error(`画像の準備が終わりません: ${id}`);
}

let container;
if (urls.length === 1) {
  container = (await api(`${me.user_id}/media`, { image_url: urls[0], caption: spec.caption }, 'POST')).id;
} else {
  const children = [];
  for (const u of urls) {
    const c = (await api(`${me.user_id}/media`, { image_url: u, is_carousel_item: 'true' }, 'POST')).id;
    await waitReady(c);
    children.push(c);
  }
  container = (await api(`${me.user_id}/media`, { media_type: 'CAROUSEL', children: children.join(','), caption: spec.caption }, 'POST')).id;
}
await waitReady(container);

const published = await api(`${me.user_id}/media_publish`, { creation_id: container }, 'POST');
const media = await api(published.id, { fields: 'permalink' });
spec.posted = { id: published.id, permalink: media.permalink, at: new Date().toISOString() };
await writeFile(file, JSON.stringify(spec, null, 2) + '\n');
console.log(`投稿しました: ${media.permalink}`);

// Instagram API（Instagram ログイン版）から最新投稿を取得し、instagram.json と画像を書き出す。
// 画像の URL は時間がたつと切れるので、リポジトリに保存してサイトから参照する。
import { mkdir, readdir, unlink, writeFile } from 'node:fs/promises';

const token = process.env.IG_TOKEN;
if (!token) throw new Error('IG_TOKEN が設定されていません（GitHub の Secrets を確認してください）');

const LIMIT = 6;
const fields = 'id,caption,media_type,media_url,thumbnail_url,permalink,timestamp';
const url = `https://graph.instagram.com/me/media?fields=${fields}&limit=${LIMIT}&access_token=${encodeURIComponent(token)}`;

const res = await fetch(url);
const body = await res.json();
if (!res.ok) {
  throw new Error(`Instagram API エラー: ${JSON.stringify(body.error ?? body)}`);
}

await mkdir('instagram', { recursive: true });
const posts = [];
for (const m of body.data ?? []) {
  const src = m.media_type === 'VIDEO' ? m.thumbnail_url : m.media_url;
  if (!src) continue;
  const img = await fetch(src);
  if (!img.ok) continue;
  const file = `instagram/${m.id}.jpg`;
  await writeFile(file, Buffer.from(await img.arrayBuffer()));
  posts.push({
    id: m.id,
    image: file,
    permalink: m.permalink,
    caption: (m.caption ?? '').slice(0, 140),
    type: m.media_type,
    timestamp: m.timestamp,
  });
}

// 表示しなくなった古い画像を消す
const keep = new Set(posts.map((p) => `${p.id}.jpg`));
for (const f of await readdir('instagram')) {
  if (f.endsWith('.jpg') && !keep.has(f)) await unlink(`instagram/${f}`);
}

await writeFile('instagram.json', JSON.stringify({ updated: new Date().toISOString(), posts }, null, 2) + '\n');
console.log(`${posts.length} 件の投稿を保存しました`);

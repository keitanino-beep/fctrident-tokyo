# _parts/*.html に共通のヘッダー・帯・フッターを付けて、各ページの HTML を作る
# index は Artifact 用に doctype なし（../fctrident-top.html）、ほかは完全な HTML で出力する
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
if (-not $root) { $root = (Get-Location).Path }
$utf8 = New-Object System.Text.UTF8Encoding($false)

$nav = @(
  @{ file = 'news.html';    en = 'News';    jp = 'お知らせ' },
  @{ file = 'match.html';   en = 'Match';   jp = '試合情報' },
  @{ file = 'members.html'; en = 'Members'; jp = 'メンバー' },
  @{ file = 'gallery.html'; en = 'Gallery'; jp = 'ギャラリー' },
  @{ file = 'club.html';    en = 'Club';    jp = 'クラブ概要' },
  @{ file = 'contact.html'; en = 'Contact'; jp = 'お問い合わせ' },
  @{ file = 'sponsor.html'; en = 'Partner'; jp = 'スポンサー募集' }
)
$pages = @('index.html') + ($nav | ForEach-Object { $_.file })

$emblem = '<img class="emblem" src="emblem.webp" alt="">'

function Desktop-Nav($current) {
  $out = @()
  foreach ($p in $nav) {
    $cur = ''; if ($p.file -eq $current) { $cur = ' aria-current="page"' }
    $cls = ''; if ($p.file -eq 'sponsor.html') { $cls = ' class="nav-cta"' }
    $out += "<a$cls href=`"$($p.file)`"$cur>$($p.en)<small>$($p.jp)</small></a>"
  }
  return ($out -join "`n      ")
}
function Mobile-Nav($current) {
  $cur = ''; if ($current -eq 'index.html') { $cur = ' aria-current="page"' }
  $out = @("<a href=`"index.html`"$cur>トップ</a>")
  foreach ($p in $nav) {
    $cur = ''; if ($p.file -eq $current) { $cur = ' aria-current="page"' }
    $out += "<a href=`"$($p.file)`"$cur>$($p.jp)</a>"
  }
  return ($out -join "`n        ")
}

$fonts = @'
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Anton&family=Barlow+Condensed:wght@700;800&family=Noto+Sans+JP:wght@400;500;700;900&display=swap">
<link rel="stylesheet" href="style.css">
'@

$join = @'
<section class="join">
  <div class="wrap">
    <div>
      <p class="kicker">Join us</p>
      <h2>一緒にプレーする仲間を募集中</h2>
      <p>練習参加・対戦のご依頼・スポンサーのご相談はこちらから。</p>
    </div>
    <a class="btn btn-yellow" href="contact.html">お問い合わせ <span class="arrow">→</span></a>
  </div>
</section>
'@

foreach ($file in $pages) {
  $part = [IO.File]::ReadAllText((Join-Path $root "_parts\$file"), $utf8)
  $m = [regex]::Match($part, '<!-- title: (.+?) -->')
  $title = $m.Groups[1].Value
  $body = $part.Substring($m.Index + $m.Length).Trim()
  $band = $join; if ($file -eq 'contact.html') { $band = '' }

  $inner = @"
<div class="proto">試作版です。点線の「仮」がついた内容はダミーで、実際の情報に差し替えます。</div>

<header class="site-head">
  <div class="wrap">
    <a class="brand" href="index.html" aria-label="FC TRIDENT TOKYO トップ">
      $emblem
      <span class="brand-name">FC TRIDENT<small>TOKYO SOCIETY</small></span>
    </a>
    <nav class="nav" aria-label="メインメニュー">
      $(Desktop-Nav $file)
    </nav>
    <details class="menu">
      <summary>MENU</summary>
      <div class="menu-panel">
        $(Mobile-Nav $file)
      </div>
    </details>
  </div>
</header>

$body

$band
<footer class="site-foot">
  <div class="wrap">
    <div class="foot-big" aria-hidden="true">FC TRIDENT TOKYO</div>
    <div class="foot-grid">
      <div>
        <a class="brand" href="index.html">$emblem<span class="brand-name">FC TRIDENT<small>TOKYO SOCIETY</small></span></a>
        <p>活動場所：東京都内（詳細はここに入ります）<span class="tag-temp">仮</span></p>
      </div>
      <nav class="foot-links" aria-label="フッターメニュー">
        <a href="index.html">トップ</a><a href="news.html">お知らせ</a><a href="match.html">試合情報</a>
        <a href="members.html">メンバー</a><a href="gallery.html">ギャラリー</a><a href="sponsor.html">スポンサー募集</a>
        <a href="club.html">クラブ概要</a><a href="contact.html">お問い合わせ</a>
        <a href="https://www.instagram.com/fctridenttokyo_society/" target="_blank" rel="noopener">Instagram</a>
      </nav>
    </div>
    <p class="copy"><span>© 2026 FC TRIDENT TOKYO</span><span>TOKYO / JAPAN</span></p>
  </div>
</footer>
"@

  $pageTitle = "$title | FC TRIDENT TOKYO"
  if ($file -eq 'index.html') { $pageTitle = 'FC TRIDENT TOKYO' }
  $html = @"
<!doctype html>
<html lang="ja">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>$pageTitle</title>
<meta name="description" content="FC TRIDENT TOKYO 公式サイト。FOOTBALL 7 SOCIETY LEAGUE 関東リーグ所属のソサイチチームです。">
<link rel="icon" href="emblem.webp">
$fonts
</head>
<body>
$inner
</body>
</html>
"@
  [IO.File]::WriteAllText((Join-Path $root $file), $html, $utf8)
  if ($file -eq 'index.html') {
    # Claude の試作ページ（Artifact）用。doctype などは公開時に付く
    New-Item -ItemType Directory -Force (Join-Path $root '_preview') | Out-Null
    [IO.File]::WriteAllText((Join-Path $root '_preview\top.html'), "<title>FC TRIDENT TOKYO</title>`n$fonts`n$inner", $utf8)
  }
  Write-Output "built $file"
}

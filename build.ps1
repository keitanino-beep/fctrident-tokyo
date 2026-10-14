# _parts/*.html に共通のヘッダー・帯・フッターを付けて、各ページの HTML を作る
# ギャラリーは _data/matches.json と photos/<日付>_<対戦相手>/ から自動で作る
#   - 写真は縮小して gallery/<日付>/ と gallery/<日付>/thumb/ に書き出す
#   - 写真がある試合だけアルバムページ（gallery-<日付>.html）を作る
#   - photos/<…>/memo.txt（任意）: 「ひと言：」「動画：」「得点：」の行を読む
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
if (-not $root) { $root = (Get-Location).Path }
$utf8 = New-Object System.Text.UTF8Encoding($false)
Add-Type -AssemblyName System.Drawing

$nav = @(
  @{ file = 'news.html';    en = 'News';    jp = 'お知らせ' },
  @{ file = 'match.html';   en = 'Match';   jp = '試合情報' },
  @{ file = 'members.html'; en = 'Members'; jp = 'メンバー' },
  @{ file = 'gallery.html'; en = 'Gallery'; jp = 'ギャラリー' },
  @{ file = 'recruit.html'; en = 'Recruit'; jp = '選手募集' },
  @{ file = 'club.html';    en = 'Club';    jp = 'クラブ概要' },
  @{ file = 'contact.html'; en = 'Contact'; jp = 'お問い合わせ' },
  @{ file = 'sponsor.html'; en = 'Partner'; jp = 'スポンサー募集' }
)

$emblem = '<img class="emblem" src="emblem.webp" alt="">'

function Esc($s) { return [System.Net.WebUtility]::HtmlEncode([string]$s) }

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
      <p>全ポジションの選手とマネージャーを募集しています。練習参加は何回でもOKです。</p>
    </div>
    <a class="btn btn-yellow" href="recruit.html">選手募集を見る <span class="arrow">→</span></a>
  </div>
</section>
'@

# ---------- スポンサー（_data/sponsors.json）----------
$sponsors = @(([IO.File]::ReadAllText((Join-Path $root '_data\sponsors.json'), $utf8) | ConvertFrom-Json).sponsors)
$sponsorTiles = ($sponsors | ForEach-Object {
  $cls = "partner-tile plate-$($_.plate)"; if ($_.tier -eq 'main') { $cls += ' is-main' }
  $label = if ($_.tier -eq 'main') { '<em>MAIN PARTNER</em>' } else { '' }
  "<a class=`"$cls`" href=`"$($_.url)`" target=`"_blank`" rel=`"noopener sponsored`">$label<img src=`"$($_.logo)`" alt=`"$(Esc $_.name)`"><small>$(Esc $_.name)</small></a>"
}) -join "`n        "
$partnerBand = @"
<section class="partner-band" aria-label="オフィシャルパートナー">
  <div class="wrap">
    <p class="partner-band-label">Official Partners</p>
    <div class="partner-band-logos">
      $(($sponsors | ForEach-Object { "<a class=`"partner-chip plate-$($_.plate)$(if ($_.tier -eq 'main') { ' is-main' })`" href=`"$($_.url)`" target=`"_blank`" rel=`"noopener sponsored`"><img src=`"$($_.logo)`" alt=`"$(Esc $_.name)`"></a>" }) -join "`n      ")
    </div>
  </div>
</section>
"@

# ---------- 検索・SNS 向けの情報 ----------
$sitePath = '/fctrident-tokyo/'
$siteUrl = 'https://keitanino-beep.github.io' + $sitePath
$defaultDesc = 'FC TRIDENT TOKYO（FCトライデント東京）の公式サイト。FOOTBALL 7 SOCIETY LEAGUE 関東リーグ 4部C所属、東京を拠点に活動するソサイチ（7人制サッカー）チームです。'
$descs = @{
  'index.html'   = $defaultDesc + '試合情報、メンバー、試合アルバム、スポンサー募集を掲載しています。'
  'news.html'    = 'FC TRIDENT TOKYOのお知らせ。試合結果や告知、クラブからのニュースをお届けします。'
  'match.html'   = 'FC TRIDENT TOKYOの2026シーズンの日程・結果と、FOOTBALL 7 SOCIETY LEAGUE 関東リーグ 4部Cの順位表です。'
  'members.html' = 'FC TRIDENT TOKYOの選手・スタッフ紹介とユニフォームです。'
  'gallery.html' = 'FC TRIDENT TOKYOの試合ごとの写真アルバムと試合動画です。'
  'club.html'    = 'FC TRIDENT TOKYOの理念、チーム紹介、基本情報、沿革です。'
  'contact.html' = 'FC TRIDENT TOKYOへのお問い合わせ。練習参加、新部門の立ち上げ、対戦のご依頼、スポンサーのご相談を受け付けています。'
  'sponsor.html' = 'FC TRIDENT TOKYOのスポンサー募集。ユニフォームへのロゴ掲載、HP・Instagramでのご紹介など、協賛の形はご相談に応じます。'
  'recruit.html' = 'FC TRIDENT TOKYOの選手・マネージャー募集。全ポジション募集中。練習参加は何回でもOK、InstagramのDMで応募できます。'
  'privacy.html' = 'FC TRIDENT TOKYOのプライバシーポリシーです。'
  '404.html'     = 'お探しのページが見つかりませんでした。'
}
$jsonLd = @"
<script type="application/ld+json">
{"@context":"https://schema.org","@type":"SportsTeam","name":"FC TRIDENT TOKYO","alternateName":"FCトライデント東京","sport":"Football 7 (ソサイチ)","url":"$siteUrl","logo":"${siteUrl}icon-512.png","foundingDate":"2025","location":{"@type":"Place","name":"東京都"},"memberOf":{"@type":"SportsOrganization","name":"FOOTBALL 7 SOCIETY LEAGUE 関東リーグ"},"sameAs":["https://www.instagram.com/fctridenttokyo_society/","https://football7society.jp/kanto/team/fc-trident-tokyo/"]}
</script>
"@

function Write-Page($file, $title, $body, $current, $desc) {
  $band = $join; if ($file -eq 'contact.html') { $band = '' }
  $band = $band + "`n" + $partnerBand
  $body = $body.Replace('<!--SPONSOR_TILES-->', $sponsorTiles)
  $inner = @"
<header class="site-head">
  <div class="wrap">
    <a class="brand" href="index.html" aria-label="FC TRIDENT TOKYO トップ">
      $emblem
      <span class="brand-name">FC TRIDENT<small>TOKYO SOCIETY</small></span>
    </a>
    <nav class="nav" aria-label="メインメニュー">
      $(Desktop-Nav $current)
    </nav>
    <details class="menu">
      <summary>MENU</summary>
      <div class="menu-panel">
        $(Mobile-Nav $current)
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
        <p>活動エリア：東京都（品川区・目黒区・港区周辺）／毎週土日</p>
      </div>
      <nav class="foot-links" aria-label="フッターメニュー">
        <a href="index.html">トップ</a><a href="news.html">お知らせ</a><a href="match.html">試合情報</a>
        <a href="members.html">メンバー</a><a href="gallery.html">ギャラリー</a><a href="sponsor.html">スポンサー募集</a>
        <a href="recruit.html">選手募集</a><a href="club.html">クラブ概要</a><a href="contact.html">お問い合わせ</a>
        <a href="https://www.instagram.com/fctridenttokyo_society/" target="_blank" rel="noopener">Instagram</a>
        <a href="privacy.html">プライバシーポリシー</a>
      </nav>
    </div>
    <p class="copy"><span>© 2026 FC TRIDENT TOKYO</span><span>TOKYO / JAPAN</span></p>
  </div>
</footer>
"@

  $pageTitle = "$title | FC TRIDENT TOKYO"
  if ($file -eq 'index.html') { $pageTitle = 'FC TRIDENT TOKYO（FCトライデント東京）公式サイト' }
  if (-not $desc) { $desc = $defaultDesc }
  $pageUrl = if ($file -eq 'index.html') { $siteUrl } else { $siteUrl + $file }
  # 404 はどの階層の URL でも表示されるので、リンクの基準をサイトの先頭に固定する
  $extraHead = ''
  if ($file -eq '404.html') { $extraHead = "<base href=`"$sitePath`">`n<meta name=`"robots`" content=`"noindex`">" }
  if ($file -eq 'index.html') { $extraHead = $jsonLd }
  $html = @"
<!doctype html>
<html lang="ja">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
$extraHead
<title>$pageTitle</title>
<meta name="description" content="$(Esc $desc)">
<meta name="google-site-verification" content="3fvlOXseDaexdJXk9XOEBY44Orwv73djX0tCYXAo0rs">
<link rel="canonical" href="$pageUrl">
<meta property="og:type" content="website">
<meta property="og:site_name" content="FC TRIDENT TOKYO">
<meta property="og:title" content="$(Esc $pageTitle)">
<meta property="og:description" content="$(Esc $desc)">
<meta property="og:url" content="$pageUrl">
<meta property="og:image" content="${siteUrl}og-image.jpg">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta property="og:locale" content="ja_JP">
<meta name="twitter:card" content="summary_large_image">
<meta name="theme-color" content="#0d0b0c">
<link rel="icon" href="emblem.webp">
<link rel="apple-touch-icon" href="icon-180.png">
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

# ---------- 写真の縮小 ----------
$jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }

function Save-Resized($src, $dst, $maxSide) {
  if ((Test-Path $dst) -and ((Get-Item $dst).LastWriteTime -ge (Get-Item $src).LastWriteTime)) { return }
  $img = [System.Drawing.Image]::FromFile($src)
  try {
    # スマホ写真の向き（EXIF）を反映する
    if ($img.PropertyIdList -contains 274) {
      switch ([int]$img.GetPropertyItem(274).Value[0]) {
        3 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipNone) }
        6 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipNone) }
        8 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipNone) }
      }
    }
    $scale = [Math]::Min(1.0, $maxSide / [Math]::Max($img.Width, $img.Height))
    $w = [int][Math]::Round($img.Width * $scale); $h = [int][Math]::Round($img.Height * $scale)
    $bmp = New-Object System.Drawing.Bitmap($w, $h)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear([System.Drawing.Color]::White)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.DrawImage($img, 0, 0, $w, $h)
    $params = New-Object System.Drawing.Imaging.EncoderParameters(1)
    $params.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]82)
    $bmp.Save($dst, $jpegCodec, $params)
    $g.Dispose(); $bmp.Dispose()
  } finally { $img.Dispose() }
}

# ---------- 試合データ ----------
$data = [IO.File]::ReadAllText((Join-Path $root '_data\matches.json'), $utf8) | ConvertFrom-Json
$days = @('日', '月', '火', '水', '木', '金', '土')
$leagueLine = "$($data.league) $($data.division)"

$albums = @()
foreach ($m in ($data.matches | Where-Object { $null -ne $_.us } | Sort-Object date -Descending)) {
  $d = [DateTime]::ParseExact($m.date, 'yyyy-MM-dd', $null)
  $dateLabel = '{0}（{1}）' -f $d.ToString('yyyy.MM.dd'), $days[[int]$d.DayOfWeek]
  $result = if ($m.us -gt $m.them) { 'WIN' } elseif ($m.us -lt $m.them) { 'LOSE' } else { 'DRAW' }
  $resCls = @{ WIN = 'w'; LOSE = 'l'; DRAW = 'd' }[$result]

  $src = Join-Path $root ("photos\{0}_{1}" -f $m.date, $m.opponent)
  $photos = @()
  $memo = @{}
  if (Test-Path $src) {
    $files = Get-ChildItem $src -File | Where-Object { $_.Extension -match '^\.(jpe?g|png)$' } | Sort-Object Name
    # 表紙：photos に cover.jpg があればそれ、なければ matches.json の cover（集合写真）
    $cover = $files | Where-Object { $_.BaseName -ieq 'cover' } | Select-Object -First 1
    if (-not $cover -and $m.cover) { $cover = $files | Where-Object { $_.BaseName -ieq $m.cover } | Select-Object -First 1 }
    if ($cover) { $files = @($cover) + @($files | Where-Object { $_.FullName -ne $cover.FullName }) }
    $outDir = Join-Path $root "gallery\$($m.date)"
    if ($files) { New-Item -ItemType Directory -Force (Join-Path $outDir 'thumb') | Out-Null }
    # 書き出す名前は元のファイル名に合わせる（消したり並べ替えたりしても写真が入れ替わらないように）
    $keep = @{}
    foreach ($f in $files) {
      $name = (($f.BaseName -replace '[^\w\-]', '_').ToLower()) + '.jpg'
      $keep[$name] = $true
      Save-Resized $f.FullName (Join-Path $outDir $name) 1800
      Save-Resized $f.FullName (Join-Path $outDir "thumb\$name") 640
      $photos += "gallery/$($m.date)/$name"
    }
    # photos から消された写真の書き出しを消す
    if (Test-Path $outDir) {
      Get-ChildItem $outDir -Recurse -File -Filter '*.jpg' | Where-Object { -not $keep.ContainsKey($_.Name) } | Remove-Item
      if (-not $files) { Remove-Item $outDir -Recurse -Force }
    }
    $memoFile = Join-Path $src 'memo.txt'
    if (Test-Path $memoFile) {
      foreach ($line in [IO.File]::ReadAllLines($memoFile, $utf8)) {
        $mm = [regex]::Match($line, '^\s*(ひと言|動画|得点)\s*[：:]\s*(.+)$')
        if ($mm.Success) { $memo[$mm.Groups[1].Value] = $mm.Groups[2].Value.Trim() }
      }
    }
  }
  $albums += [pscustomobject]@{
    m = $m; dateLabel = $dateLabel; result = $result; resCls = $resCls; photos = $photos; memo = $memo
    page = "gallery-$($m.date).html"
  }
}

# ---------- アルバムページ ----------
# 写真か動画のどちらかがある試合はアルバムページを作る
foreach ($a in $albums) { if (-not $a.memo['動画'] -and $a.m.video) { $a.memo['動画'] = $a.m.video } }
$withPhotos = @($albums | Where-Object { $_.photos.Count -gt 0 -or $_.memo['動画'] })
for ($k = 0; $k -lt $withPhotos.Count; $k++) {
  $a = $withPhotos[$k]; $m = $a.m
  $scorers = if ($a.memo['得点']) { $a.memo['得点'] } else { $m.scorers }
  $info = @()
  $info += "<dt>日時</dt><dd>$($a.dateLabel)$(if ($m.kickoff) { ' ' + $m.kickoff + ' KO' })</dd>"
  $info += "<dt>会場</dt><dd>$(Esc $m.venue)</dd>"
  if ($m.half) { $info += "<dt>前半 / 後半</dt><dd>$(Esc $m.half)</dd>" }
  if ($scorers) { $info += "<dt>得点</dt><dd>$(Esc $scorers)</dd>" }
  $note = if ($a.memo['ひと言']) { "<p class=`"album-note`">$(Esc $a.memo['ひと言'])</p>" } else { '' }
  # 動画（Veo は埋め込み不可のため、表紙＝集合写真の上に再生マークを重ねたリンクにする）
  $video = ''
  if ($a.memo['動画']) {
    $bg = if ($a.photos.Count -gt 0) { "<img src=`"$($a.photos[0])`" alt=`"`">" } else { "<span class=`"video-vs`"><img src=`"emblem.webp`" alt=`"`"><b>VS</b><img src=`"$($m.logo)`" alt=`"`"></span>" }
    $video = "<a class=`"video-card`" href=`"$(Esc $a.memo['動画'])`" target=`"_blank`" rel=`"noopener`">$bg<span class=`"video-play`" aria-hidden=`"true`"></span><span class=`"video-text`"><small>FULL MATCH ・ VEO</small>試合動画を見る<em>Veo のページが別のタブで開きます</em></span></a>"
  }
  $grid = ($a.photos | ForEach-Object -Begin { $n = 0 } -Process {
    $n++
    $thumb = $_ -replace '/([^/]+)$', '/thumb/$1'
    "<button type=`"button`" class=`"photo`" data-full=`"$_`" aria-label=`"写真 $n を拡大`"><img src=`"$thumb`" alt=`"第$($m.round)節 vs $(Esc $m.opponent) の写真 $n`" loading=`"lazy`"></button>"
  }) -join "`n        "
  $prev = if ($k -lt $withPhotos.Count - 1) { $p = $withPhotos[$k + 1]; "<a class=`"album-nav-link`" href=`"$($p.page)`">← 第$($p.m.round)節 vs $(Esc $p.m.opponent)</a>" } else { '<span></span>' }
  $next = if ($k -gt 0) { $p = $withPhotos[$k - 1]; "<a class=`"album-nav-link`" href=`"$($p.page)`">第$($p.m.round)節 vs $(Esc $p.m.opponent) →</a>" } else { '<span></span>' }

  $body = @"
<main>
  <section class="page-head album-head">
    <div class="wrap">
      <p class="crumb"><a href="index.html">Top</a> / <a href="gallery.html">Gallery</a> / Round $($m.round)</p>
      <p class="album-league">$(Esc $leagueLine)</p>
      <h1 class="album-title">第$($m.round)節<span>vs $(Esc $m.opponent)</span></h1>
      <div class="album-score">
        <span class="crest us"><img src="emblem.webp" alt=""></span>
        <span class="score">$($m.us)<span class="dash">-</span>$($m.them)</span>
        <span class="crest them"><img src="$($m.logo)" alt=""></span>
        <span class="res $($a.resCls)">$($a.result)</span>
      </div>
    </div>
  </section>

  <section class="sec">
    <div class="wrap album-body">
      <dl class="facts album-facts">
        $($info -join "`n        ")
      </dl>
      $note
      <div class="album-actions"><a class="more" href="https://football7society.jp/kanto/event/$($m.event)/" target="_blank" rel="noopener">League record <span class="jp">リーグ公式の試合記録</span></a></div>
      $video
      $(if ($grid) { "<div class=`"photo-grid`">`n        $grid`n      </div>" } else { '<p class="album-empty">この試合の写真は準備中です。</p>' })
      <nav class="album-nav" aria-label="ほかのアルバム">$prev<a class="album-nav-link" href="gallery.html">アルバム一覧</a>$next</nav>
    </div>
  </section>
</main>
<div class="lightbox" id="lightbox" hidden>
  <button type="button" class="lb-close" aria-label="閉じる">×</button>
  <button type="button" class="lb-prev" aria-label="前の写真">‹</button>
  <img alt="" id="lb-img">
  <button type="button" class="lb-next" aria-label="次の写真">›</button>
  <p class="lb-count" id="lb-count"></p>
</div>
<script>
  (function () {
    var items = Array.prototype.slice.call(document.querySelectorAll('.photo'));
    var box = document.getElementById('lightbox');
    var img = document.getElementById('lb-img');
    var count = document.getElementById('lb-count');
    var cur = 0, opener = null;
    function show(i) {
      cur = (i + items.length) % items.length;
      img.src = items[cur].getAttribute('data-full');
      img.alt = items[cur].querySelector('img').alt;
      count.textContent = (cur + 1) + ' / ' + items.length;
    }
    function open(i) { opener = items[i]; show(i); box.hidden = false; document.body.style.overflow = 'hidden'; box.querySelector('.lb-close').focus(); }
    function close() { box.hidden = true; document.body.style.overflow = ''; if (opener) opener.focus(); }
    items.forEach(function (b, i) { b.addEventListener('click', function () { open(i); }); });
    box.querySelector('.lb-close').addEventListener('click', close);
    box.querySelector('.lb-prev').addEventListener('click', function () { show(cur - 1); });
    box.querySelector('.lb-next').addEventListener('click', function () { show(cur + 1); });
    box.addEventListener('click', function (e) { if (e.target === box) close(); });
    document.addEventListener('keydown', function (e) {
      if (box.hidden) return;
      if (e.key === 'Escape') close();
      if (e.key === 'ArrowLeft') show(cur - 1);
      if (e.key === 'ArrowRight') show(cur + 1);
    });
    var x0 = null;
    box.addEventListener('touchstart', function (e) { x0 = e.touches[0].clientX; }, { passive: true });
    box.addEventListener('touchend', function (e) {
      if (x0 === null) return;
      var dx = e.changedTouches[0].clientX - x0; x0 = null;
      if (Math.abs(dx) > 40) show(cur + (dx < 0 ? 1 : -1));
    });
  })();
</script>
"@
  Write-Page $a.page "第$($m.round)節 vs $($m.opponent)" $body 'gallery.html' "$leagueLine 第$($m.round)節、FC TRIDENT TOKYO vs $($m.opponent)（$($a.dateLabel)、$($m.us)-$($m.them)）の試合写真と試合動画です。"
}

# ---------- ギャラリー一覧 ----------
$cards = foreach ($a in $albums) {
  $m = $a.m
  $head = @"
<p class="album-league">$(Esc $leagueLine)</p>
          <h3 class="album-card-title">第$($m.round)節<span>vs $(Esc $m.opponent)</span></h3>
          <p class="album-meta"><span class="res $($a.resCls)">$($a.result)</span><span class="album-score-sm">$($m.us) - $($m.them)</span><span>$($a.dateLabel)</span></p>
"@
  $vbadge = if ($a.memo['動画']) { '<span class="album-video">▶ VIDEO</span>' } else { '' }
  if ($a.photos.Count -gt 0) {
    $thumb = $a.photos[0] -replace '/([^/]+)$', '/thumb/$1'
    @"
<a class="album" href="$($a.page)">
        <div class="album-cover"><img src="$thumb" alt="" loading="lazy"><span class="album-count">$($a.photos.Count) PHOTOS</span>$vbadge</div>
        <div class="album-info">
          $head
        </div>
      </a>
"@
  } elseif ($a.memo['動画']) {
    @"
<a class="album" href="$($a.page)">
        <div class="album-cover album-vs"><img src="emblem.webp" alt=""><span>VS</span><img src="$($m.logo)" alt=""><span class="album-count">PHOTO COMING SOON</span>$vbadge</div>
        <div class="album-info">
          $head
        </div>
      </a>
"@
  } else {
    @"
<div class="album is-empty">
        <div class="album-cover album-vs"><img src="emblem.webp" alt=""><span>VS</span><img src="$($m.logo)" alt=""><span class="album-count">PHOTO COMING SOON</span></div>
        <div class="album-info">
          $head
        </div>
      </div>
"@
  }
}

$galleryBody = @"
<main>
  <section class="page-head">
    <div class="wrap">
      <p class="crumb"><a href="index.html">Top</a> / Gallery</p>
      <p class="eyebrow">Gallery</p>
      <h1>ギャラリー</h1>
      <p class="lead">$(Esc $leagueLine)の試合ごとの写真アルバムです。</p>
    </div>
  </section>

  <section class="sec">
    <div class="wrap">
      <div class="sec-head"><div><p class="eyebrow">Albums</p><h2>試合アルバム</h2></div></div>
      <div class="album-grid">
      $($cards -join "`n      ")
      </div>
      <div class="insta">
        <p><small>INSTAGRAM</small>最新の様子はInstagramで発信しています</p>
        <a class="btn btn-red" href="https://www.instagram.com/fctridenttokyo_society/" target="_blank" rel="noopener">@fctridenttokyo_society <span class="arrow">→</span></a>
      </div>
    </div>
  </section>
</main>
"@

# ---------- 各ページを書き出す ----------
$pages = @('index.html') + ($nav | ForEach-Object { $_.file }) + @('privacy.html', '404.html')
foreach ($file in $pages) {
  if ($file -eq 'gallery.html') {
    Write-Page $file 'ギャラリー' $galleryBody $file $descs[$file]
    continue
  }
  $part = [IO.File]::ReadAllText((Join-Path $root "_parts\$file"), $utf8)
  $m = [regex]::Match($part, '<!-- title: (.+?) -->')
  Write-Page $file $m.Groups[1].Value $part.Substring($m.Index + $m.Length).Trim() $file $descs[$file]
}

# ---------- サイトマップと robots.txt ----------
$today = (Get-Date).ToString('yyyy-MM-dd')
$urls = @($pages | Where-Object { $_ -ne '404.html' }) + @($withPhotos | ForEach-Object { $_.page })
$sitemap = "<?xml version=`"1.0`" encoding=`"UTF-8`"?>`n<urlset xmlns=`"http://www.sitemaps.org/schemas/sitemap/0.9`">`n" +
  (($urls | ForEach-Object { $u = if ($_ -eq 'index.html') { $siteUrl } else { $siteUrl + $_ }; "  <url><loc>$u</loc><lastmod>$today</lastmod></url>" }) -join "`n") + "`n</urlset>`n"
[IO.File]::WriteAllText((Join-Path $root 'sitemap.xml'), $sitemap, $utf8)
[IO.File]::WriteAllText((Join-Path $root 'robots.txt'), "User-agent: *`nAllow: /`n`nSitemap: ${siteUrl}sitemap.xml`n", $utf8)
Write-Output "built sitemap.xml ($($urls.Count) urls)"

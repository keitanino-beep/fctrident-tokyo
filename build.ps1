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

# 2027年版の試作：TEAM TRIDENT（3部門）。お問い合わせはパソコンのメニューから外し、フッターとスマホのメニューに残す
$nav = @(
  @{ file = 'news.html';    en = 'News';    jp = 'お知らせ' },
  @{ file = 'teams.html';   en = 'Teams';   jp = '3部門' },
  @{ file = 'match.html';   en = 'Match';   jp = '試合情報' },
  @{ file = 'schedule.html'; en = 'Schedule'; jp = '活動日程' },
  @{ file = 'members.html'; en = 'Members'; jp = 'メンバー' },
  @{ file = 'gallery.html'; en = 'Gallery'; jp = 'ギャラリー' },
  @{ file = 'recruit.html'; en = 'Recruit'; jp = '選手募集' },
  @{ file = 'club.html';    en = 'Club';    jp = 'クラブ概要' },
  @{ file = 'contact.html'; en = 'Contact'; jp = 'お問い合わせ'; mobileOnly = $true },
  @{ file = 'sponsor.html'; en = 'Partner'; jp = 'スポンサー募集' }
)

$emblem = '<img class="emblem" src="emblem.webp" alt="">'

function Esc($s) { return [System.Net.WebUtility]::HtmlEncode([string]$s) }

# 部門ごとのメニュー。ソサイチは今のページをそのまま使い、サッカー・学生は準備中のページを作る
$sections = @(
  @{ key = 'match';    en = 'Match';    jp = '試合情報' },
  @{ key = 'schedule'; en = 'Schedule'; jp = '活動日程' },
  @{ key = 'members';  en = 'Members';  jp = 'メンバー' },
  @{ key = 'gallery';  en = 'Gallery';  jp = 'ギャラリー' }
)
$divisions = @(
  @{ key = 'society';    en = 'Society';    jp = 'ソサイチ部門';     name = 'FC Trident Tokyo';            prefix = '' },
  @{ key = 'football';   en = 'Football';   jp = 'サッカー部門';     name = 'FC Trident Tokyo Football';   prefix = 'football-' },
  @{ key = 'university'; en = 'University'; jp = '学生ソサイチ部門'; name = 'FC Trident Tokyo University'; prefix = 'university-' }
)
function Division-Of($file) {
  if ($file -match '^(football|university)-gallery-') { return ($divisions | Where-Object { $file.StartsWith($_.prefix) -and $_.prefix } | Select-Object -First 1) }
  if ($file -like 'gallery-*') { return $divisions[0] }
  foreach ($d in $divisions) { foreach ($s in $sections) { if ("$($d.prefix)$($s.key).html" -eq $file) { return $d } } }
  return $null
}
$menuTop = @(
  @{ file = 'news.html'; en = 'News'; jp = 'お知らせ' }
)
$menuTail = @(
  @{ file = 'recruit.html'; en = 'Recruit'; jp = '選手募集' },
  @{ file = 'club.html';    en = 'Club';    jp = 'クラブ概要' },
  @{ file = 'contact.html'; en = 'Contact'; jp = 'お問い合わせ'; mobileOnly = $true },
  @{ file = 'sponsor.html'; en = 'Partner'; jp = 'スポンサー募集' }
)
function Desktop-Nav($current) {
  $out = @()
  $curDiv = Division-Of $current
  foreach ($p in $menuTop) { $cur = if ($p.file -eq $current) { ' aria-current="page"' } else { '' }; $out += "<a href=`"$($p.file)`"$cur>$($p.en)<small>$($p.jp)</small></a>" }
  foreach ($d in $divisions) {
    $isCur = if ($curDiv -and $curDiv.key -eq $d.key) { ' aria-current="page"' } else { '' }
    $subs = ($sections | ForEach-Object { $f = "$($d.prefix)$($_.key).html"; $c = if ($f -eq $current) { ' aria-current="page"' } else { '' }; "<a href=`"$f`"$c>$($_.jp)<small>$($_.en)</small></a>" }) -join ''
    $out += "<div class=`"nav-drop`"><a class=`"nav-top`" href=`"teams.html#$($d.key)`"$isCur>$($d.en)<small>$($d.jp)</small></a><div class=`"nav-sub`"><p class=`"nav-sub-head`">$($d.name)</p>$subs</div></div>"
  }
  foreach ($p in $menuTail) {
    if ($p.mobileOnly) { continue }
    $cur = if ($p.file -eq $current) { ' aria-current="page"' } else { '' }
    $cls = if ($p.file -eq 'sponsor.html') { ' class="nav-cta"' } else { '' }
    $out += "<a$cls href=`"$($p.file)`"$cur>$($p.en)<small>$($p.jp)</small></a>"
  }
  return ($out -join "`n      ")
}
function Mobile-Nav($current) {
  $cur = if ($current -eq 'index.html') { ' aria-current="page"' } else { '' }
  $out = @("<a href=`"index.html`"$cur>トップ</a>")
  foreach ($p in $menuTop) { $cur = if ($p.file -eq $current) { ' aria-current="page"' } else { '' }; $out += "<a href=`"$($p.file)`"$cur>$($p.jp)</a>" }
  foreach ($d in $divisions) {
    $subs = ($sections | ForEach-Object { $f = "$($d.prefix)$($_.key).html"; $c = if ($f -eq $current) { ' aria-current="page"' } else { '' }; "<a class=`"menu-sub`" href=`"$f`"$c><small>$($_.en.ToUpper())</small>$($_.jp)</a>" }) -join ''
    $out += "<div class=`"menu-group mg-$($d.key)`"><a class=`"menu-group-head`" href=`"teams.html#$($d.key)`">$($d.jp)<small>$($d.name)</small></a><div class=`"menu-subs`">$subs</div></div>"
  }
  foreach ($p in $menuTail) { $cur = if ($p.file -eq $current) { ' aria-current="page"' } else { '' }; $out += "<a href=`"$($p.file)`"$cur>$($p.jp)</a>" }
  return ($out -join "`n        ")
}

$fonts = @'
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Anton&family=Barlow+Condensed:wght@700;800&family=Noto+Sans+JP:wght@400;500;700;900&display=swap">
<link rel="stylesheet" href="style.css?v=CSSVER">
'@
# style.css を直したら URL を変えて、ブラウザに古い CSS を使わせない
$cssVer = (Get-FileHash (Join-Path $root 'style.css') -Algorithm MD5).Hash.Substring(0, 8).ToLower()
$fonts = $fonts.Replace('CSSVER', $cssVer)

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
  'schedule.html' = 'FC TRIDENT TOKYOの活動日程。公式戦の日時・会場・対戦相手と結果を掲載しています。'
  'members.html' = 'FC TRIDENT TOKYOの選手・スタッフ紹介とユニフォームです。'
  'gallery.html' = 'FC TRIDENT TOKYOの試合ごとの写真アルバムと試合動画です。'
  'club.html'    = 'FC TRIDENT TOKYOの理念、チーム紹介、基本情報、沿革です。'
  'contact.html' = 'FC TRIDENT TOKYOへのお問い合わせ。練習参加、新部門の立ち上げ、対戦のご依頼、スポンサーのご相談を受け付けています。'
  'sponsor.html' = 'FC TRIDENT TOKYOのスポンサー募集。ユニフォームへのロゴ掲載、HP・Instagramでのご紹介など、協賛の形はご相談に応じます。'
  'recruit.html' = 'FC TRIDENT TOKYOの選手・マネージャー募集。全ポジション募集中。練習参加は何回でもOK、InstagramのDMで応募できます。'
  'privacy.html' = 'FC TRIDENT TOKYOのプライバシーポリシーです。'
  '404.html'     = 'お探しのページが見つかりませんでした。'
  'teams.html'   = 'TEAM TRIDENTの3部門（FC Trident Tokyo／Football／University）の紹介です。'
}
# Google アナリティクス（GA4 の測定 ID。空なら読み込まない）
$gaId = 'G-H27ZJS6CV7'
$gaTag = ''
if ($gaId) {
  $gaTag = @"
<script async src="https://www.googletagmanager.com/gtag/js?id=$gaId"></script>
<script>window.dataLayer=window.dataLayer||[];function gtag(){dataLayer.push(arguments);}gtag('js',new Date());gtag('config','$gaId');</script>
"@
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
  # 部門のページには、その部門のタブ（試合情報・活動日程・メンバー・ギャラリー）を付ける
  $dv = Division-Of $file
  if ($dv) {
    # いま見ている項目（試合情報・活動日程…）。部門を切り替えても同じ項目のページへ
    $curSec = ($file.Substring($dv.prefix.Length) -replace '-.*$', '' -replace '\.html$', '')
    $switch = ($divisions | ForEach-Object { $c = if ($_.key -eq $dv.key) { ' aria-current="true"' } else { '' }; "<a class=`"ds ds-$($_.key)`" href=`"$($_.prefix)$curSec.html`"$c><b>$($_.jp)</b><small>$($_.en.ToUpper())</small></a>" }) -join ''
    $tabs = ($sections | ForEach-Object { $f = "$($dv.prefix)$($_.key).html"; $c = if ($_.key -eq $curSec) { ' aria-current="page"' } else { '' }; "<a href=`"$f`"$c><small>$($_.en.ToUpper())</small>$($_.jp)</a>" }) -join ''
    $body = "<nav class=`"div-tabs div-$($dv.key)`" aria-label=`"部門と項目のメニュー`"><div class=`"div-switch`"><div class=`"wrap`"><span class=`"div-switch-label`">部門を選ぶ</span><div class=`"div-switch-links`">$switch</div></div></div><div class=`"div-sec`"><div class=`"wrap`"><span class=`"div-sec-name`">$($dv.name)</span><div class=`"div-tabs-links`">$tabs</div></div></div></nav>`n" + $body
  }
  $inner = @"
<header class="site-head">
  <div class="wrap">
    <div class="brand">
      <a class="brand-emblem" href="index.html" aria-label="TEAM TRIDENT トップ">$emblem</a>
      <span class="brand-name"><a href="index.html">TEAM TRIDENT</a><span class="brand-divs" aria-label="部門">$(($divisions | ForEach-Object { $c = if ($dv -and $dv.key -eq $_.key) { ' aria-current="true"' } else { '' }; "<a class=`"bd bd-$($_.key)`" href=`"teams.html#$($_.key)`"$c>$($_.jp -replace '部門$', '')</a>" }) -join '')</span></span>
    </div>
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
    <div class="foot-big" aria-hidden="true">TEAM TRIDENT</div>
    <div class="foot-grid">
      <div>
        <a class="brand" href="index.html">$emblem<span class="brand-name">TEAM TRIDENT<small>SOCIETY ・ FOOTBALL ・ UNIVERSITY</small></span></a>
        <p>活動エリア：東京都（品川区・目黒区・港区周辺）／毎週土日</p>
      </div>
      <nav class="foot-links" aria-label="フッターメニュー">
        <a href="index.html">トップ</a><a href="news.html">お知らせ</a><a href="teams.html">3部門</a><a href="match.html">試合情報</a>
        <a href="schedule.html">活動日程</a><a href="members.html">メンバー</a><a href="gallery.html">ギャラリー</a><a href="sponsor.html">スポンサー募集</a>
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
  if ($file -eq 'index.html') { $extraHead += "`n" + $jsonLd }
  $html = @"
<!doctype html>
<html lang="ja">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
$gaTag
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

# 部門ページの見出し（パンくず・h1）。ソサイチは今までどおり、ほかの部門は部門名を添える
function Div-Head($dv, $en, $jp) {
  if (-not $dv.prefix) { return "<p class=`"crumb`"><a href=`"index.html`">Top</a> / $en</p>`n      <p class=`"eyebrow`">$en</p>`n      <h1>$jp</h1>" }
  return "<p class=`"crumb`"><a href=`"index.html`">Top</a> / <a href=`"teams.html#$($dv.key)`">$($dv.en)</a> / $en</p>`n      <p class=`"eyebrow`">$en</p>`n      <h1>$jp<span class=`"h1-sub`">$($dv.name)</span></h1>"
}

# 試合の呼び方：ふだんは「第N節」、大会などは matches.json の label（例：第4試合）
function RL($m) { if ($m.label) { return [string]$m.label } return "第$($m.round)節" }

# 勝敗。同点でシュートアウト（soUs・soThem）があればその結果で決める
function Res-Of($m) {
  if ($null -eq $m.us) { return @('', '') }
  $a = [int]$m.us; $b = [int]$m.them
  if ($a -eq $b -and $null -ne $m.soUs) { $a = [int]$m.soUs; $b = [int]$m.soThem }
  if ($a -gt $b) { return @('WIN', 'w') } elseif ($a -lt $b) { return @('LOSE', 'l') } else { return @('DRAW', 'd') }
}
function So-Text($m) { if ($null -ne $m.soUs) { return " (SO $($m.soUs)-$($m.soThem))" } return '' }
# ---------- 試合データ（部門ごと）----------
# ソサイチ：_data/matches.json、photos/<日付>_<相手>/ → gallery/<日付>/、gallery-<日付>.html
# ほかの部門：_data/<部門>/matches.json、photos/<部門>/<日付>_<相手>/ → gallery/<部門>/<日付>/、<部門>-gallery-<日付>.html
$days = @('日', '月', '火', '水', '木', '金', '土')
$dataBy = @{}; $albumsBy = @{}; $withPhotosBy = @{}; $galleryBodyBy = @{}; $leagueLineBy = @{}
foreach ($dv in $divisions) {
$pfx = $dv.prefix
$dataFile = if ($pfx) { Join-Path $root "_data\$($dv.key)\matches.json" } else { Join-Path $root '_data\matches.json' }
$data = if (Test-Path $dataFile) { [IO.File]::ReadAllText($dataFile, $utf8) | ConvertFrom-Json } else { [pscustomobject]@{ league = ''; division = ''; matches = @() } }
$photoBase = if ($pfx) { "photos\$($dv.key)\" } else { 'photos\' }
$galleryDir = if ($pfx) { "gallery\$($dv.key)\" } else { 'gallery\' }
$galleryUrl = if ($pfx) { "gallery/$($dv.key)/" } else { 'gallery/' }
$galleryPage = "$($pfx)gallery.html"
$leagueLine = "$($data.league) $($data.division)".Trim()

$albums = @()
foreach ($m in (@($data.matches) | Where-Object { $_ -and ($null -ne $_.us -or $_.video -or @(Get-ChildItem (Join-Path $root ("{0}{1}_{2}" -f $photoBase, $_.date, $_.opponent)) -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -match '^\.(jpe?g|png)$' }).Count) } | Sort-Object date -Descending)) {
  $d = [DateTime]::ParseExact($m.date, 'yyyy-MM-dd', $null)
  $dateLabel = '{0}（{1}）' -f $d.ToString('yyyy.MM.dd'), $days[[int]$d.DayOfWeek]
  $result = (Res-Of $m)[0]
  $resCls = if ($result) { @{ WIN = 'w'; LOSE = 'l'; DRAW = 'd' }[$result] } else { '' }
  $scoreTxt = if ($null -eq $m.us) { 'VS' } else { "$($m.us) - $($m.them)$(So-Text $m)" }

  $src = Join-Path $root ("{0}{1}_{2}" -f $photoBase, $m.date, $m.opponent)
  $photos = @()
  $memo = @{}
  if (Test-Path $src) {
    $files = Get-ChildItem $src -File | Where-Object { $_.Extension -match '^\.(jpe?g|png)$' } | Sort-Object Name
    # 表紙：photos に cover.jpg があればそれ、なければ matches.json の cover（集合写真）
    $cover = $files | Where-Object { $_.BaseName -ieq 'cover' } | Select-Object -First 1
    if (-not $cover -and $m.cover) { $cover = $files | Where-Object { $_.BaseName -ieq $m.cover } | Select-Object -First 1 }
    if ($cover) { $files = @($cover) + @($files | Where-Object { $_.FullName -ne $cover.FullName }) }
    $outDir = Join-Path $root "$galleryDir$($m.date)"
    if ($files) { New-Item -ItemType Directory -Force (Join-Path $outDir 'thumb') | Out-Null }
    # 書き出す名前は元のファイル名に合わせる（消したり並べ替えたりしても写真が入れ替わらないように）
    $keep = @{}
    foreach ($f in $files) {
      $name = (($f.BaseName -replace '[^\w\-]', '_').ToLower()) + '.jpg'
      $keep[$name] = $true
      Save-Resized $f.FullName (Join-Path $outDir $name) 1800
      Save-Resized $f.FullName (Join-Path $outDir "thumb\$name") 640
      $photos += "$galleryUrl$($m.date)/$name"
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
    m = $m; dateLabel = $dateLabel; result = $result; resCls = $resCls; scoreTxt = $scoreTxt; photos = $photos; memo = $memo
    page = "$($pfx)gallery-$($m.date).html"
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
  if ($m.venue) { $info += "<dt>会場</dt><dd>$(Esc $m.venue)</dd>" }
  if ($m.half) { $info += "<dt>前半 / 後半</dt><dd>$(Esc $m.half)</dd>" }
  if ($null -ne $m.soUs) { $info += "<dt>シュートアウト</dt><dd>$($m.soUs)-$($m.soThem)</dd>" }
  if ($m.entryName) { $info += "<dt>大会登録名</dt><dd>$(Esc $m.entryName)</dd>" }
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
    "<button type=`"button`" class=`"photo`" data-full=`"$_`" aria-label=`"写真 $n を拡大`"><img src=`"$thumb`" alt=`"$(RL $m) vs $(Esc $m.opponent) の写真 $n`" loading=`"lazy`"></button>"
  }) -join "`n        "
  $prev = if ($k -lt $withPhotos.Count - 1) { $p = $withPhotos[$k + 1]; "<a class=`"album-nav-link`" href=`"$($p.page)`">← $(RL $p.m) vs $(Esc $p.m.opponent)</a>" } else { '<span></span>' }
  $next = if ($k -gt 0) { $p = $withPhotos[$k - 1]; "<a class=`"album-nav-link`" href=`"$($p.page)`">$(RL $p.m) vs $(Esc $p.m.opponent) →</a>" } else { '<span></span>' }

  $body = @"
<main>
  <section class="page-head album-head">
    <div class="wrap">
      <p class="crumb"><a href="index.html">Top</a> / $(if ($pfx) { "<a href=`"teams.html#$($dv.key)`">$($dv.en)</a> / " })<a href="$galleryPage">Gallery</a> / Round $($m.round)</p>
      <p class="album-league">$(Esc $leagueLine)</p>
      <h1 class="album-title">$(RL $m)<span>vs $(Esc $m.opponent)</span></h1>
      <div class="album-score">
        <span class="crest us"><img src="emblem.webp" alt=""></span>
        $(if ($null -eq $m.us) { '<span class="score">VS</span>' } else { "<span class=`"score`">$($m.us)<span class=`"dash`">-</span>$($m.them)</span>" })
        <span class="crest them">$(if ($m.logo) { "<img src=`"$($m.logo)`" alt=`"`">" } else { "<b class=`"crest-txt`">$(Esc ($m.opponent.Substring(0, 1)))</b>" })</span>
        $(if ($a.result) { "<span class=`"res $($a.resCls)`">$($a.result)</span>" })
      </div>
    </div>
  </section>

  <section class="sec">
    <div class="wrap album-body">
      <dl class="facts album-facts">
        $($info -join "`n        ")
      </dl>
      $note
      $(if ($m.event) { "<div class=`"album-actions`"><a class=`"more`" href=`"https://football7society.jp/kanto/event/$($m.event)/`" target=`"_blank`" rel=`"noopener`">League record <span class=`"jp`">リーグ公式の試合記録</span></a></div>" })
      $video
      $(if ($grid) { "<div class=`"photo-grid`">`n        $grid`n      </div>" } else { '<p class="album-empty">この試合の写真は準備中です。</p>' })
      <nav class="album-nav" aria-label="ほかのアルバム">$prev<a class="album-nav-link" href="$galleryPage">アルバム一覧</a>$next</nav>
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
  Write-Page $a.page "$(RL $m) vs $($m.opponent)" $body $galleryPage "$leagueLine $(RL $m)、$($dv.name) vs $($m.opponent)（$($a.dateLabel)$(if ($null -ne $m.us) { "、$($m.us)-$($m.them)" })）の試合写真と試合動画です。"
}

# ---------- ギャラリー一覧 ----------
$cards = foreach ($a in $albums) {
  $m = $a.m
  $head = @"
<p class="album-league">$(Esc $leagueLine)</p>
          <h3 class="album-card-title">$(RL $m)<span>vs $(Esc $m.opponent)</span></h3>
          <p class="album-meta">$(if ($a.result) { "<span class=`"res $($a.resCls)`">$($a.result)</span>" })<span class="album-score-sm">$($a.scoreTxt)</span><span>$($a.dateLabel)</span></p>
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
      $(Div-Head $dv 'Gallery' 'ギャラリー')
      <p class="lead">$(if ($leagueLine) { Esc $leagueLine } else { Esc $dv.name })の試合ごとの写真アルバムです。</p>
    </div>
  </section>

  <section class="sec">
    <div class="wrap">
      <div class="sec-head"><div><p class="eyebrow">Albums</p><h2>試合アルバム</h2></div></div>
      $(if (@($cards).Count) { "<div class=`"album-grid`">`n      $($cards -join "`n      ")`n      </div>" } else { "<div class=`"soon-box`"><p class=`"soon-tag`">NO ALBUM YET</p><p class=`"soon-text`">試合が始まったら、試合ごとの写真アルバムと試合動画をここに掲載します。</p></div>" })
      <div class="insta">
        <p><small>INSTAGRAM</small>最新の様子はInstagramで発信しています</p>
        <a class="btn btn-red" href="https://www.instagram.com/fctridenttokyo_society/" target="_blank" rel="noopener">@fctridenttokyo_society <span class="arrow">→</span></a>
      </div>
    </div>
  </section>
</main>
"@
$dataBy[$dv.key] = $data; $albumsBy[$dv.key] = $albums; $withPhotosBy[$dv.key] = $withPhotos; $galleryBodyBy[$dv.key] = $galleryBody; $leagueLineBy[$dv.key] = $leagueLine
}
# ソサイチの値を、このあとの処理（活動日程・サイトマップなど）で使う
$data = $dataBy['society']; $albums = $albumsBy['society']; $withPhotos = $withPhotosBy['society']; $galleryBody = $galleryBodyBy['society']; $leagueLine = $leagueLineBy['society']

# ---------- 活動日程 ----------
# 公式戦は matches.json から自動で入れる。練習・練習試合・イベントは _data/schedule.json の events に足す
$typeInfo = @{
  official = @{ jp = '公式戦';   order = 1 }
  friendly = @{ jp = '練習試合'; order = 2 }
  practice = @{ jp = '練習';     order = 3 }
  event    = @{ jp = 'イベント'; order = 4 }
}
$scheduleBodyBy = @{}
foreach ($dv in $divisions) {
$pfx = $dv.prefix; $data = $dataBy[$dv.key]; $withPhotos = $withPhotosBy[$dv.key]; $schedPage = "$($pfx)schedule.html"
$albumByDate = @{}; foreach ($a in $withPhotos) { $albumByDate[$a.m.date] = $a.page }
$events = @()
foreach ($m in @($data.matches)) {
  $events += [pscustomobject]@{
    date = $m.date; type = 'official'; start = $m.kickoff; end = ''; title = "$(if ($pfx) { $data.league } else { '関東リーグ' }) $($data.division) $(RL $m)" -replace '\s+', ' ' -replace '^ ', ''
    opponent = $m.opponent; logo = $m.logo; ha = $m.ha; place = $m.venue; note = ''; us = $m.us; them = $m.them; soUs = $m.soUs; soThem = $m.soThem
    link = $albumByDate[$m.date]
  }
}
$schedFile = Join-Path $root '_data\schedule.json'
if (Test-Path $schedFile) {
  foreach ($e in @(([IO.File]::ReadAllText($schedFile, $utf8) | ConvertFrom-Json).events)) {
    if (-not $e.date) { continue }
    $evDiv = if ($e.division) { [string]$e.division } else { 'society' }
    if ($evDiv -ne $dv.key) { continue }
    $type = if ($typeInfo.ContainsKey([string]$e.type)) { [string]$e.type } else { 'event' }
    $events += [pscustomobject]@{
      date = $e.date; type = $type; start = $e.start; end = $e.end; title = $(if ($e.title) { $e.title } else { $typeInfo[$type].jp })
      opponent = $e.opponent; logo = $e.logo; ha = $e.ha; place = $e.place; note = $e.note; us = $e.us; them = $e.them; link = $e.link
    }
  }
}
$todayKey = (Get-Date).ToString('yyyy-MM-dd')
$inv = [Globalization.CultureInfo]::InvariantCulture

function Event-Html($e, $isPast) {
  $d = [DateTime]::ParseExact($e.date, 'yyyy-MM-dd', $null)
  $wk = if ($d.DayOfWeek -eq 'Saturday') { ' sat' } elseif ($d.DayOfWeek -eq 'Sunday') { ' sun' } else { '' }
  $isMatch = $e.type -eq 'official' -or $e.type -eq 'friendly'
  $time = ''
  if ($e.start) { $time = if ($isMatch) { "$($e.start) KICK OFF" } elseif ($e.end) { "$($e.start)〜$($e.end)" } else { "$($e.start)〜" } }
  elseif (-not $isPast) { $time = '時間未定' }
  $meta = @()
  if ($time) { $meta += "<span class=`"ev-time`">$(Esc $time)</span>" }
  if ($e.place) { $meta += "<span class=`"ev-place`">$(Esc $e.place)</span>" }
  if ($e.ha) { $meta += "<span>$(if ($e.ha -eq 'H') { 'ホーム' } else { 'アウェイ' })</span>" }
  $vs = ''
  if ($e.opponent) {
    $logo = if ($e.logo) { "<img src=`"$($e.logo)`" alt=`"`">" } else { '' }
    $vs = "<p class=`"ev-vs`"><span class=`"ev-vs-us`"><img src=`"emblem.webp`" alt=`"`"></span><b>VS</b>$logo<span>$(Esc $e.opponent)</span></p>"
  }
  $note = if ($e.note) { "<p class=`"ev-note`">$(Esc $e.note)</p>" } else { '' }
  # 右側：終わった試合は結果、これからの予定は「カレンダーに追加」
  $side = ''
  if ($isPast -and $null -ne $e.us -and $null -ne $e.them) {
    $res = Res-Of $e
    $side = "<span class=`"ev-score`">$($e.us)<span class=`"dash`">-</span>$($e.them)$(if ($null -ne $e.soUs) { "<small>SO $($e.soUs)-$($e.soThem)</small>" })</span><span class=`"res $($res[1])`">$($res[0])</span>"
    if ($e.link) { $side += "<a class=`"ev-link`" href=`"$($e.link)`">写真・動画</a>" }
  } elseif ($isPast -and $e.link) {
    $side = "<a class=`"ev-link`" href=`"$($e.link)`">写真・動画</a>"
  } elseif (-not $isPast) {
    $text = "$($dv.name) " + $e.title + $(if ($e.opponent) { " vs $($e.opponent)" } else { '' })
    if ($e.start) {
      $s = [DateTime]::ParseExact("$($e.date) $($e.start)", 'yyyy-MM-dd HH:mm', $null)
      $f = if ($e.end) { [DateTime]::ParseExact("$($e.date) $($e.end)", 'yyyy-MM-dd HH:mm', $null) } else { $s.AddHours(2) }
      $dates = $s.ToString('yyyyMMddTHHmm00') + '/' + $f.ToString('yyyyMMddTHHmm00')
    } else {
      $dates = $d.ToString('yyyyMMdd') + '/' + $d.AddDays(1).ToString('yyyyMMdd')
    }
    $gcal = 'https://calendar.google.com/calendar/render?action=TEMPLATE&text=' + [uri]::EscapeDataString($text) +
      '&dates=' + $dates + '&ctz=Asia%2FTokyo&location=' + [uri]::EscapeDataString([string]$e.place) +
      '&details=' + [uri]::EscapeDataString("FC TRIDENT TOKYO 活動日程`n${siteUrl}$schedPage")
    $side = "<a class=`"ev-cal`" href=`"$(Esc $gcal)`" target=`"_blank`" rel=`"noopener`">＋ カレンダーに追加</a><span class=`"ev-done`">終了</span>"
  }
  return @"
<li class="ev" data-type="$($e.type)" data-date="$($e.date)">
            <div class="ev-date$wk"><b>$($d.Day)</b><span>$($d.ToString('ddd', $inv).ToUpper())<small>$($days[[int]$d.DayOfWeek])</small></span></div>
            <div class="ev-body">
              <p class="ev-head"><span class="ev-type $($e.type)">$($typeInfo[$e.type].jp)</span><span class="ev-title">$(Esc $e.title)</span></p>
              $vs
              <p class="ev-meta">$($meta -join '')</p>
              $note
            </div>
            <div class="ev-side">$side</div>
          </li>
"@
}

function Month-Groups($list, $isPast) {
  $out = @()
  foreach ($g in ($list | Group-Object { $_.date.Substring(0, 7) })) {
    $d = [DateTime]::ParseExact($g.Name + '-01', 'yyyy-MM-dd', $null)
    $items = ($g.Group | ForEach-Object { Event-Html $_ $isPast }) -join "`n          "
    $out += @"
<section class="ev-month">
        <h3 class="ev-month-head"><b>$($d.Month)</b><span>$($d.ToString('MMM', $inv).ToUpper())<small>$($d.Year)</small></span></h3>
        <ol class="ev-list">
          $items
        </ol>
      </section>
"@
  }
  return ($out -join "`n      ")
}

$upcoming = @($events | Where-Object { $_.date -ge $todayKey } | Sort-Object date, start)
$past = @($events | Where-Object { $_.date -lt $todayKey } | Sort-Object date, start -Descending)
$usedTypes = @($events | ForEach-Object { $_.type } | Select-Object -Unique | Sort-Object { $typeInfo[$_].order })
$filters = ''
if ($usedTypes.Count -gt 1) {
  $filters = '<div class="filters" role="group" aria-label="種類で絞り込む"><button type="button" data-filter="all" aria-pressed="true">すべて</button>' +
    (($usedTypes | ForEach-Object { "<button type=`"button`" data-filter=`"$_`" aria-pressed=`"false`">$($typeInfo[$_].jp)</button>" }) -join '') + '</div>'
}
$upcomingHtml = if ($upcoming.Count) { Month-Groups $upcoming $false } else { '<p class="ev-empty">いま決まっている予定はありません。</p>' }
$pastHtml = if ($past.Count) { @"
<details class="ev-past">
        <summary>終了した日程<span>$($past.Count)</span></summary>
        $(Month-Groups $past $true)
      </details>
"@ } else { '' }

$scheduleBody = @"
<main>
  <section class="page-head">
    <div class="wrap">
      $(Div-Head $dv 'Schedule' '活動日程')
      <p class="lead">$(Esc $dv.jp)の公式戦の日程と結果をまとめています。練習や練習試合の日程も、順次ここに掲載していきます。</p>
    </div>
  </section>

  <section class="sec">
    <div class="wrap">
      <div class="sec-head"><div><p class="eyebrow">Upcoming</p><h2>これからの予定</h2></div><a class="more" href="$($pfx)match.html">Standings <span class="jp">順位表を見る</span></a></div>
      $filters
      <div class="ev-months" id="ev-upcoming">
      $upcomingHtml
      </div>
      $pastHtml
      <p class="src">日時・会場は変更になることがあります。最新の情報は<a href="https://www.instagram.com/fctridenttokyo_society/" target="_blank" rel="noopener">Instagram</a>でもお知らせします。練習に参加したい方は<a href="recruit.html">選手募集</a>をご覧ください。</p>
    </div>
  </section>
</main>
<script>
  (function () {
    // ページを作り直す前に日付が過ぎた予定は「終了」にし、次の予定に NEXT を付ける
    var now = new Date();
    var today = now.getFullYear() + '-' + ('0' + (now.getMonth() + 1)).slice(-2) + '-' + ('0' + now.getDate()).slice(-2);
    var next = null;
    Array.prototype.forEach.call(document.querySelectorAll('#ev-upcoming .ev'), function (li) {
      if (li.getAttribute('data-date') < today) { li.classList.add('is-done'); }
      else if (!next) { next = li; }
    });
    function markNext() {
      Array.prototype.forEach.call(document.querySelectorAll('.ev.is-next'), function (li) { li.classList.remove('is-next'); });
      var first = Array.prototype.find.call(document.querySelectorAll('#ev-upcoming .ev'), function (li) { return !li.classList.contains('is-done') && !li.hidden; });
      if (first) first.classList.add('is-next');
    }
    markNext();
    var buttons = document.querySelectorAll('.filters button');
    Array.prototype.forEach.call(buttons, function (b) {
      b.addEventListener('click', function () {
        var f = b.getAttribute('data-filter');
        Array.prototype.forEach.call(buttons, function (x) { x.setAttribute('aria-pressed', String(x === b)); });
        Array.prototype.forEach.call(document.querySelectorAll('.ev'), function (li) { li.hidden = f !== 'all' && li.getAttribute('data-type') !== f; });
        Array.prototype.forEach.call(document.querySelectorAll('.ev-month'), function (sec) { sec.hidden = !sec.querySelector('.ev:not([hidden])'); });
        markNext();
      });
    });
  })();
</script>
"@
$scheduleBodyBy[$dv.key] = $scheduleBody
}
$data = $dataBy['society']; $withPhotos = $withPhotosBy['society']; $scheduleBody = $scheduleBodyBy['society']

# ---------- メンバー（_data/players.json ＋ photos/players/<背番号>_<名前>/）----------
$pdata = [IO.File]::ReadAllText((Join-Path $root '_data\players.json'), $utf8) | ConvertFrom-Json
$playerSrc = Join-Path $root 'photos\players'
$playerOut = Join-Path $root 'players'
$profLabels = [ordered]@{
  career = '経歴'; skill = '得意なプレー'; goalFootball = '今シーズンの目標（サッカー）'; goalPrivate = '今シーズンの目標（プライベート）'
  motto = '好きな言葉'; favorite = '好きなサッカー選手'
}
$posNames = [ordered]@{ GK = 'ゴールキーパー'; DF = 'ディフェンダー'; MF = 'ミッドフィルダー'; FW = 'フォワード' }
$keepPlayers = @{}
$photoJobs = @()
# 所属（"ソサイチ部門" など）で部門ごとに分ける
$memberGroupsBy = @{}; $profilesBy = @{}
foreach ($dv in $divisions) { $memberGroupsBy[$dv.key] = @(); $profilesBy[$dv.key] = @() }
foreach ($pos in $posNames.Keys) {
  $cardsBy = @{}; foreach ($dv in $divisions) { $cardsBy[$dv.key] = @() }
  foreach ($p in @($pdata.players | Where-Object { $_.pos -eq $pos })) {
    $kind = if ($pos -eq 'GK') { 'gk' } else { 'fp' }
    # 写真：フォルダの main.* を優先、なければファイル名順の1枚目
    $photo = ''
    $dir = if (Test-Path $playerSrc) { Get-ChildItem $playerSrc -Directory | Where-Object { $_.Name -match "^$($p.num)_" } | Select-Object -First 1 }
    if ($dir) {
      $imgs = @(Get-ChildItem $dir.FullName -File | Where-Object { $_.Extension -match '^\.(jpe?g|png|heic|heif)$' } | Sort-Object Name)
      $main = $imgs | Where-Object { $_.BaseName -ieq 'main' } | Select-Object -First 1
      if (-not $main -and $imgs.Count) { $main = $imgs[0] }
      if ($main) {
        New-Item -ItemType Directory -Force $playerOut | Out-Null
        $srcPath = $main.FullName
        # iPhone の HEIC は System.Drawing で読めないので、Windows の画像機能でいったん JPEG にする
        if ($main.Extension -match '^\.hei[cf]$') {
          Add-Type -AssemblyName PresentationCore
          $tmpDir = Join-Path $root '_build\heic'; New-Item -ItemType Directory -Force $tmpDir | Out-Null
          $srcPath = Join-Path $tmpDir "$($p.num).jpg"
          $in = [IO.File]::OpenRead($main.FullName)
          try {
            $dec = [Windows.Media.Imaging.BitmapDecoder]::Create($in, 'None', 'OnLoad')
            $enc = New-Object Windows.Media.Imaging.JpegBitmapEncoder; $enc.QualityLevel = 92
            $enc.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($dec.Frames[0]))
            $out = [IO.File]::Create($srcPath); try { $enc.Save($out) } finally { $out.Close() }
          } finally { $in.Close() }
        }
        $photoJobs += [pscustomobject]@{ num = $p.num; src = $srcPath; cutout = ($p.cutout -ne $false); cut = '' }
        $keepPlayers["$($p.num).jpg"] = $true
        $photo = "<img src=`"players/$($p.num).jpg`" alt=`"$(Esc $p.name)`" loading=`"lazy`">"
      }
    }
    # ギャラリーのプレー写真（players.json の play：src と切り出し位置 cx・top・h）
    # カードはプレー写真を優先し、本人の写真（白背景）はプロフィールの中で見せる
    $playPhoto = ''
    if ($p.play -and (Test-Path (Join-Path $root $p.play.src))) {
      New-Item -ItemType Directory -Force $playerOut | Out-Null
      $im = [System.Drawing.Image]::FromFile((Join-Path $root $p.play.src))
      try {
        $ch = [int][Math]::Min([int]$p.play.h, $im.Height); $cw = [int]($ch * 3 / 4)
        $cx = [int][Math]::Max(0, [Math]::Min($im.Width - $cw, [int]$p.play.cx - $cw / 2))
        $cy = [int][Math]::Max(0, [Math]::Min($im.Height - $ch, [int]$p.play.top))
        $bmp = New-Object System.Drawing.Bitmap 750, 1000
        $gr = [System.Drawing.Graphics]::FromImage($bmp); $gr.InterpolationMode = 'HighQualityBicubic'
        $gr.DrawImage($im, (New-Object System.Drawing.Rectangle 0, 0, 750, 1000), (New-Object System.Drawing.Rectangle $cx, $cy, $cw, $ch), [System.Drawing.GraphicsUnit]::Pixel)
        $ep = New-Object System.Drawing.Imaging.EncoderParameters(1)
        $ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]84)
        $bmp.Save((Join-Path $playerOut "$($p.num)-play.jpg"), $jpegCodec, $ep); $gr.Dispose(); $bmp.Dispose()
      } finally { $im.Dispose() }
      $keepPlayers["$($p.num)-play.jpg"] = $true
      $playPhoto = "<img class=`"is-play`" src=`"players/$($p.num)-play.jpg`" alt=`"$(Esc $p.name)`" loading=`"lazy`">"
    }
    $profilePhoto = if ($photo) { $photo } else { $playPhoto }
    if ($playPhoto) { $photo = $playPhoto }
    $note = "$($p.goals)ゴール" + $(if ($p.note) { '・' + $p.note } else { '' })
    $division = if ($p.division) { $p.division } else { $pdata.defaultDivision }
    $divTag = if ($division) { "<span class=`"member-div`">$(Esc $division)</span>" } else { '' }
    $pdv = $divisions | Where-Object { $_.jp -eq $division } | Select-Object -First 1
    $divKey = if ($pdv) { $pdv.key } else { 'society' }
    $goalLine = if ($divKey -eq 'society') { '関東リーグ 4部C' } else { '公式戦' }
    $posCls = if ($kind -eq 'gk') { 'pos gk' } else { 'pos' }
    $open = ''
    if ($p.profile) {
      $open = "<button type=`"button`" class=`"member-open`" data-profile=`"p-$($p.num)`" aria-haspopup=`"dialog`"><span>プロフィールを見る</span></button>"
      $dl = @()
      if ($division) { $dl += "<dt>所属</dt><dd>$(Esc $division)</dd>" }
      $dl += foreach ($k in $profLabels.Keys) { if ($p.profile.$k) { "<dt>$($profLabels[$k])</dt><dd>$(Esc $p.profile.$k)</dd>" } }
      $msg = if ($p.profile.message) { "<p class=`"profile-msg`">$(Esc $p.profile.message)</p>" } else { '' }
      $nick = if ($p.profile.nickname) { "<p class=`"profile-nick`">$(Esc $p.profile.nickname)</p>" } else { '' }
      $profilesBy[$divKey] += @"
<dialog class="profile" id="p-$($p.num)" aria-labelledby="p-$($p.num)-name">
  <div class="profile-inner">
    <button type="button" class="profile-close" aria-label="閉じる">×</button>
    <div class="profile-photo member-photo $kind">$($profilePhoto.Replace(' loading="lazy"', ''))<span class="num">$($p.num)</span></div>
    <div class="profile-body">
      <p class="$posCls">$pos ・ $($posNames[$pos])</p>
      <h3 id="p-$($p.num)-name">$(Esc $p.name)</h3>
      $nick
      $msg
      <dl class="profile-dl">
        $($dl -join "`n        ")
      </dl>
      <p class="profile-goals">$goalLine <b>$($p.goals)</b> ゴール<small>（$($pdata.goalsAsOf)時点）</small></p>
    </div>
  </div>
</dialog>
"@
    }
    $soon = if ($p.profile) { '' } else { '<span class="member-soon">PROFILE<b>COMING SOON</b></span>' }
    $cardsBy[$divKey] += "<article class=`"member$(if ($p.profile) { ' has-profile' })`"><div class=`"member-photo $kind`">$photo<span class=`"num`">$($p.num)</span>$soon</div><div class=`"member-info`"><span class=`"member-tags`"><span class=`"$posCls`">$pos</span>$divTag</span><b>$(Esc $p.name)</b><span class=`"note`">$note</span></div>$open</article>"
  }
  foreach ($dv in $divisions) {
    $cards = $cardsBy[$dv.key]
    if ($cards.Count) {
      $memberGroupsBy[$dv.key] += "<div class=`"pos-head`"><h2>$pos</h2><span>$($posNames[$pos])</span></div>`n      <div class=`"members`">`n        $($cards -join "`n        ")`n      </div>"
    }
  }
}
# 背景の切り抜き（_build/rembg-venv があるときだけ。players.json で "cutout": false の選手は元の写真のまま）
# 切り抜き結果は _build/cutout/<番号>.png に残し、元の写真が変わったときだけ作り直す
$py = Join-Path $root '_build\rembg-venv\Scripts\python.exe'
$cutDir = Join-Path $root '_build\cutout'
$cutArgs = @(); $cutKeys = @()
if (Test-Path $py) {
  New-Item -ItemType Directory -Force $cutDir, (Join-Path $root '_build\cutout-src') | Out-Null
  foreach ($j in $photoJobs | Where-Object { $_.cutout }) {
    $norm = Join-Path $root "_build\cutout-src\$($j.num).jpg"
    $png = Join-Path $cutDir "$($j.num).png"
    $key = Join-Path $cutDir "$($j.num).src"
    $stamp = "$($j.src)|$((Get-Item $j.src).LastWriteTimeUtc.Ticks)"
    if (-not (Test-Path $png) -or -not (Test-Path $key) -or ([IO.File]::ReadAllText($key, $utf8) -ne $stamp)) {
      if (Test-Path $norm) { Remove-Item $norm }
      Save-Resized $j.src $norm 1600
      $cutArgs += $norm, $png
      $cutKeys += [pscustomobject]@{ key = $key; stamp = $stamp }
    }
    $j.cut = $png
  }
  if ($cutArgs.Count) {
    & $py (Join-Path $root '_build\cutout.py') @cutArgs | Out-Null
    if ($LASTEXITCODE) { throw '背景の切り抜きに失敗しました' }
    foreach ($k in $cutKeys) { [IO.File]::WriteAllText($k.key, $k.stamp, $utf8) }
  }
}
# 透明な部分は Save-Resized で白になる
foreach ($j in $photoJobs) {
  $dst = Join-Path $playerOut "$($j.num).jpg"
  if (Test-Path $dst) { Remove-Item $dst }
  $s = if ($j.cut -and (Test-Path $j.cut)) { $j.cut } else { $j.src }
  Save-Resized $s $dst 1000
}
# 消された写真の書き出しを消す
if (Test-Path $playerOut) { Get-ChildItem $playerOut -File | Where-Object { -not $keepPlayers.ContainsKey($_.Name) } | Remove-Item }
$profileScript = @'
<script>
  (function () {
    var opener = null;
    Array.prototype.forEach.call(document.querySelectorAll('.member-open'), function (b) {
      b.addEventListener('click', function () {
        var d = document.getElementById(b.getAttribute('data-profile'));
        opener = b; d.showModal(); document.body.style.overflow = 'hidden';
      });
    });
    Array.prototype.forEach.call(document.querySelectorAll('dialog.profile'), function (d) {
      d.addEventListener('close', function () { document.body.style.overflow = ''; if (opener) opener.focus(); });
      d.addEventListener('click', function (e) { if (e.target === d) d.close(); });
      d.querySelector('.profile-close').addEventListener('click', function () { d.close(); });
    });
  })();
</script>
'@
$membersHtml = ($memberGroupsBy['society'] -join "`n`n      ")

# トップページのメンバー：部門ごとのタブで切り替え。各部門ポジションごとに1人（写真のある選手を優先、その中で得点の多い順）
$topTabs = @(); $topPanels = @()
foreach ($dv in $divisions) {
  $divPlayers = @($pdata.players | Where-Object { $d = if ($_.division) { $_.division } else { $pdata.defaultDivision }; $d -eq $dv.jp })
  $topMembers = foreach ($pos in $posNames.Keys) {
    $order = 0
    $p = @($divPlayers | Where-Object { $_.pos -eq $pos } | ForEach-Object { $_ | Add-Member -NotePropertyName _order -NotePropertyValue ($order++) -Force -PassThru } |
      Sort-Object @{ Expression = { $keepPlayers.ContainsKey("$($_.num)-play.jpg") -or $keepPlayers.ContainsKey("$($_.num).jpg") }; Descending = $true }, @{ Expression = { [int]$_.goals }; Descending = $true }, @{ Expression = { $_._order } }) | Select-Object -First 1
    if (-not $p) { continue }
    $kind = if ($pos -eq 'GK') { 'gk' } else { 'fp' }
    $posCls = if ($kind -eq 'gk') { 'pos gk' } else { 'pos' }
    $img = if ($keepPlayers.ContainsKey("$($p.num)-play.jpg")) { "<img class=`"is-play`" src=`"players/$($p.num)-play.jpg`" alt=`"$(Esc $p.name)`" loading=`"lazy`">" }
      elseif ($keepPlayers.ContainsKey("$($p.num).jpg")) { "<img src=`"players/$($p.num).jpg`" alt=`"$(Esc $p.name)`" loading=`"lazy`">" } else { '' }
    $note = "$($p.goals)ゴール" + $(if ($p.note) { '・' + $p.note } else { '' })
    "<a class=`"member`" href=`"$($dv.prefix)members.html`"><div class=`"member-photo $kind`">$img<span class=`"num`">$($p.num)</span></div><div class=`"member-info`"><span class=`"$posCls`">$pos</span><b>$(Esc $p.name)</b><span class=`"note`">$note</span></div></a>"
  }
  $first = $dv.key -eq 'society'
  $topTabs += "<button type=`"button`" role=`"tab`" class=`"ds ds-$($dv.key)`" id=`"tm-tab-$($dv.key)`" aria-controls=`"tm-$($dv.key)`" aria-selected=`"$(if ($first) { 'true' } else { 'false' })`"><b>$($dv.jp)</b><small>$($dv.en.ToUpper())</small></button>"
  $inner = if (@($topMembers).Count) { "<div class=`"members`">`n          $($topMembers -join "`n          ")`n        </div>" } else {
    "<div class=`"soon-box`"><p class=`"soon-tag`">COMING SOON</p><p class=`"soon-text`">$($dv.jp)のメンバーは、所属が決まりしだい掲載します。</p><div class=`"partner-cta`"><a class=`"btn btn-yellow`" href=`"recruit.html#$($dv.key)`">$($dv.jp)に応募する <span class=`"arrow`">→</span></a></div></div>"
  }
  $topPanels += "<div class=`"tm-panel`" role=`"tabpanel`" id=`"tm-$($dv.key)`" aria-labelledby=`"tm-tab-$($dv.key)`"$(if (-not $first) { ' hidden' })>`n        $inner`n        <p class=`"tm-more`"><a class=`"more`" href=`"$($dv.prefix)members.html`">View all <span class=`"jp`">$($dv.jp)の全メンバー</span></a></p>`n      </div>"
}
$topMembersHtml = @"
<div class="tm-tabs div-switch-links" role="tablist" aria-label="部門を選ぶ">$($topTabs -join '')</div>
      $($topPanels -join "`n      ")
      <script>
        (function () {
          var tabs = document.querySelectorAll('.tm-tabs [role=tab]');
          Array.prototype.forEach.call(tabs, function (t) {
            t.addEventListener('click', function () {
              Array.prototype.forEach.call(tabs, function (x) {
                var on = x === t;
                x.setAttribute('aria-selected', String(on));
                document.getElementById(x.getAttribute('aria-controls')).hidden = !on;
              });
            });
          });
        })();
      </script>
"@
# トップのカルーセル：中身は _data/slides.json に書く（上から順に表示）
$slideData = [IO.File]::ReadAllText((Join-Path $root '_data\slides.json'), $utf8) | ConvertFrom-Json
$slideNo = 0
$topSlides = foreach ($s in $slideData.slides) {
  # ページの最上部なので、最初の1枚だけはすぐ読み込む
  $load = if ($slideNo++ -eq 0) { 'eager' } else { 'lazy' }
  $text = if ($s.text) { "<span class=`"slide-text`">$(Esc $s.text)</span>" } else { '' }
  $cta = if ($s.cta) { "<span class=`"slide-more`">$(Esc $s.cta) <span class=`"arrow`">→</span></span>" } else { '' }
  "<a class=`"slide`" href=`"$(Esc $s.link)`"><img src=`"$(Esc $s.image)`" alt=`"`" loading=`"$load`" draggable=`"false`"><span class=`"slide-cap`"><small>$(Esc $s.kicker)</small><b>$(Esc $s.title)</b>$text$cta</span></a>"
}
$topSlidesHtml = ($topSlides -join "`n        ")
$membersExtra = ($profilesBy['society'] -join "`n") + "`n" + $profileScript

# ---------- 星取表（_data/results-4c.json）----------
# 行のチームから見た結果。○勝ち・×負け、SOはシュートアウト、不戦は不戦勝・不戦敗
$rt = [IO.File]::ReadAllText((Join-Path $root '_data\results-4c.json'), $utf8) | ConvertFrom-Json
$rtShort = @{ 'FC TRIDENT TOKYO' = 'TRIDENT'; 'PHLCO SC' = 'PHLCO'; 'South Tokyo FC' = 'South Tokyo'; 'Luana All Stars' = 'Luana'; '宮前スカーヴァティー' = '宮前'; 'WELL-BE SOCIETY' = 'WELL-BE'; 'CURIOCITY' = 'CURIOCITY'; 'FC.OXALA' = 'OXALA'; 'FC.全力de蹴球' = '全力de蹴球'; 'FC金沢' = '金沢'; 'Bachelors' = 'Bachelors'; 'CK UNITED' = 'CK UNITED' }
$rtHead = ($rt.order | ForEach-Object { $us = if ($_ -eq 'FC TRIDENT TOKYO') { ' class="us"' } else { '' }; "<th$us scope=`"col`"><img src=`"$($rt.logos.$_)`" alt=`"`"><span>$(Esc $rtShort[$_])</span></th>" }) -join ''
$rtRows = foreach ($row in $rt.order) {
  $cells = foreach ($col in $rt.order) {
    if ($row -eq $col) { '<td class="rt-self" aria-label="同じチーム"></td>'; continue }
    $m = $rt.matches | Where-Object { ($_.h -eq $row -and $_.a -eq $col) -or ($_.h -eq $col -and $_.a -eq $row) } | Select-Object -First 1
    if (-not $m) { '<td class="rt-none">－</td>'; continue }
    $isHome = $m.h -eq $row
    $my = if ($isHome) { $m.hs } else { $m.as }; $op = if ($isHome) { $m.as } else { $m.hs }
    $myso = if ($isHome) { $m.hso } else { $m.aso }; $opso = if ($isHome) { $m.aso } else { $m.hso }
    $win = if ($my -ne $op) { $my -gt $op } else { $myso -gt $opso }
    $mark = if ($win) { '○' } else { '×' }
    $cls = if ($win) { 'rt-w' } else { 'rt-l' }
    $note = ''
    if ($m.ff) { $note = if ($win) { '<small>不戦勝</small>' } else { '<small>不戦敗</small>' } }
    elseif ($my -eq $op) { $note = "<small>SO $myso-$opso</small>"; $cls += ' rt-so' }
    $us = if ($row -eq 'FC TRIDENT TOKYO' -or $col -eq 'FC TRIDENT TOKYO') { ' rt-us' } else { '' }
    "<td class=`"$cls$us`"><b>$mark</b><span>$my-$op</span>$note</td>"
  }
  $usRow = if ($row -eq 'FC TRIDENT TOKYO') { ' class="us"' } else { '' }
  "<tr$usRow><th scope=`"row`"><span class=`"tname`"><img src=`"$($rt.logos.$row)`" alt=`"`">$(Esc $row)</span></th>$($cells -join '')</tr>"
}
$resultsTableHtml = @"
<div class="table-scroll rt-scroll">
        <table class="results-table">
          <thead><tr><th class="rt-corner" scope="col">チーム ＼ 相手</th>$rtHead</tr></thead>
          <tbody>
            $($rtRows -join "`n            ")
          </tbody>
        </table>
      </div>
      <p class="src">左の列のチームから見た結果です。○＝勝ち、×＝負け、SO＝シュートアウト（同点のときのPK戦）。チームは順位の順に並んでいます。出典：<a href="https://football7society.jp/kanto/result/" target="_blank" rel="noopener">F7SL 関東リーグ 日程・結果</a>（$($rt.asOf)時点）</p>
"@

# ---------- 各ページを書き出す ----------
$pages = @('index.html') + ($nav | ForEach-Object { $_.file }) + @('privacy.html', '404.html')
foreach ($file in $pages) {
  if ($file -eq 'gallery.html') {
    Write-Page $file 'ギャラリー' $galleryBody $file $descs[$file]
    continue
  }
  if ($file -eq 'schedule.html') {
    Write-Page $file '活動日程' $scheduleBody $file $descs[$file]
    continue
  }
  $part = [IO.File]::ReadAllText((Join-Path $root "_parts\$file"), $utf8)
  if ($file -eq 'match.html') { $part = $part.Replace('<!--RESULTS_TABLE-->', $resultsTableHtml) }
  if ($file -eq 'index.html') { $part = $part.Replace('<!--TOP_MEMBERS-->', $topMembersHtml).Replace('<!--TOP_SLIDES-->', $topSlidesHtml) }
  if ($file -eq 'members.html') { $part = $part.Replace('<!--MEMBERS-->', $membersHtml).Replace('</main>', "</main>`n$membersExtra") }
  $m = [regex]::Match($part, '<!-- title: (.+?) -->')
  Write-Page $file $m.Groups[1].Value $part.Substring($m.Index + $m.Length).Trim() $file $descs[$file]
}

# ---------- サッカー部門・学生ソサイチ部門のページ ----------
# ソサイチと同じ作り。試合は _data/<部門>/matches.json（順位は同じファイルの standings）、写真は photos/<部門>/<日付>_<相手>/、
# 練習などは _data/schedule.json の events に "division": "<部門>" を付ける、選手は players.json の division で分ける
$league = @{
  football   = '東京都社会人サッカーリーグ（3部からスタート予定・正式決定前）'
  university = 'FOOTBALL 7 SOCIETY LEAGUE 関東リーグ（2027年から新チームとして参加）'
}
function Match-Card($m, $label, $isNext) {
  $d = [DateTime]::ParseExact($m.date, 'yyyy-MM-dd', $null)
  $logo = if ($m.logo) { "<img src=`"$($m.logo)`" alt=`"`">" } else { '' }
  if ($isNext) {
    $score = "<div class=`"score time`">$(if ($m.kickoff) { $m.kickoff } else { 'TBA' })<small>KICK OFF</small></div>"
    $foot = "<span>$($d.Month)月$($d.Day)日（$($days[[int]$d.DayOfWeek])）</span><span>$(Esc $m.venue)</span>"
  } else {
    $res = Res-Of $m
    $score = "<div class=`"score`">$($m.us)<span class=`"dash`">-</span>$($m.them)<small>$(if ($null -ne $m.soUs) { "SO $($m.soUs)-$($m.soThem)" } else { 'FULL TIME' })</small></div>"
    $foot = "<span class=`"res $($res[1])`">$($res[0])</span><span>$($d.Month)月$($d.Day)日（$($days[[int]$d.DayOfWeek])）</span><span>$(Esc $m.venue)</span>$(if ($m.scorers) { "<span>得点：$(Esc $m.scorers)</span>" })"
  }
  $cls = if ($isNext) { 'is-next' } else { 'is-last' }
  $lcls = if ($isNext) { 'match-label next' } else { 'match-label' }
  return @"
<article class="match $cls">
          <div class="match-top"><span class="$lcls">$label</span><span>$(RL $m)</span></div>
          <div class="vs">
            <div class="team"><span class="crest us"><img src="emblem.webp" alt=""></span>$(Esc $dv.name)</div>
            $score
            <div class="team"><span class="crest them">$logo</span>$(Esc $m.opponent)</div>
          </div>
          <div class="match-foot">$foot</div>
        </article>
"@
}
foreach ($dv in $divisions | Where-Object { $_.prefix }) {
  $pfx = $dv.prefix; $data = $dataBy[$dv.key]; $leagueLine = $leagueLineBy[$dv.key]
  $season = if ($data.season) { "$($data.season)シーズン" } else { '2027シーズン' }
  $ms = @($data.matches | Where-Object { $_ })
  $nextM = $ms | Where-Object { $null -eq $_.us -and $_.date -ge (Get-Date).ToString('yyyy-MM-dd') } | Sort-Object date | Select-Object -First 1
  $lastM = $ms | Where-Object { $null -ne $_.us } | Sort-Object date -Descending | Select-Object -First 1
  $cardsHtml = @()
  if ($nextM) { $cardsHtml += Match-Card $nextM 'NEXT MATCH' $true }
  if ($lastM) { $cardsHtml += Match-Card $lastM 'LAST RESULT' $false }
  $cardsSec = if ($cardsHtml.Count) { "<div class=`"matches`">`n        $($cardsHtml -join "`n        ")`n      </div>" } else {
    "<div class=`"soon-box`"><p class=`"soon-tag`">COMING SOON</p><p class=`"soon-text`">$season の日程・結果は、リーグの発表後に掲載します。</p><dl class=`"facts`"><dt>所属リーグ</dt><dd>$($league[$dv.key])</dd></dl><div class=`"partner-cta`"><a class=`"btn btn-yellow`" href=`"recruit.html#$($dv.key)`">$($dv.jp)に応募する <span class=`"arrow`">→</span></a><a class=`"btn btn-line`" href=`"teams.html#$($dv.key)`">部門の紹介 <span class=`"arrow`">→</span></a></div></div>"
  }
  $rows = foreach ($m in ($ms | Sort-Object date -Descending)) {
    $d = [DateTime]::ParseExact($m.date, 'yyyy-MM-dd', $null)
    $logo = if ($m.logo) { "<img src=`"$($m.logo)`" alt=`"`">" } else { '' }
    if ($null -ne $m.us) {
      $res = Res-Of $m
      $sc = "$($m.us) - $($m.them)$(So-Text $m)"
    } else { $res = $(if ($m.date -lt (Get-Date).ToString('yyyy-MM-dd')) { '終了', 'n' } else { '予定', 'n' }); $sc = '-' }
    "<tr><td>$($m.round)</td><td>$($d.ToString('MM/dd'))</td><td>$(if ($m.kickoff) { $m.kickoff } else { '-' })</td><td class=`"txt`"><span class=`"tname`">$logo$(Esc $m.opponent)</span></td><td>$(if ($m.ha) { $m.ha } else { '-' })</td><td class=`"txt`">$(Esc $m.venue)</td><td>$sc</td><td><span class=`"res $($res[1])`">$($res[0])</span></td></tr>"
  }
  $schedTable = if (@($rows).Count) { @"
<div class="table-scroll">
        <table class="schedule">
          <thead><tr><th>節</th><th>日付</th><th>KO</th><th class="txt">対戦相手</th><th>H/A</th><th class="txt">会場</th><th>スコア</th><th>結果</th></tr></thead>
          <tbody>
            $($rows -join "`n            ")
          </tbody>
        </table>
      </div>
      <p class="src">スコアは左が$(Esc $dv.name)の得点です。H＝ホーム、A＝アウェイ。</p>
"@ } else { '<p class="ev-empty">日程はリーグの発表後に掲載します。</p>' }
  $stRows = foreach ($s in @($data.standings | Where-Object { $_ })) {
    $us = if ($s.us) { ' class="us"' } else { '' }
    $logo = if ($s.us) { '<img src="emblem.webp" alt="">' } elseif ($s.logo) { "<img src=`"$($s.logo)`" alt=`"`">" } else { '' }
    "<tr$us><td>$($s.rank)</td><td class=`"txt`"><span class=`"tname`">$logo$(Esc $s.team)</span></td><td>$($s.p)</td><td>$($s.w)</td><td>$($s.d)</td><td>$($s.l)</td><td>$($s.gf)</td><td>$($s.ga)</td><td>$('{0:+0;-0;0}' -f ([int]$s.gf - [int]$s.ga))</td><td class=`"pts`">$($s.pts)</td></tr>"
  }
  $stTable = if (@($stRows).Count) { @"
<div class="table-scroll">
        <table class="standings">
          <thead><tr><th>順位</th><th class="txt">チーム</th><th>試合</th><th>勝</th><th>分</th><th>負</th><th>得点</th><th>失点</th><th>得失点</th><th>勝点</th></tr></thead>
          <tbody>
            $($stRows -join "`n            ")
          </tbody>
        </table>
      </div>
"@ } else { '<p class="ev-empty">順位はシーズンが始まってから掲載します。</p>' }
  $matchBody = @"
<main>
  <section class="page-head">
    <div class="wrap">
      $(Div-Head $dv 'Match' '試合情報')
      <p class="lead">$(if ($leagueLine) { Esc $leagueLine } else { $league[$dv.key] })の日程・結果と順位です。</p>
    </div>
  </section>

  <section class="sec">
    <div class="wrap">
      $cardsSec
    </div>
  </section>

  <section class="sec">
    <div class="wrap">
      <div class="sec-head"><div><p class="eyebrow">Schedule</p><h2>$season 日程・結果</h2></div><a class="more" href="$($pfx)schedule.html">Schedule <span class="jp">活動日程を見る</span></a></div>
      $schedTable
    </div>
  </section>

  <section class="sec">
    <div class="wrap">
      <div class="sec-head"><div><p class="eyebrow">Standings</p><h2>$season 順位</h2></div></div>
      $stTable
    </div>
  </section>
</main>
"@
  Write-Page "$($pfx)match.html" "試合情報（$($dv.jp)）" $matchBody "$($pfx)match.html" "$($dv.name)の試合情報（日程・結果・順位）です。"

  Write-Page "$($pfx)schedule.html" "活動日程（$($dv.jp)）" $scheduleBodyBy[$dv.key] "$($pfx)schedule.html" "$($dv.name)の公式戦・練習の日程です。"

  $groups = $memberGroupsBy[$dv.key]
  $membersSec = if ($groups.Count) { $groups -join "`n`n      " } else {
    "<div class=`"soon-box`"><p class=`"soon-tag`">COMING SOON</p><p class=`"soon-text`">$season のメンバーは、所属が決まりしだい掲載します。選手のカードを押すと、プロフィールが見られるようになります。</p><div class=`"partner-cta`"><a class=`"btn btn-yellow`" href=`"recruit.html#$($dv.key)`">$($dv.jp)に応募する <span class=`"arrow`">→</span></a><a class=`"btn btn-line`" href=`"teams.html#$($dv.key)`">部門の紹介 <span class=`"arrow`">→</span></a></div></div>"
  }
  $memBody = @"
<main>
  <section class="page-head">
    <div class="wrap">
      $(Div-Head $dv 'Members' 'メンバー')
      <p class="lead">$($dv.jp)で戦う選手とスタッフです。</p>
    </div>
  </section>

  <section class="sec">
    <div class="wrap">
      $membersSec
    </div>
  </section>
</main>
$($profilesBy[$dv.key] -join "`n")
$profileScript
"@
  Write-Page "$($pfx)members.html" "メンバー（$($dv.jp)）" $memBody "$($pfx)members.html" "$($dv.name)のメンバーです。"

  Write-Page "$($pfx)gallery.html" "ギャラリー（$($dv.jp)）" $galleryBodyBy[$dv.key] "$($pfx)gallery.html" "$($dv.name)の試合ごとの写真アルバムです。"

  $pages += "$($pfx)match.html", "$($pfx)schedule.html", "$($pfx)members.html", "$($pfx)gallery.html"
}
# ---------- サイトマップと robots.txt ----------
$today = (Get-Date).ToString('yyyy-MM-dd')
$urls = @($pages | Where-Object { $_ -ne '404.html' }) + @($divisions | ForEach-Object { $withPhotosBy[$_.key] | ForEach-Object { $_.page } })
$sitemap = "<?xml version=`"1.0`" encoding=`"UTF-8`"?>`n<urlset xmlns=`"http://www.sitemaps.org/schemas/sitemap/0.9`">`n" +
  (($urls | ForEach-Object { $u = if ($_ -eq 'index.html') { $siteUrl } else { $siteUrl + $_ }; "  <url><loc>$u</loc><lastmod>$today</lastmod></url>" }) -join "`n") + "`n</urlset>`n"
[IO.File]::WriteAllText((Join-Path $root 'sitemap.xml'), $sitemap, $utf8)
[IO.File]::WriteAllText((Join-Path $root 'robots.txt'), "User-agent: *`nAllow: /`n`nSitemap: ${siteUrl}sitemap.xml`n", $utf8)
Write-Output "built sitemap.xml ($($urls.Count) urls)"

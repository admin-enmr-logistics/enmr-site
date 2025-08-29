Param(
  [string]$Audio = "mouse-click-290204.mp3"
)

$audioPath = Join-Path (Get-Location) $Audio
if (-not (Test-Path $audioPath)) {
  Write-Warning "Audio file '$Audio' not found in repo root. Place it in the repo folder and re-run."
}

$cssBlock = @'
<!-- ENMR nav click CSS OVERRIDE START -->
<style id="nav-click-override">
  /* Keep pointer on hover, but NO color change on hover */
  .nav-button:hover { background-color: var(--button-brown) !important; cursor: pointer; }
  /* Show lighter brown ONLY while the mouse is pressed */
  .nav-button:active { background-color: var(--button-hover) !important; }
</style>
<!-- ENMR nav click CSS OVERRIDE END -->
'@

$jsBlock = @'
<!-- ENMR nav click AUDIO+JS START -->
<audio id="navClickSound" preload="auto">
  <source src="mouse-click-290204.mp3" type="audio/mpeg">
</audio>
<script>
  (function () {
    var audio = document.getElementById('navClickSound');
    if (!audio) return;
    var buttons = document.querySelectorAll('.navbar .nav-button');
    buttons.forEach(function (btn) {
      btn.addEventListener('click', function () {
        try {
          audio.currentTime = 0;
          audio.play().catch(function(){});
        } catch (e) {}
      });
    });
  })();
</script>
<!-- ENMR nav click AUDIO+JS END -->
'@

Get-ChildItem -Path . -Filter *.html -File -Recurse | ForEach-Object {
  $path = $_.FullName
  $html = Get-Content $path -Raw

  # ----- CSS override: replace existing block or insert before </head>
  if ($html -match '<!-- ENMR nav click CSS OVERRIDE START -->') {
    $html = [regex]::Replace(
      $html,
      '(?s)<!-- ENMR nav click CSS OVERRIDE START -->.*?<!-- ENMR nav click CSS OVERRIDE END -->',
      [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $cssBlock }
    )
  } elseif ($html -match '</head>') {
    $html = $html -replace '</head>', ($cssBlock + "`r`n</head>")
  } else {
    $html = $cssBlock + "`r`n" + $html
  }

  # ----- Audio + JS: replace existing block or insert before </body>
  if ($html -match '<!-- ENMR nav click AUDIO\+JS START -->') {
    $html = [regex]::Replace(
      $html,
      '(?s)<!-- ENMR nav click AUDIO\+JS START -->.*?<!-- ENMR nav click AUDIO\+JS END -->',
      [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $jsBlock }
    )
  } elseif ($html -match '</body>') {
    $html = $html -replace '</body>', ($jsBlock + "`r`n</body>")
  } else {
    $html += "`r`n" + $jsBlock
  }

  Set-Content -Path $path -Value $html -Encoding utf8
  Write-Host "Patched $path"
}

Write-Host "Done. (If you used a different audio file name, re-run: .\patch-nav-click.ps1 -Audio '<yourfile>.mp3')"

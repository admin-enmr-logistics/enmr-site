Param([string[]]$Files)

$start = '<!-- ENMR legal footer START -->'
$end   = '<!-- ENMR legal footer END -->'

$footerBlock = @'
<!-- ENMR legal footer START -->
<footer style="text-align:center; padding:16px 12px; border-top:1px solid black;">
  &copy; 2025 ENMR Logistics LLC |
  <a href="terms.html" onclick="return openLegalPopup(this.href)" rel="noopener">Terms &amp; Conditions</a> |
  <a href="privacy.html" onclick="return openLegalPopup(this.href)" rel="noopener">Privacy Policy</a>
</footer>

<script>
  function openLegalPopup(url) {
    window.open(url,'enmrLegal','width=920,height=700,scrollbars=yes,resizable=yes');
    return false;
  }
</script>

<noscript>
  <div style="text-align:center; padding:8px 0;">
    <a href="terms.html" target="_blank" rel="noopener">Terms &amp; Conditions</a> |
    <a href="privacy.html" target="_blank" rel="noopener">Privacy Policy</a>
  </div>
</noscript>
<!-- ENMR legal footer END -->
'@

function Inject-Footer($path) {
  if (-not (Test-Path $path)) { return }
  if ($path -match '(?i)(^|[\\/])(terms|privacy)\.html$') { return } # skip legal pages

  $html = Get-Content $path -Raw

  if ($html -match [regex]::Escape($start)) {
    $pattern = '(?s)<!-- ENMR legal footer START -->.*?<!-- ENMR legal footer END -->'
    $html = [regex]::Replace($html, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $footerBlock })
  }
  elseif ($html -match '</body>') {
    $html = $html -replace '</body>', "$footerBlock`r`n</body>"
  }
  else {
    $html = $html + "`r`n$footerBlock"
  }

  Set-Content -Path $path -Value $html -Encoding utf8
  Write-Host "Injected/updated footer in $path"
}

if ($Files -and $Files.Count) {
  foreach ($f in $Files) { Inject-Footer $f }
} else {
  Get-ChildItem -Path . -Filter *.html -File -Recurse |
    Where-Object { $_.Name -notmatch '^(terms|privacy)\.html$' } |
    ForEach-Object { Inject-Footer $_.FullName }
}

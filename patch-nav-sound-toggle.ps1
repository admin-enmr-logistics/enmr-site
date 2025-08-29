# Adds/updates a click-sound toggle and sets volume on all *.html pages.
# Idempotent: replaces between <!-- NAV SOUND START --> and <!-- NAV SOUND END -->
$block = @'
<!-- NAV SOUND START -->
<button id="soundToggle" class="sound-toggle" aria-label="Toggle navigation click sound" title="Toggle sound">
  <svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true">
    <!-- speaker -->
    <path d="M3 10v4h4l5 4V6l-5 4H3z" fill="currentColor"></path>
    <!-- X when muted -->
    <path id="muteX" d="M16 9l5 5m0-5l-5 5" stroke="currentColor" stroke-width="2" fill="none" style="display:none"></path>
  </svg>
</button>

<audio id="navClickAudio" preload="auto">
  <source src="mouse-click-290204.mp3" type="audio/mpeg">
</audio>

<style>
  .sound-toggle{
    position:fixed; right:10px; top:10px; z-index:1000;
    background:var(--button-brown); color:#fff; border:2px solid #000;
    width:36px; height:36px; border-radius:6px;
    display:flex; align-items:center; justify-content:center; cursor:pointer;
  }
  .sound-toggle:hover{ background:var(--button-hover); }
  .sound-toggle.muted{ opacity:0.7; }
</style>

<script>
(function(){
  var audio = document.getElementById('navClickAudio');
  if(!audio){
    audio = document.createElement('audio');
    audio.id = 'navClickAudio';
    audio.preload = 'auto';
    var s = document.createElement('source');
    s.src = 'mouse-click-290204.mp3'; s.type = 'audio/mpeg';
    audio.appendChild(s);
    document.body.appendChild(audio);
  }

  // 🔉 Set your preferred loudness here (0.0 - 1.0)
  audio.volume = 0.5;

  var btn = document.getElementById('soundToggle');
  if(!btn){
    btn = document.createElement('button');
    btn.id = 'soundToggle';
    btn.className = 'sound-toggle';
    btn.setAttribute('aria-label','Toggle navigation click sound');
    btn.title = 'Toggle sound';
    btn.innerHTML = '<svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true"><path d="M3 10v4h4l5 4V6l-5 4H3z" fill="currentColor"></path><path id="muteX" d="M16 9l5 5m0-5l-5 5" stroke="currentColor" stroke-width="2" fill="none" style="display:none"></path></svg>';
    document.body.appendChild(btn);
  }

  function updateIcon(){
    var x = btn.querySelector('#muteX');
    if(x) x.style.display = audio.muted ? 'block' : 'none';
    btn.classList.toggle('muted', audio.muted);
    btn.setAttribute('aria-pressed', (!audio.muted).toString());
  }

  // Persist user preference
  var stored = localStorage.getItem('muteNav') === '1';
  audio.muted = stored;
  updateIcon();

  btn.addEventListener('click', function(e){
    e.preventDefault();
    audio.muted = !audio.muted;
    localStorage.setItem('muteNav', audio.muted ? '1' : '0');
    updateIcon();
  });

  // Play only for top nav buttons
  document.querySelectorAll('.nav-button').forEach(function(a){
    a.addEventListener('click', function(){
      if(audio.muted) return;
      try { audio.currentTime = 0; audio.play(); } catch(e){}
    }, {capture:true});
  });
})();
</script>
<!-- NAV SOUND END -->
'@

$pages = Get-ChildItem -Path . -Filter *.html -File -Recurse
foreach ($p in $pages) {
  $html = Get-Content $p.FullName -Raw

  if ($html -match '(?s)<!-- NAV SOUND START -->.*?<!-- NAV SOUND END -->') {
    $html = [regex]::Replace($html, '(?s)<!-- NAV SOUND START -->.*?<!-- NAV SOUND END -->', $block)
  }
  else {
    if ($html -match '</body>') {
      $html = $html -replace '</body>', ($block + "`r`n</body>")
    } else {
      $html += "`r`n" + $block
    }
  }

  Set-Content -Path $p.FullName -Value $html -Encoding utf8
  Write-Host "Updated $($p.Name)"
}

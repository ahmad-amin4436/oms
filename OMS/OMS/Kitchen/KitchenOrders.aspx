<%@ Page Title="Kitchen" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true"
   CodeBehind="KitchenOrders.aspx.cs" Inherits="OMS.Kitchen.KitchenOrders" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">

  <style>
    .kt-card { border-left: 5px solid #00d27a; transition: opacity .25s, transform .25s; }
    .kt-card.kt-warn   { border-left-color: #f5803e; }
    .kt-card.kt-late   { border-left-color: #e63757; }
    .kt-card.kt-new    { animation: ktflash 1.6s ease-out 1; }
    .kt-card.kt-leaving{ opacity: 0; transform: scale(.96); }
    .kt-qty  { font-size: 1.6rem; font-weight: 700; line-height: 1; }
    .kt-name { font-size: 1.15rem; font-weight: 600; }
    @keyframes ktflash { 0% { box-shadow: 0 0 0 4px rgba(44,123,229,.55); } 100% { box-shadow: 0 0 0 0 rgba(44,123,229,0); } }
  </style>

  <div class="d-flex flex-wrap align-items-center justify-content-between gap-2 mb-3">
    <div>
      <h4 class="mb-0">Kitchen</h4>
      <p class="text-600 fs--1 mb-0">Dishes being prepared. Press <strong>Done</strong> when a dish is ready; it disappears from the list.</p>
    </div>
    <div class="d-flex align-items-center gap-3 fs--1">
      <label class="mb-0 d-flex align-items-center gap-1"><input type="checkbox" id="ktSound" checked /> Sound for new dishes</label>
      <span id="ktStatus" class="badge badge-subtle-secondary">Connecting...</span>
    </div>
  </div>

  <%-- Category filter (built from the dishes currently on the screen) --%>
  <div id="ktCats" class="d-flex flex-wrap gap-2 mb-3"></div>

  <div id="ktGrid" class="row g-3"></div>
  <div id="ktEmpty" class="card d-none"><div class="card-body text-center text-600 py-5">
    <span class="fas fa-check-circle fs-3 text-success d-block mb-2"></span>Nothing to prepare right now.
  </div></div>

  <script>
    (function () {
      var FEED = '<%= FeedUrl %>';
      var POLL_MS = 3000, POLL_HIDDEN_MS = 10000, WARN_MIN = 10, LATE_MIN = 20;

      var items = [], known = {}, justDone = {}, firstLoad = true, cat = 'all', fetchedAt = Date.now();
      var grid = document.getElementById('ktGrid'), cats = document.getElementById('ktCats');
      var empty = document.getElementById('ktEmpty'), status = document.getElementById('ktStatus');
      var soundBox = document.getElementById('ktSound');
      try { var s = localStorage.getItem('ktSound'); if (s !== null) soundBox.checked = s === '1'; } catch (e) {}
      soundBox.addEventListener('change', function () { try { localStorage.setItem('ktSound', soundBox.checked ? '1' : '0'); } catch (e) {} });

      function esc(v) { return String(v == null ? '' : v).replace(/[&<>"']/g, function (c) { return ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'})[c]; }); }
      function ageMin(it) { return Math.floor((it.ageSec + (Date.now() - fetchedAt) / 1000) / 60); }

      function beep() {                                    // short two-tone beep; silently skipped if the browser blocks audio
        try {
          var ctx = new (window.AudioContext || window.webkitAudioContext)();
          [880, 1175].forEach(function (f, i) {
            var o = ctx.createOscillator(), g = ctx.createGain();
            o.frequency.value = f; o.connect(g); g.connect(ctx.destination);
            g.gain.setValueAtTime(0.15, ctx.currentTime + i * 0.18);
            o.start(ctx.currentTime + i * 0.18); o.stop(ctx.currentTime + i * 0.18 + 0.15);
          });
        } catch (e) {}
      }

      function renderCats() {
        var counts = {}, order = [];
        items.forEach(function (it) { if (!(it.catId in counts)) { counts[it.catId] = { name: it.cat, n: 0 }; order.push(it.catId); } counts[it.catId].n++; });
        if (cat !== 'all' && !(cat in counts)) cat = 'all';           // the chosen category has nothing left: show everything
        var html = chip('all', 'All', items.length);
        order.forEach(function (id) { html += chip(String(id), counts[id].name, counts[id].n); });
        cats.innerHTML = html;
      }
      function chip(id, name, n) {
        var on = String(cat) === id;
        return '<button type="button" class="btn btn-sm ' + (on ? 'btn-primary' : 'btn-falcon-default') + '" data-cat="' + id + '">' +
               esc(name) + ' <span class="badge ' + (on ? 'bg-light text-primary' : 'badge-subtle-secondary') + ' ms-1">' + n + '</span></button>';
      }

      function render(newIds) {
        renderCats();
        var shown = items.filter(function (it) { return cat === 'all' || String(it.catId) === String(cat); });
        grid.innerHTML = shown.map(function (it) {
          var m = ageMin(it), cls = m >= LATE_MIN ? 'kt-late' : m >= WARN_MIN ? 'kt-warn' : '';
          var where = it.type === 'DineIn' && it.table ? 'Table ' + esc(it.table) : esc(it.type === 'DineIn' ? 'Dine in' : it.type);
          return '<div class="col-sm-6 col-lg-4 col-xxl-3" data-id="' + it.id + '"><div class="card kt-card h-100 ' + cls + (newIds && newIds[it.id] ? ' kt-new' : '') + '">' +
            '<div class="card-body d-flex flex-column">' +
              '<div class="d-flex justify-content-between align-items-start mb-2">' +
                '<div><div class="fw-bold">' + where + '</div><div class="fs--2 text-600">' + esc(it.orderNo) + '</div></div>' +
                '<span class="badge ' + (m >= LATE_MIN ? 'badge-subtle-danger' : m >= WARN_MIN ? 'badge-subtle-warning' : 'badge-subtle-success') + '">' + m + ' min</span>' +
              '</div>' +
              '<div class="d-flex align-items-center gap-3 mb-2"><span class="kt-qty text-primary">' + it.qty + '&times;</span>' +
                '<div><div class="kt-name">' + esc(it.name) + '</div>' +
                (it.size ? '<div class="fs--1 text-600">' + esc(it.size) + '</div>' : '') + '</div></div>' +
              (it.note ? '<div class="alert alert-warning py-1 px-2 fs--1 mb-2">' + esc(it.note) + '</div>' : '') +
              '<div class="fs--2 text-600 mb-2">' + esc(it.cat) + '</div>' +
              '<button type="button" class="btn btn-success mt-auto" data-done="' + it.id + '">Done</button>' +
            '</div></div></div>';
        }).join('');
        empty.classList.toggle('d-none', items.length !== 0);
      }

      // Done: remove the dish from the screen at once, tell the server in the background.
      grid.addEventListener('click', function (e) {
        var b = e.target.closest('button[data-done]');
        if (!b) return;
        var id = parseInt(b.getAttribute('data-done'), 10);
        b.disabled = true;
        var col = b.closest('[data-id]');
        if (col) col.firstChild.classList.add('kt-leaving');
        justDone[id] = true;                               // stays hidden even if a refresh already in flight still lists it
        items = items.filter(function (it) { return it.id !== id; });
        setTimeout(function () { render(); }, 220);
        fetch(FEED, {
          method: 'POST', credentials: 'same-origin',
          headers: { 'X-Requested-With': 'XMLHttpRequest', 'Content-Type': 'application/x-www-form-urlencoded' },
          body: 'done=' + id
        }).then(function (r) { if (!r.ok) throw new Error(r.status); poll(true); })
          .catch(function () { delete justDone[id]; setStatus('Could not save "Done" - checking again...', 'danger'); poll(true); });   // the next refresh re-shows it if it was not saved
      });
      cats.addEventListener('click', function (e) {
        var b = e.target.closest('button[data-cat]');
        if (!b) return;
        cat = b.getAttribute('data-cat');
        render();
      });

      function setStatus(text, kind) { status.textContent = text; status.className = 'badge badge-subtle-' + kind; }

      var timer = null, inFlight = false;
      function poll(now) {
        if (inFlight) return;
        inFlight = true;
        clearTimeout(timer);
        fetch(FEED, { credentials: 'same-origin', cache: 'no-store', headers: { 'X-Requested-With': 'XMLHttpRequest' } })
          .then(function (r) {
            if (r.status === 401) { setStatus('Signed out - please sign in again', 'danger'); throw new Error('401'); }
            if (!r.ok) throw new Error(r.status);
            return r.json();
          })
          .then(function (d) {
            var listed = {};
            (d.items || []).forEach(function (it) { listed[it.id] = true; });
            Object.keys(justDone).forEach(function (k) { if (!listed[k]) delete justDone[k]; });   // the server has caught up
            items = (d.items || []).filter(function (it) { return !justDone[it.id]; }); fetchedAt = Date.now();
            var fresh = {}, any = false;
            items.forEach(function (it) { if (!known[it.id]) { known[it.id] = true; if (!firstLoad) { fresh[it.id] = true; any = true; } } });
            render(fresh);
            if (any && soundBox.checked) beep();
            firstLoad = false;
            setStatus('Live - ' + new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' }), 'success');
          })
          .catch(function () { if (status.textContent.indexOf('Signed out') !== 0) setStatus('Reconnecting...', 'warning'); })
          .then(function () { inFlight = false; timer = setTimeout(poll, document.hidden ? POLL_HIDDEN_MS : POLL_MS); });
      }
      document.addEventListener('visibilitychange', function () { if (!document.hidden) poll(); });
      setInterval(function () { if (items.length) render(); }, 30000);    // keep the "minutes waiting" fresh between refreshes
      poll();
    })();
  </script>
</asp:Content>

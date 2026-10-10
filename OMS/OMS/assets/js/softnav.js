/*
  OMS in-app navigation ("soft navigation").

  Clicking a link to another screen fetches that screen in the background and swaps ONLY the content area
  (#softRoot). The menu, header, theme scripts and the Ajax framework stay alive, so moving between screens
  does not rebuild the whole page. Web Forms state travels with the swap: the new screen's hidden fields
  (ViewState / EventValidation), form action, UpdatePanel registrations and scripts.

  Anything that looks unsafe falls back to an ordinary page load, so the worst case is the old behaviour:
    - login / logout / access-denied, redirects, non-HTML or error responses
    - the dashboard (its charts start on window "load", which cannot be replayed)
    - a screen whose scripts wait for DOMContentLoaded / window load
    - any exception while swapping
  Opt a link out with data-no-soft. Links that open a new tab or use a modifier key are left alone.

  A screen that starts timers or listeners can register window.__pageCleanup = function () { ... };
  it is called before the screen is replaced.
*/
(function () {
  'use strict';
  if (!window.fetch || !window.DOMParser || !window.history || !history.pushState || !window.Sys) return;

  var ROOT_ID = 'softRoot', TAIL_ID = 'softTail';
  var NO_SOFT_TARGET = /\/(Login|Logout|AccessDenied|Default|Dashboard)\.aspx$/i;     // always a full load
  var NO_SOFT_SOURCE = /\/(Login|AccessDenied|Default|Dashboard)\.aspx$/i;           // leaving these is a full load too
  var UNSAFE_SCRIPT = /DOMContentLoaded|window\.onload|addEventListener\(\s*['"]load['"]/;
  // Web Forms writes a screen's validation/submit scripts near the top of the form, outside the content area.
  var FORM_SCRIPT = /WebForm_OnSubmit|Page_Validators|Page_ValidationActive|Page_ValidationSummaries|ValidatorOnLoad|WebForm_AutoFocus/;
  var HIDDEN = ['__EVENTTARGET', '__EVENTARGUMENT', '__LASTFOCUS', '__VIEWSTATE', '__VIEWSTATEGENERATOR',
                '__VIEWSTATEENCRYPTED', '__EVENTVALIDATION', '__PREVIOUSPAGE'];
  var busy = false;
  var lastKey = location.pathname + location.search;

  // The menu, logo and bell are rendered once, with links relative to the page they were first served from
  // ("Default.aspx", "../Orders/OrderList.aspx"). After the address changes to another folder those would point
  // at the wrong place (e.g. /Orders/Default.aspx), so turn them into root-relative paths while they still match.
  function absolutize(scope) {
    [].forEach.call(scope.querySelectorAll('a[href]'), function (a) {
      var h = a.getAttribute('href');
      if (!h || h.charAt(0) === '#' || /^([a-z][a-z0-9+.\-]*:|\/)/i.test(h)) return;
      try { var u = new URL(a.href, location.href); a.setAttribute('href', u.pathname + u.search + u.hash); } catch (e) {}
    });
  }
  absolutize(document);

  function bar() { return document.getElementById('ajaxBar'); }
  function progress(on) {
    var b = bar(); if (!b) return;
    if (on) { b.style.opacity = '1'; b.style.width = '70%'; document.body.style.cursor = 'progress'; }
    else { b.style.width = '100%'; document.body.style.cursor = ''; setTimeout(function () { b.style.opacity = '0'; b.style.width = '0'; }, 250); }
  }
  function hardGo(url) { window.location.href = url; }

  // ------------------------------------------------------------------ click handling
  document.addEventListener('click', function (e) {
    if (e.defaultPrevented || e.button !== 0 || e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return;
    var a = e.target.closest ? e.target.closest('a[href]') : null;
    if (!a) return;
    if ((a.target && a.target !== '_self') || a.hasAttribute('download') || a.hasAttribute('data-no-soft')) return;
    var raw = a.getAttribute('href');
    if (!raw || raw.charAt(0) === '#' || /^(javascript|mailto|tel):/i.test(raw)) return;
    var u;
    try { u = new URL(a.href, location.href); } catch (err) { return; }
    if (u.origin !== location.origin || !/\.aspx$/i.test(u.pathname) || NO_SOFT_TARGET.test(u.pathname)) return;
    if (NO_SOFT_SOURCE.test(location.pathname) || !document.getElementById(ROOT_ID)) return;
    if (u.pathname + u.search === location.pathname + location.search) { e.preventDefault(); return; }   // already here
    e.preventDefault();
    navigate(u.href, true);
  });

  window.addEventListener('popstate', function () {
    var key = location.pathname + location.search;
    if (key === lastKey) return;                                  // only the #hash changed
    if (busy || NO_SOFT_TARGET.test(location.pathname) || NO_SOFT_SOURCE.test(lastKey.split('?')[0])) { hardGo(location.href); return; }
    navigate(location.href, false);
  });

  // ------------------------------------------------------------------ the swap
  function navigate(url, push) {
    if (busy) return;
    busy = true; progress(true);
    var requested = new URL(url, location.href);
    fetch(requested.href, { credentials: 'same-origin', headers: { 'X-Requested-With': 'XMLHttpRequest', 'Accept': 'text/html' } })
      .then(function (res) {
        var ct = res.headers.get('Content-Type') || '';
        var landed = new URL(res.url);
        if (!res.ok || ct.indexOf('text/html') === -1 || landed.pathname.toLowerCase() !== requested.pathname.toLowerCase()) return null;
        return res.text();
      })
      .then(function (html) {
        if (html === null) { hardGo(requested.href); return; }
        var doc = new DOMParser().parseFromString(html, 'text/html');
        var plan = plan_(doc);
        if (!plan) { hardGo(requested.href); return; }
        return swap(doc, plan, requested.href, push);
      })
      .catch(function (err) {
        if (window.console) console.warn('Soft navigation failed; loading the page normally.', err);
        hardGo(requested.href);
      })
      .then(function () { busy = false; progress(false); });
  }

  // Decide whether the fetched screen can be swapped in, and what has to be run for it.
  function plan_(doc) {
    var root = doc.getElementById(ROOT_ID), tail = doc.getElementById(TAIL_ID);
    var form = document.forms[0], nform = doc.forms[0];
    if (!root || !tail || !form || !nform) return null;
    var plan = { root: root, nform: nform, externals: [], inline: [], prm: null };
    var seen = {};
    [].forEach.call(document.scripts, function (s) { if (s.src) seen[s.src] = true; });

    [].forEach.call(nform.querySelectorAll('script'), function (s) {
      if (s.src) {                                                  // e.g. validation scripts a screen needs
        var abs = new URL(s.getAttribute('src'), location.href).href;
        if (!seen[abs]) { seen[abs] = true; plan.externals.push(abs); }
        return;
      }
      var text = s.textContent || '';
      var m = text.match(/Sys\.WebForms\.PageRequestManager\._initialize\(([^;]*)\)\s*;/);
      if (m) { plan.prm = m[1]; return; }                           // ScriptManager's panel registration (handled below)
      var inRoot = root.contains(s);
      var afterTail = !!(tail.compareDocumentPosition(s) & Node.DOCUMENT_POSITION_FOLLOWING) && !root.contains(s);
      if (inRoot || afterTail || FORM_SCRIPT.test(text)) { plan.inline.push(text); }
    });
    for (var i = 0; i < plan.inline.length; i++) if (UNSAFE_SCRIPT.test(plan.inline[i])) return null;
    return plan;
  }

  function syncHidden(form, nform) {
    var holder = form.querySelector('.aspNetHidden') || form;
    HIDDEN.forEach(function (name) {
      var n = nform.querySelector('input[name="' + name + '"]');
      var c = form.querySelector('input[name="' + name + '"]');
      if (n) {
        if (c) c.value = n.value;
        else { var i = document.createElement('input'); i.type = 'hidden'; i.name = name; i.id = name; i.value = n.value; holder.appendChild(i); }
      } else if (c && name !== '__EVENTTARGET' && name !== '__EVENTARGUMENT' && name !== '__LASTFOCUS') {
        c.parentNode.removeChild(c);
      }
    });
    ['__EVENTTARGET', '__EVENTARGUMENT'].forEach(function (name) { var c = form.querySelector('input[name="' + name + '"]'); if (c) c.value = ''; });
  }

  function loadExternals(list) {
    return list.reduce(function (p, src) {
      return p.then(function () {
        return new Promise(function (resolve) {
          var s = document.createElement('script'); s.src = src; s.onload = resolve; s.onerror = resolve; document.body.appendChild(s);
        });
      });
    }, Promise.resolve());
  }

  function runInline(list) {
    list.forEach(function (text) {
      var s = document.createElement('script'); s.text = text;
      document.body.appendChild(s); document.body.removeChild(s);           // executes synchronously, in order
    });
  }

  function syncChrome(doc) {
    // The notification bell is rendered per request: take the fresh copy.
    var mine = [].filter.call(document.querySelectorAll('li.nav-item.dropdown'), function (li) { return li.querySelector('#navbarDropdownNotification'); });
    var theirs = [].filter.call(doc.querySelectorAll('li.nav-item.dropdown'), function (li) { return li.querySelector('#navbarDropdownNotification'); });
    mine.forEach(function (li, i) { if (theirs[i]) { li.innerHTML = theirs[i].innerHTML; absolutize(li); } });

    // Menu highlight follows the current screen.
    var path = location.pathname.toLowerCase();
    var navs = document.querySelectorAll('#navbarVerticalNav, [data-top-nav-dropdowns]');
    [].forEach.call(navs, function (nav) {
      [].forEach.call(nav.querySelectorAll('a[href]'), function (a) {
        var h = a.getAttribute('href');
        if (!h || h.charAt(0) === '#' || /^javascript/i.test(h)) return;
        var p; try { p = new URL(a.href, location.href).pathname.toLowerCase(); } catch (e) { return; }
        a.classList.toggle('active', p === path);
      });
      [].forEach.call(nav.querySelectorAll('a[data-bs-toggle]'), function (t) {
        var panel = t.nextElementSibling;
        if (!panel) return;
        var has = !!panel.querySelector('a.active');
        t.classList.toggle('active', has);
        if (has && panel.classList.contains('collapse')) panel.classList.add('show');
      });
    });
  }

  function swap(doc, plan, url, push) {
    var form = document.forms[0], root = document.getElementById(ROOT_ID);

    if (typeof window.__pageCleanup === 'function') { try { window.__pageCleanup(); } catch (e) {} }
    window.__pageCleanup = null;
    try { Sys.Application.disposeElement(root, true); } catch (e) {}

    syncHidden(form, plan.nform);
    var onsubmit = plan.nform.getAttribute('onsubmit');                 // present when the screen has validators
    if (onsubmit) form.setAttribute('onsubmit', onsubmit); else form.removeAttribute('onsubmit');
    if (push) history.pushState({ soft: 1 }, '', url);
    lastKey = location.pathname + location.search;
    form.setAttribute('action', plan.nform.getAttribute('action'));     // './Page.aspx': resolves against the new URL
    document.title = doc.title;

    root.innerHTML = plan.root.innerHTML;
    syncChrome(doc);

    // Tell the Ajax framework which UpdatePanels / controls this screen has.
    if (plan.prm) {
      var a = (new Function('return [' + plan.prm + ']'))();            // [scriptManagerId, formId, panels, async, postback, timeout, separator]
      Sys.WebForms.PageRequestManager.getInstance()._updateControls(a[2], a[3], a[4], a[5], a[6]);
    }

    return loadExternals(plan.externals).then(function () {
      runInline(plan.inline);
      try { if (Sys.Application.raiseLoad) Sys.Application.raiseLoad(); } catch (e) {}
      if (window.bootstrap && bootstrap.Tooltip) {
        [].forEach.call(root.querySelectorAll('[data-bs-toggle="tooltip"]'), function (el) { try { new bootstrap.Tooltip(el); } catch (e) {} });
      }
      window.scrollTo(0, 0);
      if (window.OmsExport) { try { OmsExport.scan(); } catch (e) {} }
    });
  }
})();

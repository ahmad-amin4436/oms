/*
  OMS table export: every data table gets an "Export" button. The user ticks the columns to include and
  downloads them as Excel (.xlsx) or PDF. Nothing is sent to the server: the file is built in the browser
  from the rows currently shown in the table.

  Opt a table out with data-no-export. Action columns (empty header or "Actions") start unticked.
  The column choice is remembered per screen and table.
*/
(function () {
  'use strict';
  var STORE = 'omsExportCols:';

  // ------------------------------------------------------------------ reading a table
  function clean(t) { return String(t == null ? '' : t).replace(/[\u0000-\u0008\u000B\u000C\u000E-\u001F]/g, '').replace(/\s+/g, ' ').trim(); }

  function readTable(table) {
    var rows = [].slice.call(table.rows);
    var headRow = null, i;
    for (i = 0; i < rows.length; i++) { if (rows[i].querySelector('th')) { headRow = rows[i]; break; } }
    if (!headRow) return null;
    var heads = [].map.call(headRow.cells, function (c) { return clean(c.innerText || c.textContent); });
    if (!heads.length) return null;
    var data = [];
    rows.forEach(function (r) {
      if (r === headRow || r.querySelector('th') || r.cells.length !== heads.length) return;   // pager / empty-data / sub rows
      if (r.offsetParent === null && r.getClientRects().length === 0) return;                  // hidden rows
      data.push([].map.call(r.cells, function (c) { return clean(c.innerText || c.textContent); }));
    });
    return { heads: heads, rows: data };
  }

  function titleFor(table) {
    var card = table.closest('.card');
    var h = card && card.querySelector('.card-header h5, .card-header h6, .card-header h4');
    var t = h ? clean(h.textContent) : '';
    var page = document.querySelector('#softRoot h4, #softRoot h3, h4');
    var pt = page ? clean(page.textContent) : clean(document.title);
    if (t && pt && t.toLowerCase() !== pt.toLowerCase()) return pt + ' - ' + t;
    return t || pt || 'Export';
  }

  // ------------------------------------------------------------------ Excel (.xlsx, no library)
  var CRC = (function () { var t = [], c, n, k; for (n = 0; n < 256; n++) { c = n; for (k = 0; k < 8; k++) c = c & 1 ? 0xEDB88320 ^ (c >>> 1) : c >>> 1; t[n] = c >>> 0; } return t; })();
  function crc32(b) { var c = 0xFFFFFFFF; for (var i = 0; i < b.length; i++) c = CRC[(c ^ b[i]) & 255] ^ (c >>> 8); return (c ^ 0xFFFFFFFF) >>> 0; }
  function utf8(s) { return new TextEncoder().encode(s); }

  function zipStore(files) {                                       // files: [{ name, data: Uint8Array }]
    var parts = [], central = [], offset = 0;
    files.forEach(function (f) {
      var name = utf8(f.name), crc = crc32(f.data), size = f.data.length;
      var lh = new DataView(new ArrayBuffer(30));
      lh.setUint32(0, 0x04034b50, true); lh.setUint16(4, 20, true); lh.setUint16(6, 0x0800, true); lh.setUint16(8, 0, true);
      lh.setUint16(10, 0, true); lh.setUint16(12, 33, true); lh.setUint32(14, crc, true); lh.setUint32(18, size, true);
      lh.setUint32(22, size, true); lh.setUint16(26, name.length, true); lh.setUint16(28, 0, true);
      parts.push(new Uint8Array(lh.buffer), name, f.data);
      var ch = new DataView(new ArrayBuffer(46));
      ch.setUint32(0, 0x02014b50, true); ch.setUint16(4, 20, true); ch.setUint16(6, 20, true); ch.setUint16(8, 0x0800, true);
      ch.setUint16(10, 0, true); ch.setUint16(12, 0, true); ch.setUint16(14, 33, true); ch.setUint32(16, crc, true);
      ch.setUint32(20, size, true); ch.setUint32(24, size, true); ch.setUint16(28, name.length, true);
      ch.setUint32(42, offset, true);
      central.push(new Uint8Array(ch.buffer), name);
      offset += 30 + name.length + size;
    });
    var cdSize = central.reduce(function (n, p) { return n + p.length; }, 0);
    var end = new DataView(new ArrayBuffer(22));
    end.setUint32(0, 0x06054b50, true); end.setUint16(8, files.length, true); end.setUint16(10, files.length, true);
    end.setUint32(12, cdSize, true); end.setUint32(16, offset, true);
    return new Blob(parts.concat(central, [new Uint8Array(end.buffer)]),
      { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' });
  }

  function xmlEsc(s) { return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;'); }
  function colName(i) { var s = ''; i++; while (i > 0) { var m = (i - 1) % 26; s = String.fromCharCode(65 + m) + s; i = Math.floor((i - 1) / 26); } return s; }
  function asNumber(t) {
    if (!/^(Rs\.?\s*)?-?\d{1,3}(,\d{3})*(\.\d+)?$|^(Rs\.?\s*)?-?\d+(\.\d+)?$/i.test(t)) return null;
    if (/^0\d/.test(t)) return null;                                // phone numbers, codes
    return Number(t.replace(/^Rs\.?\s*/i, '').replace(/,/g, ''));
  }

  function buildXlsx(title, heads, rows) {
    var widths = heads.map(function (h, c) {
      var m = h.length; rows.forEach(function (r) { if (r[c].length > m) m = r[c].length; });
      return Math.min(60, Math.max(8, m + 2));
    });
    var x = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">' +
      '<sheetViews><sheetView workbookViewId="0"><pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews><cols>';
    widths.forEach(function (w, i) { x += '<col min="' + (i + 1) + '" max="' + (i + 1) + '" width="' + w + '" customWidth="1"/>'; });
    x += '</cols><sheetData><row r="1">';
    heads.forEach(function (h, c) { x += '<c r="' + colName(c) + '1" s="1" t="inlineStr"><is><t xml:space="preserve">' + xmlEsc(h) + '</t></is></c>'; });
    x += '</row>';
    rows.forEach(function (r, ri) {
      x += '<row r="' + (ri + 2) + '">';
      r.forEach(function (v, c) {
        var ref = colName(c) + (ri + 2), n = asNumber(v);
        x += n !== null ? '<c r="' + ref + '"><v>' + n + '</v></c>'
                        : '<c r="' + ref + '" t="inlineStr"><is><t xml:space="preserve">' + xmlEsc(v) + '</t></is></c>';
      });
      x += '</row>';
    });
    x += '</sheetData></worksheet>';
    var sheetName = xmlEsc(title.replace(/[\[\]:*?\/\\]/g, ' ').slice(0, 31) || 'Sheet1');
    var f = [
      { name: '[Content_Types].xml', data: utf8('<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/><Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/></Types>') },
      { name: '_rels/.rels', data: utf8('<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>') },
      { name: 'xl/workbook.xml', data: utf8('<?xml version="1.0" encoding="UTF-8" standalone="yes"?><workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="' + sheetName + '" sheetId="1" r:id="rId1"/></sheets></workbook>') },
      { name: 'xl/_rels/workbook.xml.rels', data: utf8('<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>') },
      { name: 'xl/styles.xml', data: utf8('<?xml version="1.0" encoding="UTF-8" standalone="yes"?><styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><fonts count="2"><font><sz val="11"/><name val="Calibri"/></font><font><b/><sz val="11"/><name val="Calibri"/></font></fonts><fills count="3"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill><fill><patternFill patternType="solid"><fgColor rgb="FFE9ECEF"/></patternFill></fill></fills><borders count="1"><border/></borders><cellStyleXfs count="1"><xf/></cellStyleXfs><cellXfs count="2"><xf/><xf fontId="1" fillId="2" applyFont="1" applyFill="1"/></cellXfs></styleSheet>') },
      { name: 'xl/worksheets/sheet1.xml', data: utf8(x) }
    ];
    return zipStore(f);
  }

  // ------------------------------------------------------------------ PDF (built-in Helvetica, no library)
  function latin(s) { return String(s).replace(/[‘’]/g, "'").replace(/[“”]/g, '"').replace(/[–—]/g, '-')
    .replace(/…/g, '...').replace(/ /g, ' ').replace(/[^\x20-\x7E\xA0-\xFF]/g, '?'); }
  function pdfEsc(s) { return latin(s).replace(/\\/g, '\\\\').replace(/\(/g, '\\(').replace(/\)/g, '\\)'); }

  function wrap(text, maxChars, maxLines) {
    var words = text.split(' '), lines = [], cur = '';
    words.forEach(function (w) {
      while (w.length > maxChars) {                                   // a single long token
        if (cur) { lines.push(cur); cur = ''; }
        lines.push(w.slice(0, maxChars)); w = w.slice(maxChars);
      }
      if (!cur) cur = w;
      else if ((cur + ' ' + w).length <= maxChars) cur += ' ' + w;
      else { lines.push(cur); cur = w; }
    });
    if (cur || !lines.length) lines.push(cur);
    if (lines.length > maxLines) { lines = lines.slice(0, maxLines); lines[maxLines - 1] = lines[maxLines - 1].slice(0, Math.max(0, maxChars - 3)) + '...'; }
    return lines;
  }

  function buildPdf(title, heads, rows) {
    var landscape = heads.length > 5;
    var W = landscape ? 842 : 595, H = landscape ? 595 : 842, M = 28, FS = 8, LH = 10.5, PAD = 3, CW = FS * 0.55;
    var avail = W - M * 2;
    var weights = heads.map(function (h, c) {
      var m = h.length; rows.forEach(function (r) { if (r[c].length > m) m = r[c].length; });
      return Math.min(40, Math.max(5, m)) + 2;
    });
    var tw = weights.reduce(function (a, b) { return a + b; }, 0);
    var colW = weights.map(function (w) { return w / tw * avail; });
    var maxChars = colW.map(function (w) { return Math.max(3, Math.floor((w - PAD * 2) / CW)); });

    var pages = [], cur = null, y = 0;
    function newPage() { cur = []; pages.push(cur); y = H - M; if (pages.length === 1) {
        cur.push('BT /F2 14 Tf ' + M + ' ' + (y - 12) + ' Td (' + pdfEsc(title) + ') Tj ET');
        cur.push('BT /F1 8 Tf 0.4 g ' + M + ' ' + (y - 26) + ' Td (' + pdfEsc('Generated ' + new Date().toLocaleString() + '   |   ' + rows.length + ' row' + (rows.length === 1 ? '' : 's')) + ') Tj ET 0 g');
        y -= 38; }
      drawHeader(); }
    function drawHeader() {
      var lines = heads.map(function (h, c) { return wrap(h, maxChars[c], 2); });
      var hh = Math.max.apply(null, lines.map(function (l) { return l.length; })) * LH + 4;
      cur.push('0.91 g ' + M + ' ' + (y - hh) + ' ' + avail + ' ' + hh + ' re f 0 g');
      var x = M;
      lines.forEach(function (l, c) {
        l.forEach(function (t, i) { cur.push('BT /F2 ' + FS + ' Tf ' + (x + PAD) + ' ' + (y - 9 - i * LH) + ' Td (' + pdfEsc(t) + ') Tj ET'); });
        x += colW[c];
      });
      y -= hh;
    }
    newPage();
    rows.forEach(function (r) {
      var cells = r.map(function (v, c) { return wrap(v, maxChars[c], 6); });
      var rh = Math.max.apply(null, cells.map(function (l) { return l.length; })) * LH + 4;
      if (y - rh < M + 14) newPage();
      var x = M;
      cells.forEach(function (l, c) {
        l.forEach(function (t, i) { cur.push('BT /F1 ' + FS + ' Tf ' + (x + PAD) + ' ' + (y - 9 - i * LH) + ' Td (' + pdfEsc(t) + ') Tj ET'); });
        x += colW[c];
      });
      y -= rh;
      cur.push('0.85 G 0.4 w ' + M + ' ' + y + ' m ' + (M + avail) + ' ' + y + ' l S 0 G');
    });
    pages.forEach(function (p, i) {
      p.push('BT /F1 8 Tf 0.4 g ' + (W - M - 70) + ' ' + (M - 10) + ' Td (' + pdfEsc('Page ' + (i + 1) + ' of ' + pages.length) + ') Tj ET 0 g');
    });

    var objs = [];                                                    // object bodies, 1-based ids = index + 1
    objs.push('<< /Type /Catalog /Pages 2 0 R >>');
    var kids = pages.map(function (_, i) { return (5 + i * 2) + ' 0 R'; }).join(' ');
    objs.push('<< /Type /Pages /Kids [' + kids + '] /Count ' + pages.length + ' >>');
    objs.push('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>');
    objs.push('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>');
    pages.forEach(function (p, i) {
      var stream = p.join('\n');
      objs.push('<< /Type /Page /Parent 2 0 R /MediaBox [0 0 ' + W + ' ' + H + '] /Resources << /Font << /F1 3 0 R /F2 4 0 R >> >> /Contents ' + (6 + i * 2) + ' 0 R >>');
      objs.push('<< /Length ' + stream.length + ' >>\nstream\n' + stream + '\nendstream');
    });
    var out = '%PDF-1.4\n', offs = [];
    objs.forEach(function (o, i) { offs.push(out.length); out += (i + 1) + ' 0 obj\n' + o + '\nendobj\n'; });
    var xref = out.length;
    out += 'xref\n0 ' + (objs.length + 1) + '\n0000000000 65535 f \n';
    offs.forEach(function (o) { out += ('0000000000' + o).slice(-10) + ' 00000 n \n'; });
    out += 'trailer\n<< /Size ' + (objs.length + 1) + ' /Root 1 0 R >>\nstartxref\n' + xref + '\n%%EOF';
    var bytes = new Uint8Array(out.length);
    for (var i = 0; i < out.length; i++) bytes[i] = out.charCodeAt(i) & 255;
    return new Blob([bytes], { type: 'application/pdf' });
  }

  // ------------------------------------------------------------------ download + UI
  function save(blob, name) {
    var a = document.createElement('a'), url = URL.createObjectURL(blob);
    a.href = url; a.download = name; a.style.display = 'none';
    document.body.appendChild(a); a.click();
    setTimeout(function () { document.body.removeChild(a); URL.revokeObjectURL(url); }, 1500);
  }
  function fileBase(title) {
    var d = new Date(), p = function (n) { return ('0' + n).slice(-2); };
    return (title.replace(/[^\w\- ]+/g, '').trim().replace(/\s+/g, '_').slice(0, 60) || 'export') + '_' +
           d.getFullYear() + p(d.getMonth() + 1) + p(d.getDate()) + '_' + p(d.getHours()) + p(d.getMinutes());
  }

  function esc(s) { return String(s).replace(/[&<>"']/g, function (c) { return ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]; }); }
  function isAction(h) { return !h || /^actions?$/i.test(h); }

  function attach(table, index) {
    if (table.getAttribute('data-exp') || table.hasAttribute('data-no-export')) return;
    if (table.closest('nav, header, .navbar, .modal, [data-no-export]')) return;
    if (table.querySelector('table')) return;                         // layout table with real tables inside
    var info = readTable(table);
    if (!info || info.heads.length < 2 || !info.rows.length) return;       // nothing to export yet
    table.setAttribute('data-exp', '1');

    var key = STORE + location.pathname.toLowerCase() + '#' + index + ':' + info.heads.join('|');
    var wrapEl = table.closest('.table-responsive') || table;
    var bar = document.createElement('div');
    bar.className = 'd-flex justify-content-end px-3 pt-2 position-relative';
    bar.setAttribute('data-exp-bar', '1');
    bar.innerHTML = '<button type="button" class="btn btn-sm btn-falcon-default" data-exp-open>' +
      '<span class="fas fa-file-export me-1"></span>Export</button>' +
      '<div class="card shadow position-absolute d-none" data-exp-panel style="top:100%;right:1rem;z-index:1050;min-width:240px;max-width:90vw;">' +
      '<div class="card-body p-3"><div class="fw-semibold fs--1 mb-2">Columns to export</div>' +
      '<div data-exp-cols style="max-height:240px;overflow:auto"></div>' +
      '<div class="fs--2 mb-2 mt-1"><a href="#" data-exp-all data-no-soft>All</a> &middot; <a href="#" data-exp-none data-no-soft>None</a></div>' +
      '<div class="d-flex gap-2"><button type="button" class="btn btn-sm btn-success flex-fill" data-exp-do="xlsx"><span class="fas fa-file-excel me-1"></span>Excel</button>' +
      '<button type="button" class="btn btn-sm btn-danger flex-fill" data-exp-do="pdf"><span class="fas fa-file-pdf me-1"></span>PDF</button></div>' +
      '<div class="fs--2 text-600 mt-2" data-exp-msg></div></div></div>';
    wrapEl.parentNode.insertBefore(bar, wrapEl);

    var panel = bar.querySelector('[data-exp-panel]'), list = bar.querySelector('[data-exp-cols]'), msg = bar.querySelector('[data-exp-msg]');

    function buildList() {
      var cur = readTable(table) || info, saved = null;
      try { saved = JSON.parse(localStorage.getItem(key)); } catch (e) {}
      list.innerHTML = cur.heads.map(function (h, c) {
        var on = saved && saved.length === cur.heads.length ? !!saved[c] : !isAction(h);
        return '<label class="d-flex align-items-center gap-2 fs--1 mb-1"><input type="checkbox" class="form-check-input mt-0" data-c="' + c + '"' +
               (on ? ' checked' : '') + '><span>' + esc(h || '(no title)') + '</span></label>';
      }).join('');
      msg.textContent = cur.rows.length + ' row' + (cur.rows.length === 1 ? '' : 's') + ' shown in this table.';
    }
    function picked() { return [].map.call(list.querySelectorAll('input'), function (i) { return i.checked; }); }
    function remember() { try { localStorage.setItem(key, JSON.stringify(picked())); } catch (e) {} }

    bar.addEventListener('click', function (e) {
      var t = e.target;
      if (t.closest('[data-exp-open]')) { buildList(); panel.classList.toggle('d-none'); return; }
      if (t.closest('[data-exp-all]'))  { e.preventDefault(); [].forEach.call(list.querySelectorAll('input'), function (i) { i.checked = true; }); remember(); return; }
      if (t.closest('[data-exp-none]')) { e.preventDefault(); [].forEach.call(list.querySelectorAll('input'), function (i) { i.checked = false; }); remember(); return; }
      var go = t.closest('[data-exp-do]');
      if (!go) return;
      var cur = readTable(table);
      if (!cur) { msg.textContent = 'This table is no longer available.'; return; }
      var sel = picked(), idx = [];
      cur.heads.forEach(function (_, c) { if (sel[c]) idx.push(c); });
      if (!idx.length) { msg.textContent = 'Tick at least one column.'; return; }
      var heads = idx.map(function (c) { return cur.heads[c] || 'Column ' + (c + 1); });
      var rows = cur.rows.map(function (r) { return idx.map(function (c) { return r[c]; }); });
      var title = titleFor(table);
      try {
        if (go.getAttribute('data-exp-do') === 'xlsx') save(buildXlsx(title, heads, rows), fileBase(title) + '.xlsx');
        else save(buildPdf(title, heads, rows), fileBase(title) + '.pdf');
        msg.textContent = 'Downloaded ' + rows.length + ' row' + (rows.length === 1 ? '' : 's') + '.';
        remember();
      } catch (err) { msg.textContent = 'Export failed: ' + err.message; }
    });
    list.addEventListener('change', remember);
  }

  document.addEventListener('click', function (e) {                   // click elsewhere closes any open panel
    [].forEach.call(document.querySelectorAll('[data-exp-panel]:not(.d-none)'), function (p) {
      if (!p.parentNode.contains(e.target)) p.classList.add('d-none');
    });
  });

  function scan() {
    var root = document.getElementById('softRoot') || document.body;
    // an UpdatePanel refresh replaces a table together with its bar; drop bars whose table is gone
    [].forEach.call(root.querySelectorAll('[data-exp-bar]'), function (b) {
      var n = b.nextElementSibling;
      if (!n || !(n.matches('table[data-exp]') || n.querySelector('table[data-exp]'))) b.parentNode.removeChild(b);
    });
    [].forEach.call(root.querySelectorAll('table'), function (t, i) { try { attach(t, i); } catch (e) {} });
  }

  window.OmsExport = { scan: scan };
  scan();
  try {
    if (window.Sys && Sys.WebForms && Sys.WebForms.PageRequestManager) {
      Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function () { setTimeout(scan, 0); });
    }
  } catch (e) {}
})();

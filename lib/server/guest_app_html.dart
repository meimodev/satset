// The guest self-order SPA (ADR-0027 / ADR-0029), served verbatim by the
// cleartext guest plane for any unmatched GET. Single self-contained file:
// inline CSS + vanilla JS, **no** external fonts/CDNs/frameworks, so it loads
// instantly over a LAN with no internet. Talks JSON to `/guest/*`.
//
// Kept as a raw triple-quoted string so `$` (none used) and quotes pass
// through untouched. Edit the markup here directly.
const String guestAppHtml = r'''<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
<title>Pesan Mandiri</title>
<style>
  :root { --brown:#4A3728; --cream:#FBF9F4; --line:#e7e0d4; --accent:#7a5c43; --ok:#3f7d4e; --warn:#b0772a; }
  * { box-sizing:border-box; -webkit-tap-highlight-color:transparent; }
  body { margin:0; font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;
    background:var(--cream); color:var(--brown); padding-bottom:84px; }
  header { position:sticky; top:0; background:var(--cream); border-bottom:1px solid var(--line);
    padding:14px 16px; z-index:5; }
  header h1 { margin:0; font-size:18px; }
  header .sub { font-size:13px; opacity:.7; margin-top:2px; }
  .cats { display:flex; gap:8px; overflow-x:auto; padding:10px 16px; position:sticky; top:62px;
    background:var(--cream); z-index:4; border-bottom:1px solid var(--line); }
  .cats button { white-space:nowrap; border:1px solid var(--line); background:#fff; color:var(--brown);
    padding:6px 12px; border-radius:16px; font-size:13px; }
  .cats button.on { background:var(--brown); color:#fff; border-color:var(--brown); }
  .item { display:flex; gap:12px; padding:12px 16px; border-bottom:1px solid var(--line); align-items:center; }
  .item img { width:56px; height:56px; border-radius:8px; object-fit:cover; background:#eee; flex:0 0 auto; }
  .item .body { flex:1; min-width:0; }
  .item .name { font-weight:600; font-size:15px; }
  .item .desc { font-size:12px; opacity:.65; margin-top:2px;
    overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
  .item .price { font-size:13px; margin-top:4px; }
  .item .add { border:0; background:var(--brown); color:#fff; width:34px; height:34px;
    border-radius:17px; font-size:20px; flex:0 0 auto; }
  .catlabel { padding:14px 16px 4px; font-size:13px; font-weight:700; opacity:.55; text-transform:uppercase; }
  .bar { position:fixed; left:0; right:0; bottom:0; background:var(--brown); color:#fff;
    padding:16px; display:none; align-items:center; justify-content:space-between; }
  .bar.show { display:flex; }
  .bar b { font-size:16px; }
  .bar button { border:0; background:#fff; color:var(--brown); font-weight:700; padding:12px 20px; border-radius:10px; }
  .sheet-bg { position:fixed; inset:0; background:rgba(0,0,0,.4); display:none; z-index:10; }
  .sheet-bg.show { display:block; }
  .sheet { position:fixed; left:0; right:0; bottom:0; background:var(--cream); border-radius:16px 16px 0 0;
    max-height:88vh; overflow:auto; padding:18px 16px 110px; transform:translateY(100%); transition:transform .2s; }
  .sheet.show { transform:translateY(0); }
  .sheet h2 { margin:0 0 4px; font-size:18px; }
  .grp { margin-top:16px; } .grp .gh { font-weight:700; font-size:14px; margin-bottom:6px; }
  .grp .req { color:var(--warn); font-size:12px; font-weight:600; }
  .opt { display:flex; align-items:center; justify-content:space-between; padding:10px 0; border-bottom:1px solid var(--line); }
  .opt label { display:flex; gap:10px; align-items:center; }
  textarea { width:100%; border:1px solid var(--line); border-radius:8px; padding:8px; font-family:inherit; margin-top:6px; }
  .qtyrow { display:flex; align-items:center; gap:16px; margin-top:18px; }
  .qtyrow button { width:38px; height:38px; border-radius:19px; border:1px solid var(--brown); background:#fff;
    color:var(--brown); font-size:20px; }
  .sheetcta { position:fixed; left:0; right:0; bottom:0; padding:14px 16px; background:var(--cream);
    border-top:1px solid var(--line); }
  .sheetcta button { width:100%; border:0; background:var(--brown); color:#fff; padding:15px;
    border-radius:10px; font-weight:700; font-size:16px; }
  .center { text-align:center; padding:60px 24px; }
  .center .big { font-size:42px; margin-bottom:12px; }
  .pill { display:inline-block; padding:4px 10px; border-radius:12px; font-size:12px; font-weight:600; }
  .pill.pendingReview { background:#efe7d8; color:var(--warn); }
  .pill.sent, .pill.prep, .pill.cooked { background:#e0ece2; color:var(--ok); }
  .pill.ready, .pill.served { background:#dCeAdd; color:var(--ok); }
  .pill.voided { background:#f0dcd8; color:#9a3b2c; }
  .linkbtn { background:none; border:0; color:var(--accent); text-decoration:underline; font-size:14px; margin-top:20px; }
  .err { color:#9a3b2c; padding:16px; text-align:center; }
</style>
</head>
<body>
<div id="app"><div class="center">Memuat…</div></div>

<script>
"use strict";
var TOKEN=null, TABLE=null, MENU=null, CART=[], CURRENT=null, SHEETSEL={}, SHEETQTY=1, IDEM=null;

function rp(n){ return "Rp " + (n||0).toLocaleString("id-ID"); }
function el(id){ return document.getElementById(id); }
function tableIdFromUrl(){
  var m = location.pathname.match(/\/t\/([^\/]+)/);
  return m ? decodeURIComponent(m[1]) : null;
}
function api(method, path, body){
  var h = {};
  if (TOKEN) h["authorization"] = "Bearer " + TOKEN;
  if (body) h["content-type"] = "application/json";
  return fetch(path, { method:method, headers:h, body: body?JSON.stringify(body):undefined })
    .then(function(r){ return r.json().then(function(j){ return {ok:r.ok, status:r.status, body:j}; }); });
}

function start(){
  TABLE = tableIdFromUrl();
  if(!TABLE){ document.getElementById("app").innerHTML='<div class="err">QR tidak valid.</div>'; return; }
  api("POST", "/guest/session?table="+encodeURIComponent(TABLE)).then(function(r){
    if(!r.ok){ return sessionError(r.body && r.body.code); }
    TOKEN = r.body.token;
    TABLE = { id:r.body.tableId, label:r.body.tableLabel };
    loadMenu();
  });
}
function sessionError(code){
  var msg = "Pemesanan mandiri tidak tersedia di meja ini.";
  if(code==="guest_ordering_disabled") msg="Pemesanan mandiri belum diaktifkan. Silakan panggil pramusaji.";
  if(code==="table_disabled") msg="Meja ini belum mengaktifkan pesan mandiri. Silakan panggil pramusaji.";
  document.getElementById("app").innerHTML='<div class="center"><div class="big">🔔</div>'+msg+'</div>';
}

function loadMenu(){
  api("GET", "/guest/menu").then(function(r){
    if(!r.ok){ return sessionError(); }
    MENU = r.body; renderMenu(MENU.categories[0] && MENU.categories[0].id);
  });
}

function renderMenu(activeCat){
  var cats = MENU.categories, items = MENU.items;
  var html = '<header><h1>Menu</h1><div class="sub">Meja '+esc(TABLE.label)+'</div></header>';
  html += '<div class="cats">';
  cats.forEach(function(c){
    html += '<button class="'+(c.id===activeCat?"on":"")+'" onclick="renderMenu(\''+c.id+'\')">'+esc(c.name)+'</button>';
  });
  html += '</div>';
  cats.forEach(function(c){
    var its = items.filter(function(i){ return i.categoryId===c.id; });
    if(!its.length) return;
    html += '<div class="catlabel" id="cat_'+c.id+'">'+esc(c.name)+'</div>';
    its.forEach(function(i){ html += itemRow(i); });
  });
  document.getElementById("app").innerHTML = html;
  if(activeCat){ var t=document.getElementById("cat_"+activeCat); if(t) t.scrollIntoView({behavior:"smooth",block:"start"}); }
  loadPhotos(items);
  renderBar();
}
function itemRow(i){
  var price = i.variants && i.variants.length ? (i.variants[0].price) : i.basePrice;
  var prefix = i.variants && i.variants.length ? "mulai " : "";
  return '<div class="item">'
    + '<img data-item="'+i.id+'" alt="">'
    + '<div class="body"><div class="name">'+esc(i.name)+'</div>'
    + (i.description?'<div class="desc">'+esc(i.description)+'</div>':'')
    + '<div class="price">'+prefix+rp(price)+'</div></div>'
    + '<button class="add" onclick="openItem(\''+i.id+'\')">+</button></div>';
}
function loadPhotos(items){
  items.forEach(function(i){
    if(!i.photoRev) return;
    fetch("/guest/menu/photo/"+i.id, {headers:{authorization:"Bearer "+TOKEN}})
      .then(function(r){ return r.ok?r.blob():null; })
      .then(function(b){ if(!b) return; var u=URL.createObjectURL(b);
        var img=document.querySelector('img[data-item="'+i.id+'"]'); if(img) img.src=u; });
  });
}

function openItem(id){
  CURRENT = MENU.items.find(function(i){ return i.id===id; });
  SHEETSEL = { variantId:null, options:{} };
  SHEETQTY = 1;
  if(CURRENT.variants && CURRENT.variants.length) SHEETSEL.variantId = CURRENT.variants[0].id;
  renderSheet();
  el("sbg").classList.add("show"); el("sheet").classList.add("show");
}
function closeSheet(){ el("sbg").classList.remove("show"); el("sheet").classList.remove("show"); }

function renderSheet(){
  var i = CURRENT, h = '<h2>'+esc(i.name)+'</h2>';
  if(i.description) h += '<div class="desc" style="white-space:normal">'+esc(i.description)+'</div>';
  if(i.variants && i.variants.length){
    h += '<div class="grp"><div class="gh">Pilihan <span class="req">wajib</span></div>';
    i.variants.forEach(function(v){
      h += '<div class="opt"><label><input type="radio" name="variant" '
        +(SHEETSEL.variantId===v.id?"checked":"")+' onchange="pickVariant(\''+v.id+'\')"> '+esc(v.name)+'</label>'
        +'<span>'+rp(v.price)+'</span></div>';
    });
    h += '</div>';
  }
  (i.modifierGroups||[]).forEach(function(g){
    h += '<div class="grp"><div class="gh">'+esc(g.name)+(g.required?' <span class="req">wajib</span>':'')+'</div>';
    (g.options||[]).forEach(function(o){
      var type = g.multi?"checkbox":"radio";
      var checked = (SHEETSEL.options[g.id]||[]).indexOf(o.id)>=0;
      h += '<div class="opt"><label><input type="'+type+'" name="g_'+g.id+'" '+(checked?"checked":"")
        +' onchange="pickOpt(\''+g.id+'\',\''+o.id+'\','+(g.multi?"true":"false")+')"> '+esc(o.name)+'</label>'
        +'<span>'+(o.priceDelta?(o.priceDelta>0?"+":"")+rp(o.priceDelta):"")+'</span></div>';
    });
    h += '</div>';
  });
  h += '<div class="grp"><div class="gh">Catatan</div><textarea id="note" maxlength="140" placeholder="mis. tidak pedas"></textarea></div>';
  h += '<div class="qtyrow"><button onclick="bumpQty(-1)">−</button><b id="qv">'+SHEETQTY+'</b><button onclick="bumpQty(1)">+</button></div>';
  el("sheetbody").innerHTML = h;
  el("addcta").textContent = "Tambah · " + rp(linePrice());
}
function pickVariant(id){ SHEETSEL.variantId=id; renderSheet(); }
function pickOpt(gid, oid, multi){
  var cur = SHEETSEL.options[gid] || [];
  if(multi){ var idx=cur.indexOf(oid); if(idx>=0) cur.splice(idx,1); else cur.push(oid); }
  else { cur = [oid]; }
  SHEETSEL.options[gid] = cur; renderSheet();
}
function bumpQty(d){ SHEETQTY=Math.max(1,Math.min(99,SHEETQTY+d)); renderSheet(); }
function linePrice(){
  var base = CURRENT.basePrice;
  if(SHEETSEL.variantId){ var v=CURRENT.variants.find(function(x){return x.id===SHEETSEL.variantId;}); if(v) base=v.price; }
  var d=0;
  (CURRENT.modifierGroups||[]).forEach(function(g){
    (SHEETSEL.options[g.id]||[]).forEach(function(oid){
      var o=(g.options||[]).find(function(x){return x.id===oid;}); if(o) d+=o.priceDelta||0;
    });
  });
  return (base+d)*SHEETQTY;
}
function addToCart(){
  // enforce required client-side (server re-validates anyway)
  if(CURRENT.variants && CURRENT.variants.length && !SHEETSEL.variantId){ return; }
  var missing=false;
  (CURRENT.modifierGroups||[]).forEach(function(g){ if(g.required && !(SHEETSEL.options[g.id]||[]).length) missing=true; });
  if(missing){ alert("Lengkapi pilihan wajib dulu."); return; }
  var opts=[]; (CURRENT.modifierGroups||[]).forEach(function(g){ (SHEETSEL.options[g.id]||[]).forEach(function(o){opts.push(o);}); });
  CART.push({ itemId:CURRENT.id, name:CURRENT.name, variantId:SHEETSEL.variantId,
    optionIds:opts, qty:SHEETQTY, note:(el("note").value||"").trim(), unit:linePrice()/SHEETQTY });
  closeSheet(); renderBar();
}
function cartTotal(){ return CART.reduce(function(a,l){ return a + l.unit*l.qty; }, 0); }
function cartCount(){ return CART.reduce(function(a,l){ return a + l.qty; }, 0); }
function renderBar(){
  var bar=el("bar");
  if(!CART.length){ bar.classList.remove("show"); return; }
  bar.classList.add("show");
  el("barcount").textContent = cartCount()+" item · "+rp(cartTotal());
}

function submitOrder(){
  if(!CART.length) return;
  IDEM = IDEM || (Date.now()+"-"+Math.random().toString(36).slice(2));
  var lines = CART.map(function(l){ return { itemId:l.itemId, variantId:l.variantId, optionIds:l.optionIds, qty:l.qty, note:l.note }; });
  el("submitbtn").disabled = true;
  api("POST","/guest/orders",{ idempotencyKey:IDEM, lines:lines }).then(function(r){
    if(r.ok){ CART=[]; IDEM=null; renderBar(); showStatus(); }
    else {
      el("submitbtn").disabled=false;
      var c=r.body&&r.body.code;
      if(c==="pending_batch_open") alert("Pesanan sebelumnya masih diproses pramusaji.");
      else if(c==="visit_closed") alert("Sesi meja sudah ditutup. Silakan scan ulang.");
      else alert("Gagal mengirim pesanan. Coba lagi.");
    }
  });
}

function showStatus(){
  document.getElementById("app").innerHTML =
    '<header><h1>Pesanan Anda</h1><div class="sub">Meja '+esc(TABLE.label)+'</div></header><div id="statuslist" class="center">Memuat…</div>';
  el("bar").classList.remove("show");
  pollStatus();
}
function pollStatus(){
  api("GET","/guest/orders").then(function(r){
    if(!r.ok) return;
    var rows=r.body.orders||[];
    var anyPending=rows.some(function(t){return t.status==="pendingReview";});
    var h='';
    rows.forEach(function(t){
      h+='<div class="item"><div class="body"><div class="name">'+t.qty+'× '+esc(t.name)
        +(t.variantName?' <small>('+esc(t.variantName)+')</small>':'')+'</div></div>'
        +'<span class="pill '+t.status+'">'+statusLabel(t.status)+'</span></div>';
    });
    if(!rows.length) h='<div class="center">Belum ada pesanan.</div>';
    var note = anyPending
      ? '<div class="center" style="padding:20px"><div class="big">⏳</div>Menunggu konfirmasi pramusaji…</div>'
      : '<div class="center" style="padding:20px"><div class="big">✅</div>Pesanan dikonfirmasi, sedang disiapkan.</div>';
    document.getElementById("statuslist").innerHTML = note + h
      + '<button class="linkbtn" onclick="loadMenu()">+ Pesan lagi</button>';
  });
  setTimeout(pollStatus, 5000);
}
function statusLabel(s){
  if(s==="pendingReview") return "menunggu";
  if(s==="voided") return "ditolak";
  if(s==="sent"||s==="prep") return "disiapkan";
  if(s==="cooked"||s==="ready") return "siap";
  if(s==="served") return "disajikan";
  return s;
}

function esc(s){ return (s==null?"":""+s).replace(/[&<>"]/g, function(c){
  return {"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;"}[c]; }); }

// static chrome (sheet + bar live outside #app so they persist across renders)
document.body.insertAdjacentHTML("beforeend",
  '<div class="bar" id="bar"><b id="barcount"></b><button id="submitbtn-open" onclick="reviewCart()">Lihat Keranjang</button></div>'
  +'<div class="sheet-bg" id="sbg" onclick="closeSheet()"></div>'
  +'<div class="sheet" id="sheet" onclick="event.stopPropagation()"><div id="sheetbody"></div>'
  +'<div class="sheetcta"><button id="addcta" onclick="addToCart()">Tambah</button></div></div>'
  +'<div class="sheet-bg" id="cbg" onclick="closeCart()"></div>'
  +'<div class="sheet" id="csheet" onclick="event.stopPropagation()"><div id="cartbody"></div>'
  +'<div class="sheetcta"><button id="submitbtn" onclick="submitOrder()">Kirim ke Dapur</button></div></div>');

function reviewCart(){
  var h='<h2>Keranjang</h2>';
  CART.forEach(function(l,idx){
    h+='<div class="opt"><label>'+l.qty+'× '+esc(l.name)
      +(l.note?'<br><small style="opacity:.6">'+esc(l.note)+'</small>':'')+'</label>'
      +'<span>'+rp(l.unit*l.qty)+' <button class="linkbtn" style="margin:0" onclick="rmLine('+idx+')">hapus</button></span></div>';
  });
  h+='<div class="opt"><b>Total</b><b>'+rp(cartTotal())+'</b></div>';
  el("cartbody").innerHTML=h;
  el("cbg").classList.add("show"); el("csheet").classList.add("show");
}
function rmLine(idx){ CART.splice(idx,1); renderBar(); if(CART.length) reviewCart(); else closeCart(); }
function closeCart(){ el("cbg").classList.remove("show"); el("csheet").classList.remove("show"); }

start();
</script>
</body>
</html>''';

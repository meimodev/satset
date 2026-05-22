// SatSet — design canvas. Tablet artboards first, then phone.
/* global React, ReactDOM,
   IOSDevice,
   TopBar, TabBar, Header,
   PinScreen, TablesScreen, TableDetailScreen, MenuScreen, ModifierSheet,
   ReviewScreen, SentScreen, ReadyToast,
   OrdersScreen, MeScreen, LineItemActionSheet,
   SATSET_DATA, formatIDR, ALLERGEN_CODES, ALLERGEN_NAMES, courseFromCategory,
   statusLabel, statusText, zoneName,
   DesignCanvas, DCSection, DCArtboard, Icons
*/

const NOOP = () => {};
const PW = 402, PH = 874;        // phone
const TW = 1180, TH = 820;       // tablet

const tables = SATSET_DATA.tables;
const tickets = JSON.parse(JSON.stringify(SATSET_DATA.initialTicketsByTable));

const seededCart = [
  { id: 'D1', itemId: 'rendang', name: 'Rendang Sapi', station: 'kitchen', variantName: '',
    modifiers: ['Nasi putih'], modifierIds: {}, special: '', course: 'mains', qty: 1,
    unitPrice: 145000, allergens: ['nut'] },
  { id: 'D2', itemId: 'nasi-goreng', name: 'Nasi Goreng', station: 'kitchen', variantName: 'Reguler',
    modifiers: ['Udang', 'Sedang', '+ Krupuk'], modifierIds: {}, special: 'Tanpa MSG — tamu sensitif',
    course: 'mains', qty: 1, unitPrice: 113000, allergens: ['shellfish', 'egg', 'gluten'] },
  { id: 'D3', itemId: 'margarita', name: 'Margarita Pedas', station: 'bar', variantName: '',
    modifiers: [], modifierIds: {}, special: '', course: 'drinks-now', qty: 2,
    unitPrice: 110000, allergens: [] },
  { id: 'D4', itemId: 'pisang', name: 'Pisang Goreng', station: 'kitchen', variantName: '',
    modifiers: ['Vanila'], modifierIds: {}, special: '', course: 'desserts', qty: 1,
    unitPrice: 55000, allergens: ['gluten', 'dairy', 'egg'] },
];

const auditLogSeeded = [
  { id: 'A1', type: 'void', title: 'Batal ×1 Mie Goreng (Rp 80.000)',
    tableId: 'T1', when: '17:58', approvedBy: 'Sari (Mgr)', reason: 'Tamu berubah pikiran' },
  { id: 'A2', type: 'fire', title: 'Kirim Utama untuk Meja T1',
    tableId: 'T1', when: '17:46', approvedBy: null, reason: null },
  { id: 'A3', type: 'modify', title: 'Ubah ×1 Rendang Sapi',
    tableId: 'T1', when: '17:50', approvedBy: null, reason: 'Ganti nasi uduk → nasi putih' },
];

// ─────────────────────────────────────────────────────────────────────
//  Tablet snapshots — iframe-based since the tablet app sets a stage that
//  scales-to-fit, and embedding it inline would scale to the artboard.
//  We just point an <iframe> at tablet.html with query params if we wanted
//  to control state; for the demo, we show the default view.
//
//  Lighter alternative below: render a static "tablet preview" component
//  for each state using simple DOM + the existing CSS classes.
// ─────────────────────────────────────────────────────────────────────

function Tab({ children }) {
  // The tablet bezel + screen wrapper, sized for an artboard.
  return (
    <div style={{ width: TW, height: TH }}>
      <div className="tab-ipad" style={{ width: '100%', height: '100%' }}>
        <div className="tab-screen">
          {children}
        </div>
      </div>
    </div>
  );
}

// Reusable mini-shell — left rail + topbar, used by all tablet snapshots.
function MiniShell({ active = 'tables', crumbs, readyCount = 3, syncOffline, children, extras }) {
  return (
    <>
      <div className="tab-rail">
        <div className="tab-mark">S</div>
        <div className="tab-nav">
          <MiniNavBtn id="tables" Ic={Icons.Tables} label="Meja" active={active === 'tables'}/>
          <MiniNavBtn id="orders" Ic={Icons.Orders} label="Pesanan" active={active === 'orders'} badge={readyCount} alert={readyCount > 0}/>
          <MiniNavBtn id="me"     Ic={Icons.Me}     label="Saya"  active={active === 'me'}/>
        </div>
        <div className="tab-rail-foot">
          <div className="tab-avatar">MA</div>
        </div>
      </div>
      <div className="tab-main">
        <div className="tab-topbar">
          {crumbs}
          <div className="tab-clock">
            <span className={'tab-sync ' + (syncOffline ? 'offline' : '')}>
              <span className="dot"></span>
              {syncOffline ? 'HANYA LAN · CLOUD TUNGGU' : 'LIVE · LAN'}
            </span>
            <span>18:14 · Sab</span>
          </div>
        </div>
        {children}
      </div>
      {extras}
    </>
  );
}
function MiniNavBtn({ Ic, label, active, badge, alert }) {
  return (
    <button className={'tab-nav-btn ' + (active ? 'active' : '')}>
      <Ic size={22}/>
      <span>{label}</span>
      {!!badge && <span className={'badge ' + (alert ? 'alert' : '')}>{badge}</span>}
    </button>
  );
}
function MiniCrumbs({ items }) {
  return (
    <div className="tab-crumbs">
      {items.map((it, i) => (
        <React.Fragment key={i}>
          {i > 0 && <span className="sep">›</span>}
          <span className={i === items.length - 1 ? 'cur' : ''}>{it}</span>
        </React.Fragment>
      ))}
    </div>
  );
}

// ─── Floor view snapshot ─────────────────────────────────────────────
function T_Floor({ zone = 'terrace', toast = null, syncOffline = false }) {
  const z = SATSET_DATA.zones.find((x) => x.id === zone);
  const zt = tables.filter((t) => t.zone === zone);
  const occ = zt.filter((t) => t.status !== 'available').length;
  const rdy = zt.filter((t) => t.status === 'ready').length;
  return (
    <Tab>
      <MiniShell
        syncOffline={syncOffline}
        crumbs={<MiniCrumbs items={['Warung Sebelah', z.name]}/>}
        extras={toast && (
          <div className="tab-ready-toast">
            <div className="ic"><Icons.Bell size={20}/></div>
            <div className="body">
              <div className="t">Siap di pass · {toast.what}</div>
              <div className="d">MEJA {toast.tableId} · {toast.zone.toUpperCase()} · SEKARANG</div>
            </div>
            <button className="go">Ambil di pass</button>
          </div>
        )}
      >
        <div className="tab-content">
          <div className="tab-section-head">
            <div>
              <div className="tab-h1">{z.name}</div>
              <div className="tab-sub">{occ} dari {zt.length} terisi · {rdy} siap diambil</div>
            </div>
          </div>
          <div className="tab-zones">
            {SATSET_DATA.zones.map((zz) => {
              const cs = tables.filter((t) => t.zone === zz.id);
              const r = cs.filter((t) => t.status === 'ready').length;
              return (
                <button key={zz.id} className={'tab-zone-btn ' + (zone === zz.id ? 'active' : '')}>
                  {zz.name}
                  <span className="count">{r > 0 ? r + ' siap' : cs.length}</span>
                </button>
              );
            })}
          </div>
          <div className="tab-tables-grid">
            {zt.map((t) => (
              <div key={t.id} className={['tab-table-card', 's-' + t.status, t.mine ? 's-mine' : ''].join(' ')}>
                <div className="tt-row1">
                  <span className="tt-num">{t.id}</span>
                  <span className="tt-pax">{t.pax} tamu</span>
                </div>
                {t.open > 0 && <div className="tt-amt">{formatIDR(t.open)}</div>}
                <div className="tt-row2">
                  <span className="tt-dot"></span>
                  <span className="tt-lbl">{statusLabel(t)}</span>
                  {t.elapsed && <span className="tt-time">{t.elapsed}</span>}
                </div>
              </div>
            ))}
          </div>
        </div>
      </MiniShell>
    </Tab>
  );
}

// ─── Detail view snapshot (split with context panel) ─────────────────
function T_Detail() {
  const tableId = 'T1';
  return (
    <Tab>
      <MiniShell
        crumbs={<MiniCrumbs items={['Teras', 'Meja ' + tableId, 'Detail']}/>}
      >
        <div className="tab-split">
          <div className="tab-pane size-md">
            <DetailLeftPane tableId={tableId} tickets={tickets[tableId]}/>
          </div>
          <div className="tab-pane" style={{ flex: 1 }}>
            <ContextRightPane table={tables.find((t) => t.id === tableId)} tickets={tickets[tableId]}/>
          </div>
        </div>
      </MiniShell>
    </Tab>
  );
}

function DetailLeftPane({ tableId, tickets }) {
  const table = tables.find((t) => t.id === tableId);
  const total = tickets.reduce((s, t) => s + (t.status === 'voided' ? 0 : t.price * t.qty), 0);
  const courseOrder = ['drinks-now', 'starters', 'mains', 'sides', 'desserts'];
  const grouped = {};
  tickets.forEach((t) => { grouped[t.course] = grouped[t.course] || []; grouped[t.course].push(t); });
  const readyAny = tickets.some((t) => t.status === 'ready');

  return (
    <>
      <div className="tab-td-head">
        <div className="tnumline">
          <span className="tnum">{tableId}</span>
          <span className="tinfo">{zoneName(table.zone)} · {table.pax} tamu</span>
        </div>
        <div className="tmeta">
          <span className="h-pill"><Icons.Clock size={12}/> duduk {table.elapsed || '0:00'}</span>
          <span className="h-pill">{formatIDR(total)}</span>
          {readyAny && <span className="h-pill success">{tickets.filter((t) => t.status === 'ready').length} siap diambil</span>}
        </div>
      </div>
      <div className="tab-tickets">
        {courseOrder.map((cId) => {
          const items = grouped[cId];
          if (!items) return null;
          const course = SATSET_DATA.courses.find((c) => c.id === cId);
          const allHeld = items.every((it) => it.status === 'held');
          return (
            <div className="tab-course-block" key={cId}>
              <div className="ch">
                <span className="cdot" style={{ background: course.color }}></span>
                <span className="ctitle">{course.name}</span>
                <span className="cmeta">{items.length} item{allHeld ? ' · ditahan' : ''}</span>
              </div>
              {items.map((it) => (
                <div key={it.id} className={'tab-line' + (it.status === 'ready' ? ' is-ready' : '')}>
                  <div className="lq">×{it.qty}</div>
                  <div className="lbody">
                    <div className="lname">{it.name}{it.variantName ? ' · ' + it.variantName : ''}</div>
                    {it.modifiers.length > 0 && <div className="lmods">{it.modifiers.join(' · ')}</div>}
                    {it.specialInstructions && <div className="lspecial">⚠ {it.specialInstructions}</div>}
                    <div className="lfoot">
                      <span className={'li-status ' + it.status}>{statusText(it.status)}</span>
                      <span style={{ fontFamily: 'var(--font-mono)', fontSize: 10, color: 'var(--text-lo)' }}>
                        {it.station === 'kitchen' ? 'DPR' : 'BAR'} · {it.sentAt}
                      </span>
                      <span className="lprice">{formatIDR(it.price * it.qty)}</span>
                    </div>
                  </div>
                </div>
              ))}
              {allHeld && (
                <button className="tab-fire-btn">
                  <Icons.Fire size={14}/> Kirim {course.name}
                </button>
              )}
            </div>
          );
        })}
      </div>
      <div className="tab-td-foot">
        <button className="btn-primary"><Icons.Plus size={18}/> Tambah pesanan</button>
      </div>
    </>
  );
}

function ContextRightPane({ table, tickets }) {
  const sent = tickets.filter((t) => t.status !== 'voided' && t.status !== 'served').length;
  const allergens = Array.from(new Set(tickets.flatMap((t) => {
    const item = SATSET_DATA.items.find((i) => i.id === t.itemId);
    return item ? item.allergens : [];
  })));
  return (
    <div className="tab-context">
      <div className="tab-context-head">
        <div className="tab-context-h">Konteks meja</div>
        <div style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--text-lo)', letterSpacing: '0.04em', marginTop: 4 }}>
          DUDUK {table.elapsed || '0:00'} · {table.pax} TAMU
        </div>
      </div>
      <div className="tab-context-body">
        <div className="tab-stat-grid">
          <div className="tab-statc"><div className="v">{tickets.length}</div><div className="l">Total item</div></div>
          <div className="tab-statc"><div className="v">{sent}</div><div className="l">Dalam proses</div></div>
          <div className="tab-statc"><div className="v">{tickets.filter((t) => t.status === 'served').length}</div><div className="l">Disajikan</div></div>
        </div>
        <div className="tab-card" style={{ marginBottom: 14 }}>
          <div className="tab-card-h">Catatan tamu</div>
          <div style={{ display: 'flex', gap: 10, padding: '10px 12px', background: 'var(--urgent-soft)', border: '1px solid rgba(255,92,92,0.25)', borderRadius: 12, color: 'var(--urgent)', fontSize: 13, fontWeight: 500 }}>
            <Icons.Alert size={16}/>
            <span>Tamu alergi kacang — hindari saus kacang & garnish sate.</span>
          </div>
        </div>
        <div className="tab-card" style={{ marginBottom: 14 }}>
          <div className="tab-card-h">Alergen di pesanan</div>
          <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
            {allergens.map((a) => (
              <span key={a} className="h-pill urgent" style={{ fontSize: 12 }}>
                <Icons.Alert size={11}/> {ALLERGEN_NAMES[a]}
              </span>
            ))}
          </div>
        </div>
        <div className="tab-card">
          <div className="tab-card-h">Aksi cepat</div>
          <button className="tab-fire-btn" style={{ marginTop: 0, marginBottom: 6 }}>
            <Icons.Sparkle size={14}/> Cetak struk meja
          </button>
          <button className="tab-fire-btn" style={{ background: 'var(--bg-3)', color: 'var(--text-md)', border: '1px solid var(--border-1)' }}>
            <Icons.Edit size={14}/> Pindahkan meja
          </button>
        </div>
      </div>
    </div>
  );
}

// ─── Add-order view: menu + cart side-by-side ────────────────────────
function T_AddOrder({ withCart = true }) {
  const tableId = 'T1';
  const cart = withCart ? seededCart : [];
  return (
    <Tab>
      <MiniShell
        crumbs={<MiniCrumbs items={['Teras', 'Meja ' + tableId, 'Tambah item']}/>}
      >
        <div className="tab-split">
          <MenuColumn tableId={tableId} cart={cart}/>
          <CartColumn tableId={tableId} cart={cart}/>
        </div>
      </MiniShell>
    </Tab>
  );
}

function MenuColumn({ tableId, cart }) {
  const inCart = {};
  cart.forEach((c) => { inCart[c.itemId] = (inCart[c.itemId] || 0) + c.qty; });
  const items = SATSET_DATA.items.filter((i) => i.category === 'mains');
  return (
    <div className="tab-menu-pane">
      <div className="tab-menu-head">
        <button className="back"><Icons.Back size={18}/></button>
        <div>
          <div className="htitle">Tambah ke Meja {tableId}</div>
          <div className="hsub">TERAS · 2 TAMU · 5 ITEM SUDAH KIRIM</div>
        </div>
        <div className="search">
          <Icons.Search size={14} stroke="var(--text-lo)"/>
          <span>Cari menu…</span>
        </div>
      </div>
      <div className="tab-cat-tabs">
        {SATSET_DATA.categories.map((c) => (
          <button key={c.id} className={'tab-cat-tab ' + (c.id === 'mains' ? 'active' : '')}>
            {c.name}
          </button>
        ))}
      </div>
      <div className="tab-item-grid">
        {items.map((it) => (
          <div key={it.id} className={'tab-item' + (inCart[it.id] ? ' has-some' : '') + (it.unavailable ? ' unavailable' : '')}>
            <div className="img">
              {it.unavailable && <span className="killswitch">86'd</span>}
              {inCart[it.id] > 0 && <span className="qty-on">×{inCart[it.id]}</span>}
              <span className="img-lbl">PHOTO</span>
            </div>
            <div className="meta">
              <div className="name">{it.name}</div>
              <div className="price">{formatIDR(it.basePrice)}{it.variants.length > 1 ? '+' : ''}</div>
              {it.allergens.length > 0 && (
                <div className="allergens">
                  {it.allergens.map((a) => (
                    <span key={a} className="alg">{ALLERGEN_CODES[a]}</span>
                  ))}
                </div>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

function CartColumn({ tableId, cart }) {
  const courseOrder = ['drinks-now', 'starters', 'mains', 'sides', 'desserts', 'fire-now'];
  const grouped = {};
  cart.forEach((c) => { grouped[c.course] = grouped[c.course] || []; grouped[c.course].push(c); });
  const subtotal = cart.reduce((s, c) => s + c.unitPrice * c.qty, 0);
  const cnt = cart.reduce((s, c) => s + c.qty, 0);
  const kit = cart.filter((c) => c.station === 'kitchen').reduce((s, c) => s + c.qty, 0);
  const bar = cart.filter((c) => c.station === 'bar').reduce((s, c) => s + c.qty, 0);
  return (
    <div className="tab-cart">
      <div className="tab-cart-head">
        <div className="label">Pesanan baru · Meja {tableId}</div>
        <div className="title">{cnt} item siap kirim</div>
        <div className="sub">
          {kit > 0 && 'Dapur × ' + kit}
          {kit > 0 && bar > 0 && '  ·  '}
          {bar > 0 && 'Bar × ' + bar}
        </div>
      </div>
      <div className="tab-cart-body">
        {cart.length === 0 ? (
          <div className="tab-cart-empty">Belum ada item di keranjang. Pilih dari menu di kiri.</div>
        ) : courseOrder.map((cId) => {
          const items = grouped[cId];
          if (!items) return null;
          const c = SATSET_DATA.courses.find((cc) => cc.id === cId);
          return (
            <div className="tab-course-block" key={cId}>
              <div className="ch">
                <span className="cdot" style={{ background: c.color }}></span>
                <span className="ctitle">{c.name}</span>
                <span className="cmeta">{cId === 'fire-now' || cId === 'drinks-now' ? 'kirim otomatis' : 'ditahan'}</span>
              </div>
              {items.map((ci) => (
                <div className="tab-line" key={ci.id}>
                  <div className="lq">×{ci.qty}</div>
                  <div className="lbody">
                    <div className="lname">{ci.name}{ci.variantName ? ' · ' + ci.variantName : ''}</div>
                    {ci.modifiers.length > 0 && <div className="lmods">{ci.modifiers.join(' · ')}</div>}
                    {ci.special && <div className="lspecial">⚠ {ci.special}</div>}
                    <div className="lfoot">
                      <span style={{ fontSize: 12, color: 'var(--urgent)', display: 'flex', alignItems: 'center', gap: 4 }}>
                        <Icons.Trash size={12}/> Hapus
                      </span>
                      <span className="lprice">{formatIDR(ci.unitPrice * ci.qty)}</span>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          );
        })}
      </div>
      {cart.length > 0 && (
        <div className="tab-cart-foot">
          <div className="totals">
            <div className="row"><span>Subtotal</span><span>{formatIDR(subtotal)}</span></div>
            <div className="row"><span>Layanan 7% · Pajak 11%</span><span>{formatIDR(Math.round(subtotal * 0.18))}</span></div>
            <div className="row total"><span>Estimasi</span><span>{formatIDR(Math.round(subtotal * 1.18))}</span></div>
          </div>
          <button className="btn-send">
            <Icons.Sparkle size={16}/> Kirim ke {kit > 0 && bar > 0 ? 'dapur + bar' : kit > 0 ? 'dapur' : 'bar'}
          </button>
        </div>
      )}
    </div>
  );
}

// ─── PIN ───────────────────────────────────────────────────────────
function T_Pin() {
  return (
    <Tab>
      <div className="tab-pin">
        <div className="tab-pin-left">
          <div className="tab-pin-brand">
            <div className="mark">S</div>
            <div className="tab-pin-wordmark">satset</div>
          </div>
          <div className="tab-pin-greet">Selamat sore</div>
          <div className="tab-pin-name">Maya,<br/>masukkan PIN</div>
          <div className="tab-pin-shift">Pelayan · Zona Teras · mulai 17:30</div>
          <div className="tab-pin-venue">
            WARUNG SEBELAH<br/>BERAWA, BALI<br/><br/>
            PIN BERAKHIR DI AKHIR SHIFT · BYOD · v2.0
          </div>
        </div>
        <div className="tab-pin-right">
          <div className="tab-pin-dots">
            {[1,2,3,4].map((i) => (
              <div key={i} className={'tab-pin-dot ' + (i <= 2 ? 'filled' : '')}></div>
            ))}
          </div>
          <div className="tab-pin-pad">
            {['1','2','3','4','5','6','7','8','9'].map((k) => (
              <button key={k} className="tab-pin-key">{k}</button>
            ))}
            <div/>
            <button className="tab-pin-key">0</button>
            <button className="tab-pin-key muted"><Icons.Back size={22}/></button>
          </div>
        </div>
      </div>
    </Tab>
  );
}

// ─── Orders ────────────────────────────────────────────────────────
function T_Orders() {
  const all = [];
  Object.entries(tickets).forEach(([tid, tx]) => {
    const t = tables.find((tt) => tt.id === tid);
    if (!t || !t.mine) return;
    tx.forEach((x) => all.push({ ...x, tableId: tid }));
  });
  const ready = all.filter((t) => t.status === 'ready');
  return (
    <Tab>
      <MiniShell active="orders" crumbs={<MiniCrumbs items={['Maya', 'Pesanan saya']}/>}>
        <div className="tab-content">
          <div className="tab-section-head">
            <div>
              <div className="tab-h1">Pesanan saya</div>
              <div className="tab-sub">5 berjalan · {ready.length} siap diambil</div>
            </div>
          </div>
          <div className="tab-segs">
            <button className="tab-seg active">Siap diambil <span className="count">{ready.length}</span></button>
            <button className="tab-seg">Disiapkan <span className="count">5</span></button>
            <button className="tab-seg">Selesai <span className="count">3</span></button>
          </div>
          <div className="tab-orders-list">
            {ready.map((t) => (
              <div key={t.id} className="tab-order-row is-ready">
                <div className="otab">{t.tableId}</div>
                <div className="obody">
                  <div className="oname">
                    {t.qty > 1 && <span style={{ color: 'var(--text-md)', fontFamily: 'var(--font-mono)', fontSize: 12, marginRight: 4 }}>×{t.qty}</span>}
                    {t.name}
                  </div>
                  {t.modifiers && t.modifiers.length > 0 && (
                    <div className="omods">{t.modifiers.join(' · ')}</div>
                  )}
                  <div className="ofoot">
                    <span className={'li-status ' + t.status}>{statusText(t.status)}</span>
                    <span style={{ fontFamily: 'var(--font-mono)', fontSize: 10, color: 'var(--text-lo)' }}>
                      {t.station === 'kitchen' ? 'DPR' : 'BAR'} · {t.sentAt}
                    </span>
                  </div>
                </div>
                <Icons.Chev size={18} stroke="var(--text-lo)"/>
              </div>
            ))}
          </div>
        </div>
      </MiniShell>
    </Tab>
  );
}

// ─── Me ────────────────────────────────────────────────────────────
function T_Me() {
  return (
    <Tab>
      <MiniShell active="me" crumbs={<MiniCrumbs items={['Maya Anjani', 'Ringkasan shift']}/>}>
        <div className="tab-content">
          <div className="tab-section-head">
            <div>
              <div className="tab-h1">Ringkasan shift</div>
              <div className="tab-sub">SABTU, 21 MEI · 47 MENIT SEJAK MULAI</div>
            </div>
          </div>
          <div className="tab-me">
            <div className="tab-me-col">
              <div className="tab-me-hero">
                <div className="av">MA</div>
                <div>
                  <div className="nm">Maya Anjani</div>
                  <div className="rl">Pelayan · Zona Teras</div>
                  <div className="sf">PIN MASUK 17:30 · BYOD · iPad-1</div>
                </div>
              </div>
              <div className="tab-me-stats">
                <div className="tab-statc"><div className="v">11</div><div className="l">Tiket kirim</div></div>
                <div className="tab-statc"><div className="v">12</div><div className="l">Tamu aktif</div></div>
                <div className="tab-statc" style={{ background: 'var(--urgent-soft)' }}>
                  <div className="v" style={{ color: 'var(--urgent)' }}>1</div><div className="l">Pembatalan</div>
                </div>
                <div className="tab-statc"><div className="v">0</div><div className="l">Gratisan</div></div>
              </div>
              <div className="tab-card">
                <div className="tab-card-h">Preferensi</div>
                <div className="tab-pref-row">
                  <div className="ic"><Icons.Bell size={16}/></div>
                  <div style={{ flex: 1 }}>
                    <div className="lbl">Alert audio</div>
                    <div className="sublbl">Nada peringatan + getaran kuat</div>
                  </div>
                  <div className="val">Aktif</div>
                </div>
                <div className="tab-pref-row">
                  <div className="ic"><Icons.Wifi size={16}/></div>
                  <div style={{ flex: 1 }}>
                    <div className="lbl">Server</div>
                    <div className="sublbl">192.168.4.21 · sertifikat OK · ping 38ms</div>
                  </div>
                  <div className="val">Warung Sebelah</div>
                </div>
              </div>
            </div>
            <div className="tab-me-col">
              <div className="tab-card">
                <div className="tab-card-h">
                  Aktivitas terkini
                  <span style={{ color: 'var(--text-dim)' }}>{auditLogSeeded.length} entri</span>
                </div>
                {auditLogSeeded.map((a) => (
                  <div className="audit-row" style={{ padding: '12px 0', borderBottom: '1px solid var(--border-0)' }} key={a.id}>
                    <div className={'audit-ic ' + a.type}>
                      {a.type === 'void' && <Icons.Trash size={14}/>}
                      {a.type === 'comp' && <Icons.Sparkle size={14}/>}
                      {a.type === 'modify' && <Icons.Edit size={14}/>}
                      {a.type === 'fire' && <Icons.Fire size={14}/>}
                    </div>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div className="audit-title">{a.title}</div>
                      <div className="audit-sub">
                        Meja {a.tableId} · {a.when}
                        {a.approvedBy ? ' · disetujui ' + a.approvedBy : ''}
                        {a.reason ? ' · ' + a.reason : ''}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </MiniShell>
    </Tab>
  );
}

// ─── Modifier modal over add-order ─────────────────────────────────
function T_Modifier() {
  const item = SATSET_DATA.items.find((i) => i.id === 'nasi-goreng');
  return (
    <Tab>
      <MiniShell crumbs={<MiniCrumbs items={['Teras', 'Meja T1', 'Tambah item']}/>}>
        <div className="tab-split">
          <MenuColumn tableId="T1" cart={[]}/>
          <CartColumn tableId="T1" cart={[]}/>
        </div>
        <div className="tab-modal-scrim">
          <div className="tab-modal">
            <div className="tab-modal-head">
              <div className="img"/>
              <div className="info">
                <div className="name">{item.name}</div>
                <div className="desc">{item.description}</div>
              </div>
              <button className="tab-modal-close"><Icons.Close size={18}/></button>
            </div>
            <div className="tab-allergen-banner">
              <Icons.Alert size={16}/>
              Mengandung {item.allergens.map((a) => ALLERGEN_NAMES[a]).join(', ').toLowerCase()} — konfirmasi ke tamu
            </div>
            <div className="tab-modal-body">
              <div className="tab-modal-col">
                <div className="mod-group" style={{ padding: 0, borderBottom: 0, marginBottom: 14 }}>
                  <div className="label" style={{ marginBottom: 8 }}>
                    <span className="title">Ukuran</span><span className="req">WAJIB</span>
                  </div>
                  <div className="mod-opts">
                    {item.variants.map((v, i) => (
                      <button key={v.id} className={'mod-opt ' + (i === 0 ? 'selected' : '')}>
                        <span className="check">{i === 0 && <Icons.Check size={14}/>}</span>
                        <span className="name">{v.name}</span>
                        <span className="delta">{formatIDR(v.price)}</span>
                      </button>
                    ))}
                  </div>
                </div>
                <div className="mod-group" style={{ padding: 0, borderBottom: 0, marginBottom: 14 }}>
                  <div className="label" style={{ marginBottom: 8 }}>
                    <span className="title">Pilih protein</span><span className="req">WAJIB</span>
                  </div>
                  <div className="mod-opts">
                    {item.modifierGroups[0].options.slice(0, 4).map((o, i) => (
                      <button key={o.id} className={'mod-opt ' + (i === 2 ? 'selected' : '')}>
                        <span className="check">{i === 2 && <Icons.Check size={14}/>}</span>
                        <span className="name">{o.name}</span>
                        {o.price !== 0 && <span className="delta">{o.price > 0 ? '+' : '−'} {formatIDR(Math.abs(o.price))}</span>}
                      </button>
                    ))}
                  </div>
                </div>
              </div>
              <div className="tab-modal-col">
                <div className="mod-group" style={{ padding: 0, borderBottom: 0, marginBottom: 14 }}>
                  <div className="label" style={{ marginBottom: 8 }}>
                    <span className="title">Tingkat pedas</span><span className="req">WAJIB</span>
                  </div>
                  <div className="mod-opts">
                    {item.modifierGroups[1].options.slice(0, 4).map((o, i) => (
                      <button key={o.id} className={'mod-opt ' + (i === 2 ? 'selected' : '')}>
                        <span className="check">{i === 2 && <Icons.Check size={14}/>}</span>
                        <span className="name">{o.name}</span>
                      </button>
                    ))}
                  </div>
                </div>
                <div className="mod-group" style={{ padding: 0, borderBottom: 0, marginBottom: 14 }}>
                  <div className="label" style={{ marginBottom: 8 }}>
                    <span className="title">Tambahan</span><span className="opt">PILIH BEBAS</span>
                  </div>
                  <div className="mod-opts">
                    {item.modifierGroups[2].options.map((o, i) => (
                      <button key={o.id} className={'mod-opt multi ' + (i === 0 ? 'selected' : '')}>
                        <span className="check">{i === 0 && <Icons.Check size={14}/>}</span>
                        <span className="name">{o.name}</span>
                        <span className="delta">+ {formatIDR(o.price)}</span>
                      </button>
                    ))}
                  </div>
                </div>
              </div>
            </div>
            <div className="tab-modal-foot">
              <div className="qty-stepper">
                <button>−</button><span className="v">1</span><button>+</button>
              </div>
              <div style={{ flex: 1, fontFamily: 'var(--font-mono)', fontSize: 12, color: 'var(--text-md)', textAlign: 'center' }}>
                Rp 100.000 × 1 = Rp 100.000
              </div>
              <button className="btn btn-primary" style={{ minWidth: 200 }}>Tambah ke pesanan</button>
            </div>
          </div>
        </div>
      </MiniShell>
    </Tab>
  );
}

// ─── Sent overlay ──────────────────────────────────────────────────
function T_Sent() {
  return (
    <Tab>
      <MiniShell crumbs={<MiniCrumbs items={['Teras', 'Meja T1', 'Terkirim']}/>}>
        <div className="tab-content"/>
        <div className="tab-sent-overlay">
          <div className="tab-sent-check">
            <svg width="60" height="60" viewBox="0 0 24 24" fill="none" stroke="var(--success)" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
              <path d="M5 12.5l4.5 4.5L19 7.5"/>
            </svg>
          </div>
          <div>
            <div className="tab-sent-title">Terkirim</div>
            <div className="tab-sent-sub">Pesanan Meja T1 sudah tampil di layar dapur & bar. Akan masuk antrian KDS dalam 184ms.</div>
          </div>
          <div className="tab-sent-stations">
            <div className="tab-sent-station">
              <span className="ok"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"><path d="M5 12.5l4.5 4.5L19 7.5"/></svg></span>
              Dapur
            </div>
            <div className="tab-sent-station">
              <span className="ok"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"><path d="M5 12.5l4.5 4.5L19 7.5"/></svg></span>
              Bar
            </div>
          </div>
          <div style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--text-lo)', letterSpacing: '0.1em', marginTop: 12 }}>
            LAN P50 184MS · CLOUD MENUNGGU
          </div>
        </div>
      </MiniShell>
    </Tab>
  );
}

// ─── Action sheet (void flow) ──────────────────────────────────────
function T_Action({ step }) {
  const tableId = 'T1';
  const ticket = tickets[tableId].find((t) => t.status === 'prep');
  return (
    <Tab>
      <MiniShell crumbs={<MiniCrumbs items={['Teras', 'Meja T1', 'Detail']}/>}>
        <div className="tab-split">
          <div className="tab-pane size-md">
            <DetailLeftPane tableId={tableId} tickets={tickets[tableId]}/>
          </div>
          <div className="tab-pane" style={{ flex: 1 }}>
            <ContextRightPane table={tables.find((t) => t.id === tableId)} tickets={tickets[tableId]}/>
          </div>
        </div>
        <LineItemActionSheet
          ticket={{ ...ticket, tableId }}
          table={tables.find((t) => t.id === tableId)}
          step={step}
          onClose={NOOP}
          onPick={NOOP}
          onVoidReason={NOOP}
          onApprove={NOOP}
          onComplete={NOOP}
        />
      </MiniShell>
    </Tab>
  );
}

// ─────────────────────────────────────────────────────────────────────
// Phone snapshots — reuse existing components
// ─────────────────────────────────────────────────────────────────────
function PhoneFrame({ children, extras }) {
  return (
    <div style={{ width: PW, height: PH }}>
      <IOSDevice width={PW} height={PH} dark={true}>
        <div className="app">
          {children}
          {extras}
        </div>
      </IOSDevice>
    </div>
  );
}

const P_Floor = () => (
  <PhoneFrame>
    <TopBar activeZone="terrace" onSwitchZone={NOOP} sync="connected"/>
    <TablesScreen activeZone="terrace" onZoneChange={NOOP} onSelectTable={NOOP} tables={tables}/>
    <TabBar active="tables" onChange={NOOP} readyCount={3}/>
  </PhoneFrame>
);

const P_Detail = () => (
  <PhoneFrame>
    <TableDetailScreen
      tableId="T1" table={tables.find((t) => t.id === 'T1')}
      tickets={tickets.T1} onAdd={NOOP} onBack={NOOP} onMarkServed={NOOP}
      onFireCourse={NOOP} onTicketTap={NOOP}
    />
  </PhoneFrame>
);

const P_Menu = () => (
  <PhoneFrame>
    <MenuScreen tableId="T1" table={tables.find((t) => t.id === 'T1')}
      cart={[]} onOpenItem={NOOP} onReview={NOOP} onBack={NOOP}/>
  </PhoneFrame>
);

const P_Modifier = () => {
  const item = SATSET_DATA.items.find((i) => i.id === 'nasi-goreng');
  return (
    <PhoneFrame extras={<ModifierSheet item={item} onAdd={NOOP} onClose={NOOP}/>}>
      <MenuScreen tableId="T1" table={tables.find((t) => t.id === 'T1')}
        cart={[]} onOpenItem={NOOP} onReview={NOOP} onBack={NOOP}/>
    </PhoneFrame>
  );
};

const P_Review = () => (
  <PhoneFrame>
    <ReviewScreen tableId="T1" table={tables.find((t) => t.id === 'T1')}
      cart={seededCart} onRemove={NOOP} onEdit={NOOP} onSend={NOOP} onBack={NOOP}/>
  </PhoneFrame>
);

const P_Sent = () => (
  <PhoneFrame>
    <SentScreen stations={['Dapur', 'Bar']} tableId="T1" latency={184} onDone={NOOP}/>
  </PhoneFrame>
);

const P_Orders = () => (
  <PhoneFrame>
    <OrdersScreen ticketsByTable={tickets} tables={tables} onOpenTable={NOOP} onOpenTicket={NOOP}/>
    <TabBar active="orders" onChange={NOOP} readyCount={3}/>
  </PhoneFrame>
);

const P_Me = () => (
  <PhoneFrame>
    <MeScreen tables={tables} ticketsByTable={tickets} auditLog={auditLogSeeded} onEndShift={NOOP}/>
    <TabBar active="me" onChange={NOOP} readyCount={3}/>
  </PhoneFrame>
);

// ─────────────────────────────────────────────────────────────────────
// Root canvas
// ─────────────────────────────────────────────────────────────────────
function App() {
  React.useEffect(() => {
    document.documentElement.setAttribute('data-theme', 'dark');
  }, []);

  return (
    <DesignCanvas>

      <DCSection
        id="design-system"
        title="Design system"
        subtitle="Colors · type · spacing · components · shared across all surfaces"
      >
        <DCArtboard id="ds-colors"     label="Color tokens"        width={1280} height={820}><DS_Colors/></DCArtboard>
        <DCArtboard id="ds-type"       label="Type system"         width={1280} height={820}><DS_Type/></DCArtboard>
        <DCArtboard id="ds-spacing"    label="Spacing & radii"     width={1280} height={820}><DS_Spacing/></DCArtboard>
        <DCArtboard id="ds-components" label="Component library"   width={1280} height={920}><DS_Components/></DCArtboard>
      </DCSection>

      <DCSection
        id="tablet-primary"
        title="Waiter · Tablet · primary form"
        subtitle="Landscape iPad 10.9″ · venue-issued atau BYOD"
      >
        <DCArtboard id="t-pin"        label="PIN login"                   width={TW} height={TH}><T_Pin/></DCArtboard>
        <DCArtboard id="t-floor"      label="Peta lantai · Teras"         width={TW} height={TH}><T_Floor/></DCArtboard>
        <DCArtboard id="t-floor-bar"  label="Peta lantai · Bar"           width={TW} height={TH}><T_Floor zone="bar"/></DCArtboard>
        <DCArtboard id="t-floor-toast" label="Alert siap di pass"         width={TW} height={TH}><T_Floor toast={{ tableId: 'T2', zone: 'Teras', what: 'Tempe Sambal Bowl + Mie Goreng' }}/></DCArtboard>
        <DCArtboard id="t-offline"    label="LAN-only mode"               width={TW} height={TH}><T_Floor syncOffline={true}/></DCArtboard>
      </DCSection>

      <DCSection
        id="tablet-table"
        title="Detail meja · split view"
        subtitle="Tiket aktif di kiri · konteks tamu / aksi cepat di kanan"
      >
        <DCArtboard id="t-detail" label="Detail meja T1"             width={TW} height={TH}><T_Detail/></DCArtboard>
      </DCSection>

      <DCSection
        id="tablet-add"
        title="Tambah pesanan · menu + cart side-by-side"
        subtitle="Tanpa pindah layar — pelanggan tetap fokus pada percakapan"
      >
        <DCArtboard id="t-add-empty" label="Menu · cart kosong"      width={TW} height={TH}><T_AddOrder withCart={false}/></DCArtboard>
        <DCArtboard id="t-add-full"  label="Menu · cart terisi"      width={TW} height={TH}><T_AddOrder withCart={true}/></DCArtboard>
        <DCArtboard id="t-modifier"  label="Opsi item · dialog"      width={TW} height={TH}><T_Modifier/></DCArtboard>
        <DCArtboard id="t-sent"      label="Terkirim · overlay"      width={TW} height={TH}><T_Sent/></DCArtboard>
      </DCSection>

      <DCSection
        id="tablet-tabs"
        title="Tab lain"
        subtitle="Pesanan saya · ringkasan shift dengan jejak audit"
      >
        <DCArtboard id="t-orders" label="Pesanan saya"   width={TW} height={TH}><T_Orders/></DCArtboard>
        <DCArtboard id="t-me"     label="Saya · shift"   width={TW} height={TH}><T_Me/></DCArtboard>
      </DCSection>

      <DCSection
        id="tablet-mutations"
        title="Mutasi pasca-kirim"
        subtitle="Aksi cepat · pembatalan · PIN manajer"
      >
        <DCArtboard id="t-action"      label="Aksi item"        width={TW} height={TH}><T_Action step="actions"/></DCArtboard>
        <DCArtboard id="t-void"        label="Alasan batal"     width={TW} height={TH}><T_Action step="void-reason"/></DCArtboard>
        <DCArtboard id="t-mgr"         label="PIN manajer"      width={TW} height={TH}><T_Action step="manager-pin"/></DCArtboard>
      </DCSection>

      <DCSection
        id="phone-secondary"
        title="Waiter · Phone · secondary form"
        subtitle="Maya pakai HP-nya sendiri saat tablet sedang dipakai pelayan lain"
      >
        <DCArtboard id="p-floor"   label="Peta meja"         width={PW} height={PH}><P_Floor/></DCArtboard>
        <DCArtboard id="p-detail"  label="Detail meja"       width={PW} height={PH}><P_Detail/></DCArtboard>
        <DCArtboard id="p-menu"    label="Menu"              width={PW} height={PH}><P_Menu/></DCArtboard>
        <DCArtboard id="p-modifier" label="Opsi item"        width={PW} height={PH}><P_Modifier/></DCArtboard>
        <DCArtboard id="p-review"  label="Review"            width={PW} height={PH}><P_Review/></DCArtboard>
        <DCArtboard id="p-sent"    label="Terkirim"          width={PW} height={PH}><P_Sent/></DCArtboard>
        <DCArtboard id="p-orders"  label="Pesanan"           width={PW} height={PH}><P_Orders/></DCArtboard>
        <DCArtboard id="p-me"      label="Saya"              width={PW} height={PH}><P_Me/></DCArtboard>
      </DCSection>

      <DCSection
        id="kds"
        title="Kitchen / Bar · KDS"
        subtitle="Wall-mounted Android tablet 1280×800 · also runs the local server"
      >
        <DCArtboard id="kds-main"   label="Tickets · live queue"   width={1280} height={800}><KDS_Main/></DCArtboard>
        <DCArtboard id="kds-server" label="Server status"          width={1280} height={800}><KDS_Server/></DCArtboard>
        <DCArtboard id="kds-pair"   label="Pair device · QR"       width={1280} height={800}><KDS_Pair/></DCArtboard>
      </DCSection>

      <DCSection
        id="manager"
        title="Manager · admin"
        subtitle="Desktop browser or 13″ tablet · 1440×900 · oversight, menu, reports, audit"
      >
        <DCArtboard id="mg-floor"   label="Live floor + alerts"    width={1440} height={900}><MG_Floor/></DCArtboard>
        <DCArtboard id="mg-menu"    label="Menu admin · kill-switch" width={1440} height={900}><MG_Menu/></DCArtboard>
        <DCArtboard id="mg-reports" label="Reports · shift KPIs"   width={1440} height={900}><MG_Reports/></DCArtboard>
        <DCArtboard id="mg-audit"   label="Audit log · full trail" width={1440} height={900}><MG_Audit/></DCArtboard>
        <DCArtboard id="mg-settings" label="Sistem · server & config" width={1180} height={1480}>
          <div style={{ width: 1180, minHeight: 1480, background: 'var(--bg-0)', display: 'flex', flexDirection: 'column' }}>
            <SettingsScreen sync="live" onToggleSync={() => {}}/>
          </div>
        </DCArtboard>
        <DCArtboard id="mg-staff" label="Staff & akun · RBAC" width={1180} height={1280}>
          <div style={{ width: 1180, minHeight: 1280, background: 'var(--bg-0)', display: 'flex', flexDirection: 'column' }}>
            <StaffScreen/>
          </div>
        </DCArtboard>
      </DCSection>

      <DCSection
        id="expediter"
        title="Expediter · pass"
        subtitle="Optional role · tablet at the pass · venues > 80 covers"
      >
        <DCArtboard id="ex-pass" label="Expediter cards"           width={1180} height={820}><EX_Pass/></DCArtboard>
      </DCSection>

    </DesignCanvas>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App/>);

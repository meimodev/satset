// SatSet — TABLET app. Single file, contains shell + all screens.
/* global React, ReactDOM, Icons, SATSET_DATA, formatIDR, ALLERGEN_CODES, ALLERGEN_NAMES, courseFromCategory, statusText, statusLabel, zoneName, LineItemActionSheet, TweaksPanel, useTweaks, TweakSection, TweakRadio, TweakToggle, TweakButton */

const { useState, useEffect, useMemo, useCallback, useRef } = React;

// ─────────────────────────────────────────────────────────────────────
//  Shell — left rail + topbar
// ─────────────────────────────────────────────────────────────────────
function Shell({ activeTab, onTab, crumbs, sync = 'live', readyCount = 0, onEndShift, children, extras }) {
  return (
    <div className="tab-screen">
      <div className="tab-rail">
        <div className="tab-mark">S</div>
        <div className="tab-nav">
          <NavBtn id="tables" active={activeTab === 'tables'} onTab={onTab} Ic={Icons.Tables} label="Meja" />
          <NavBtn id="orders" active={activeTab === 'orders'} onTab={onTab} Ic={Icons.Orders} label="Pesanan" badge={readyCount} alert={readyCount > 0}/>
          <NavBtn id="kds"    active={activeTab === 'kds'}    onTab={onTab} Ic={Icons.Fire}    label="KDS" />
          <div style={{ height: 1, width: 36, background: 'var(--border-0)', margin: '8px 0' }}></div>
          <NavBtn id="floor"   active={activeTab === 'floor'}   onTab={onTab} Ic={Icons.Pin}     label="Lantai" />
          <NavBtn id="menuadm" active={activeTab === 'menuadm'} onTab={onTab} Ic={Icons.Menu}    label="Menu" />
          <NavBtn id="reports" active={activeTab === 'reports'} onTab={onTab} Ic={Icons.Sparkle} label="Laporan" />
          <NavBtn id="audit"   active={activeTab === 'audit'}   onTab={onTab} Ic={Icons.Clock}   label="Audit" />
          <div style={{ height: 1, width: 36, background: 'var(--border-0)', margin: '8px 0' }}></div>
          <NavBtn id="expo"   active={activeTab === 'expo'}   onTab={onTab} Ic={Icons.Bell}    label="Expo" />
          <NavBtn id="settings" active={activeTab === 'settings'} onTab={onTab} Ic={Icons.Wifi} label="Sistem" />
          <NavBtn id="staff"    active={activeTab === 'staff'}    onTab={onTab} Ic={Icons.Me}   label="Staf" />
        </div>
        <div className="tab-rail-foot">
          <button
            className={'tab-avatar tab-avatar-btn ' + (activeTab === 'me' ? 'active' : '')}
            title="Saya · ringkasan shift"
            onClick={() => onTab('me')}
          >MA</button>
        </div>
      </div>

      <div className="tab-main">
        <div className="tab-topbar">
          {crumbs}
          <div className="tab-clock">
            <span className={'tab-sync ' + (sync === 'offline' ? 'offline' : '')}>
              <span className="dot"></span>
              {sync === 'offline' ? 'HANYA LAN · CLOUD TUNGGU' : 'LIVE · LAN'}
            </span>
            <span>18:14 · Sab</span>
          </div>
        </div>
        {children}
      </div>

      {extras}
    </div>
  );
}

function NavBtn({ id, active, onTab, Ic, label, badge, alert }) {
  return (
    <button className={'tab-nav-btn ' + (active ? 'active' : '')} onClick={() => onTab(id)}>
      <Ic size={22}/>
      <span>{label}</span>
      {!!badge && <span className={'badge ' + (alert ? 'alert' : '')}>{badge}</span>}
    </button>
  );
}

function Crumbs({ items }) {
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

// ─────────────────────────────────────────────────────────────────────
//  PIN screen (full width)
// ─────────────────────────────────────────────────────────────────────
function PinScreen({ onSignedIn }) {
  const [pin, setPin] = useState('');
  const max = 4;
  function press(d) {
    if (d === 'del') { setPin((p) => p.slice(0, -1)); return; }
    setPin((p) => {
      if (p.length >= max) return p;
      const next = p + d;
      if (next.length === max) setTimeout(onSignedIn, 220);
      return next;
    });
  }
  const keys = ['1','2','3','4','5','6','7','8','9','','0','del'];
  return (
    <div className="tab-screen">
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
            {Array.from({ length: max }).map((_, i) => (
              <div key={i} className={'tab-pin-dot ' + (i < pin.length ? 'filled' : '')}></div>
            ))}
          </div>
          <div className="tab-pin-pad">
            {keys.map((k, i) => {
              if (k === '') return <div key={i}/>;
              if (k === 'del') return <button key={i} className="tab-pin-key muted" onClick={() => press('del')}><Icons.Back size={22}/></button>;
              return <button key={i} className="tab-pin-key" onClick={() => press(k)}>{k}</button>;
            })}
          </div>
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────
//  Floor / Tables screen
// ─────────────────────────────────────────────────────────────────────
function FloorScreen({ activeZone, onZoneChange, onSelectTable, tables }) {
  const zone = SATSET_DATA.zones.find((z) => z.id === activeZone);
  const zoneTables = tables.filter((t) => t.zone === activeZone);
  const occupiedCount = zoneTables.filter((t) => t.status !== 'available').length;
  const readyCount = zoneTables.filter((t) => t.status === 'ready').length;

  const counts = useMemo(() => {
    const m = {};
    SATSET_DATA.zones.forEach((z) => {
      const t = tables.filter((tt) => tt.zone === z.id);
      m[z.id] = { total: t.length, ready: t.filter((tt) => tt.status === 'ready').length };
    });
    return m;
  }, [tables]);

  return (
    <div className="tab-content">
      <div className="tab-section-head">
        <div>
          <div className="tab-h1">{zone.name}</div>
          <div className="tab-sub">{occupiedCount} dari {zoneTables.length} terisi · {readyCount} siap diambil</div>
        </div>
      </div>

      <div className="tab-zones">
        {SATSET_DATA.zones.map((z) => (
          <button
            key={z.id}
            className={'tab-zone-btn ' + (activeZone === z.id ? 'active' : '')}
            onClick={() => onZoneChange(z.id)}
          >
            {z.name}
            <span className="count">{counts[z.id].ready > 0 ? counts[z.id].ready + ' siap' : counts[z.id].total}</span>
          </button>
        ))}
      </div>

      <div className="tab-tables-grid">
        {zoneTables.map((t) => (
          <button
            key={t.id}
            className={['tab-table-card', 's-' + t.status, t.mine ? 's-mine' : ''].join(' ')}
            onClick={() => onSelectTable(t.id)}
          >
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
          </button>
        ))}
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────
//  Table detail (left pane of split)
// ─────────────────────────────────────────────────────────────────────
function TableDetailPane({ tableId, table, tickets, onAdd, onFireCourse, onMarkServed, onTicketTap, mode, onCancelAdd }) {
  const courseOrder = ['drinks-now', 'starters', 'mains', 'sides', 'desserts'];
  const grouped = useMemo(() => {
    const m = {};
    tickets.forEach((t) => { m[t.course] = m[t.course] || []; m[t.course].push(t); });
    return m;
  }, [tickets]);
  const total = tickets.reduce((s, t) => s + (t.status === 'voided' ? 0 : t.price * t.qty), 0);
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
        {tickets.length === 0 ? (
          <div style={{ padding: '32px 14px', textAlign: 'center', color: 'var(--text-lo)', fontSize: 14 }}>
            Belum ada item — ketuk <b>Tambah pesanan</b> di kanan untuk mulai.
          </div>
        ) : courseOrder.map((cId) => {
          const items = grouped[cId];
          if (!items || items.length === 0) return null;
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
                <div
                  key={it.id}
                  className={'tab-line' + (it.status === 'ready' ? ' is-ready' : '') + (it.status === 'voided' ? ' is-voided' : '')}
                  onClick={() => onTicketTap && onTicketTap(it)}
                >
                  <div className="lq">×{it.qty}</div>
                  <div className="lbody">
                    <div className="lname">{it.name}{it.variantName ? ' · ' + it.variantName : ''}</div>
                    {it.modifiers && it.modifiers.length > 0 && (
                      <div className="lmods">{it.modifiers.join(' · ')}</div>
                    )}
                    {it.specialInstructions && (
                      <div className="lspecial">⚠ {it.specialInstructions}</div>
                    )}
                    {it.voidReason && (
                      <div className="lmods" style={{ color: 'var(--urgent)' }}>
                        Dibatalkan · {it.voidReason} · disetujui {it.voidApprovedBy}
                      </div>
                    )}
                    <div className="lfoot">
                      <span className={'li-status ' + it.status}>{statusText(it.status)}</span>
                      <span style={{ fontFamily: 'var(--font-mono)', fontSize: 10, color: 'var(--text-lo)', letterSpacing: '0.04em' }}>
                        {it.station === 'kitchen' ? 'DPR' : 'BAR'} · {it.sentAt}
                      </span>
                      <span className="lprice">{formatIDR(it.price * it.qty)}</span>
                    </div>
                    {it.status === 'ready' && (
                      <div style={{ marginTop: 10 }}>
                        <button className="tab-fire-btn" style={{ background: 'var(--success-soft)', color: 'var(--success)', borderColor: 'rgba(77,212,135,0.4)' }} onClick={(e) => { e.stopPropagation(); onMarkServed(it.id); }}>
                          <Icons.Check size={14}/> Tandai disajikan
                        </button>
                      </div>
                    )}
                  </div>
                </div>
              ))}
              {allHeld && (
                <button className="tab-fire-btn" style={{ marginTop: 4 }} onClick={() => onFireCourse(cId)}>
                  <Icons.Fire size={14}/> Kirim {course.name}
                </button>
              )}
            </div>
          );
        })}
      </div>

      <div className="tab-td-foot">
        {mode === 'adding' ? (
          <>
            <button className="btn-ghost" onClick={onCancelAdd}>
              <Icons.Close size={16}/> Batalkan
            </button>
            <div style={{ flex: 1, textAlign: 'center', fontSize: 12, color: 'var(--text-md)' }}>
              Pilih item di kanan — keranjang muncul otomatis
            </div>
          </>
        ) : (
          <button className="btn-primary" onClick={onAdd}>
            <Icons.Plus size={18}/>
            {tickets.length === 0 ? 'Buat pesanan' : 'Tambah pesanan'}
          </button>
        )}
      </div>
    </>
  );
}

// ─────────────────────────────────────────────────────────────────────
//  Context panel (right side when no add mode) — table stats + actions
// ─────────────────────────────────────────────────────────────────────
function TableContextPane({ table, tickets }) {
  const sent = tickets.filter((t) => t.status !== 'voided' && t.status !== 'served').length;
  const allergens = Array.from(new Set(tickets.flatMap((t) => {
    const item = SATSET_DATA.items.find((i) => i.id === t.itemId);
    return item ? item.allergens : [];
  })));
  const peanut = tickets.find((t) => t.specialInstructions && t.specialInstructions.toLowerCase().includes('kacang'));

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
          <div className="tab-statc">
            <div className="v">{tickets.length}</div>
            <div className="l">Total item</div>
          </div>
          <div className="tab-statc">
            <div className="v">{sent}</div>
            <div className="l">Dalam proses</div>
          </div>
          <div className="tab-statc">
            <div className="v">{tickets.filter((t) => t.status === 'served').length}</div>
            <div className="l">Disajikan</div>
          </div>
        </div>

        <div className="tab-card" style={{ marginBottom: 14 }}>
          <div className="tab-card-h">Catatan tamu</div>
          {peanut ? (
            <div style={{ display: 'flex', gap: 10, padding: '10px 12px', background: 'var(--urgent-soft)', border: '1px solid rgba(255,92,92,0.25)', borderRadius: 12, color: 'var(--urgent)', fontSize: 13, fontWeight: 500 }}>
              <Icons.Alert size={16}/>
              <span>Tamu alergi kacang — hindari saus kacang & garnish sate.</span>
            </div>
          ) : (
            <div style={{ color: 'var(--text-lo)', fontSize: 13 }}>Belum ada catatan khusus.</div>
          )}
        </div>

        <div className="tab-card" style={{ marginBottom: 14 }}>
          <div className="tab-card-h">Alergen di pesanan</div>
          {allergens.length === 0 ? (
            <div style={{ color: 'var(--text-lo)', fontSize: 13 }}>Tidak ada.</div>
          ) : (
            <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
              {allergens.map((a) => (
                <span key={a} className="h-pill urgent" style={{ fontSize: 12 }}>
                  <Icons.Alert size={11}/> {ALLERGEN_NAMES[a]}
                </span>
              ))}
            </div>
          )}
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

// ─────────────────────────────────────────────────────────────────────
//  Menu + cart pane (when in adding mode)
// ─────────────────────────────────────────────────────────────────────
function MenuAddPane({ tableId, table, tickets, cart, onOpenItem, onRemoveFromCart, onSend, onReview, onCancelAdd }) {
  const [cat, setCat] = useState('mains');
  const items = useMemo(() => {
    return SATSET_DATA.items.filter((i) => cat === 'all' || i.category === cat);
  }, [cat]);
  const inCart = useMemo(() => {
    const m = {};
    cart.forEach((c) => { m[c.itemId] = (m[c.itemId] || 0) + c.qty; });
    return m;
  }, [cart]);

  return (
    <>
      <div className="tab-menu-pane">
        <div className="tab-menu-head">
          <button className="back" onClick={onCancelAdd} title="Kembali ke detail meja">
            <Icons.Back size={18}/>
          </button>
          <div>
            <div className="htitle">Tambah ke Meja {tableId}</div>
            <div className="hsub">{zoneName(table.zone).toUpperCase()} · {table.pax} TAMU · {tickets.length} ITEM SUDAH KIRIM</div>
          </div>
          <div className="search">
            <Icons.Search size={14} stroke="var(--text-lo)"/>
            <span>Cari menu…</span>
          </div>
        </div>

        <div className="tab-cat-tabs">
          {SATSET_DATA.categories.map((c) => (
            <button key={c.id} className={'tab-cat-tab ' + (cat === c.id ? 'active' : '')} onClick={() => setCat(c.id)}>
              {c.name}
            </button>
          ))}
        </div>

        <div className="tab-item-grid">
          {items.map((it) => (
            <button
              key={it.id}
              className={'tab-item' + (inCart[it.id] ? ' has-some' : '') + (it.unavailable ? ' unavailable' : '')}
              onClick={() => !it.unavailable && onOpenItem(it)}
              disabled={it.unavailable}
            >
              <div className="img">
                {it.unavailable && <span className="killswitch">86'd</span>}
                {inCart[it.id] > 0 && <span className="qty-on">×{inCart[it.id]}</span>}
                <span className="img-lbl">PHOTO</span>
              </div>
              <div className="meta">
                <div className="name">{it.name}</div>
                <div className="price">{formatIDR(it.basePrice)}{it.variants && it.variants.length > 1 ? '+' : ''}</div>
                {it.allergens.length > 0 && (
                  <div className="allergens">
                    {it.allergens.map((a) => (
                      <span key={a} className="alg" title={ALLERGEN_NAMES[a]}>{ALLERGEN_CODES[a]}</span>
                    ))}
                  </div>
                )}
              </div>
            </button>
          ))}
        </div>
      </div>

      <CartPane tableId={tableId} table={table} cart={cart} onRemove={onRemoveFromCart} onSend={onSend} onReview={onReview}/>
    </>
  );
}

// ─────────────────────────────────────────────────────────────────────
//  Cart pane (right edge during add)
// ─────────────────────────────────────────────────────────────────────
function CartPane({ tableId, table, cart, onRemove, onSend, onReview }) {
  const courseOrder = ['drinks-now', 'starters', 'mains', 'sides', 'desserts', 'fire-now'];
  const grouped = useMemo(() => {
    const m = {};
    cart.forEach((c) => { m[c.course] = m[c.course] || []; m[c.course].push(c); });
    return m;
  }, [cart]);
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
          <div className="tab-cart-empty">
            Belum ada item di keranjang. Pilih dari menu di kiri.
          </div>
        ) : courseOrder.map((cId) => {
          const items = grouped[cId];
          if (!items || items.length === 0) return null;
          const course = SATSET_DATA.courses.find((c) => c.id === cId);
          const willFire = cId === 'fire-now' || cId === 'drinks-now';
          return (
            <div className="tab-course-block" key={cId}>
              <div className="ch">
                <span className="cdot" style={{ background: course.color }}></span>
                <span className="ctitle">{course.name}</span>
                <span className="cmeta">{willFire ? 'kirim otomatis' : 'ditahan'}</span>
              </div>
              {items.map((c) => (
                <div className="tab-line" key={c.id}>
                  <div className="lq">×{c.qty}</div>
                  <div className="lbody">
                    <div className="lname">{c.name}{c.variantName ? ' · ' + c.variantName : ''}</div>
                    {c.modifiers.length > 0 && <div className="lmods">{c.modifiers.join(' · ')}</div>}
                    {c.special && <div className="lspecial">⚠ {c.special}</div>}
                    <div className="lfoot">
                      <button onClick={() => onRemove(c.id)} style={{ fontSize: 12, color: 'var(--urgent)', display: 'flex', alignItems: 'center', gap: 4 }}>
                        <Icons.Trash size={12}/> Hapus
                      </button>
                      <span className="lprice">{formatIDR(c.unitPrice * c.qty)}</span>
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
          <button className="btn-send" onClick={onSend}>
            <Icons.Sparkle size={16}/>
            Kirim ke {kit > 0 && bar > 0 ? 'dapur + bar' : kit > 0 ? 'dapur' : 'bar'}
          </button>
        </div>
      )}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────
//  Modifier modal — centered, two-column layout
// ─────────────────────────────────────────────────────────────────────
function ModifierModal({ item, onAdd, onClose }) {
  const [variantId, setVariantId] = useState(item.variants[0].id);
  const [selections, setSelections] = useState(() => {
    const init = {};
    item.modifierGroups.forEach((g) => { init[g.id] = g.multi ? [] : null; });
    return init;
  });
  const [special, setSpecial] = useState('');
  const [course, setCourse] = useState(() => courseFromCategory(item.category));
  const [qty, setQty] = useState(1);

  function toggle(group, optId) {
    setSelections((s) => {
      const cur = s[group.id];
      if (group.multi) {
        const arr = Array.isArray(cur) ? cur : [];
        const next = arr.includes(optId) ? arr.filter((x) => x !== optId) : [...arr, optId];
        return { ...s, [group.id]: next };
      }
      return { ...s, [group.id]: optId };
    });
  }

  const valid = useMemo(() => item.modifierGroups.every((g) => {
    if (!g.required) return true;
    const v = selections[g.id];
    return g.multi ? Array.isArray(v) && v.length > 0 : !!v;
  }), [item.modifierGroups, selections]);

  const variant = item.variants.find((v) => v.id === variantId);
  const unit = useMemo(() => {
    let p = variant.price;
    item.modifierGroups.forEach((g) => {
      const v = selections[g.id];
      if (g.multi) (v || []).forEach((oid) => { const o = g.options.find((o) => o.id === oid); if (o) p += o.price; });
      else if (v) { const o = g.options.find((o) => o.id === v); if (o) p += o.price; }
    });
    return p;
  }, [variant, selections, item.modifierGroups]);

  function handleAdd() {
    const labels = [];
    item.modifierGroups.forEach((g) => {
      const v = selections[g.id];
      if (g.multi) (v || []).forEach((oid) => { const o = g.options.find((o) => o.id === oid); if (o) labels.push((o.price > 0 ? '+ ' : '') + o.name); });
      else if (v) { const o = g.options.find((o) => o.id === v); if (o) labels.push(o.name); }
    });
    onAdd({
      itemId: item.id,
      name: item.name,
      station: item.station,
      variantId, variantName: variant.name,
      modifiers: labels, modifierIds: selections,
      special, course, qty, unitPrice: unit,
      allergens: item.allergens,
    });
  }

  // Split groups across two columns
  const groups = [...(item.variants.length > 1 ? [{ id: '__size', name: 'Ukuran', required: true, multi: false, options: item.variants.map((v) => ({ id: v.id, name: v.name, price: v.price })) }] : []), ...item.modifierGroups];
  const mid = Math.ceil(groups.length / 2);
  const colA = groups.slice(0, mid);
  const colB = groups.slice(mid);

  return (
    <div className="tab-modal-scrim" onClick={onClose}>
      <div className="tab-modal" onClick={(e) => e.stopPropagation()}>
        <div className="tab-modal-head">
          <div className="img"/>
          <div className="info">
            <div className="name">{item.name}</div>
            <div className="desc">{item.description}</div>
          </div>
          <button className="tab-modal-close" onClick={onClose}><Icons.Close size={18}/></button>
        </div>

        {item.allergens.length > 0 && (
          <div className="tab-allergen-banner">
            <Icons.Alert size={16}/>
            Mengandung {item.allergens.map((a) => ALLERGEN_NAMES[a]).join(', ').toLowerCase()} — konfirmasi ke tamu
          </div>
        )}

        <div className="tab-modal-body">
          <ModColumn groups={colA} selections={selections} variantId={variantId} setVariantId={setVariantId} toggle={toggle} />
          <ModColumn groups={colB} selections={selections} variantId={variantId} setVariantId={setVariantId} toggle={toggle} />
        </div>

        <div className="tab-modal-col" style={{ padding: '0 22px 6px', borderTop: '1px solid var(--border-0)' }}>
          <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', padding: '14px 0 8px' }}>
            <span style={{ fontSize: 14, fontWeight: 600 }}>Course & catatan</span>
            <span style={{ fontFamily: 'var(--font-mono)', fontSize: 10, color: 'var(--text-lo)', letterSpacing: '0.08em' }}>WAKTU KIRIM</span>
          </div>
          <div className="course-chips" style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
            {['fire-now','drinks-now','starters','mains','desserts'].map((cId) => {
              const c = SATSET_DATA.courses.find((cc) => cc.id === cId);
              return (
                <button key={cId} className={'course-chip ' + (course === cId ? 'selected' : '')} onClick={() => setCourse(cId)}>
                  <span className="cdot" style={{ background: c.color }}></span>{c.name}
                </button>
              );
            })}
          </div>
          <textarea
            className={'special ' + (special ? 'warn-text' : '')}
            maxLength={80}
            value={special}
            onChange={(e) => setSpecial(e.target.value)}
            placeholder="Catatan khusus — pilihan terakhir, tampil merah di layar dapur"
            style={{ marginTop: 10 }}
          />
          <div className="char-count">{special.length} / 80</div>
        </div>

        <div className="tab-modal-foot">
          <div className="qty-stepper">
            <button onClick={() => setQty((q) => Math.max(1, q - 1))} disabled={qty <= 1}>−</button>
            <span className="v">{qty}</span>
            <button onClick={() => setQty((q) => Math.min(20, q + 1))}>+</button>
          </div>
          <div style={{ flex: 1, fontFamily: 'var(--font-mono)', fontSize: 12, color: 'var(--text-md)', textAlign: 'center' }}>
            {valid ? formatIDR(unit) + ' × ' + qty + ' = ' + formatIDR(unit * qty) : 'Pilih opsi yang wajib dulu'}
          </div>
          <button
            className="btn btn-primary"
            disabled={!valid}
            style={{ opacity: valid ? 1 : 0.4, minWidth: 200 }}
            onClick={handleAdd}
          >
            Tambah ke pesanan
          </button>
        </div>
      </div>
    </div>
  );
}

function ModColumn({ groups, selections, variantId, setVariantId, toggle }) {
  return (
    <div className="tab-modal-col">
      {groups.map((g) => (
        <div className="mod-group" key={g.id} style={{ padding: 0, borderBottom: 0, marginBottom: 14 }}>
          <div className="label" style={{ marginBottom: 8 }}>
            <span className="title">{g.name}</span>
            <span className={g.required ? 'req' : 'opt'}>
              {g.required ? 'WAJIB' : (g.multi ? 'PILIH BEBAS' : 'OPSIONAL')}
            </span>
          </div>
          <div className="mod-opts">
            {g.options.map((o) => {
              let selected, onClk;
              if (g.id === '__size') {
                selected = variantId === o.id;
                onClk = () => setVariantId(o.id);
              } else {
                const v = selections[g.id];
                selected = g.multi ? (v || []).includes(o.id) : v === o.id;
                onClk = () => toggle(g, o.id);
              }
              return (
                <button
                  key={o.id}
                  className={'mod-opt ' + (g.multi ? 'multi ' : '') + (selected ? 'selected' : '')}
                  onClick={onClk}
                >
                  <span className="check">{selected && <Icons.Check size={14}/>}</span>
                  <span className="name">{o.name}</span>
                  {o.price !== 0 && (
                    <span className="delta">{o.price > 0 ? '+ ' : '− '}{formatIDR(Math.abs(o.price))}</span>
                  )}
                </button>
              );
            })}
          </div>
        </div>
      ))}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────
//  Orders screen
// ─────────────────────────────────────────────────────────────────────
function OrdersScreen({ ticketsByTable, tables, onOpenTable }) {
  const [seg, setSeg] = useState('ready');
  const all = useMemo(() => {
    const out = [];
    Object.entries(ticketsByTable).forEach(([tid, tx]) => {
      const t = tables.find((tt) => tt.id === tid);
      if (!t || !t.mine) return;
      tx.forEach((x) => out.push({ ...x, tableId: tid, zone: t.zone }));
    });
    return out;
  }, [ticketsByTable, tables]);
  const ready = all.filter((t) => t.status === 'ready');
  const active = all.filter((t) => t.status === 'sent' || t.status === 'prep' || t.status === 'held');
  const done = all.filter((t) => t.status === 'served' || t.status === 'voided');
  const list = seg === 'ready' ? ready : seg === 'active' ? active : done;

  return (
    <div className="tab-content">
      <div className="tab-section-head">
        <div>
          <div className="tab-h1">Pesanan saya</div>
          <div className="tab-sub">{active.length} berjalan · {ready.length} siap diambil</div>
        </div>
      </div>

      <div className="tab-segs">
        <button className={'tab-seg ' + (seg === 'ready' ? 'active' : '')} onClick={() => setSeg('ready')}>
          Siap diambil <span className="count">{ready.length}</span>
        </button>
        <button className={'tab-seg ' + (seg === 'active' ? 'active' : '')} onClick={() => setSeg('active')}>
          Disiapkan <span className="count">{active.length}</span>
        </button>
        <button className={'tab-seg ' + (seg === 'done' ? 'active' : '')} onClick={() => setSeg('done')}>
          Selesai <span className="count">{done.length}</span>
        </button>
      </div>

      {list.length === 0 ? (
        <div style={{ padding: '60px 32px', textAlign: 'center', color: 'var(--text-lo)' }}>
          {seg === 'ready' ? 'Belum ada yang siap di pass.' :
           seg === 'active' ? 'Tidak ada item yang sedang disiapkan.' :
           'Belum ada item yang selesai pada sesi ini.'}
        </div>
      ) : (
        <div className="tab-orders-list">
          {list.map((t) => (
            <button key={t.id} className={'tab-order-row ' + (t.status === 'ready' ? 'is-ready' : '')} onClick={() => onOpenTable(t.tableId)}>
              <div className="otab">{t.tableId}</div>
              <div className="obody">
                <div className="oname">
                  {t.qty > 1 && <span style={{ color: 'var(--text-md)', fontFamily: 'var(--font-mono)', fontSize: 12, marginRight: 4 }}>×{t.qty}</span>}
                  {t.name}{t.variantName ? <span style={{ color: 'var(--text-md)' }}> · {t.variantName}</span> : null}
                </div>
                {t.modifiers && t.modifiers.length > 0 && (
                  <div className="omods">{t.modifiers.slice(0, 2).join(' · ')}{t.modifiers.length > 2 ? ' · …' : ''}</div>
                )}
                <div className="ofoot">
                  <span className={'li-status ' + t.status}>{statusText(t.status)}</span>
                  <span style={{ fontFamily: 'var(--font-mono)', fontSize: 10, color: 'var(--text-lo)', letterSpacing: '0.04em' }}>
                    {t.station === 'kitchen' ? 'DPR' : 'BAR'} · {t.sentAt}
                  </span>
                </div>
              </div>
              <Icons.Chev size={18} stroke="var(--text-lo)"/>
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────
//  Me screen
// ─────────────────────────────────────────────────────────────────────
function MeScreen({ tables, ticketsByTable, auditLog, onEndShift }) {
  const myTables = tables.filter((t) => t.mine);
  const ticketCount = myTables.reduce((s, t) => s + (ticketsByTable[t.id]?.length || 0), 0);
  const openCovers = myTables.reduce((s, t) => s + (t.status !== 'available' ? t.pax : 0), 0);
  const voidCount = auditLog.filter((a) => a.type === 'void').length;
  const compCount = auditLog.filter((a) => a.type === 'comp').length;

  return (
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
            <div className="tab-statc"><div className="v">{ticketCount}</div><div className="l">Tiket kirim</div></div>
            <div className="tab-statc"><div className="v">{openCovers}</div><div className="l">Tamu aktif</div></div>
            <div className="tab-statc" style={{ background: voidCount ? 'var(--urgent-soft)' : '' }}>
              <div className="v" style={{ color: voidCount ? 'var(--urgent)' : '' }}>{voidCount}</div>
              <div className="l">Pembatalan</div>
            </div>
            <div className="tab-statc" style={{ background: compCount ? 'var(--warn-soft)' : '' }}>
              <div className="v" style={{ color: compCount ? 'var(--warn)' : '' }}>{compCount}</div>
              <div className="l">Gratisan</div>
            </div>
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

          <button className="btn btn-outline" style={{ width: '100%' }} onClick={onEndShift}>
            Akhiri shift & keluar
          </button>
        </div>

        <div className="tab-me-col">
          <div className="tab-card">
            <div className="tab-card-h">
              Aktivitas terkini
              <span style={{ color: 'var(--text-dim)' }}>{auditLog.length} entri</span>
            </div>
            <div>
              {auditLog.length === 0 ? (
                <div style={{ color: 'var(--text-lo)', fontSize: 13, padding: '8px 0' }}>
                  Belum ada entri audit. Pembatalan, gratisan, dan perubahan setelah kirim akan tampil di sini.
                </div>
              ) : auditLog.slice(0, 7).map((a) => (
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
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────
//  Sent overlay
// ─────────────────────────────────────────────────────────────────────
function SentOverlay({ stations, tableId, latency, onDone }) {
  const [progress, setProgress] = useState(0);
  useEffect(() => {
    const t1 = setTimeout(() => setProgress(1), 280);
    const t2 = setTimeout(() => setProgress(2), 620);
    const t3 = setTimeout(onDone, 1900);
    return () => { clearTimeout(t1); clearTimeout(t2); clearTimeout(t3); };
  }, [onDone]);
  return (
    <div className="tab-sent-overlay">
      <div className="tab-sent-check">
        <svg width="60" height="60" viewBox="0 0 24 24" fill="none" stroke="var(--success)" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
          <path d="M5 12.5l4.5 4.5L19 7.5"/>
        </svg>
      </div>
      <div>
        <div className="tab-sent-title">Terkirim</div>
        <div className="tab-sent-sub">Pesanan Meja {tableId} sudah tampil di layar dapur & bar. Akan masuk antrian KDS dalam {latency}ms.</div>
      </div>
      <div className="tab-sent-stations">
        {stations.map((s, i) => (
          <div key={s} className="tab-sent-station">
            {progress > i ? (
              <span className="ok"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"><path d="M5 12.5l4.5 4.5L19 7.5"/></svg></span>
            ) : (
              <span style={{ width: 22, height: 22, borderRadius: '50%', border: '2px solid var(--border-2)', borderTopColor: 'var(--accent)', display: 'inline-block', animation: 'spin 0.8s linear infinite' }}></span>
            )}
            {s}
          </div>
        ))}
      </div>
      <div style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--text-lo)', letterSpacing: '0.1em', marginTop: 12 }}>
        LAN P50 {latency}MS · CLOUD MENUNGGU
      </div>
      <style>{`@keyframes spin { to { transform: rotate(360deg) } }`}</style>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────
//  Ready toast
// ─────────────────────────────────────────────────────────────────────
function ReadyToast({ alert, onView, onDismiss }) {
  useEffect(() => {
    if (!alert) return;
    const t = setTimeout(onDismiss, 6500);
    return () => clearTimeout(t);
  }, [alert, onDismiss]);
  if (!alert) return null;
  return (
    <div className="tab-ready-toast" onClick={onDismiss}>
      <div className="ic"><Icons.Bell size={20}/></div>
      <div className="body">
        <div className="t">Siap di pass · {alert.what}</div>
        <div className="d">MEJA {alert.tableId} · {alert.zone.toUpperCase()} · SEKARANG</div>
      </div>
      <button className="go" onClick={(e) => { e.stopPropagation(); onView(alert); }}>
        Ambil di pass
      </button>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────
//  Main App
// ─────────────────────────────────────────────────────────────────────
function TabletApp() {
  const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
    "syncMode": "live"
  }/*EDITMODE-END*/;
  const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);

  const [signedIn, setSignedIn] = useState(true);
  const [activeTab, setActiveTab] = useState('tables');
  const [activeZone, setActiveZone] = useState('terrace');
  const [selectedTable, setSelectedTable] = useState(null); // null = floor view
  const [mode, setMode] = useState('detail'); // 'detail' | 'adding'
  const [cart, setCart] = useState([]);
  const [modifierItem, setModifierItem] = useState(null);
  const [actionFlow, setActionFlow] = useState(null);
  const [readyAlert, setReadyAlert] = useState(null);
  const [sentOverlay, setSentOverlay] = useState(null);

  const [tables, setTables] = useState(SATSET_DATA.tables);
  const [ticketsByTable, setTicketsByTable] = useState(
    () => JSON.parse(JSON.stringify(SATSET_DATA.initialTicketsByTable))
  );
  const [auditLog, setAuditLog] = useState([
    { id: 'A0', type: 'fire', title: 'Kirim Utama untuk Meja T1', tableId: 'T1', when: '17:46' },
  ]);

  // Set dark theme on mount
  useEffect(() => {
    document.documentElement.setAttribute('data-theme', 'dark');
  }, []);

  const totalReadyCount = useMemo(
    () => tables.reduce((s, x) => s + (x.status === 'ready' ? (x.readyCount || 1) : 0), 0),
    [tables]
  );

  // ── Handlers ──────────────────────────────────────────────────────
  function nowStamp() {
    const d = new Date();
    return String(d.getHours()).padStart(2, '0') + ':' + String(d.getMinutes()).padStart(2, '0');
  }
  function stationsFromCart(c) {
    return [...new Set(c.map((x) => x.station))].map((x) => x === 'kitchen' ? 'Dapur' : 'Bar');
  }

  const selectTable = useCallback((id) => {
    setSelectedTable(id); setMode('detail');
  }, []);
  const backToFloor = useCallback(() => {
    setSelectedTable(null); setMode('detail'); setCart([]);
  }, []);

  const onAdd = useCallback(() => setMode('adding'), []);
  const onCancelAdd = useCallback(() => { setMode('detail'); setCart([]); }, []);

  const openItem = useCallback((item) => setModifierItem(item), []);
  const addToCart = useCallback((ci) => {
    setCart((c) => [...c, { ...ci, id: 'C' + Date.now() + '-' + c.length }]);
    setModifierItem(null);
  }, []);
  const removeFromCart = useCallback((id) => setCart((c) => c.filter((x) => x.id !== id)), []);

  const sendOrder = useCallback(() => {
    const tableId = selectedTable;
    const stamp = nowStamp();
    const newTickets = cart.map((c, i) => ({
      id: 'N' + Date.now() + '-' + i,
      itemId: c.itemId, name: c.name, course: c.course, variantName: c.variantName,
      station: c.station, qty: c.qty, modifiers: c.modifiers, specialInstructions: c.special,
      price: c.unitPrice,
      status: (c.course === 'fire-now' || c.course === 'drinks-now') ? 'sent' : 'held',
      sentAt: stamp,
    }));
    setTicketsByTable((m) => ({ ...m, [tableId]: [...(m[tableId] || []), ...newTickets] }));
    setTables((ts) => ts.map((x) => x.id === tableId ? { ...x, status: 'pending', elapsed: x.elapsed || '0:01', mine: true } : x));
    setSentOverlay({ stations: stationsFromCart(cart), tableId, latency: 120 + Math.floor(Math.random() * 180) });
    setCart([]);
    setMode('detail');
  }, [cart, selectedTable]);

  const fireCourse = useCallback((courseId) => {
    if (!selectedTable) return;
    setTicketsByTable((m) => ({
      ...m,
      [selectedTable]: m[selectedTable].map((it) =>
        it.course === courseId && it.status === 'held' ? { ...it, status: 'sent' } : it
      ),
    }));
    const cn = SATSET_DATA.courses.find((c) => c.id === courseId)?.name || courseId;
    setAuditLog((l) => [{ id: 'A' + Date.now(), type: 'fire', title: `Kirim ${cn} untuk Meja ${selectedTable}`, tableId: selectedTable, when: nowStamp() }, ...l]);
  }, [selectedTable]);

  const markServed = useCallback((id) => {
    if (!selectedTable) return;
    setTicketsByTable((m) => ({ ...m, [selectedTable]: m[selectedTable].map((it) => it.id === id ? { ...it, status: 'served' } : it) }));
    setTables((ts) => ts.map((tt) => {
      if (tt.id !== selectedTable) return tt;
      const rem = (tt.readyCount || 1) - 1;
      return rem <= 0 ? { ...tt, status: 'occupied', readyCount: 0 } : { ...tt, readyCount: rem };
    }));
  }, [selectedTable]);

  const openTicketAction = useCallback((ticket) => {
    setActionFlow({ ticket: { ...ticket, tableId: selectedTable }, step: 'actions' });
  }, [selectedTable]);

  const pickAction = useCallback((id) => {
    setActionFlow((f) => {
      if (!f) return f;
      if (id === 'void') return { ...f, step: 'void-reason' };
      if (id === 'fire')  { fireCourse(f.ticket.course); return null; }
      if (id === 'serve') { markServed(f.ticket.id); return null; }
      if (id === 'modify' || id === 'request-modify') {
        setAuditLog((l) => [{ id: 'A' + Date.now(), type: 'modify', title: `Ubah ×${f.ticket.qty} ${f.ticket.name}`, tableId: f.ticket.tableId, when: nowStamp(), reason: id === 'request-modify' ? 'Menunggu konfirmasi station' : 'Edit sebelum prep' }, ...l]);
        return null;
      }
      return f;
    });
  }, [fireCourse, markServed]);

  const pickVoidReason = useCallback((reason) => {
    setActionFlow((f) => f ? { ...f, step: 'manager-pin', reason } : f);
  }, []);
  const approveVoid = useCallback((approval) => {
    setActionFlow((f) => {
      if (!f) return f;
      setTicketsByTable((m) => ({ ...m, [f.ticket.tableId]: m[f.ticket.tableId].map((it) => it.id === f.ticket.id ? { ...it, status: 'voided', voidReason: f.reason.label, voidApprovedBy: approval.approver } : it) }));
      setAuditLog((l) => [{ id: 'A' + Date.now(), type: 'void', title: `Batal ×${f.ticket.qty} ${f.ticket.name} (Rp ${f.ticket.price.toLocaleString('id-ID')})`, tableId: f.ticket.tableId, when: nowStamp(), reason: f.reason.label + (f.reason.text ? ' — "' + f.reason.text + '"' : ''), approvedBy: approval.approver }, ...l]);
      return { ...f, step: 'confirmed' };
    });
  }, []);

  const triggerReady = useCallback(() => {
    setReadyAlert({ tableId: 'T2', zone: 'Teras', what: 'Tempe Sambal Bowl + Mie Goreng' });
  }, []);

  // ── Render selection ──────────────────────────────────────────────
  const sync = t.syncMode === 'offline' ? 'offline' : 'live';
  const selTable = tables.find((tt) => tt.id === selectedTable);
  const selTickets = (selectedTable && ticketsByTable[selectedTable]) || [];

  if (!signedIn) {
    return (
      <div className="tab-stage">
        <div className="tab-ipad">
          <PinScreen onSignedIn={() => setSignedIn(true)}/>
        </div>
      </div>
    );
  }

  function crumbs() {
    if (activeTab === 'orders') return <Crumbs items={[zoneName(activeZone), 'Pesanan saya']}/>;
    if (activeTab === 'me')     return <Crumbs items={['Maya Anjani', 'Ringkasan shift']}/>;
    if (activeTab === 'kds')    return <Crumbs items={['Stasiun', 'Dapur Utama', 'KDS · live queue']}/>;
    if (activeTab === 'floor')   return <Crumbs items={['Manajer', 'Live floor']}/>;
    if (activeTab === 'menuadm') return <Crumbs items={['Manajer', 'Menu admin']}/>;
    if (activeTab === 'reports') return <Crumbs items={['Manajer', 'Laporan shift']}/>;
    if (activeTab === 'audit')   return <Crumbs items={['Manajer', 'Audit log']}/>;
    if (activeTab === 'expo')    return <Crumbs items={['Expediter', 'Pass · live']}/>;
    if (activeTab === 'settings') return <Crumbs items={['Sistem', 'Server & konfigurasi']}/>;
    if (activeTab === 'staff')    return <Crumbs items={['Sistem', 'Staff & akun']}/>;
    if (selectedTable) {
      return <Crumbs items={[zoneName(selTable.zone), 'Meja ' + selectedTable, mode === 'adding' ? 'Tambah item' : 'Detail']}/>;
    }
    return <Crumbs items={['Warung Sebelah', zoneName(activeZone)]}/>;
  }

  let content;
  if (activeTab === 'tables') {
    if (selectedTable) {
      if (mode === 'adding') {
        content = (
          <div className="tab-split">
            <MenuAddPane
              tableId={selectedTable}
              table={selTable}
              tickets={selTickets}
              cart={cart}
              onOpenItem={openItem}
              onRemoveFromCart={removeFromCart}
              onSend={sendOrder}
              onReview={() => {}}
              onCancelAdd={onCancelAdd}
            />
          </div>
        );
      } else {
        content = (
          <div className="tab-split">
            <div className="tab-pane size-md">
              <TableDetailPane
                tableId={selectedTable}
                table={selTable}
                tickets={selTickets}
                onAdd={onAdd}
                onCancelAdd={onCancelAdd}
                onFireCourse={fireCourse}
                onMarkServed={markServed}
                onTicketTap={openTicketAction}
                mode={mode}
              />
            </div>
            <div className="tab-pane" style={{ flex: 1 }}>
              <TableContextPane table={selTable} tickets={selTickets}/>
            </div>
          </div>
        );
      }
    } else {
      content = <FloorScreen activeZone={activeZone} onZoneChange={setActiveZone} onSelectTable={selectTable} tables={tables}/>;
    }
  } else if (activeTab === 'orders') {
    content = <OrdersScreen ticketsByTable={ticketsByTable} tables={tables} onOpenTable={(id) => { setActiveTab('tables'); selectTable(id); }}/>;
  } else if (activeTab === 'me') {
    content = <MeScreen tables={tables} ticketsByTable={ticketsByTable} auditLog={auditLog} onEndShift={() => { setSignedIn(false); setActiveTab('tables'); setSelectedTable(null); setMode('detail'); }}/>;
  } else if (activeTab === 'kds') {
    content = (
      <>
        <div className="embedded-strip">
          <div>
            <div className="h1">KDS · Dapur Utama</div>
            <div className="sub">3 NEW · 4 PREP · 2 HELD · AVG 8:42 · 6 CLIENTS</div>
          </div>
          <div style={{ marginLeft: 'auto', display: 'flex', gap: 10 }}>
            <span className="tab-sync"><span className="dot"></span>SERVER OK</span>
            <button className="kds-btn" style={{ width: 'auto', padding: '0 14px' }}>Pair device</button>
          </div>
        </div>
        <KDS_Main/>
      </>
    );
  } else if (activeTab === 'floor') {
    content = <MG_Floor/>;
  } else if (activeTab === 'menuadm') {
    content = <MG_Menu/>;
  } else if (activeTab === 'reports') {
    content = <MG_Reports/>;
  } else if (activeTab === 'audit') {
    content = <MG_Audit/>;
  } else if (activeTab === 'expo') {
    content = <EX_Pass/>;
  } else if (activeTab === 'settings') {
    content = <SettingsScreen sync={sync} onToggleSync={() => setTweak('syncMode', t.syncMode === 'offline' ? 'live' : 'offline')}/>;
  } else if (activeTab === 'staff') {
    content = <StaffScreen/>;
  }

  return (
    <div className="tab-stage">
      <div className="tab-ipad">
        <Shell
          activeTab={activeTab}
          onTab={(tab) => { setActiveTab(tab); if (tab === 'tables') {/* keep selectedTable */} }}
          crumbs={
            <>
              {selectedTable && activeTab === 'tables' && (
                <button className="iconbtn" onClick={backToFloor} style={{ marginRight: 6 }}>
                  <Icons.Back size={18}/>
                </button>
              )}
              {crumbs()}
            </>
          }
          sync={sync}
          readyCount={totalReadyCount}
        >
          {content}
          {modifierItem && (
            <ModifierModal item={modifierItem} onAdd={addToCart} onClose={() => setModifierItem(null)}/>
          )}
          {sentOverlay && (
            <SentOverlay
              stations={sentOverlay.stations}
              tableId={sentOverlay.tableId}
              latency={sentOverlay.latency}
              onDone={() => setSentOverlay(null)}
            />
          )}
          {actionFlow && (
            <LineItemActionSheet
              ticket={actionFlow.ticket}
              table={selTable}
              step={actionFlow.step}
              onClose={() => setActionFlow(null)}
              onPick={pickAction}
              onVoidReason={pickVoidReason}
              onApprove={approveVoid}
              onComplete={() => setActionFlow(null)}
            />
          )}
          {readyAlert && (
            <ReadyToast
              alert={readyAlert}
              onView={(a) => { setReadyAlert(null); setActiveTab('tables'); selectTable(a.tableId); }}
              onDismiss={() => setReadyAlert(null)}
            />
          )}
          <a className="tab-aside-link" href="phone.html">PHONE VIEW →</a>
        </Shell>
      </div>

      <TweaksPanel>
        <TweakSection label="Status sistem">
          <TweakRadio
            label="Konektivitas"
            value={t.syncMode}
            onChange={(v) => setTweak('syncMode', v)}
            options={[
              { value: 'live', label: 'LAN + Cloud' },
              { value: 'offline', label: 'Hanya LAN' },
            ]}
          />
        </TweakSection>
        <TweakSection label="Demo cepat">
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 6 }}>
            <TweakButton label="Login PIN" onClick={() => setSignedIn(false)}/>
            <TweakButton label="Floor view" onClick={() => { setSignedIn(true); setActiveTab('tables'); setSelectedTable(null); setMode('detail'); }}/>
            <TweakButton label="Detail T1" onClick={() => { setSignedIn(true); setActiveTab('tables'); selectTable('T1'); }}/>
            <TweakButton label="Tambah ke T1" onClick={() => { setSignedIn(true); setActiveTab('tables'); selectTable('T1'); setMode('adding'); }}/>
            <TweakButton label="Opsi item" onClick={() => {
              setSignedIn(true); setActiveTab('tables'); selectTable('T1'); setMode('adding');
              setModifierItem(SATSET_DATA.items.find((i) => i.id === 'nasi-goreng'));
            }}/>
            <TweakButton label="Cart terisi" onClick={() => {
              setSignedIn(true); setActiveTab('tables'); selectTable('T1'); setMode('adding');
              setCart([
                { id: 'D1', itemId: 'rendang', name: 'Rendang Sapi', station: 'kitchen', variantName: '', modifiers: ['Nasi putih'], modifierIds: {}, special: '', course: 'mains', qty: 1, unitPrice: 145000, allergens: ['nut'] },
                { id: 'D2', itemId: 'nasi-goreng', name: 'Nasi Goreng', station: 'kitchen', variantName: 'Reguler', modifiers: ['Udang', 'Sedang'], modifierIds: {}, special: '', course: 'mains', qty: 1, unitPrice: 113000, allergens: ['shellfish'] },
                { id: 'D3', itemId: 'margarita', name: 'Margarita Pedas', station: 'bar', variantName: '', modifiers: [], modifierIds: {}, special: '', course: 'drinks-now', qty: 2, unitPrice: 110000, allergens: [] },
              ]);
            }}/>
            <TweakButton label="Pesanan tab" onClick={() => { setSignedIn(true); setActiveTab('orders'); }}/>
            <TweakButton label="Saya tab" onClick={() => { setSignedIn(true); setActiveTab('me'); }}/>
            <TweakButton label="Alert siap" onClick={triggerReady}/>
            <TweakButton label="Alur batal" onClick={() => {
              setSignedIn(true); setActiveTab('tables'); selectTable('T1');
              const t = ticketsByTable['T1'].find((tt) => tt.status === 'prep');
              if (t) setActionFlow({ ticket: { ...t, tableId: 'T1' }, step: 'actions' });
            }}/>
            <TweakButton label="PIN manajer" onClick={() => {
              setSignedIn(true); setActiveTab('tables'); selectTable('T1');
              const t = ticketsByTable['T1'].find((tt) => tt.status === 'prep');
              if (t) setActionFlow({ ticket: { ...t, tableId: 'T1' }, step: 'manager-pin', reason: { id: 'allergy', label: 'Alergi / diet', text: null } });
            }}/>
          </div>
        </TweakSection>
      </TweaksPanel>
    </div>
  );
}

// Scale stage to fit viewport
function Root() {
  const ref = useRef(null);
  const [scale, setScale] = useState(1);
  useEffect(() => {
    function rc() {
      const w = window.innerWidth, h = window.innerHeight;
      const s = Math.min((w - 32) / 1180, (h - 32) / 820, 1);
      setScale(s);
    }
    rc();
    window.addEventListener('resize', rc);
    return () => window.removeEventListener('resize', rc);
  }, []);
  return (
    <div ref={ref} style={{ width: '100%', height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', overflow: 'hidden' }}>
      <div style={{ transform: `scale(${scale})`, transformOrigin: 'center center' }}>
        <TabletApp/>
      </div>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<Root/>);

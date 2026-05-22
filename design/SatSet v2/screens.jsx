// SatSet — screen components. Depends on window.{Icons, SATSET_DATA, formatIDR, ALLERGEN_CODES, ALLERGEN_NAMES}.
/* global React, Icons, SATSET_DATA, formatIDR, ALLERGEN_CODES, ALLERGEN_NAMES */

const { useState, useEffect, useMemo, useRef } = React;

// ─────────────────────────────────────────────────────────────────────
//  Top bar — zone selector + sync status + avatar (used inside the app)
// ─────────────────────────────────────────────────────────────────────
function TopBar({ activeZone, onSwitchZone, sync = 'connected' }) {
  const z = SATSET_DATA.zones.find((zz) => zz.id === activeZone) || SATSET_DATA.zones[0];
  return (
    <div className="topbar">
      <button className="zone-switch" onClick={onSwitchZone}>
        <Icons.Pin size={14}/>
        {z.name}
        <Icons.ChevDn size={14} stroke="currentColor"/>
      </button>
      <div className={'sync ' + (sync === 'offline' ? 'offline' : '')}>
        <span className="dot"></span>
        {sync === 'offline' ? 'HANYA LAN · CLOUD DITUNDA' : 'LIVE · LAN'}
      </div>
      <div className="avatar" title={SATSET_DATA.user.name}>MA</div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────
//  Bottom tab bar
// ─────────────────────────────────────────────────────────────────────
function TabBar({ active, onChange, readyCount = 0 }) {
  const tabs = [
    { id: 'tables', label: 'Meja',   Ic: Icons.Tables },
    { id: 'orders', label: 'Pesanan', Ic: Icons.Orders, badge: readyCount, alert: readyCount > 0 },
    { id: 'me',     label: 'Saya',   Ic: Icons.Me },
  ];
  return (
    <div className="tabbar">
      {tabs.map((t) => (
        <button
          key={t.id}
          className={'tab ' + (active === t.id ? 'active' : '')}
          onClick={() => onChange(t.id)}
        >
          <t.Ic size={20}/>
          <span>{t.label}</span>
          {!!t.badge && <span className={'badge ' + (t.alert ? 'alert' : '')}>{t.badge}</span>}
        </button>
      ))}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────
//  Reusable header (large title + subtitle row)
// ─────────────────────────────────────────────────────────────────────
function Header({ title, sub, right }) {
  return (
    <div className="h-row">
      <div>
        <div className="h-title">{title}</div>
        {sub && <div className="h-sub">{sub}</div>}
      </div>
      {right}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────
//  PIN screen — Maya signs in for her shift
// ─────────────────────────────────────────────────────────────────────
function PinScreen({ onSignedIn }) {
  const [pin, setPin] = useState('');
  const max = 4;

  function press(d) {
    if (d === 'del') {
      setPin((p) => p.slice(0, -1));
      return;
    }
    setPin((p) => {
      if (p.length >= max) return p;
      const next = p + d;
      if (next.length === max) setTimeout(() => onSignedIn(), 220);
      return next;
    });
  }

  const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', 'del'];

  return (
    <div className="pin-screen">
      <div className="pin-brand">
        <div className="mark">S</div>
        <div className="wordmark">satset</div>
        <div className="venue">
          {SATSET_DATA.venue.name.toUpperCase()}<br/>
          {SATSET_DATA.venue.address.toUpperCase()}
        </div>
      </div>

      <div className="pin-greet">Selamat sore</div>
      <div className="pin-name">{SATSET_DATA.user.name},<br/>masukkan PIN</div>
      <div className="pin-shift">Pelayan · Zona Teras · mulai 17:30</div>

      <div className="pin-dots">
        {Array.from({ length: max }).map((_, i) => (
          <div key={i} className={'pin-dot ' + (i < pin.length ? 'filled' : '')}></div>
        ))}
      </div>

      <div className="pin-pad">
        {keys.map((k, i) => {
          if (k === '') return <div key={i}/>;
          if (k === 'del') {
            return (
              <button key={i} className="pin-key muted" onClick={() => press('del')}>
                <Icons.Back size={18}/>
              </button>
            );
          }
          return (
            <button key={i} className="pin-key" onClick={() => press(k)}>{k}</button>
          );
        })}
      </div>

      <div className="pin-foot">PIN BERAKHIR DI AKHIR SHIFT · BYOD</div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────
//  Tables / Floor screen
// ─────────────────────────────────────────────────────────────────────
function TablesScreen({ activeZone, onZoneChange, onSelectTable, tables }) {
  const counts = useMemo(() => {
    const map = {};
    SATSET_DATA.zones.forEach((z) => {
      const t = tables.filter((tt) => tt.zone === z.id);
      map[z.id] = {
        total: t.length,
        ready: t.filter((tt) => tt.status === 'ready').length,
      };
    });
    return map;
  }, [tables]);

  const zoneTables = tables.filter((t) => t.zone === activeZone);
  const zone = SATSET_DATA.zones.find((z) => z.id === activeZone);

  const occupiedCount = zoneTables.filter((t) => t.status !== 'available').length;
  const readyCount = zoneTables.filter((t) => t.status === 'ready').length;

  return (
    <>
      <Header
        title={zone.name}
        sub={`${occupiedCount} dari ${zoneTables.length} terisi · ${readyCount} siap`}
      />

      <div className="zone-tabs">
        {SATSET_DATA.zones.map((z) => (
          <button
            key={z.id}
            className={'zone-tab ' + (activeZone === z.id ? 'active' : '')}
            onClick={() => onZoneChange(z.id)}
          >
            {z.name}
            <span className="count">
              {counts[z.id].ready > 0 ? `${counts[z.id].ready}·sp` : counts[z.id].total}
            </span>
          </button>
        ))}
      </div>

      <div className="body-scroll">
        <div className="tables-grid">
          {zoneTables.map((t) => (
            <button
              key={t.id}
              className={[
                'table-card',
                's-' + t.status,
                t.mine ? 's-mine' : '',
              ].join(' ')}
              onClick={() => onSelectTable(t.id)}
            >
              <div className="row1">
                <div className="tnum">{t.id}</div>
                <div className="pax">{t.pax}p</div>
              </div>
              <div className="row2">
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, minWidth: 0 }}>
                  <span className="status-dot"></span>
                  <span className="status-lbl">{statusLabel(t)}</span>
                </div>
                {t.elapsed && <div className="timer">{t.elapsed}</div>}
              </div>
            </button>
          ))}
        </div>
      </div>
    </>
  );
}

function statusLabel(t) {
  switch (t.status) {
    case 'available': return 'Kosong';
    case 'occupied':  return 'Terisi';
    case 'pending':   return 'Masuk';
    case 'ready':     return `Siap ×${t.readyCount || 1}`;
    default: return t.status;
  }
}

// ─────────────────────────────────────────────────────────────────────
//  Table detail — current open order, course-grouped, with Add CTA
// ─────────────────────────────────────────────────────────────────────
function TableDetailScreen({ tableId, table, tickets, onAdd, onBack, onMarkServed, onFireCourse, onTicketTap }) {
  const grouped = useMemo(() => {
    const byCourse = {};
    tickets.forEach((t) => {
      byCourse[t.course] = byCourse[t.course] || [];
      byCourse[t.course].push(t);
    });
    return byCourse;
  }, [tickets]);

  const courseOrder = ['drinks-now', 'starters', 'mains', 'sides', 'desserts'];
  const total = tickets.reduce((s, t) => s + t.price * t.qty, 0);
  const readyAny = tickets.some((t) => t.status === 'ready');

  return (
    <>
      <div className="topbar">
        <button className="iconbtn" onClick={onBack}>
          <Icons.Back size={20}/>
        </button>
        <div className={'sync'}>
          <span className="dot"></span>
          T+{table.elapsed || '—'}
        </div>
        <div className="avatar">MA</div>
      </div>

      <div className="td-header">
        <div className="num">{tableId}</div>
        <div className="info">
          <div className="zoneline">{zoneName(table.zone)} · {table.pax} tamu</div>
          <div className="meta">
            <span className="h-pill"><Icons.Clock size={12}/> duduk {table.elapsed || '0:00'}</span>
            <span className="h-pill">{formatIDR(total)}</span>
          </div>
        </div>
      </div>

      {readyAny && (
        <div className="allergen-banner" style={{ background: 'var(--success-soft)', borderColor: 'rgba(77, 212, 135, 0.3)', color: 'var(--success)' }}>
          <Icons.Bell size={14}/> Ada item siap di pass — tandai sudah disajikan di bawah
        </div>
      )}

      <div className="body-scroll" style={{ paddingBottom: 180 }}>
        {courseOrder.map((cId) => {
          const items = grouped[cId];
          if (!items || items.length === 0) return null;
          const course = SATSET_DATA.courses.find((c) => c.id === cId);
          const allHeld = items.every((it) => it.status === 'held');
          return (
            <div className="course-block" key={cId}>
              <div className="ch">
                <span className="cdot" style={{ background: course.color }}></span>
                <span className="ctitle">{course.name}</span>
                <span className="cmeta">
                  {items.length} item{allHeld ? ' · ditahan' : ''}
                </span>
              </div>
              {items.map((it) => (
                <div
                  key={it.id}
                  className={
                    'line-item tappable' +
                    (it.status === 'ready' ? ' is-ready' : '') +
                    (it.status === 'voided' ? ' is-voided' : '')
                  }
                  onClick={() => onTicketTap && onTicketTap(it)}
                >
                  <div className="qty">×{it.qty}</div>
                  <div className="li-body">
                    <div className="li-name">{it.name}{it.variantName ? ' · ' + it.variantName : ''}</div>
                    {it.modifiers && it.modifiers.length > 0 && (
                      <div className="li-mods">{it.modifiers.join(' · ')}</div>
                    )}
                    {it.specialInstructions && (
                      <div className="li-special">⚠ {it.specialInstructions}</div>
                    )}
                    {it.voidReason && (
                      <div className="li-mods" style={{ color: 'var(--urgent)' }}>
                        Dibatalkan · {it.voidReason} · disetujui {it.voidApprovedBy}
                      </div>
                    )}
                    <div className="li-foot">
                      <span className={'li-status ' + it.status}>{statusText(it.status)}</span>
                      <span style={{ fontFamily: 'var(--font-mono)', fontSize: 10, color: 'var(--text-lo)', letterSpacing: '0.04em' }}>
                        {it.station === 'kitchen' ? 'DPR' : 'BAR'} · {it.sentAt}
                      </span>
                      <span className="li-price">{formatIDR(it.price * it.qty)}</span>
                    </div>
                    {it.status === 'ready' && (
                      <div className="course-actions" style={{ marginTop: 8 }}>
                        <button
                          className="fire-btn"
                          style={{ background: 'var(--success-soft)', color: 'var(--success)', borderColor: 'rgba(77, 212, 135, 0.4)' }}
                          onClick={(e) => { e.stopPropagation(); onMarkServed(it.id); }}
                        >
                          <Icons.Check size={14}/> Tandai disajikan
                        </button>
                      </div>
                    )}
                  </div>
                </div>
              ))}
              {allHeld && (
                <div className="course-actions">
                  <button className="fire-btn" onClick={() => onFireCourse(cId)}>
                    <Icons.Fire size={14}/> Kirim {course.name}
                  </button>
                </div>
              )}
            </div>
          );
        })}

        {tickets.length === 0 && (
          <div style={{ padding: '32px 24px', textAlign: 'center', color: 'var(--text-lo)', fontSize: 13 }}>
            Belum ada item — ketuk “Tambah pesanan” untuk mulai.
          </div>
        )}
      </div>

      <div className="fab-row">
        <button className="btn btn-primary" onClick={onAdd}>
          <Icons.Plus size={18}/>
          {tickets.length === 0 ? 'Buat pesanan' : 'Tambah pesanan'}
        </button>
      </div>
    </>
  );
}

function statusText(s) {
  return { sent: 'Terkirim', prep: 'Disiapkan', ready: 'Siap diambil', served: 'Disajikan', held: 'Ditahan', voided: 'Dibatalkan' }[s] || s;
}

function capitalize(s) {
  return s ? s[0].toUpperCase() + s.slice(1) : '';
}

function zoneName(zoneId) {
  const z = SATSET_DATA.zones.find((zz) => zz.id === zoneId);
  return z ? z.name : capitalize(zoneId);
}

// ─────────────────────────────────────────────────────────────────────
//  Menu / order entry — browse and tap to add
// ─────────────────────────────────────────────────────────────────────
function MenuScreen({ tableId, table, cart, onOpenItem, onReview, onBack, onQuickInc }) {
  const [cat, setCat] = useState('mains');
  const items = useMemo(() => {
    return SATSET_DATA.items.filter((i) => cat === 'all' || i.category === cat);
  }, [cat]);

  const cartCount = cart.reduce((s, c) => s + c.qty, 0);
  const cartTotal = cart.reduce((s, c) => s + c.unitPrice * c.qty, 0);

  // map itemId -> qty in current cart for the badge on item cards
  const inCart = useMemo(() => {
    const m = {};
    cart.forEach((c) => { m[c.itemId] = (m[c.itemId] || 0) + c.qty; });
    return m;
  }, [cart]);

  return (
    <>
      <div className="topbar">
        <button className="iconbtn" onClick={onBack}>
          <Icons.Back size={20}/>
        </button>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span className="h-pill accent">
            <Icons.Pin size={11}/> Meja {tableId} · {table.pax} tamu
          </span>
        </div>
        <button className="iconbtn"><Icons.Search size={18}/></button>
      </div>

      <Header title="Tambah item" sub="Ketuk untuk pilih opsi · tahan untuk pakai default" />

      <div className="search">
        <Icons.Search size={16} stroke="var(--text-lo)"/>
        <span>Cari menu…</span>
      </div>

      <div className="cat-tabs">
        {SATSET_DATA.categories.map((c) => (
          <button
            key={c.id}
            className={'cat-tab ' + (cat === c.id ? 'active' : '')}
            onClick={() => setCat(c.id)}
          >{c.name}</button>
        ))}
      </div>

      <div className="body-scroll">
        <div className="item-grid">
          {items.map((it) => (
            <button
              key={it.id}
              className={[
                'item-card',
                inCart[it.id] ? 'has-some' : '',
                it.unavailable ? 'unavailable' : '',
              ].join(' ')}
              onClick={() => !it.unavailable && onOpenItem(it)}
              disabled={it.unavailable}
            >
              <div className="img">
                {it.unavailable && <span className="killswitch">86'd</span>}
                {inCart[it.id] > 0 && (
                  <span className="qty-on">×{inCart[it.id]}</span>
                )}
                <span className="img-lbl">PHOTO</span>
              </div>
              <div className="meta">
                <div className="name">{it.name}</div>
                <div className="price">
                  {formatIDR(it.basePrice)}{it.variants && it.variants.length > 1 ? '+' : ''}
                </div>
                {it.allergens.length > 0 && (
                  <div className="allergen-row">
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

      {cartCount > 0 && (
        <div className="cart-footer">
          <div className="lhs">
            <div className="count">{cartCount} item belum terkirim</div>
            <div className="amt">{formatIDR(cartTotal)}</div>
          </div>
          <button className="send-btn" onClick={onReview}>
            Review<Icons.Chev size={16}/>
          </button>
        </div>
      )}
    </>
  );
}

// ─────────────────────────────────────────────────────────────────────
//  Modifier sheet — configures an item, then Add to order
// ─────────────────────────────────────────────────────────────────────
function ModifierSheet({ item, onAdd, onClose }) {
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

  // validation: required groups must have a selection
  const valid = useMemo(() => {
    return item.modifierGroups.every((g) => {
      if (!g.required) return true;
      const v = selections[g.id];
      return g.multi ? Array.isArray(v) && v.length > 0 : !!v;
    });
  }, [item.modifierGroups, selections]);

  // total price
  const variant = item.variants.find((v) => v.id === variantId);
  const unit = useMemo(() => {
    let p = variant.price;
    item.modifierGroups.forEach((g) => {
      const v = selections[g.id];
      if (g.multi) {
        (v || []).forEach((oid) => {
          const o = g.options.find((o) => o.id === oid);
          if (o) p += o.price;
        });
      } else if (v) {
        const o = g.options.find((o) => o.id === v);
        if (o) p += o.price;
      }
    });
    return p;
  }, [variant, selections, item.modifierGroups]);

  function handleAdd() {
    const modifierLabels = [];
    item.modifierGroups.forEach((g) => {
      const v = selections[g.id];
      if (g.multi) {
        (v || []).forEach((oid) => {
          const o = g.options.find((o) => o.id === oid);
          if (o) modifierLabels.push((o.price > 0 ? '+ ' : '') + o.name);
        });
      } else if (v) {
        const o = g.options.find((o) => o.id === v);
        if (o) modifierLabels.push(o.name);
      }
    });
    onAdd({
      itemId: item.id,
      name: item.name,
      station: item.station,
      variantId,
      variantName: variant.name,
      modifiers: modifierLabels,
      modifierIds: selections,
      special,
      course,
      qty,
      unitPrice: unit,
      allergens: item.allergens,
    });
  }

  return (
    <>
      <div className="sheet-scrim" onClick={onClose}/>
      <div className="sheet">
        <div className="grabber"></div>
        <div className="sheet-head">
          <div className="img"/>
          <div className="info">
            <div className="name">{item.name}</div>
            <div className="desc">{item.description}</div>
          </div>
          <button className="iconbtn" onClick={onClose}>
            <Icons.Close size={18}/>
          </button>
        </div>

        <div className="sheet-scroll">
          {item.allergens.length > 0 && (
            <div className="allergen-banner">
              <Icons.Alert size={14}/>
              Mengandung {item.allergens.map((a) => ALLERGEN_NAMES[a]).join(', ').toLowerCase()} — konfirmasi ke tamu
            </div>
          )}

          {item.variants.length > 1 && (
            <div className="mod-group">
              <div className="label">
                <span className="title">Ukuran</span>
                <span className="req">WAJIB</span>
              </div>
              <div className="mod-opts">
                {item.variants.map((v) => (
                  <button
                    key={v.id}
                    className={'mod-opt ' + (variantId === v.id ? 'selected' : '')}
                    onClick={() => setVariantId(v.id)}
                  >
                    <span className="check">{variantId === v.id && <Icons.Check size={14}/>}</span>
                    <span className="name">{v.name}</span>
                    <span className="delta">{formatIDR(v.price)}</span>
                  </button>
                ))}
              </div>
            </div>
          )}

          {item.modifierGroups.map((g) => (
            <div className="mod-group" key={g.id}>
              <div className="label">
                <span className="title">{g.name}</span>
                <span className={g.required ? 'req' : 'opt'}>
                  {g.required ? 'WAJIB' : (g.multi ? 'PILIH BEBAS' : 'OPSIONAL')}
                </span>
              </div>
              <div className="mod-opts">
                {g.options.map((o) => {
                  const v = selections[g.id];
                  const selected = g.multi ? (v || []).includes(o.id) : v === o.id;
                  return (
                    <button
                      key={o.id}
                      className={'mod-opt ' + (g.multi ? 'multi ' : '') + (selected ? 'selected' : '')}
                      onClick={() => toggle(g, o.id)}
                    >
                      <span className="check">{selected && <Icons.Check size={14}/>}</span>
                      <span className="name">{o.name}</span>
                      {o.price !== 0 && (
                        <span className="delta">
                          {o.price > 0 ? '+ ' : '− '}{formatIDR(Math.abs(o.price))}
                        </span>
                      )}
                    </button>
                  );
                })}
              </div>
            </div>
          ))}

          <div className="mod-group">
            <div className="label">
              <span className="title">Course</span>
              <span className="opt">WAKTU KIRIM</span>
            </div>
            <div className="course-chips">
              {[
                SATSET_DATA.courses.find((c) => c.id === 'fire-now'),
                SATSET_DATA.courses.find((c) => c.id === 'drinks-now'),
                SATSET_DATA.courses.find((c) => c.id === 'starters'),
                SATSET_DATA.courses.find((c) => c.id === 'mains'),
                SATSET_DATA.courses.find((c) => c.id === 'desserts'),
              ].map((c) => (
                <button
                  key={c.id}
                  className={'course-chip ' + (course === c.id ? 'selected' : '')}
                  onClick={() => setCourse(c.id)}
                >
                  <span className="cdot" style={{ background: c.color }}></span>
                  {c.name}
                </button>
              ))}
            </div>
          </div>

          <div className="mod-group" style={{ borderBottom: 0 }}>
            <div className="label">
              <span className="title">Catatan khusus</span>
              <span className="opt">PILIHAN TERAKHIR</span>
            </div>
            <textarea
              className={'special ' + (special ? 'warn-text' : '')}
              maxLength={80}
              value={special}
              onChange={(e) => setSpecial(e.target.value)}
              placeholder="mis. alergi yang belum tercantum, catatan penyajian…"
            />
            <div className="char-count">{special.length} / 80 · tampil merah di layar dapur</div>
          </div>
        </div>

        <div className="sheet-foot">
          <div className="qty-stepper">
            <button onClick={() => setQty((q) => Math.max(1, q - 1))} disabled={qty <= 1}>−</button>
            <span className="v">{qty}</span>
            <button onClick={() => setQty((q) => Math.min(20, q + 1))}>+</button>
          </div>
          <button
            className="btn btn-primary"
            disabled={!valid}
            style={{ opacity: valid ? 1 : 0.4 }}
            onClick={handleAdd}
          >
            {valid ? 'Tambah ke pesanan' : 'Pilih yang wajib'}
            {valid && <span className="amt">{formatIDR(unit * qty)}</span>}
          </button>
        </div>
      </div>
    </>
  );
}

function courseFromCategory(cat) {
  if (['cocktails', 'wine', 'beer', 'soft'].includes(cat)) return 'drinks-now';
  if (cat === 'starters') return 'starters';
  if (cat === 'mains') return 'mains';
  if (cat === 'desserts') return 'desserts';
  if (cat === 'sides') return 'mains';
  return 'fire-now';
}

// ─────────────────────────────────────────────────────────────────────
//  Review screen — confirm and send
// ─────────────────────────────────────────────────────────────────────
function ReviewScreen({ tableId, table, cart, onRemove, onEdit, onSend, onBack }) {
  const courseOrder = ['drinks-now', 'starters', 'mains', 'sides', 'desserts', 'fire-now'];
  const grouped = useMemo(() => {
    const m = {};
    cart.forEach((c) => {
      m[c.course] = m[c.course] || [];
      m[c.course].push(c);
    });
    return m;
  }, [cart]);

  const subtotal = cart.reduce((s, c) => s + c.unitPrice * c.qty, 0);
  const allergens = Array.from(new Set(cart.flatMap((c) => c.allergens)));
  const kitchenCt = cart.filter((c) => c.station === 'kitchen').reduce((s, c) => s + c.qty, 0);
  const barCt = cart.filter((c) => c.station === 'bar').reduce((s, c) => s + c.qty, 0);

  return (
    <>
      <div className="topbar">
        <button className="iconbtn" onClick={onBack}>
          <Icons.Back size={20}/>
        </button>
        <div className="sync"><span className="dot"></span>LIVE · LAN</div>
        <div className="avatar">MA</div>
      </div>

      <Header
        title="Review pesanan"
        sub={`Meja ${tableId} · ${table.pax} tamu · ${cart.reduce((s, c) => s + c.qty, 0)} item`}
      />

      <div className="body-scroll" style={{ paddingBottom: 140 }}>
        <div style={{ display: 'flex', gap: 8, padding: '0 16px 12px', flexWrap: 'wrap' }}>
          {kitchenCt > 0 && <span className="h-pill"><Icons.Fire size={11}/> Dapur × {kitchenCt}</span>}
          {barCt > 0 && <span className="h-pill"><Icons.Bag size={11}/> Bar × {barCt}</span>}
          {allergens.length > 0 && (
            <span className="h-pill urgent">
              <Icons.Alert size={11}/> {allergens.map((a) => ALLERGEN_NAMES[a]).join(' · ')}
            </span>
          )}
        </div>

        {courseOrder.map((cId) => {
          const items = grouped[cId];
          if (!items || items.length === 0) return null;
          const course = SATSET_DATA.courses.find((c) => c.id === cId);
          return (
            <div className="course-block" key={cId}>
              <div className="ch">
                <span className="cdot" style={{ background: course.color }}></span>
                <span className="ctitle">{course.name}</span>
                <span className="cmeta">
                  {cId === 'fire-now' || cId === 'drinks-now' ? 'kirim otomatis' : 'ditahan sampai dikirim'}
                </span>
              </div>
              {items.map((c, i) => (
                <div key={c.id || i} className="line-item">
                  <div className="qty">×{c.qty}</div>
                  <div className="li-body">
                    <div className="li-name">{c.name}{c.variantName ? ' · ' + c.variantName : ''}</div>
                    {c.modifiers.length > 0 && (
                      <div className="li-mods">{c.modifiers.join(' · ')}</div>
                    )}
                    {c.special && <div className="li-special">⚠ {c.special}</div>}
                    <div className="li-foot">
                      <button
                        style={{ fontSize: 12, color: 'var(--text-md)', padding: '4px 0', display: 'flex', alignItems: 'center', gap: 4 }}
                        onClick={() => onEdit(c.id)}
                      >
                        <Icons.Edit size={12}/> Ubah
                      </button>
                      <button
                        style={{ fontSize: 12, color: 'var(--urgent)', padding: '4px 0', display: 'flex', alignItems: 'center', gap: 4 }}
                        onClick={() => onRemove(c.id)}
                      >
                        <Icons.Trash size={12}/> Hapus
                      </button>
                      <span className="li-price">{formatIDR(c.unitPrice * c.qty)}</span>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          );
        })}

        <div className="review-totals">
          <div className="row"><span>Subtotal</span><span className="v">{formatIDR(subtotal)}</span></div>
          <div className="row"><span>Layanan · 7%</span><span className="v">{formatIDR(Math.round(subtotal * 0.07))}</span></div>
          <div className="row"><span>Pajak · 11%</span><span className="v">{formatIDR(Math.round(subtotal * 0.11))}</span></div>
          <div className="row total">
            <span>Perkiraan total</span>
            <span className="v">{formatIDR(Math.round(subtotal * 1.18))}</span>
          </div>
        </div>

        <div style={{ padding: '14px 20px 20px', fontSize: 11, color: 'var(--text-lo)', fontFamily: 'var(--font-mono)', letterSpacing: '0.04em', lineHeight: 1.5 }}>
          PEMBAYARAN DI LUAR SATSET · BILL CETAK DARI POS SAAT STATUS DISAJIKAN
        </div>
      </div>

      <div className="fab-row">
        <button className="btn btn-primary" onClick={onSend}>
          <Icons.Sparkle size={16}/>
          Kirim ke {kitchenCt > 0 && barCt > 0 ? 'dapur + bar' : kitchenCt > 0 ? 'dapur' : 'bar'}
          <span className="amt">{formatIDR(subtotal)}</span>
        </button>
      </div>
    </>
  );
}

// ─────────────────────────────────────────────────────────────────────
//  Sent confirmation screen
// ─────────────────────────────────────────────────────────────────────
function SentScreen({ stations, tableId, latency = 240, onDone }) {
  const [progress, setProgress] = useState(0);
  useEffect(() => {
    const t1 = setTimeout(() => setProgress(1), 280);
    const t2 = setTimeout(() => setProgress(2), 620);
    const t3 = setTimeout(() => onDone(), 1900);
    return () => { clearTimeout(t1); clearTimeout(t2); clearTimeout(t3); };
  }, [onDone]);
  return (
    <div className="sent-screen">
      <div className="sent-check">
        <svg width="46" height="46" viewBox="0 0 24 24" fill="none" stroke="var(--success)" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
          <path d="M5 12.5l4.5 4.5L19 7.5"/>
        </svg>
      </div>
      <div>
        <div className="sent-title">Terkirim</div>
        <div className="sent-sub">Pesanan Meja {tableId} sudah tampil di layar dapur dan bar.</div>
      </div>
      <div className="sent-stations">
        {stations.map((s, i) => (
          <div key={s} className="sent-station">
            {progress > i ? (
              <span className="delivered">
                <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"><path d="M5 12.5l4.5 4.5L19 7.5"/></svg>
              </span>
            ) : (
              <span style={{ width: 18, height: 18, borderRadius: '50%', border: '2px solid var(--border-2)', borderTopColor: 'var(--accent)', display: 'inline-block', animation: 'spin 0.8s linear infinite' }}></span>
            )}
            {s}
          </div>
        ))}
      </div>
      <div style={{ fontFamily: 'var(--font-mono)', fontSize: 10, color: 'var(--text-lo)', letterSpacing: '0.1em', whiteSpace: 'nowrap' }}>
        LAN P50 {latency}MS · CLOUD MENUNGGU
      </div>
      <style>{`@keyframes spin { to { transform: rotate(360deg) } }`}</style>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────
//  Ready toast — overlay alert when a table's food comes up
// ─────────────────────────────────────────────────────────────────────
function ReadyToast({ alert, onView, onDismiss }) {
  useEffect(() => {
    if (!alert) return;
    const t = setTimeout(onDismiss, 6000);
    return () => clearTimeout(t);
  }, [alert, onDismiss]);
  if (!alert) return null;
  return (
    <div className="ready-toast" onClick={onDismiss}>
      <div className="ic"><Icons.Bell size={18}/></div>
      <div className="body">
        <div className="t">Siap di pass · {alert.what}</div>
        <div className="d">MEJA {alert.tableId} · {alert.zone.toUpperCase()} · SEKARANG</div>
      </div>
      <button
        className="go"
        onClick={(e) => { e.stopPropagation(); onView(alert); }}
      >
        Ambil
      </button>
    </div>
  );
}

// Export to window so app.jsx can use them across script scopes
Object.assign(window, {
  TopBar, TabBar, Header, PinScreen, TablesScreen, TableDetailScreen,
  MenuScreen, ModifierSheet, ReviewScreen, SentScreen, ReadyToast,
  statusLabel, statusText, capitalize, zoneName, courseFromCategory,
});

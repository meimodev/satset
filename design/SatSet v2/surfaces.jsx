// SatSet — KDS / Manager / Expediter surfaces. All static artboards.
/* global React, Icons, SATSET_DATA, formatIDR */

// ─────────────────────────────────────────────────────────────────────
//  KDS — Kitchen Display System (Android tablet, wall-mounted)
//  1280 × 800, landscape.
// ─────────────────────────────────────────────────────────────────────
function KDS_Main() {
  // Hand-crafted ticket payload that exercises every state
  const cards = [
    {
      id: 'k1', table: 'T4', course: 'Pembuka', timer: '0:24', urg: '',
      status: 'new',
      items: [
        { n: 'Lumpia Renyah', q: 2, mods: [] },
      ],
      add: true,
    },
    {
      id: 'k2', table: 'T1', course: 'Utama', timer: '8:42', urg: 'warn',
      status: 'prep',
      items: [
        { n: 'Nasi Goreng', q: 1, mods: ['Ayam · Sedang · + Krupuk'], allergens: ['shellfish', 'egg'] },
        { n: 'Rendang Sapi', q: 1, mods: ['Nasi putih'], special: 'Alergi kacang — tanpa garnish sate', allergens: ['nut'] },
      ],
    },
    {
      id: 'k3', table: 'T2', course: 'Utama', timer: '11:14', urg: 'red',
      status: 'prep',
      items: [
        { n: 'Tempe Sambal Bowl', q: 1, mods: ['Sambal di pinggir'], allergens: ['soy', 'egg'] },
        { n: 'Mie Goreng', q: 1, mods: [], allergens: ['gluten', 'egg'] },
      ],
      refire: true,
    },
    {
      id: 'k4', table: 'G3', course: 'Pembuka', timer: '1:08', urg: '',
      status: 'new',
      items: [
        { n: 'Sate Ayam', q: 2, mods: [], allergens: ['nut', 'soy'] },
        { n: 'Gado-Gado', q: 1, mods: ['Sedikit pedas'], allergens: ['nut', 'soy', 'egg'] },
      ],
    },
    {
      id: 'k5', table: 'T1', course: 'Penutup', timer: '—', urg: '',
      status: 'held',
      items: [
        { n: 'Pisang Goreng + Es Krim', q: 2, mods: ['Vanila'], allergens: ['gluten', 'dairy', 'egg'] },
      ],
    },
    {
      id: 'k6', table: 'I4', course: 'Utama', timer: '6:18', urg: '',
      status: 'prep',
      items: [
        { n: 'Nasi Goreng', q: 2, mods: ['Udang · Pedas', 'Tahu · Tidak pedas'], allergens: ['shellfish', 'egg'] },
      ],
    },
    {
      id: 'k7', table: 'G1', course: 'Utama', timer: '3:32', urg: '',
      status: 'new',
      items: [
        { n: 'Rendang Sapi', q: 1, mods: ['Nasi uduk'], allergens: ['nut'] },
        { n: 'Mie Goreng', q: 1, mods: [], allergens: ['gluten', 'egg'] },
      ],
    },
    {
      id: 'k8', table: 'T2', course: 'Penutup', timer: '—', urg: '',
      status: 'held',
      items: [
        { n: 'Pisang Goreng', q: 1, mods: ['Kelapa'], allergens: ['gluten', 'dairy'] },
      ],
    },
  ];

  const ALG = { gluten: 'GL', nut: 'NU', dairy: 'DA', shellfish: 'SH', egg: 'EG', soy: 'SO', sesame: 'SE', sulfites: 'SU' };

  return (
    <div className="surface-frame kds-frame">
      <div className="kds-topbar">
        <div className="kds-station">
          <div className="kds-mark">S</div>
          <div className="kds-title">SatSet KDS</div>
        </div>
        <span className="kds-station-tag">DAPUR · UTAMA</span>
        <div className="kds-counters">
          <span>NEW <span className="v">3</span></span>
          <span>PREP <span className="v">4</span></span>
          <span>HELD <span className="v">2</span></span>
          <span>AVG <span className="v">8:42</span></span>
        </div>
        <div className="kds-clock">
          <span className="kds-health"><span className="dot"></span>SERVER OK · 6 CLIENTS</span>
          <span>SAB · 18:14:22</span>
        </div>
      </div>
      <div className="kds-body">
        {cards.map((c) => (
          <div key={c.id} className={['kds-card', c.urg ? 'urg-' + c.urg : '', 'is-' + c.status].join(' ')}>
            {c.add && <div className="badge add">+ ADD</div>}
            {c.refire && <div className="badge refire">REFIRE</div>}
            <div className="kds-card-head">
              <span className="table">{c.table}</span>
              <span className="course">{c.course}</span>
              <span className="timer">{c.timer}</span>
            </div>
            <div className="kds-card-body">
              {c.items.map((it, i) => (
                <div className="kds-card-item" key={i}>
                  <div className="nm">
                    <span className="qty">×{it.q}</span>
                    {it.n}
                  </div>
                  {it.mods && it.mods.length > 0 && (
                    <div className="mods">{it.mods.join(' · ')}</div>
                  )}
                  {it.special && <div className="special">⚠ {it.special}</div>}
                  {it.allergens && it.allergens.length > 0 && (
                    <div className="allergens">
                      {it.allergens.map((a) => (
                        <span key={a} className="alg">{ALG[a]}</span>
                      ))}
                    </div>
                  )}
                </div>
              ))}
            </div>
            <div className="kds-card-foot">
              {c.status === 'new' && (
                <>
                  <button className="kds-btn">Acknowledge</button>
                  <button className="kds-btn kds-btn-primary">Start prep</button>
                </>
              )}
              {c.status === 'prep' && (
                <>
                  <button className="kds-btn">Hold</button>
                  <button className="kds-btn kds-btn-success">Mark ready</button>
                </>
              )}
              {c.status === 'held' && (
                <button className="kds-btn">Awaiting fire signal…</button>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

function KDS_Server() {
  return (
    <div className="surface-frame kds-frame">
      <div className="kds-topbar">
        <div className="kds-station">
          <div className="kds-mark">S</div>
          <div className="kds-title">SatSet KDS</div>
        </div>
        <span className="kds-station-tag">SERVER STATUS</span>
        <div className="kds-counters" style={{ marginLeft: 'auto' }}>
          <span>UPTIME <span className="v">14h 12m</span></span>
          <span>LAST CLOUD PUSH <span className="v">12s</span></span>
        </div>
        <div className="kds-clock"><span>SAB · 18:14:22</span></div>
      </div>
      <div className="kds-server">
        <div className="kds-server-grid">
          <div className="kds-health-big">
            <div>
              <div className="title">Server health</div>
              <div className="v">All systems normal</div>
              <div className="sub">
                LAN latency P50 <b style={{ color: 'var(--text-hi)' }}>124 ms</b>, P95 <b style={{ color: 'var(--text-hi)' }}>312 ms</b><br/>
                CPU 24% · RAM 38% · disk 5.2 GB / 60 GB
              </div>
            </div>
            <div>
              <div style={{ fontFamily: 'var(--font-mono)', fontSize: 10, letterSpacing: '0.1em', color: 'var(--text-lo)', textTransform: 'uppercase', fontWeight: 600 }}>LATENCY · LAST 5 MIN</div>
              <div className="meter">
                {[1,2,3,4,5,6,7,8,9,10,11,12].map(i => <span key={i}></span>)}
              </div>
            </div>
          </div>

          <div className="kds-stat-card">
            <div className="lbl">Connected clients</div>
            <div className="v">6 / 8</div>
            <div className="sub">3 phones · 2 expo tablets · 1 manager desktop</div>
          </div>

          <div className="kds-stat-card">
            <div className="lbl">Cloud sync</div>
            <div className="v" style={{ color: 'var(--success)' }}>SYNCED</div>
            <div className="sub">142 events queued · pushing every 10 s</div>
          </div>

          <div className="kds-stat-card">
            <div className="lbl">Battery</div>
            <div className="v">98%</div>
            <div className="sub">Charging · est. forever (dock OK)</div>
          </div>

          <div className="kds-stat-card">
            <div className="lbl">Storage</div>
            <div className="v">8.6%</div>
            <div className="sub">5.2 GB used · 64 GB capacity</div>
          </div>
        </div>

        <div className="mg-card" style={{ marginTop: 18 }}>
          <div className="mg-card-h">
            <div className="t">Audit · last 6 cloud pushes</div>
            <div className="s">all events delivered</div>
          </div>
          {[
            { t: '18:14:11', n: '142 events', s: 'OK · 184ms', d: 'success' },
            { t: '18:14:01', n: '139 events', s: 'OK · 198ms', d: 'success' },
            { t: '18:13:51', n: '136 events', s: 'OK · 174ms', d: 'success' },
            { t: '18:13:41', n: '132 events', s: 'OK · 211ms', d: 'success' },
            { t: '18:13:31', n: '128 events', s: 'OK · 167ms', d: 'success' },
            { t: '18:13:21', n: '124 events', s: 'OK · 152ms', d: 'success' },
          ].map((r, i) => (
            <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 16, padding: '10px 0', borderBottom: '1px solid var(--border-0)', fontFamily: 'var(--font-mono)', fontSize: 12 }}>
              <span style={{ color: 'var(--text-md)', width: 80 }}>{r.t}</span>
              <span style={{ color: 'var(--text-hi)', width: 100 }}>{r.n}</span>
              <span style={{ color: 'var(--success)', flex: 1 }}>{r.s}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function KDS_Pair() {
  return (
    <div className="surface-frame kds-frame">
      <div className="kds-topbar">
        <div className="kds-station">
          <div className="kds-mark">S</div>
          <div className="kds-title">SatSet KDS</div>
        </div>
        <span className="kds-station-tag">PAIR DEVICE</span>
        <div className="kds-clock" style={{ marginLeft: 'auto' }}><span>SAB · 18:14:22</span></div>
      </div>
      <div className="kds-pair">
        <div className="kds-pair-left">
          <div className="kds-pair-h1">Scan to pair</div>
          <div className="kds-pair-sub">PINDAI QR DENGAN APP SATSET DI HP / TABLET BARU</div>

          <div className="kds-qr">
            {/* fake QR code (visual) */}
            <svg viewBox="0 0 25 25" width="100%" height="100%" shapeRendering="crispEdges">
              {Array.from({ length: 25 }).map((_, y) => (
                Array.from({ length: 25 }).map((_, x) => {
                  // deterministic pseudo-noise
                  const v = (x * 31 + y * 17 + x * y * 7) % 100;
                  // corner finders
                  const corner = (x < 7 && y < 7) || (x > 17 && y < 7) || (x < 7 && y > 17);
                  const ringInner = corner && ((x === 0 || x === 6 || y === 0 || y === 6 || (x === 18 || x === 24) || (y === 18 || y === 24)));
                  const ringInnerLT = corner && ((x === 2 || x === 4 || y === 2 || y === 4) && (x >= 1 && x <= 5 && y >= 1 && y <= 5));
                  const ringInnerRT = corner && ((x === 20 || x === 22) && y >= 2 && y <= 4 || y === 2 && x >= 19 && x <= 23 || y === 4 && x >= 19 && x <= 23);
                  const ringInnerLB = corner && ((y === 20 || y === 22) && x >= 2 && x <= 4 || x === 2 && y >= 19 && y <= 23 || x === 4 && y >= 19 && y <= 23);
                  const isFinder = corner && (v < 50 || ringInner || ringInnerLT || ringInnerRT || ringInnerLB);
                  // outer area
                  const data = !corner && v < 48;
                  const fill = isFinder || data;
                  return fill ? <rect key={x + '-' + y} x={x} y={y} width={1} height={1} fill="#0a0a0a"/> : null;
                })
              ))}
            </svg>
          </div>

          <div className="kds-qr-meta">
            satset://192.168.4.21:8443<br/>
            cert SHA: 5F 3A C2 9D · expires 2026-11-08
          </div>
        </div>

        <div className="kds-pair-right">
          <div className="kds-pair-rh">Paired devices · this session</div>
          <div>
            {[
              { n: 'Maya · iPhone 14', m: 'BYOD · ::1f4a · 17:30', s: 'LIVE' },
              { n: 'Putu · iPad Air',  m: 'venue · ::8f12 · 16:45', s: 'LIVE' },
              { n: 'Made · iPhone 13', m: 'BYOD · ::3e88 · 16:30', s: 'LIVE' },
              { n: 'Ari · Galaxy Tab',  m: 'EXPO · ::a01b · 16:00', s: 'LIVE' },
              { n: 'Sari · MacBook',    m: 'Manager · ::b2c4 · 09:00', s: 'LIVE' },
              { n: 'Wira · iPad Pro',   m: 'EXPO · ::e017 · 09:00', s: 'LIVE' },
            ].map((d, i) => (
              <div className="kds-paired-row" key={i}>
                <div className="ic"><Icons.Wifi size={16}/></div>
                <div>
                  <div className="nm">{d.n}</div>
                  <div className="meta">{d.m}</div>
                </div>
                <div className="status">{d.s}</div>
              </div>
            ))}
          </div>
          <div style={{ marginTop: 'auto', padding: '12px 0', display: 'flex', gap: 8 }}>
            <button className="kds-btn" style={{ flex: 1 }}>Regenerate QR</button>
            <button className="kds-btn" style={{ flex: 1, background: 'var(--urgent-soft)', color: 'var(--urgent)', borderColor: 'var(--urgent)' }}>Revoke all</button>
          </div>
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────
//  Manager Admin — 1440 × 900 desktop/tablet
// ─────────────────────────────────────────────────────────────────────
function MG_Shell({ active = 'floor', children }) {
  const rail = [
    { id: 'floor',  label: 'Floor map',     Ic: Icons.Tables },
    { id: 'orders', label: 'Active orders', Ic: Icons.Orders },
    { id: 'menu',   label: 'Menu admin',    Ic: Icons.Menu },
    { id: 'reports', label: 'Reports',      Ic: Icons.Sparkle },
    { id: 'audit', label: 'Audit log',      Ic: Icons.Clock },
    { id: 'staff', label: 'Staff & PINs',   Ic: Icons.Me },
    { id: 'settings', label: 'Settings',    Ic: Icons.Edit },
  ];
  return (
    <div className="surface-frame mg-frame">
      <div className="mg-rail">
        <div className="mg-rail-brand">
          <div className="mark">S</div>
          <div>
            <div className="wm">SatSet</div>
            <div className="role">MANAGER</div>
          </div>
        </div>
        <div className="mg-rail-section">Service</div>
        {rail.slice(0, 4).map((r) => (
          <div key={r.id} className={'mg-rail-link ' + (active === r.id ? 'active' : '')}>
            <r.Ic size={16}/> {r.label}
          </div>
        ))}
        <div className="mg-rail-section">Oversight</div>
        {rail.slice(4).map((r) => (
          <div key={r.id} className={'mg-rail-link ' + (active === r.id ? 'active' : '')}>
            <r.Ic size={16}/> {r.label}
          </div>
        ))}
        <div className="mg-rail-foot">
          <div className="mg-rail-user">
            <div className="av">SA</div>
            <div>
              <div className="nm">Sari Astawa</div>
              <div className="rl">FLOOR MANAGER</div>
            </div>
          </div>
        </div>
      </div>
      <div className="mg-main">{children}</div>
    </div>
  );
}

function MG_Floor() {
  return (
    <MG_Shell active="floor">
      <div className="mg-bar">
        <div>
          <div className="h1">Live floor</div>
          <div className="sub">SABTU · 18:14 · DINNER SERVICE</div>
        </div>
        <div className="right">
          <span className="tab-sync"><span className="dot"></span>LIVE · LAN + CLOUD</span>
          <button className="btn-ghost" style={{ height: 38, borderRadius: 12, background: 'var(--bg-3)', color: 'var(--text-hi)', padding: '0 14px', fontSize: 13, fontWeight: 500, border: 0 }}>End session</button>
        </div>
      </div>
      <div className="mg-content">
        <div className="mg-floor-stats">
          <div className="mg-stat"><div className="l">Open covers</div><div className="v">42</div><div className="d">of 120 cap · 35%</div></div>
          <div className="mg-stat"><div className="l">Active orders</div><div className="v">18</div><div className="d">5 ready · 11 prep · 2 held</div></div>
          <div className="mg-stat"><div className="l">Avg sent→ready</div><div className="v">7:24</div><div className="d" style={{ color: 'var(--success)' }}>↓ 0:38 vs avg</div></div>
          <div className="mg-stat alert"><div className="l">Waiting &gt; 12 min</div><div className="v">1</div><div className="d">Meja G3 · 12:48 elapsed</div></div>
          <div className="mg-stat"><div className="l">Voids · shift</div><div className="v">1</div><div className="d">Sari approved</div></div>
          <div className="mg-stat"><div className="l">Comps · shift</div><div className="v">0</div><div className="d">none yet</div></div>
        </div>

        <div className="mg-floor-grid">
          <div className="mg-card">
            <div className="mg-card-h">
              <div className="t">Floor map · all zones</div>
              <div className="s">REFRESH 1.2s</div>
            </div>

            {[
              { name: 'TERAS', tables: SATSET_DATA.tables.filter((t) => t.zone === 'terrace') },
              { name: 'TAMAN', tables: SATSET_DATA.tables.filter((t) => t.zone === 'garden') },
              { name: 'DALAM', tables: SATSET_DATA.tables.filter((t) => t.zone === 'indoor') },
              { name: 'BAR',   tables: SATSET_DATA.tables.filter((t) => t.zone === 'bar') },
            ].map((z) => (
              <div className="mg-zone" key={z.name}>
                <div className="mg-zone-h">{z.name} · {z.tables.length} tables</div>
                <div className="mg-zone-grid">
                  {z.tables.map((t) => {
                    const alert = t.elapsed === '1:32' || (t.zone === 'garden' && t.status === 'occupied' && t.elapsed === '0:54');
                    return (
                      <div key={t.id} className={'mg-mini-table ' + (t.status === 'available' ? '' : t.status) + (alert ? ' alert' : '')}>
                        <div className="num">{t.id}</div>
                        <div className="meta">{t.pax}p {t.elapsed && '· ' + t.elapsed}</div>
                      </div>
                    );
                  })}
                </div>
              </div>
            ))}
          </div>

          <div>
            <div className="mg-card" style={{ marginBottom: 18 }}>
              <div className="mg-card-h">
                <div className="t">Alerts</div>
                <div className="s">2 ACTIVE</div>
              </div>
              <div className="mg-alert-row">
                <div className="ic urgent"><Icons.Alert size={16}/></div>
                <div className="body">
                  <div className="ti">Meja G3 waiting 12:48 for first item</div>
                  <div className="me">TAMAN · 5 TAMU · WAITER MADE</div>
                </div>
              </div>
              <div className="mg-alert-row">
                <div className="ic warn"><Icons.Fire size={16}/></div>
                <div className="body">
                  <div className="ti">Kitchen backlog: 7 tickets in prep &gt; 8 min</div>
                  <div className="me">DAPUR UTAMA · AVG 9:12</div>
                </div>
              </div>
              <div className="mg-alert-row">
                <div className="ic warn"><Icons.Sparkle size={16}/></div>
                <div className="body">
                  <div className="ti">Bar idle 4 min — staffing OK?</div>
                  <div className="me">2 ORDERS DRINKS PENDING WAITER PICKUP</div>
                </div>
              </div>
            </div>

            <div className="mg-card">
              <div className="mg-card-h">
                <div className="t">Station load</div>
                <div className="s">LIVE</div>
              </div>
              {[
                { n: 'Dapur · Utama',  v: 7, c: 10, urg: true },
                { n: 'Dapur · Pembuka', v: 3, c: 8 },
                { n: 'Dapur · Penutup', v: 2, c: 6 },
                { n: 'Bar · Cocktail',  v: 2, c: 8 },
                { n: 'Bar · Soft',      v: 4, c: 12 },
              ].map((s) => (
                <div key={s.n} style={{ padding: '10px 0', borderBottom: '1px solid var(--border-0)' }}>
                  <div style={{ display: 'flex', alignItems: 'baseline' }}>
                    <span style={{ fontSize: 13, fontWeight: 500 }}>{s.n}</span>
                    <span style={{ marginLeft: 'auto', fontFamily: 'var(--font-mono)', fontSize: 12, color: s.urg ? 'var(--urgent)' : 'var(--text-md)' }}>{s.v} / {s.c}</span>
                  </div>
                  <div style={{ marginTop: 6, height: 5, background: 'var(--bg-3)', borderRadius: 3, position: 'relative' }}>
                    <div style={{ position: 'absolute', left: 0, top: 0, bottom: 0, width: (s.v / s.c * 100) + '%', background: s.urg ? 'var(--urgent)' : 'var(--accent)', borderRadius: 3 }}></div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </MG_Shell>
  );
}

function MG_Menu() {
  const rows = [
    { id: 'rendang', n: 'Rendang Sapi', d: 'Padang beef in coconut, lemongrass, chili.', c: 'Mains', s: 'Dapur · Utama', p: 145000, sold: 18, on: true },
    { id: 'nasi-goreng', n: 'Nasi Goreng', d: 'Indonesian fried rice with shrimp paste, krupuk.', c: 'Mains', s: 'Dapur · Utama', p: 85000, sold: 32, on: true },
    { id: 'mie', n: 'Mie Goreng', d: 'Stir-fried egg noodles.', c: 'Mains', s: 'Dapur · Utama', p: 80000, sold: 14, on: true },
    { id: 'burger', n: 'Burger Wagyu', d: 'Wagyu patty, brioche, house pickles, fries.', c: 'Mains', s: 'Dapur · Utama', p: 165000, sold: 0, on: false, killed: true },
    { id: 'tempe', n: 'Tempe Sambal Bowl', d: 'Sambal-glazed tempeh, coconut rice, fried egg.', c: 'Mains', s: 'Dapur · Utama', p: 95000, sold: 9, on: true },
    { id: 'gado', n: 'Gado-Gado', d: 'Steamed veg, tofu, tempeh, peanut sauce.', c: 'Starters', s: 'Dapur · Pembuka', p: 65000, sold: 11, on: true },
    { id: 'sate', n: 'Sate Ayam', d: 'Grilled chicken skewers, lontong.', c: 'Starters', s: 'Dapur · Pembuka', p: 75000, sold: 7, on: true },
    { id: 'pisang', n: 'Pisang Goreng + Es Krim', d: 'Fried banana, palm sugar, vanilla ice cream.', c: 'Desserts', s: 'Dapur · Penutup', p: 55000, sold: 4, on: true },
    { id: 'rose', n: 'House Rosé', d: 'Crisp, dry, Provence-style. Glass / bottle.', c: 'Wine', s: 'Bar', p: 95000, sold: 5, on: true },
    { id: 'marg', n: 'Spicy Margarita', d: 'Tequila, lime, agave, fresh chili.', c: 'Cocktails', s: 'Bar · Cocktail', p: 110000, sold: 8, on: true },
    { id: 'bintang', n: 'Bintang Pilsner', d: '330ml lager.', c: 'Beer', s: 'Bar', p: 45000, sold: 22, on: true },
    { id: 'esteh', n: 'Es Teh Manis', d: 'Iced sweet jasmine tea.', c: 'Soft', s: 'Bar · Soft', p: 25000, sold: 31, on: true, low: true },
  ];

  return (
    <MG_Shell active="menu">
      <div className="mg-bar">
        <div>
          <div className="h1">Menu</div>
          <div className="sub">76 ITEMS · 9 CATEGORIES · 1 KILLED THIS SHIFT</div>
        </div>
        <div className="right">
          <button className="btn-ghost" style={{ height: 38, borderRadius: 12, background: 'var(--bg-3)', color: 'var(--text-hi)', padding: '0 14px', fontSize: 13, fontWeight: 500, border: 0 }}>Import CSV</button>
          <button style={{ height: 38, borderRadius: 12, background: 'var(--accent)', color: 'var(--accent-ink)', padding: '0 14px', fontSize: 13, fontWeight: 600 }}>+ New item</button>
        </div>
      </div>
      <div className="mg-content">
        <div className="mg-menu-toolbar">
          <div className="search">
            <Icons.Search size={14} stroke="var(--text-lo)"/>
            <span>Search menu…</span>
          </div>
          <button className="btn-ghost" style={{ height: 40, borderRadius: 12, background: 'var(--bg-2)', color: 'var(--text-hi)', padding: '0 14px', fontSize: 13, border: '1px solid var(--border-0)' }}>All categories ⌄</button>
          <button className="btn-ghost" style={{ height: 40, borderRadius: 12, background: 'var(--bg-2)', color: 'var(--text-hi)', padding: '0 14px', fontSize: 13, border: '1px solid var(--border-0)' }}>All stations ⌄</button>
          <button className="btn-ghost" style={{ height: 40, borderRadius: 12, background: 'var(--urgent-soft)', color: 'var(--urgent)', padding: '0 14px', fontSize: 13, border: '1px solid var(--urgent)' }}>1 KILLED</button>
        </div>

        <div className="mg-card" style={{ padding: 0 }}>
          <div className="mg-menu-row head">
            <div></div>
            <div>Item</div>
            <div>Category</div>
            <div>Station</div>
            <div>Price</div>
            <div>Sold today</div>
            <div>On</div>
          </div>
          {rows.map((r) => (
            <div className="mg-menu-row" key={r.id} style={{ opacity: r.killed ? 0.55 : 1 }}>
              <div className="ph"/>
              <div>
                <div className="nm">{r.n}</div>
                <div className="ds">{r.d}</div>
                {r.low && <span className="h-pill warn" style={{ fontSize: 10, marginTop: 4 }}>Low stock — 4 left</span>}
              </div>
              <div><span className="ct">{r.c}</span></div>
              <div style={{ fontSize: 13, color: 'var(--text-md)' }}>{r.s}</div>
              <div className="pr">{formatIDR(r.p)}</div>
              <div className="mg-cnt">{r.sold}</div>
              <div><div className={'mg-toggle ' + (r.killed ? 'killed' : r.on ? 'on' : '')}></div></div>
            </div>
          ))}
        </div>
      </div>
    </MG_Shell>
  );
}

function MG_Reports() {
  return (
    <MG_Shell active="reports">
      <div className="mg-bar">
        <div>
          <div className="h1">Reports</div>
          <div className="sub">DINNER · SABTU · 17:30 — IN PROGRESS</div>
        </div>
        <div className="right">
          <button className="btn-ghost" style={{ height: 38, borderRadius: 12, background: 'var(--bg-3)', color: 'var(--text-hi)', padding: '0 14px', fontSize: 13, fontWeight: 500, border: 0 }}>Dinner ⌄</button>
          <button className="btn-ghost" style={{ height: 38, borderRadius: 12, background: 'var(--bg-3)', color: 'var(--text-hi)', padding: '0 14px', fontSize: 13, fontWeight: 500, border: 0 }}>Export CSV</button>
        </div>
      </div>
      <div className="mg-content">

        <div className="mg-reports-row">
          <div className="mg-kpi">
            <div className="l">Covers served</div>
            <div className="v">42</div>
            <div className="d up">↑ 8 vs same day last week</div>
            <div className="bars">
              {[3,5,4,8,12,16,18,22,28,32,38,42].map((h, i) => (
                <span key={i} className={i >= 8 ? 'hi' : ''} style={{ height: h * 0.7 + '%' }}></span>
              ))}
            </div>
          </div>
          <div className="mg-kpi">
            <div className="l">Sent → Ready · avg</div>
            <div className="v">7:24</div>
            <div className="d up">↓ 0:38 vs avg</div>
            <div className="bars">
              {[10,8,9,12,14,11,9,8,7,8,7,7].map((h, i) => (
                <span key={i} className={i >= 8 ? 'hi' : ''} style={{ height: h * 4 + '%', background: i >= 8 ? 'var(--success)' : 'rgba(77,212,135,0.4)' }}></span>
              ))}
            </div>
          </div>
          <div className="mg-kpi">
            <div className="l">Voids · comps · refire</div>
            <div className="v">1 · 0 · 2</div>
            <div className="d">Sari approved 1 · 0.8% void rate</div>
            <div className="bars">
              {[0,0,0,0,1,0,0,1,2,0,0,0].map((h, i) => (
                <span key={i} className={h > 0 ? 'hi' : ''} style={{ height: Math.max(8, h * 30) + '%', background: h > 0 ? 'var(--urgent)' : 'rgba(255,92,92,0.2)' }}></span>
              ))}
            </div>
          </div>
        </div>

        <div className="mg-floor-grid">
          <div className="mg-card">
            <div className="mg-card-h"><div className="t">Top items today</div><div className="s">BY UNITS SOLD</div></div>
            {[
              { n: 'Nasi Goreng', c: 32, w: '100%' },
              { n: 'Es Teh Manis', c: 31, w: '97%' },
              { n: 'Bintang Pilsner', c: 22, w: '69%' },
              { n: 'Rendang Sapi', c: 18, w: '56%' },
              { n: 'Mie Goreng', c: 14, w: '44%' },
              { n: 'Gado-Gado', c: 11, w: '34%' },
              { n: 'Tempe Sambal Bowl', c: 9, w: '28%' },
              { n: 'Spicy Margarita', c: 8, w: '25%' },
            ].map((it, i) => (
              <div className="mg-rank-row" key={it.n}>
                <span className="pos">{String(i + 1).padStart(2, '0')}</span>
                <div style={{ flex: 1 }}>
                  <div style={{ display: 'flex', alignItems: 'baseline' }}>
                    <span className="nm">{it.n}</span>
                    <span className="ct" style={{ marginLeft: 'auto' }}>{it.c}</span>
                  </div>
                  <div className="bar" style={{ '--w': it.w }}></div>
                </div>
              </div>
            ))}
          </div>

          <div className="mg-card">
            <div className="mg-card-h"><div className="t">Avg prep time · station</div><div className="s">SENT → READY</div></div>
            {[
              { n: 'Bar · Soft',         t: '1:08', w: '15%' },
              { n: 'Bar · Cocktail',     t: '3:42', w: '32%' },
              { n: 'Dapur · Pembuka',    t: '5:11', w: '48%' },
              { n: 'Dapur · Penutup',    t: '6:24', w: '60%' },
              { n: 'Dapur · Utama',      t: '9:12', w: '85%' },
              { n: 'Dapur · Utama (Sat)', t: '11:38', w: '100%', red: true },
            ].map((it) => (
              <div className="mg-rank-row" key={it.n}>
                <div style={{ flex: 1 }}>
                  <div style={{ display: 'flex', alignItems: 'baseline' }}>
                    <span className="nm">{it.n}</span>
                    <span className="ct" style={{ marginLeft: 'auto', color: it.red ? 'var(--urgent)' : 'var(--text-md)' }}>{it.t}</span>
                  </div>
                  <div className="bar" style={{ '--w': it.w, '--accent': it.red ? 'var(--urgent)' : '' }}>
                    <style>{`.mg-rank-row .bar::after { background: ${it.red ? 'var(--urgent)' : 'var(--accent)'}; }`}</style>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </MG_Shell>
  );
}

function MG_Audit() {
  const rows = [
    { t: '18:14', who: 'Sari · Mgr', ev: 'void',  ti: '×1 Mie Goreng · Meja T1',          rs: 'Tamu berubah pikiran', amt: 'Rp 80.000' },
    { t: '18:12', who: 'Maya · Pelayan', ev: 'mod',  ti: '×1 Rendang Sapi · Meja T1', rs: 'Ganti nasi uduk → putih', amt: '—' },
    { t: '18:08', who: 'Maya · Pelayan', ev: 'fire', ti: 'Course Utama · Meja T1',  rs: '—', amt: '—' },
    { t: '17:54', who: 'Budi · Dapur',  ev: 'kill', ti: 'Burger Wagyu · 86\'d',     rs: 'Out of brioche',           amt: '—' },
    { t: '17:48', who: 'Sari · Mgr',   ev: 'comp', ti: '×1 Es Teh Manis · Meja T2', rs: 'Tunggu lama setelah komplain', amt: 'Rp 25.000' },
    { t: '17:42', who: 'Maya · Pelayan', ev: 'mod',  ti: '×2 Pisang Goreng · Meja T1', rs: 'Held → Fire now',         amt: '—' },
    { t: '17:30', who: 'Sari · Mgr',   ev: 'kill', ti: 'Dinner shift opened',     rs: 'Auto · scheduled',          amt: '—' },
    { t: '17:12', who: 'Made · Pelayan', ev: 'mod',  ti: '×1 Rendang Sapi · Meja G3',  rs: 'Refire — under-cooked',   amt: '—' },
    { t: '17:08', who: 'Wira · Expo',  ev: 'fire', ti: 'Course Utama · Meja G3',  rs: 'Manual fire',               amt: '—' },
    { t: '16:54', who: 'Budi · Dapur',  ev: 'void',  ti: '×1 Sate Ayam · Meja G1',     rs: 'Sent in error',           amt: 'Rp 75.000' },
  ];
  return (
    <MG_Shell active="audit">
      <div className="mg-bar">
        <div>
          <div className="h1">Audit log</div>
          <div className="sub">DINNER · ALL EVENTS · COMPLETE TRAIL</div>
        </div>
        <div className="right">
          <button className="btn-ghost" style={{ height: 38, borderRadius: 12, background: 'var(--bg-3)', color: 'var(--text-hi)', padding: '0 14px', fontSize: 13, fontWeight: 500, border: 0 }}>Today ⌄</button>
          <button className="btn-ghost" style={{ height: 38, borderRadius: 12, background: 'var(--bg-3)', color: 'var(--text-hi)', padding: '0 14px', fontSize: 13, fontWeight: 500, border: 0 }}>All events ⌄</button>
          <button className="btn-ghost" style={{ height: 38, borderRadius: 12, background: 'var(--bg-3)', color: 'var(--text-hi)', padding: '0 14px', fontSize: 13, fontWeight: 500, border: 0 }}>Export</button>
        </div>
      </div>
      <div className="mg-content">
        <div className="mg-floor-stats">
          <div className="mg-stat"><div className="l">Total events</div><div className="v">142</div><div className="d">since 17:30</div></div>
          <div className="mg-stat"><div className="l">Voids</div><div className="v" style={{ color: 'var(--urgent)' }}>1</div><div className="d">Rp 80.000</div></div>
          <div className="mg-stat"><div className="l">Comps</div><div className="v" style={{ color: 'var(--warn)' }}>1</div><div className="d">Rp 25.000</div></div>
          <div className="mg-stat"><div className="l">Refire</div><div className="v">2</div><div className="d">Kitchen-initiated</div></div>
          <div className="mg-stat"><div className="l">Kill-switch</div><div className="v">1</div><div className="d">Burger Wagyu</div></div>
          <div className="mg-stat"><div className="l">Post-send mods</div><div className="v">5</div><div className="d">3 pre-prep · 2 acknowledged</div></div>
        </div>

        <div className="mg-card" style={{ padding: 0 }}>
          <div className="mg-audit-row head">
            <div>Time</div>
            <div>Type</div>
            <div>User</div>
            <div>Event</div>
            <div>Amount</div>
            <div>Reason / note</div>
          </div>
          {rows.map((r, i) => (
            <div className="mg-audit-row" key={i}>
              <div className="when">{r.t}</div>
              <div><span className={'ev ' + r.ev}>{r.ev.toUpperCase()}</span></div>
              <div className="who">{r.who}</div>
              <div style={{ fontSize: 13 }}>{r.ti}</div>
              <div style={{ fontFamily: 'var(--font-mono)', fontSize: 12, color: 'var(--text-md)' }}>{r.amt}</div>
              <div style={{ fontSize: 12, color: 'var(--text-md)' }}>{r.rs}</div>
            </div>
          ))}
        </div>
      </div>
    </MG_Shell>
  );
}

// ─────────────────────────────────────────────────────────────────────
//  Expediter — pass view
// ─────────────────────────────────────────────────────────────────────
function EX_Pass() {
  const cards = [
    {
      id: 'T1', pax: 2, zone: 'TERAS · 0:18', timer: '8:42', urg: 'warn',
      courses: [
        { c: 'Minum dulu', n: 'Es Teh Manis ×2', s: 'fired', when: '17:42 · DONE' },
        { c: 'Pembuka',    n: 'Gado-Gado',        s: 'ready', when: '17:42 · READY' },
        { c: 'Utama',      n: 'Nasi Goreng · Rendang Sapi', s: 'fired', when: '17:46 · PREP 8:42' },
        { c: 'Penutup',    n: 'Pisang Goreng ×2',  s: 'held',  when: 'await fire' },
      ],
    },
    {
      id: 'T2', pax: 4, zone: 'TERAS · 0:42', timer: '11:14', urg: 'red',
      courses: [
        { c: 'Pembuka',    n: 'Sate Ayam ×2',      s: 'fired', when: '17:21 · DONE' },
        { c: 'Minum',      n: 'Rosé · botol',      s: 'fired', when: '17:22 · DONE' },
        { c: 'Utama',      n: 'Tempe Sambal · Mie Goreng', s: 'ready', when: '17:48 · READY ↑' },
      ],
    },
    {
      id: 'T4', pax: 6, zone: 'TERAS · 0:08', timer: '0:24',
      courses: [
        { c: 'Minum dulu', n: 'Bir Bintang ×6', s: 'fired', when: '18:02 · PREP 0:24' },
        { c: 'Pembuka',    n: 'Lumpia ×2',      s: 'fired', when: '18:02 · PREP 0:24' },
      ],
    },
    {
      id: 'G3', pax: 5, zone: 'TAMAN · 0:54', timer: '12:48', urg: 'red',
      courses: [
        { c: 'Pembuka', n: 'Gado-Gado · Sate Ayam', s: 'fired', when: '17:25 · DONE' },
        { c: 'Utama',   n: 'Rendang Sapi ×2 · refire', s: 'fired', when: '17:48 · PREP 12:48' },
      ],
    },
    {
      id: 'I4', pax: 4, zone: 'DALAM · 1:32', timer: '6:18',
      courses: [
        { c: 'Minum dulu', n: 'Bir Bintang ×4', s: 'fired', when: '16:42 · DONE' },
        { c: 'Pembuka',    n: 'Lumpia ×3',       s: 'fired', when: '16:50 · DONE' },
        { c: 'Utama',      n: 'Nasi Goreng ×2',  s: 'fired', when: '17:42 · PREP 6:18' },
      ],
    },
    {
      id: 'G1', pax: 4, zone: 'TAMAN · 0:32', timer: '3:32',
      courses: [
        { c: 'Pembuka', n: 'Gado-Gado',                s: 'ready', when: '17:48 · READY' },
        { c: 'Utama',   n: 'Rendang · Mie Goreng',     s: 'fired', when: '17:51 · PREP 3:32' },
      ],
    },
  ];

  return (
    <div className="surface-frame ex-frame">
      <div className="ex-topbar">
        <div className="kds-station">
          <div className="kds-mark">S</div>
          <div className="kds-title">SatSet · Expediter</div>
        </div>
        <span className="kds-station-tag">WIRA · PASS</span>
        <div className="kds-counters" style={{ marginLeft: 'auto' }}>
          <span>ACTIVE <span className="v">9</span></span>
          <span>READY <span className="v">3</span></span>
          <span>WAITING &gt; 12m <span className="v" style={{ color: 'var(--urgent)' }}>1</span></span>
        </div>
        <div className="kds-clock"><span className="kds-health"><span className="dot"></span>LIVE · LAN</span><span>18:14</span></div>
      </div>
      <div className="ex-grid">
        {cards.map((c) => (
          <div key={c.id} className={['ex-card', c.urg ? 'urg-' + c.urg : ''].join(' ')}>
            <div className="ex-card-head">
              <span className="num">{c.id}</span>
              <span style={{ fontSize: 11, color: 'var(--text-md)' }}>{c.pax}p</span>
              <span className="meta">{c.zone}</span>
              <span className="timer" style={{ color: c.urg === 'red' ? 'var(--urgent)' : c.urg === 'warn' ? 'var(--warn)' : 'var(--text-md)' }}>{c.timer}</span>
            </div>
            {c.courses.map((co, i) => (
              <div key={i} className={'ex-course-row ' + co.s}>
                <div className="ch">
                  {co.c}
                  <span className="when">{co.when}</span>
                </div>
                <div className="items">{co.n}</div>
              </div>
            ))}
            <div className="ex-card-foot">
              <button className="btn">Recall</button>
              <button className="btn refire">Refire</button>
              <button className="btn fire">Fire next ›</button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

window.KDS_Main = KDS_Main;
window.KDS_Server = KDS_Server;
window.KDS_Pair = KDS_Pair;
window.MG_Floor = MG_Floor;
window.MG_Menu = MG_Menu;
window.MG_Reports = MG_Reports;
window.MG_Audit = MG_Audit;
window.EX_Pass = EX_Pass;

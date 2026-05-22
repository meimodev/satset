// SatSet — design system reference artboards.
/* global React */

function DS_Colors() {
  const groups = [
    {
      name: 'Surfaces',
      colors: [
        { n: 'bg-0',  v: '#0d0e10', txt: '#f4f3ee' },
        { n: 'bg-1',  v: '#15171a', txt: '#f4f3ee' },
        { n: 'bg-2',  v: '#1c1f23', txt: '#f4f3ee' },
        { n: 'bg-3',  v: '#24282d', txt: '#f4f3ee' },
        { n: 'bg-4',  v: '#2e333a', txt: '#f4f3ee' },
        { n: 'border-2', v: 'rgba(255,255,255,0.16)', txt: '#b6b2a6' },
      ],
    },
    {
      name: 'Text',
      colors: [
        { n: 'text-hi', v: '#f4f3ee', txt: '#0d0e10', bg: '#1c1f23' },
        { n: 'text-md', v: '#b6b2a6', txt: '#0d0e10', bg: '#24282d' },
        { n: 'text-lo', v: '#7e7a70', txt: '#f4f3ee', bg: '#24282d' },
        { n: 'text-dim', v: '#565249', txt: '#f4f3ee', bg: '#24282d' },
      ],
    },
    {
      name: 'Accent · brand · primary actions',
      colors: [
        { n: 'accent',     v: '#ff9233', txt: '#160d04' },
        { n: 'accent-soft', v: 'rgba(255,146,51,0.14)', txt: '#ff9233', bg: '#1c1f23' },
        { n: 'accent-border', v: 'rgba(255,146,51,0.35)', txt: '#ff9233', bg: '#1c1f23' },
        { n: 'accent-ink', v: '#160d04', txt: '#ff9233' },
      ],
    },
    {
      name: 'Semantic · status',
      colors: [
        { n: 'success', v: '#4dd487', txt: '#0a0a0a' },
        { n: 'warn',    v: '#ffc04d', txt: '#0a0a0a' },
        { n: 'urgent',  v: '#ff5c5c', txt: '#0a0a0a' },
        { n: 'info',    v: '#6db5ff', txt: '#0a0a0a' },
        { n: 'violet',  v: '#c08aff', txt: '#0a0a0a' },
      ],
    },
    {
      name: 'Course system',
      colors: [
        { n: 'drinks-now', v: '#6db5ff', txt: '#0a0a0a' },
        { n: 'starters',   v: '#ffc04d', txt: '#0a0a0a' },
        { n: 'mains',      v: '#4dd487', txt: '#0a0a0a' },
        { n: 'desserts',   v: '#c08aff', txt: '#0a0a0a' },
        { n: 'fire-now',   v: '#ff9233', txt: '#160d04' },
      ],
    },
  ];

  return (
    <div className="ds-frame" style={{ width: 1280, minHeight: 820 }}>
      <div className="ds-h1">Color tokens</div>
      <div className="ds-sub">Dark · primary · oklch-based · loud kitchen + dim bar tested</div>

      {groups.map((g) => (
        <div className="ds-section" key={g.name}>
          <div className="ds-section-h">{g.name}</div>
          <div className="ds-color-grid">
            {g.colors.map((c) => (
              <div className="ds-color" key={c.n} style={{ background: c.bg || c.v, color: c.txt, border: c.bg ? '1px solid rgba(255,255,255,0.08)' : 'none' }}>
                <div className="nm">{c.n}</div>
                <div className="v">{c.v}</div>
              </div>
            ))}
          </div>
        </div>
      ))}
    </div>
  );
}

function DS_Type() {
  return (
    <div className="ds-frame" style={{ width: 1280, minHeight: 820 }}>
      <div className="ds-h1">Type system</div>
      <div className="ds-sub">IBM Plex Sans · primary · IBM Plex Mono · numerics & code</div>

      <div className="ds-section">
        <div className="ds-section-h">Display & headings</div>
        <div className="ds-type-row">
          <div className="ds-type-spec">Display 54 · 600 · −0.025em</div>
          <div className="ds-type-sample" style={{ fontSize: 54, fontWeight: 600, letterSpacing: '-0.025em', lineHeight: 1.05 }}>Maya, masukkan PIN</div>
        </div>
        <div className="ds-type-row">
          <div className="ds-type-spec">H1 · 32 · 600 · −0.025em</div>
          <div className="ds-type-sample" style={{ fontSize: 32, fontWeight: 600, letterSpacing: '-0.025em' }}>Pesanan saya</div>
        </div>
        <div className="ds-type-row">
          <div className="ds-type-spec">H2 · 22 · 600 · −0.02em</div>
          <div className="ds-type-sample" style={{ fontSize: 22, fontWeight: 600, letterSpacing: '-0.02em' }}>Konteks meja</div>
        </div>
        <div className="ds-type-row">
          <div className="ds-type-spec">H3 · 18 · 600 · −0.01em</div>
          <div className="ds-type-sample" style={{ fontSize: 18, fontWeight: 600, letterSpacing: '-0.01em' }}>Tambah ke Meja T1</div>
        </div>
      </div>

      <div className="ds-section">
        <div className="ds-section-h">Body</div>
        <div className="ds-type-row">
          <div className="ds-type-spec">Body L · 15 · 500</div>
          <div className="ds-type-sample" style={{ fontSize: 15, fontWeight: 500 }}>Rendang sapi padang dengan santan dan rempah. Disajikan dengan nasi uduk.</div>
        </div>
        <div className="ds-type-row">
          <div className="ds-type-spec">Body M · 13 · 500</div>
          <div className="ds-type-sample" style={{ fontSize: 13, fontWeight: 500 }}>Pelayan · Zona Teras · mulai 17:30</div>
        </div>
        <div className="ds-type-row">
          <div className="ds-type-spec">Body S · 12 · 400</div>
          <div className="ds-type-sample" style={{ fontSize: 12 }}>Layanan 7% · Pajak 11% · pembayaran di luar SatSet</div>
        </div>
      </div>

      <div className="ds-section">
        <div className="ds-section-h">Mono — numerics, codes, technical</div>
        <div className="ds-type-row">
          <div className="ds-type-spec">Mono Display · 36 · 600</div>
          <div className="ds-type-sample" style={{ fontFamily: 'var(--font-mono)', fontSize: 36, fontWeight: 600, letterSpacing: '-0.025em' }}>Rp 1.345.000</div>
        </div>
        <div className="ds-type-row">
          <div className="ds-type-spec">Mono L · 22</div>
          <div className="ds-type-sample" style={{ fontFamily: 'var(--font-mono)', fontSize: 22, fontWeight: 500 }}>T1 · 18:14 · LIVE</div>
        </div>
        <div className="ds-type-row">
          <div className="ds-type-spec">Mono M · 13 · 0.04em</div>
          <div className="ds-type-sample" style={{ fontFamily: 'var(--font-mono)', fontSize: 13, letterSpacing: '0.04em', color: 'var(--text-md)' }}>LAN P50 184MS · CLOUD MENUNGGU</div>
        </div>
        <div className="ds-type-row">
          <div className="ds-type-spec">Caption · 10 · 0.12em UPPER</div>
          <div className="ds-type-sample" style={{ fontFamily: 'var(--font-mono)', fontSize: 10, letterSpacing: '0.12em', textTransform: 'uppercase', color: 'var(--text-lo)', fontWeight: 600 }}>RINGKASAN SHIFT · AUDIT TRAIL</div>
        </div>
      </div>
    </div>
  );
}

function DS_Spacing() {
  const radii = [
    { v: 8,  n: 'r-sm  ·  8px',  use: 'inputs, small chips' },
    { v: 12, n: 'r-md  · 12px', use: 'cards, modal sections' },
    { v: 16, n: 'r-lg  · 16px', use: 'list rows, large cards' },
    { v: 22, n: 'r-xl  · 22px', use: 'sheets, primary CTAs' },
    { v: 28, n: 'r-2xl · 28px', use: 'modal containers' },
    { v: 999, n: 'r-full', use: 'pills, tags, toggles' },
  ];
  const space = [
    { v: 4, n: 's1' }, { v: 8, n: 's2' }, { v: 12, n: 's3' },
    { v: 16, n: 's4' }, { v: 20, n: 's5' }, { v: 24, n: 's6' },
  ];

  return (
    <div className="ds-frame" style={{ width: 1280, minHeight: 820 }}>
      <div className="ds-h1">Spacing & radii</div>
      <div className="ds-sub">8pt scale · consistent across phone, tablet & KDS</div>

      <div className="ds-section">
        <div className="ds-section-h">Radius scale</div>
        <div className="ds-radius-row">
          {radii.map((r) => (
            <div className="ds-radius" key={r.n} style={{ borderRadius: r.v === 999 ? 16 : r.v }}>
              <div className="sq" style={{ borderRadius: r.v }}></div>
              <div>
                <div style={{ fontSize: 13, fontWeight: 500 }}>{r.n}</div>
                <div className="v" style={{ marginTop: 4 }}>{r.use}</div>
              </div>
            </div>
          ))}
        </div>
      </div>

      <div className="ds-section">
        <div className="ds-section-h">Spacing scale · 4 → 24</div>
        <div className="ds-spacing-row">
          {space.map((s) => (
            <div className="ds-radius" key={s.n}>
              <div style={{ background: 'var(--accent-soft)', border: '1px solid var(--accent-border)', borderRadius: 6, height: s.v * 1.6, width: '100%' }}></div>
              <div>
                <div style={{ fontSize: 13, fontWeight: 500, fontFamily: 'var(--font-mono)' }}>{s.n}</div>
                <div className="v" style={{ marginTop: 4 }}>{s.v}px</div>
              </div>
            </div>
          ))}
        </div>
      </div>

      <div className="ds-section">
        <div className="ds-section-h">Touch targets · loud + dim venues</div>
        <div style={{ display: 'flex', gap: 16, alignItems: 'center' }}>
          <div style={{ width: 64, height: 64, background: 'var(--accent)', borderRadius: 16, display: 'grid', placeItems: 'center', color: 'var(--accent-ink)', fontWeight: 600, fontSize: 13 }}>64</div>
          <div style={{ width: 52, height: 52, background: 'var(--bg-3)', borderRadius: 14, display: 'grid', placeItems: 'center', fontSize: 13, fontWeight: 500 }}>52</div>
          <div style={{ width: 44, height: 44, background: 'var(--bg-2)', border: '1px solid var(--border-1)', borderRadius: 12, display: 'grid', placeItems: 'center', fontSize: 12, fontWeight: 500 }}>44</div>
          <div style={{ fontSize: 13, color: 'var(--text-md)', maxWidth: 520, lineHeight: 1.5 }}>
            <b>Min 44 ✕ 44</b> for any interactive — bumped to 52 for primary actions and 64 for KDS bump-to-ready buttons. Spacing between targets ≥ 6 px even at compact density.
          </div>
        </div>
      </div>
    </div>
  );
}

function DS_Components() {
  return (
    <div className="ds-frame" style={{ width: 1280, minHeight: 920 }}>
      <div className="ds-h1">Component library</div>
      <div className="ds-sub">Building blocks · all surfaces share the same shape language</div>

      <div className="ds-comp-grid" style={{ marginTop: 24 }}>

        <div className="ds-comp">
          <div className="ds-comp-h">Buttons</div>
          <div className="ds-row">
            <button className="btn btn-primary" style={{ height: 44, padding: '0 18px' }}><span>Tambah pesanan</span></button>
            <button className="btn btn-ghost" style={{ height: 44, padding: '0 18px' }}><span>Batalkan</span></button>
            <button className="btn btn-outline" style={{ height: 44, padding: '0 18px' }}><span>Sekunder</span></button>
          </div>
          <div className="ds-row">
            <button style={{ height: 32, padding: '0 12px', borderRadius: 10, background: 'var(--bg-3)', color: 'var(--text-hi)', fontSize: 12, fontWeight: 600 }}>Small</button>
            <button style={{ height: 52, padding: '0 22px', borderRadius: 16, background: 'var(--accent)', color: 'var(--accent-ink)', fontSize: 15, fontWeight: 600 }}>Large CTA</button>
          </div>
          <div className="ds-row">
            <button className="kds-btn">Acknowledge</button>
            <button className="kds-btn kds-btn-primary">Start prep</button>
            <button className="kds-btn kds-btn-success">Ready</button>
          </div>
        </div>

        <div className="ds-comp">
          <div className="ds-comp-h">Status pills</div>
          <div className="ds-row">
            <span className="li-status sent">Sent</span>
            <span className="li-status prep">Preparing</span>
            <span className="li-status ready">Ready · pickup</span>
            <span className="li-status served">Served</span>
            <span className="li-status held">Held</span>
            <span className="li-status voided">Voided</span>
          </div>
          <div className="ds-row" style={{ marginTop: 8 }}>
            <span className="h-pill">Default</span>
            <span className="h-pill accent">Accent</span>
            <span className="h-pill success">Success</span>
            <span className="h-pill warn">Warn</span>
            <span className="h-pill urgent">Urgent</span>
            <span className="h-pill info">Info</span>
          </div>
        </div>

        <div className="ds-comp">
          <div className="ds-comp-h">Course markers</div>
          <div className="ds-row" style={{ flexDirection: 'column', alignItems: 'stretch', gap: 8 }}>
            {[
              { c: '#6db5ff', n: 'Minum dulu', meta: 'kirim otomatis' },
              { c: '#ffc04d', n: 'Pembuka',    meta: 'fire after seat' },
              { c: '#4dd487', n: 'Utama',      meta: 'fire after starters' },
              { c: '#c08aff', n: 'Penutup',    meta: 'fire after mains' },
              { c: '#ff9233', n: 'Langsung',   meta: 'auto-fire, no wait' },
            ].map((x) => (
              <div key={x.n} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '6px 10px', background: 'var(--bg-3)', borderRadius: 10, fontSize: 13 }}>
                <span style={{ width: 9, height: 9, borderRadius: '50%', background: x.c }}></span>
                <span style={{ fontWeight: 500 }}>{x.n}</span>
                <span style={{ marginLeft: 'auto', fontFamily: 'var(--font-mono)', fontSize: 10, color: 'var(--text-lo)', letterSpacing: '0.04em' }}>{x.meta}</span>
              </div>
            ))}
          </div>
        </div>

        <div className="ds-comp">
          <div className="ds-comp-h">Allergen tags</div>
          <div className="ds-row">
            {['gluten','nut','dairy','shellfish','egg','soy','sesame','sulfites'].map((a) => (
              <span key={a} style={{ display: 'inline-flex', alignItems: 'center', gap: 6, padding: '6px 10px', borderRadius: 999, background: 'var(--urgent-soft)', color: 'var(--urgent)', fontSize: 12, fontWeight: 500, border: '1px solid rgba(255,92,92,0.3)' }}>
                <span style={{ fontFamily: 'var(--font-mono)', fontSize: 10, fontWeight: 600, opacity: 0.7 }}>{({gluten:'GL', nut:'NU', dairy:'DA', shellfish:'SH', egg:'EG', soy:'SO', sesame:'SE', sulfites:'SU'})[a]}</span>
                {a}
              </span>
            ))}
          </div>
          <div className="ds-row" style={{ marginTop: 10 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '10px 12px', background: 'var(--urgent-soft)', border: '1px solid rgba(255,92,92,0.3)', borderRadius: 12, color: 'var(--urgent)', fontSize: 13, fontWeight: 500, width: '100%' }}>
              ⚠ Mengandung kacang, telur, gluten — konfirmasi ke tamu
            </div>
          </div>
        </div>

        <div className="ds-comp">
          <div className="ds-comp-h">Cards · tables</div>
          <div className="ds-row" style={{ gap: 8, alignItems: 'stretch' }}>
            <div className="tab-table-card s-available" style={{ width: 130, minHeight: 110 }}>
              <div className="tt-row1"><span className="tt-num">T3</span><span className="tt-pax">2p</span></div>
              <div className="tt-row2"><span className="tt-dot"></span><span className="tt-lbl">Kosong</span></div>
            </div>
            <div className="tab-table-card s-occupied" style={{ width: 130, minHeight: 110 }}>
              <div className="tt-row1"><span className="tt-num">T1</span><span className="tt-pax">2p</span></div>
              <div className="tt-row2"><span className="tt-dot"></span><span className="tt-lbl">Terisi</span><span className="tt-time">0:18</span></div>
            </div>
            <div className="tab-table-card s-ready" style={{ width: 130, minHeight: 110 }}>
              <div className="tt-row1"><span className="tt-num">T2</span><span className="tt-pax">4p</span></div>
              <div className="tt-row2"><span className="tt-dot"></span><span className="tt-lbl">Siap ×2</span></div>
            </div>
            <div className="tab-table-card s-pending" style={{ width: 130, minHeight: 110 }}>
              <div className="tt-row1"><span className="tt-num">T4</span><span className="tt-pax">6p</span></div>
              <div className="tt-row2"><span className="tt-dot"></span><span className="tt-lbl">Masuk</span></div>
            </div>
          </div>
        </div>

        <div className="ds-comp">
          <div className="ds-comp-h">Sync indicator</div>
          <div className="ds-row" style={{ flexDirection: 'column', alignItems: 'stretch', gap: 10 }}>
            <span className="tab-sync"><span className="dot"></span>LIVE · LAN</span>
            <span className="tab-sync offline"><span className="dot"></span>HANYA LAN · CLOUD TUNGGU</span>
            <span className="tab-sync" style={{ background: 'var(--urgent-soft)', borderColor: 'var(--urgent)', color: 'var(--urgent)' }}><span className="dot" style={{ background: 'var(--urgent)' }}></span>SERVER UNREACHABLE</span>
          </div>
        </div>

      </div>
    </div>
  );
}

window.DS_Colors = DS_Colors;
window.DS_Type = DS_Type;
window.DS_Spacing = DS_Spacing;
window.DS_Components = DS_Components;

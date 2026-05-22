// SatSet — Staff & accounts management.
/* global React, Icons */

const STAFF = [
  // Owners
  { id: 's-komang', initials: 'KO', name: 'Komang Wirawan', role: 'owner',     station: '—',           pin: '••••', shift: '—',                last: '07:42 · today',  status: 'off',    voids: 0, comps: 0 },
  { id: 's-dewi',   initials: 'DE', name: 'Dewi Anggraini', role: 'owner',     station: '—',           pin: '••••', shift: '—',                last: '21:08 · yesterday', status: 'off', voids: 0, comps: 0 },

  // Managers
  { id: 's-sari',   initials: 'SA', name: 'Sari Astawa',     role: 'manager',   station: 'Floor',       pin: '••••', shift: 'Sab 16:00 → 23:30', last: '18:14 · live',   status: 'on',     voids: 3, comps: 2, approver: true },
  { id: 's-koko',   initials: 'KO', name: 'Koko Putra',      role: 'manager',   station: 'Floor',       pin: '••••', shift: 'libur',             last: '23:42 · yesterday', status: 'off', voids: 0, comps: 0 },

  // Floor supervisor
  { id: 's-made',   initials: 'MD', name: 'Made Suryani',    role: 'supervisor', station: 'Indoor',     pin: '••••', shift: 'Sab 17:30 → 23:30', last: '18:14 · live',   status: 'on',     voids: 0, comps: 1 },

  // Waiters
  { id: 's-maya',   initials: 'MA', name: 'Maya Anjani',     role: 'waiter',     station: 'Teras',      pin: '••••', shift: 'Sab 17:30 → 23:30', last: '18:14 · live',   status: 'on',     voids: 0, comps: 0, byod: true },
  { id: 's-putu',   initials: 'PU', name: 'Putu Mahendra',   role: 'waiter',     station: 'Taman',      pin: '••••', shift: 'Sab 17:30 → 23:30', last: '18:13 · live',   status: 'on',     voids: 0, comps: 0 },
  { id: 's-ari',    initials: 'AR', name: 'Ari Sukma',       role: 'waiter',     station: 'Indoor',     pin: '••••', shift: 'Sab 17:30 → 23:30', last: '18:12 · live',   status: 'on',     voids: 1, comps: 0, byod: true },
  { id: 's-ayu',    initials: 'AY', name: 'Ayu Pratiwi',     role: 'waiter',     station: 'Bar',        pin: '••••', shift: 'Sab 17:30 → 23:30', last: '18:14 · live',   status: 'on',     voids: 0, comps: 0 },
  { id: 's-eko',    initials: 'EK', name: 'Eko Saputra',     role: 'waiter',     station: 'Teras',      pin: '••••', shift: 'libur',             last: '23:50 · 2 hari lalu', status: 'off', voids: 0, comps: 0 },

  // Expediter
  { id: 's-wira',   initials: 'WI', name: 'Wira Mahardika',  role: 'expediter',  station: 'Pass',       pin: '••••', shift: 'Sab 17:00 → 23:30', last: '18:14 · live',   status: 'on',     voids: 0, comps: 0 },

  // Kitchen & bar staff (KDS / station accounts)
  { id: 's-budi',   initials: 'BU', name: 'Budi Hartono',    role: 'kitchen',    station: 'Dapur · Utama',  pin: '••••', shift: 'Sab 14:00 → 23:30', last: '18:14 · live',   status: 'on',     voids: 0, comps: 0, lead: true },
  { id: 's-andre',  initials: 'AN', name: 'Andre Pramana',   role: 'kitchen',    station: 'Dapur · Pembuka', pin: '••••', shift: 'Sab 14:00 → 23:30', last: '18:13 · live',   status: 'on',     voids: 0, comps: 0 },
  { id: 's-ratih',  initials: 'RA', name: 'Ratih Wulandari', role: 'kitchen',    station: 'Dapur · Penutup', pin: '••••', shift: 'Sab 14:00 → 23:30', last: '18:11 · live',   status: 'on',     voids: 0, comps: 0 },
  { id: 's-fajar',  initials: 'FA', name: 'Fajar Nugroho',   role: 'bar',        station: 'Bar · Cocktail', pin: '••••', shift: 'Sab 17:00 → 23:30', last: '18:14 · live',   status: 'on',     voids: 0, comps: 0, lead: true },
  { id: 's-indra',  initials: 'IN', name: 'Indra Kusuma',    role: 'bar',        station: 'Bar · Soft',     pin: '••••', shift: 'libur',             last: '23:20 · yesterday', status: 'off', voids: 0, comps: 0 },
];

const ROLE_LABELS = {
  owner:      'Owner',
  manager:    'Manager',
  supervisor: 'Floor supervisor',
  waiter:     'Pelayan',
  expediter:  'Expediter',
  kitchen:    'Dapur',
  bar:        'Bar',
};

const ROLE_PERMS = {
  owner:      { void: '∞',         comp: '∞',          kill: true,  reports: 'all',     menu: 'edit', staff: 'manage' },
  manager:    { void: 'PIN approve', comp: '≤ Rp 300k', kill: true,  reports: 'all',     menu: 'edit', staff: 'shift' },
  supervisor: { void: 'PIN approve', comp: '≤ Rp 50k',  kill: false, reports: 'shift',   menu: 'view', staff: 'view' },
  waiter:     { void: 'request',    comp: '—',          kill: false, reports: 'own',     menu: '—',    staff: '—' },
  expediter:  { void: 'request',    comp: '—',          kill: false, reports: 'pass',    menu: '—',    staff: '—' },
  kitchen:    { void: '—',          comp: '—',          kill: true,  reports: 'station', menu: 'flag', staff: '—' },
  bar:        { void: '—',          comp: '—',          kill: true,  reports: 'station', menu: 'flag', staff: '—' },
};

function StaffScreen() {
  const [filter, setFilter] = React.useState('all');
  const list = filter === 'all' ? STAFF : STAFF.filter((s) => s.role === filter);
  const onShift = STAFF.filter((s) => s.status === 'on').length;

  // role count for filter pills
  const cnt = (r) => STAFF.filter((s) => s.role === r).length;

  return (
    <div className="set-wrap">
      <div className="set-head">
        <div>
          <div style={{ fontSize: 22, fontWeight: 600, letterSpacing: '-0.015em' }}>Staff & akun</div>
          <div style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--text-lo)', letterSpacing: '0.06em', textTransform: 'uppercase', marginTop: 6 }}>
            {STAFF.length} TOTAL · {onShift} ON SHIFT · BYOD POLICY AKTIF
          </div>
        </div>
        <div style={{ marginLeft: 'auto', display: 'flex', gap: 10 }}>
          <button className="set-btn">Bulk SMS invite</button>
          <button className="set-btn" style={{ background: 'var(--accent)', color: 'var(--accent-ink)', border: 0, fontWeight: 600 }}>+ Staf baru</button>
        </div>
      </div>

      {/* Top stat strip */}
      <div className="set-grid" style={{ gridTemplateColumns: 'repeat(6, 1fr)', marginBottom: 18 }}>
        <Tile l="On shift" v={onShift} d={`${STAFF.length - onShift} libur`} />
        <Tile l="Pelayan aktif" v={STAFF.filter((s) => s.role === 'waiter' && s.status === 'on').length + ' / ' + cnt('waiter')} d="4 zona terjangkau" />
        <Tile l="Dapur aktif" v={STAFF.filter((s) => s.role === 'kitchen' && s.status === 'on').length + ' / ' + cnt('kitchen')} d="3 stasiun staffed" />
        <Tile l="Bar aktif" v={STAFF.filter((s) => s.role === 'bar' && s.status === 'on').length + ' / ' + cnt('bar')} d="cocktail OK · soft kosong" warn />
        <Tile l="Manager hadir" v={STAFF.filter((s) => (s.role === 'manager' || s.role === 'supervisor') && s.status === 'on').length} d="Sari (mgr) · Made (sup)" />
        <Tile l="BYOD devices" v={STAFF.filter((s) => s.byod).length} d="session expire shift end" />
      </div>

      {/* Filter pills */}
      <div style={{ display: 'flex', gap: 6, padding: '0 0 14px', flexWrap: 'wrap' }}>
        <FilterPill cur={filter} onClick={setFilter} v="all"        label="Semua" cnt={STAFF.length}/>
        <FilterPill cur={filter} onClick={setFilter} v="owner"      label="Owner" cnt={cnt('owner')}/>
        <FilterPill cur={filter} onClick={setFilter} v="manager"    label="Manager" cnt={cnt('manager')}/>
        <FilterPill cur={filter} onClick={setFilter} v="supervisor" label="Supervisor" cnt={cnt('supervisor')}/>
        <FilterPill cur={filter} onClick={setFilter} v="waiter"     label="Pelayan" cnt={cnt('waiter')}/>
        <FilterPill cur={filter} onClick={setFilter} v="expediter"  label="Expediter" cnt={cnt('expediter')}/>
        <FilterPill cur={filter} onClick={setFilter} v="kitchen"    label="Dapur" cnt={cnt('kitchen')}/>
        <FilterPill cur={filter} onClick={setFilter} v="bar"        label="Bar" cnt={cnt('bar')}/>
      </div>

      {/* Staff table */}
      <div className="set-card" style={{ padding: 0 }}>
        <div className="staff-row head">
          <div></div>
          <div>Staf</div>
          <div>Role · station</div>
          <div>Shift terkini</div>
          <div>PIN</div>
          <div>Last seen</div>
          <div>Aktivitas</div>
          <div>Status</div>
          <div></div>
        </div>
        {list.map((s) => (
          <div className="staff-row" key={s.id}>
            <div className={'staff-av role-' + s.role}>
              {s.initials}
              {s.status === 'on' && <span className="dot"></span>}
            </div>
            <div>
              <div className="nm">
                {s.name}
                {s.lead && <span className="tag lead">LEAD</span>}
                {s.approver && <span className="tag approver">APPROVE VOID</span>}
                {s.byod && <span className="tag byod">BYOD</span>}
              </div>
              <div className="meta">{s.id.replace('s-', '@')} · joined Mar 2025</div>
            </div>
            <div>
              <div style={{ fontSize: 13, fontWeight: 500 }}>{ROLE_LABELS[s.role]}</div>
              <div className="meta" style={{ fontFamily: 'var(--font-mono)' }}>{s.station}</div>
            </div>
            <div style={{ fontSize: 12, color: 'var(--text-md)', lineHeight: 1.4 }}>
              {s.shift === 'libur' || s.shift === '—'
                ? <span style={{ color: 'var(--text-lo)' }}>{s.shift}</span>
                : s.shift}
            </div>
            <div style={{ fontFamily: 'var(--font-mono)', fontSize: 13, color: 'var(--text-md)', letterSpacing: '0.1em' }}>{s.pin}</div>
            <div style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--text-lo)', letterSpacing: '0.02em' }}>{s.last}</div>
            <div style={{ display: 'flex', gap: 8, fontFamily: 'var(--font-mono)', fontSize: 11 }}>
              {s.voids > 0 && <span style={{ color: 'var(--urgent)' }}>{s.voids}V</span>}
              {s.comps > 0 && <span style={{ color: 'var(--warn)' }}>{s.comps}C</span>}
              {s.voids === 0 && s.comps === 0 && <span style={{ color: 'var(--text-dim)' }}>—</span>}
            </div>
            <div>
              <span className={'staff-status ' + s.status}>
                <span className="dot"></span>{s.status === 'on' ? 'On shift' : 'Libur'}
              </span>
            </div>
            <div style={{ display: 'flex', gap: 4, justifyContent: 'flex-end' }}>
              <button className="set-pill">Edit</button>
              <button className="set-pill" title="Reset PIN">↻</button>
            </div>
          </div>
        ))}
      </div>

      {/* Permissions matrix + audit footer */}
      <div className="set-cols" style={{ marginTop: 18 }}>
        <div className="set-card">
          <div className="set-card-h">
            Role permissions
            <span className="set-card-sub">RBAC · ENFORCED ON SERVER</span>
          </div>
          <div className="perm-table">
            <div className="perm-row head">
              <div>Role</div>
              <div>Void</div>
              <div>Comp</div>
              <div>Kill-switch</div>
              <div>Reports</div>
              <div>Menu</div>
              <div>Staff</div>
            </div>
            {['owner','manager','supervisor','waiter','expediter','kitchen','bar'].map((r) => {
              const p = ROLE_PERMS[r];
              return (
                <div className="perm-row" key={r}>
                  <div className="role-cell">
                    <span className={'staff-av sm role-' + r}>{r.slice(0, 2).toUpperCase()}</span>
                    {ROLE_LABELS[r]}
                  </div>
                  <div className={p.void === '—' ? 'mute' : ''}>{p.void}</div>
                  <div className={p.comp === '—' ? 'mute' : ''}>{p.comp}</div>
                  <div className={p.kill ? 'ok' : 'mute'}>{p.kill ? '✓' : '—'}</div>
                  <div>{p.reports}</div>
                  <div className={p.menu === '—' ? 'mute' : ''}>{p.menu}</div>
                  <div className={p.staff === '—' ? 'mute' : ''}>{p.staff}</div>
                </div>
              );
            })}
          </div>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          <div className="set-card">
            <div className="set-card-h">
              Akses & sesi
              <span className="set-card-sub">BYOD POLICY</span>
            </div>
            <div className="set-row"><div className="lbl">PIN length</div><div className="val mono">4 digit · numerik</div></div>
            <div className="set-row"><div className="lbl">PIN expiry</div><div className="val">Otomatis di akhir shift</div></div>
            <div className="set-row"><div className="lbl">BYOD persistence</div><div className="val">No local data persists · audit logged</div></div>
            <div className="set-row"><div className="lbl">Failed attempts</div><div className="val">3 salah → block 5 menit</div></div>
            <div className="set-row" style={{ borderBottom: 0 }}><div className="lbl">Aksi</div>
              <div style={{ display: 'flex', gap: 8, marginLeft: 'auto' }}>
                <button className="set-pill">Force sign-out semua</button>
                <button className="set-pill danger">Lock-down mode</button>
              </div>
            </div>
          </div>

          <div className="set-card">
            <div className="set-card-h">
              Audit · sign-in log
              <span className="set-card-sub">7 EVENT TERAKHIR</span>
            </div>
            {[
              { t: '17:30', n: 'Maya', e: 'sign-in', d: 'BYOD · iPhone 14 · ::1f4a' },
              { t: '17:30', n: 'Putu', e: 'sign-in', d: 'venue · iPad Air · ::8f12' },
              { t: '17:30', n: 'Ari',  e: 'sign-in', d: 'BYOD · iPhone 13 · ::3e88 · approved' },
              { t: '17:30', n: 'Ayu',  e: 'sign-in', d: 'venue · iPhone 12 · ::c4a2' },
              { t: '17:00', n: 'Wira', e: 'sign-in', d: 'EXPO · iPad Pro · ::e017' },
              { t: '14:00', n: 'Budi', e: 'sign-in', d: 'KDS terminal · server tablet' },
              { t: '12:42', n: 'Made', e: 'sign-out', d: 'shift end · clean session' },
            ].map((r, i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '8px 0', borderBottom: i === 6 ? 0 : '1px solid var(--border-0)' }}>
                <span style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--text-lo)', letterSpacing: '0.04em', width: 40 }}>{r.t}</span>
                <span style={{ fontSize: 13, width: 56 }}>{r.n}</span>
                <span className={'h-pill ' + (r.e === 'sign-out' ? '' : 'success')} style={{ fontSize: 10 }}>{r.e.toUpperCase()}</span>
                <span style={{ flex: 1, fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--text-md)', letterSpacing: '0.02em' }}>{r.d}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

function Tile({ l, v, d, warn }) {
  return (
    <div className="set-tile" style={warn ? { background: 'var(--warn-soft)', borderColor: 'rgba(255,192,77,0.3)' } : {}}>
      <div className="set-tile-h"><span>{l}</span></div>
      <div className="set-tile-v" style={warn ? { color: 'var(--warn)' } : {}}>{v}</div>
      <div className="set-tile-d">{d}</div>
    </div>
  );
}

function FilterPill({ cur, onClick, v, label, cnt }) {
  return (
    <button className={'tab-seg ' + (cur === v ? 'active' : '')} onClick={() => onClick(v)}>
      {label} <span className="count">{cnt}</span>
    </button>
  );
}

window.StaffScreen = StaffScreen;

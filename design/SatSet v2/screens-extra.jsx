// SatSet — Orders + Me screens. Depends on globals from screens.jsx + data.js.
/* global React, Icons, SATSET_DATA, formatIDR, statusText */

const { useMemo: useMemoX } = React;

// ─────────────────────────────────────────────────────────────────────
//  Orders screen — Maya's tickets across her tables, segmented
// ─────────────────────────────────────────────────────────────────────
function OrdersScreen({ ticketsByTable, tables, onOpenTable, onOpenTicket }) {
  const [seg, setSeg] = React.useState('ready');

  // Flatten — all tickets with table info, only mine
  const all = useMemoX(() => {
    const out = [];
    Object.entries(ticketsByTable).forEach(([tableId, tickets]) => {
      const table = tables.find((t) => t.id === tableId);
      if (!table || !table.mine) return;
      tickets.forEach((t) => out.push({ ...t, tableId, zone: table.zone, pax: table.pax }));
    });
    return out;
  }, [ticketsByTable, tables]);

  const ready    = all.filter((t) => t.status === 'ready');
  const active   = all.filter((t) => t.status === 'sent' || t.status === 'prep' || t.status === 'held');
  const done     = all.filter((t) => t.status === 'served' || t.status === 'voided');

  const list = seg === 'ready' ? ready : seg === 'active' ? active : done;

  return (
    <>
      <div className="topbar">
        <button className="zone-switch" disabled>
          <Icons.Orders size={14}/> Semua pesanan saya
        </button>
        <div className="sync"><span className="dot"></span>LIVE · LAN</div>
        <div className="avatar">MA</div>
      </div>

      <Header
        title="Pesanan"
        sub={`${active.length} berjalan · ${ready.length} siap diambil`}
      />

      <div className="zone-tabs">
        <button className={'zone-tab ' + (seg === 'ready' ? 'active' : '')} onClick={() => setSeg('ready')}>
          Siap <span className="count">{ready.length}</span>
        </button>
        <button className={'zone-tab ' + (seg === 'active' ? 'active' : '')} onClick={() => setSeg('active')}>
          Disiapkan <span className="count">{active.length}</span>
        </button>
        <button className={'zone-tab ' + (seg === 'done' ? 'active' : '')} onClick={() => setSeg('done')}>
          Selesai <span className="count">{done.length}</span>
        </button>
      </div>

      <div className="body-scroll" style={{ paddingBottom: 100 }}>
        {list.length === 0 ? (
          <div style={{ padding: '40px 24px', textAlign: 'center', color: 'var(--text-lo)', fontSize: 13 }}>
            {seg === 'ready' ? 'Belum ada yang siap di pass.' :
             seg === 'active' ? 'Tidak ada item yang sedang disiapkan.' :
             'Belum ada item yang selesai pada sesi ini.'}
          </div>
        ) : (
          <div style={{ padding: '4px 16px' }}>
            {list.map((t) => (
              <button
                key={t.id}
                className={'order-row ' + (t.status === 'ready' ? 'is-ready' : '') + (t.status === 'voided' ? ' is-voided' : '')}
                onClick={() => onOpenTable(t.tableId)}
              >
                <div className="o-table">{t.tableId}</div>
                <div className="o-body">
                  <div className="o-name">
                    {t.qty > 1 && <span style={{ color: 'var(--text-md)', fontFamily: 'var(--font-mono)', fontSize: 12, marginRight: 4 }}>×{t.qty}</span>}
                    {t.name}
                    {t.variantName ? <span style={{ color: 'var(--text-md)' }}> · {t.variantName}</span> : null}
                  </div>
                  {t.modifiers && t.modifiers.length > 0 && (
                    <div className="o-mods">{t.modifiers.slice(0, 2).join(' · ')}{t.modifiers.length > 2 ? ' · …' : ''}</div>
                  )}
                  <div className="o-foot">
                    <span className={'li-status ' + t.status}>{statusText(t.status)}</span>
                    <span className="o-meta">
                      {t.station === 'kitchen' ? 'DPR' : 'BAR'} · {t.sentAt}
                    </span>
                  </div>
                </div>
                <Icons.Chev size={16} stroke="var(--text-lo)"/>
              </button>
            ))}
          </div>
        )}
      </div>
    </>
  );
}

// ─────────────────────────────────────────────────────────────────────
//  Me screen — shift stats, audit log, end shift
// ─────────────────────────────────────────────────────────────────────
function MeScreen({ tables, ticketsByTable, auditLog, onEndShift }) {
  const myTables = tables.filter((t) => t.mine);
  const ticketCount = myTables.reduce((s, t) => s + (ticketsByTable[t.id]?.length || 0), 0);
  const voidCount = auditLog.filter((a) => a.type === 'void').length;
  const compCount = auditLog.filter((a) => a.type === 'comp').length;
  const openCovers = myTables.reduce((s, t) => s + (t.status !== 'available' ? t.pax : 0), 0);

  return (
    <>
      <div className="topbar">
        <div className="zone-switch" style={{ background: 'transparent', border: 0, padding: 0 }}>
          <Icons.Me size={14}/> Ringkasan shift
        </div>
        <div className="sync"><span className="dot"></span>LIVE · LAN</div>
        <div className="avatar">MA</div>
      </div>

      <div className="me-hero">
        <div className="me-avatar">MA</div>
        <div>
          <div className="me-name">Maya Anjani</div>
          <div className="me-role">Pelayan · Zona Teras</div>
          <div className="me-shift">
            Mulai shift {SATSET_DATA.user.shiftStartedAt} ·&nbsp;
            <span style={{ color: 'var(--accent)', whiteSpace: 'nowrap' }}>47 menit</span>
          </div>
        </div>
      </div>

      <div className="me-stats">
        <Stat label="Pesanan kirim" value={ticketCount} />
        <Stat label="Tamu aktif" value={openCovers} />
        <Stat label="Pembatalan" value={voidCount} tone={voidCount ? 'urgent' : 'normal'} />
        <Stat label="Gratisan" value={compCount} tone={compCount ? 'warn' : 'normal'} />
      </div>

      <div className="section-label">Aktivitas terkini<span className="cnt">{auditLog.length} entri</span></div>

      <div className="audit-list">
        {auditLog.length === 0 ? (
          <div style={{ padding: '16px 20px', color: 'var(--text-lo)', fontSize: 13 }}>
            Belum ada entri audit. Pembatalan, gratisan, dan perubahan setelah kirim akan tampil di sini.
          </div>
        ) : (
          auditLog.slice(0, 5).map((a) => (
            <div className="audit-row" key={a.id}>
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
          ))
        )}
      </div>

      <div className="section-label">Preferensi</div>

      <div className="me-list">
        <PrefRow icon={<Icons.Bell size={16}/>} label="Alert audio" value="Aktif" />
        <PrefRow icon={<Icons.Alert size={16}/>} label="Getaran haptik" value="Kuat" />
        <PrefRow icon={<Icons.Wifi size={16}/>} label="Koneksi server" value={SATSET_DATA.venue.name} subtle={'192.168.4.21 · sertifikat OK'} />
      </div>

      <div style={{ padding: '24px 16px 120px' }}>
        <button className="btn btn-outline" style={{ width: '100%' }} onClick={onEndShift}>
          Akhiri shift &amp; keluar
        </button>
        <div style={{ marginTop: 12, fontFamily: 'var(--font-mono)', fontSize: 10, color: 'var(--text-lo)', letterSpacing: '0.06em', textAlign: 'center' }}>
          BYOD · DATA PESANAN TIDAK TERSIMPAN DI HP · v2.0.0
        </div>
      </div>
    </>
  );
}

function Stat({ label, value, tone = 'normal' }) {
  return (
    <div className={'stat-card t-' + tone}>
      <div className="stat-val">{value}</div>
      <div className="stat-lbl">{label}</div>
    </div>
  );
}

function PrefRow({ icon, label, value, subtle }) {
  return (
    <div className="pref-row">
      <span className="pref-ic">{icon}</span>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div className="pref-label">{label}</div>
        {subtle && <div className="pref-subtle">{subtle}</div>}
      </div>
      <div className="pref-value">{value}</div>
      <Icons.Chev size={14} stroke="var(--text-lo)"/>
    </div>
  );
}

Object.assign(window, { OrdersScreen, MeScreen });

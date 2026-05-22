// SatSet — Action sheet + void flow + manager PIN. One file, one flow.
/* global React, Icons, SATSET_DATA, formatIDR, statusText */

const VOID_REASONS = [
  { id: 'error',    label: 'Salah kirim',          desc: 'Salah meja, tap ganda, salah catat' },
  { id: 'changed',  label: 'Tamu berubah pikiran', desc: 'Tamu membatalkan permintaan' },
  { id: 'allergy',  label: 'Alergi / diet',        desc: 'Tamu memberi tahu setelah pengiriman' },
  { id: 'complaint',label: 'Keluhan',              desc: 'Masalah kualitas — lebih baik refire' },
  { id: 'other',    label: 'Lainnya',              desc: 'Alasan bebas — wajib diisi' },
];

// ─────────────────────────────────────────────────────────────────────
//  LineItemActionSheet — opens when a ticket is tapped on table detail.
//  Renders 3 sub-views: actions list → reason picker → manager PIN.
// ─────────────────────────────────────────────────────────────────────
function LineItemActionSheet({ ticket, table, step, onClose, onPick, onVoidReason, onApprove, onComplete }) {
  if (!ticket) return null;
  return (
    <>
      <div className="sheet-scrim" onClick={onClose}/>
      <div className="sheet sheet-narrow">
        <div className="grabber"></div>
        <div className="action-head">
          <div>
            <div className="action-tag">
              <span className={'li-status ' + ticket.status}>{statusText(ticket.status)}</span>
              <span className="action-meta">MEJA {ticket.tableId || table?.id} · {ticket.station === 'kitchen' ? 'DAPUR' : 'BAR'} · {ticket.sentAt}</span>
            </div>
            <div className="action-title">
              ×{ticket.qty} {ticket.name}{ticket.variantName ? ' · ' + ticket.variantName : ''}
            </div>
            {ticket.modifiers && ticket.modifiers.length > 0 && (
              <div className="action-mods">{ticket.modifiers.join(' · ')}</div>
            )}
          </div>
          <button className="iconbtn" onClick={onClose}>
            <Icons.Close size={18}/>
          </button>
        </div>

        {step === 'actions'      && <ActionList ticket={ticket} onPick={onPick} />}
        {step === 'void-reason'  && <VoidReasonList onPick={onVoidReason} />}
        {step === 'manager-pin'  && <ManagerPinView ticket={ticket} onApprove={onApprove} />}
        {step === 'confirmed'    && <VoidConfirmed ticket={ticket} onDone={onComplete} />}
      </div>
    </>
  );
}

// ── Step 1: actions list ─────────────────────────────────────────────
function ActionList({ ticket, onPick }) {
  // Available actions depend on the ticket's current status
  const rows = [];

  if (ticket.status === 'sent' || ticket.status === 'held') {
    rows.push({
      id: 'modify',
      icon: <Icons.Edit size={18}/>,
      title: 'Ubah item',
      desc: 'Edit pilihan & catatan khusus — tanpa persetujuan',
      tone: 'normal',
    });
  }
  if (ticket.status === 'held') {
    rows.push({
      id: 'fire',
      icon: <Icons.Fire size={18}/>,
      title: 'Kirim sekarang',
      desc: 'Kirim course ini ke line langsung',
      tone: 'accent',
    });
  }
  if (ticket.status === 'prep') {
    rows.push({
      id: 'request-modify',
      icon: <Icons.Edit size={18}/>,
      title: 'Minta perubahan',
      desc: 'Station harus konfirmasi — “masih bisa” / “sudah terlanjur”',
      tone: 'warn',
    });
  }
  if (ticket.status === 'ready') {
    rows.push({
      id: 'serve',
      icon: <Icons.Check size={18}/>,
      title: 'Tandai disajikan',
      desc: 'Konfirmasi sudah diambil & sampai ke tamu',
      tone: 'success',
    });
  }
  if (ticket.status === 'served') {
    rows.push({
      id: 'unserve',
      icon: <Icons.Back size={18}/>,
      title: 'Batalkan sajian',
      desc: 'Kembalikan status jika ditandai terlalu cepat',
      tone: 'normal',
    });
  }

  // Pembatalan selalu tersedia (kecuali sudah dibatalkan)
  if (ticket.status !== 'voided') {
    rows.push({
      id: 'void',
      icon: <Icons.Trash size={18}/>,
      title: 'Batalkan item',
      desc: 'Hapus dari pesanan · perlu PIN manajer',
      tone: 'danger',
    });
  }

  return (
    <div className="action-list">
      {rows.map((r) => (
        <button key={r.id} className={'action-row tone-' + r.tone} onClick={() => onPick(r.id)}>
          <span className={'action-ic tone-' + r.tone}>{r.icon}</span>
          <div className="action-body">
            <div className="action-name">{r.title}</div>
            <div className="action-desc">{r.desc}</div>
          </div>
          <Icons.Chev size={16} stroke="var(--text-lo)"/>
        </button>
      ))}
    </div>
  );
}

// ── Step 2: void reason picker ──────────────────────────────────────
function VoidReasonList({ onPick }) {
  const [picked, setPicked] = React.useState(null);
  const [other, setOther] = React.useState('');

  const canContinue = picked && (picked !== 'other' || other.trim().length >= 3);

  return (
    <div className="action-list">
      <div className="reason-intro">
        <Icons.Alert size={14}/>
        <span>Pembatalan dicatat dengan akun anda, alasan, dan manajer yang menyetujui. <b>Refire</b> mungkin lebih cocok untuk masalah kualitas.</span>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 6, padding: '0 16px' }}>
        {VOID_REASONS.map((r) => (
          <button
            key={r.id}
            className={'mod-opt ' + (picked === r.id ? 'selected' : '')}
            onClick={() => setPicked(r.id)}
          >
            <span className="check">{picked === r.id && <Icons.Check size={14}/>}</span>
            <div style={{ flex: 1, textAlign: 'left' }}>
              <div style={{ fontSize: 14, fontWeight: 500 }}>{r.label}</div>
              <div style={{ fontSize: 11, color: 'var(--text-md)', marginTop: 2 }}>{r.desc}</div>
            </div>
          </button>
        ))}
      </div>

      {picked === 'other' && (
        <div style={{ padding: '10px 16px 4px' }}>
          <textarea
            className="special warn-text"
            placeholder="Wajib — jelaskan alasan pembatalan"
            maxLength={120}
            value={other}
            onChange={(e) => setOther(e.target.value)}
          />
          <div className="char-count">{other.length} / 120</div>
        </div>
      )}

      <div className="sheet-foot" style={{ marginTop: 4 }}>
        <button
          className="btn btn-primary"
          disabled={!canContinue}
          style={{ width: '100%', opacity: canContinue ? 1 : 0.45 }}
          onClick={() => onPick({
            id: picked,
            label: VOID_REASONS.find((r) => r.id === picked).label,
            text: picked === 'other' ? other.trim() : null,
          })}
        >
          Lanjut ke PIN manajer
          <Icons.Chev size={14}/>
        </button>
      </div>
    </div>
  );
}

// ── Step 3: manager PIN ──────────────────────────────────────────────
function ManagerPinView({ ticket, onApprove }) {
  const [pin, setPin] = React.useState('');
  const [err, setErr] = React.useState(false);
  const max = 4;

  // demo: any 4 digits except "0000" works; "0000" simulates wrong PIN
  function press(d) {
    setErr(false);
    if (d === 'del') {
      setPin((p) => p.slice(0, -1));
      return;
    }
    setPin((p) => {
      if (p.length >= max) return p;
      const next = p + d;
      if (next.length === max) {
        setTimeout(() => {
          if (next === '0000') {
            setErr(true);
            setPin('');
          } else {
            onApprove({ pin: next, approver: 'Sari (Mgr)' });
          }
        }, 220);
      }
      return next;
    });
  }

  const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', 'del'];

  return (
    <div className="mgr-pin">
      <div className="mgr-pin-head">
        <div className="mgr-pin-lock">
          <Icons.Pin size={16}/>
        </div>
        <div style={{ flex: 1 }}>
          <div className="mgr-pin-title">PIN manajer diperlukan</div>
          <div className="mgr-pin-sub">
            Membatalkan ×{ticket.qty} {ticket.name} — Rp {ticket.price.toLocaleString('id-ID')}
          </div>
        </div>
      </div>

      <div className="pin-dots" style={{ marginTop: 22 }}>
        {Array.from({ length: max }).map((_, i) => (
          <div key={i} className={'pin-dot ' + (i < pin.length ? 'filled' : '') + (err ? ' err' : '')}></div>
        ))}
      </div>
      {err && <div className="mgr-pin-err">PIN salah — coba lagi</div>}

      <div className="pin-pad" style={{ padding: '20px 32px 8px' }}>
        {keys.map((k, i) => {
          if (k === '') return <div key={i}/>;
          if (k === 'del') return <button key={i} className="pin-key muted" onClick={() => press('del')}><Icons.Back size={18}/></button>;
          return <button key={i} className="pin-key" onClick={() => press(k)}>{k}</button>;
        })}
      </div>

      <div style={{ padding: '6px 24px 22px', textAlign: 'center', fontFamily: 'var(--font-mono)', fontSize: 10, color: 'var(--text-lo)', letterSpacing: '0.06em' }}>
        COBA 0000 UNTUK SIMULASI PIN SALAH
      </div>
    </div>
  );
}

// ── Step 4: confirmation ─────────────────────────────────────────────
function VoidConfirmed({ ticket, onDone }) {
  React.useEffect(() => {
    const t = setTimeout(onDone, 1500);
    return () => clearTimeout(t);
  }, [onDone]);
  return (
    <div className="void-done">
      <div className="sent-check" style={{ background: 'rgba(255,92,92,0.16)' }}>
        <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="var(--urgent)" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
          <path d="M4 7h16M9 7V5a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2M6 7l1 13a2 2 0 0 0 2 2h6a2 2 0 0 0 2-2l1-13"/>
        </svg>
      </div>
      <div className="void-done-title">Item dibatalkan</div>
      <div className="void-done-sub">
        Dicatat: ×{ticket.qty} {ticket.name} · disetujui Sari (Mgr) · tampil di jejak audit
      </div>
    </div>
  );
}

Object.assign(window, { LineItemActionSheet });

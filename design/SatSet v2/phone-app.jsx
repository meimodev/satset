// SatSet — main app shell. State, routing, demo behaviors.
/* global React, ReactDOM,
   IOSDevice, IOSStatusBar,
   TopBar, TabBar, Header,
   PinScreen, TablesScreen, TableDetailScreen, MenuScreen, ModifierSheet,
   ReviewScreen, SentScreen, ReadyToast,
   SATSET_DATA, courseFromCategory, statusLabel, Icons,
   TweaksPanel, useTweaks, TweakSection, TweakRadio, TweakToggle, TweakButton, TweakColor
*/

const { useState, useEffect, useMemo, useRef, useCallback } = React;

function App() {
  // ── Tweaks (theme, density, demos) ────────────────────────────────
  const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
    "theme": "dark",
    "density": "comfy",
    "syncMode": "live",
    "showFrame": true
  }/*EDITMODE-END*/;
  const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);

  // ── App state ─────────────────────────────────────────────────────
  const [signedIn, setSignedIn] = useState(false);
  const [route, setRoute] = useState({ screen: 'tables' }); // tables | tableDetail | menu | review | sent
  const [activeTab, setActiveTab] = useState('tables');
  const [activeZone, setActiveZone] = useState('terrace');
  const [selectedTable, setSelectedTable] = useState(null);
  const [modifierItem, setModifierItem] = useState(null);
  const [cart, setCart] = useState([]); // pending items not yet sent

  // Tables + tickets (mutable copies of the dataset)
  const [tables, setTables] = useState(SATSET_DATA.tables);
  const [ticketsByTable, setTicketsByTable] = useState(
    () => JSON.parse(JSON.stringify(SATSET_DATA.initialTicketsByTable))
  );

  // Audit log — every void / comp / modify / fire entry
  const [auditLog, setAuditLog] = useState([
    { id: 'A0', type: 'fire', title: 'Kirim Utama untuk Meja T1', tableId: 'T1', when: '17:46', approvedBy: null, reason: null },
  ]);

  // Action sheet flow: { ticket, step: 'actions' | 'void-reason' | 'manager-pin' | 'confirmed', reason? }
  const [actionFlow, setActionFlow] = useState(null);

  // Ready alert overlay
  const [readyAlert, setReadyAlert] = useState(null);

  // Ready count for tab-bar badge
  const totalReadyCount = useMemo(
    () => tables.reduce((s, t) => s + (t.status === 'ready' ? (t.readyCount || 1) : 0), 0),
    [tables]
  );

  // Apply theme + density to root
  useEffect(() => {
    document.documentElement.setAttribute('data-theme', t.theme);
  }, [t.theme]);

  // ── Helpers ───────────────────────────────────────────────────────
  const goTable = useCallback((id) => {
    setSelectedTable(id);
    setRoute({ screen: 'tableDetail' });
  }, []);

  const openAddMenu = useCallback(() => {
    setRoute({ screen: 'menu' });
  }, []);

  const openItem = useCallback((item) => setModifierItem(item), []);

  const addToCart = useCallback((cartItem) => {
    setCart((c) => [...c, { ...cartItem, id: 'C' + (c.length + 1) + '-' + Date.now() }]);
    setModifierItem(null);
  }, []);

  const removeFromCart = useCallback((id) => {
    setCart((c) => c.filter((x) => x.id !== id));
  }, []);

  const sendOrder = useCallback(() => {
    const tableId = selectedTable;
    // Convert cart items to sent tickets
    const sentAt = new Date();
    const hh = String(sentAt.getHours()).padStart(2, '0');
    const mm = String(sentAt.getMinutes()).padStart(2, '0');
    const stamp = `${hh}:${mm}`;
    const newTickets = cart.map((c, i) => ({
      id: 'N' + Date.now() + '-' + i,
      itemId: c.itemId,
      name: c.name,
      course: c.course,
      variantName: c.variantName,
      station: c.station,
      qty: c.qty,
      modifiers: c.modifiers,
      specialInstructions: c.special,
      price: c.unitPrice,
      status: (c.course === 'fire-now' || c.course === 'drinks-now') ? 'sent' : 'held',
      sentAt: stamp,
    }));
    setTicketsByTable((m) => ({
      ...m,
      [tableId]: [...(m[tableId] || []), ...newTickets],
    }));
    // Mark table as having pending order
    setTables((ts) =>
      ts.map((t) => t.id === tableId ? { ...t, status: 'pending', elapsed: t.elapsed || '0:01', mine: true } : t)
    );
    setRoute({ screen: 'sent', stations: stationsFromCart(cart) });
    setCart([]);
  }, [cart, selectedTable]);

  function stationsFromCart(c) {
    const s = new Set(c.map((x) => x.station));
    return [...s].map((x) => x === 'kitchen' ? 'Dapur' : 'Bar');
  }

  function nowStamp() {
    const d = new Date();
    return String(d.getHours()).padStart(2, '0') + ':' + String(d.getMinutes()).padStart(2, '0');
  }

  const fireCourse = useCallback((courseId) => {
    if (!selectedTable) return;
    setTicketsByTable((m) => ({
      ...m,
      [selectedTable]: m[selectedTable].map((it) =>
        it.course === courseId && it.status === 'held' ? { ...it, status: 'sent' } : it
      ),
    }));
    const courseName = SATSET_DATA.courses.find((c) => c.id === courseId)?.name || courseId;
    setAuditLog((l) => [
      { id: 'A' + Date.now(), type: 'fire',
        title: `Kirim ${courseName} untuk Meja ${selectedTable}`,
        tableId: selectedTable, when: nowStamp(), reason: null, approvedBy: null },
      ...l,
    ]);
  }, [selectedTable]);

  const markServed = useCallback((ticketId) => {
    if (!selectedTable) return;
    let servedTicket = null;
    setTicketsByTable((m) => ({
      ...m,
      [selectedTable]: m[selectedTable].map((it) => {
        if (it.id === ticketId) {
          servedTicket = it;
          return { ...it, status: 'served' };
        }
        return it;
      }),
    }));
    // Update the table's ready count
    setTables((ts) => ts.map((tt) => {
      if (tt.id !== selectedTable) return tt;
      const remaining = (tt.readyCount || 1) - 1;
      if (remaining <= 0) {
        return { ...tt, status: 'occupied', readyCount: 0 };
      }
      return { ...tt, readyCount: remaining };
    }));
  }, [selectedTable]);

  // ── Action sheet flow (modify / void / serve) ─────────────────────
  const openTicketAction = useCallback((ticket) => {
    setActionFlow({ ticket: { ...ticket, tableId: selectedTable }, step: 'actions' });
  }, [selectedTable]);

  const pickAction = useCallback((actionId) => {
    setActionFlow((f) => {
      if (!f) return f;
      if (actionId === 'void') return { ...f, step: 'void-reason' };
      if (actionId === 'fire') {
        fireCourse(f.ticket.course);
        return null;
      }
      if (actionId === 'serve') {
        markServed(f.ticket.id);
        return null;
      }
      if (actionId === 'modify' || actionId === 'request-modify') {
        // Demo: catat entri modify, tutup. (Full edit flow belum dibangun.)
        setAuditLog((l) => [
          { id: 'A' + Date.now(), type: 'modify',
            title: `Ubah ×${f.ticket.qty} ${f.ticket.name}`,
            tableId: f.ticket.tableId, when: nowStamp(),
            reason: actionId === 'request-modify' ? 'Menunggu konfirmasi station' : 'Edit sebelum prep',
            approvedBy: null },
          ...l,
        ]);
        return null;
      }
      if (actionId === 'unserve') {
        setTicketsByTable((m) => ({
          ...m,
          [f.ticket.tableId]: m[f.ticket.tableId].map((it) =>
            it.id === f.ticket.id ? { ...it, status: 'ready' } : it
          ),
        }));
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
      // Mark ticket as voided
      setTicketsByTable((m) => ({
        ...m,
        [f.ticket.tableId]: m[f.ticket.tableId].map((it) =>
          it.id === f.ticket.id
            ? { ...it, status: 'voided', voidReason: f.reason.label, voidApprovedBy: approval.approver }
            : it
        ),
      }));
      setAuditLog((l) => [
        { id: 'A' + Date.now(), type: 'void',
          title: `Batal ×${f.ticket.qty} ${f.ticket.name} (Rp ${f.ticket.price.toLocaleString('id-ID')})`,
          tableId: f.ticket.tableId, when: nowStamp(),
          reason: f.reason.label + (f.reason.text ? ' — "' + f.reason.text + '"' : ''),
          approvedBy: approval.approver },
        ...l,
      ]);
      return { ...f, step: 'confirmed' };
    });
  }, []);

  const completeFlow = useCallback(() => setActionFlow(null), []);
  const closeFlow = useCallback(() => setActionFlow(null), []);

  // ── Demo: trigger ready alert ─────────────────────────────────────
  const triggerReadyAlert = useCallback(() => {
    setReadyAlert({
      tableId: 'T2',
      zone: 'Teras',
      what: 'Tempe Sambal Bowl + Mie Goreng',
    });
  }, []);

  // ── Cycle screens for demo ────────────────────────────────────────
  const dismissAlert = () => setReadyAlert(null);
  const viewAlert = (alert) => {
    setReadyAlert(null);
    setSelectedTable(alert.tableId);
    setRoute({ screen: 'tableDetail' });
  };

  // ── Current screen content ────────────────────────────────────────
  const selTable = tables.find((tt) => tt.id === selectedTable) || tables[0];
  const selTickets = (selectedTable && ticketsByTable[selectedTable]) || [];

  const sync = t.syncMode === 'offline' ? 'offline' : 'connected';

  function renderScreen() {
    if (!signedIn) return <PinScreen onSignedIn={() => setSignedIn(true)} />;

    // Orders / Me / etc. live on their own tabs
    if (activeTab === 'orders') {
      return (
        <>
          <OrdersScreen
            ticketsByTable={ticketsByTable}
            tables={tables}
            onOpenTable={(id) => { setActiveTab('tables'); setSelectedTable(id); setRoute({ screen: 'tableDetail' }); }}
            onOpenTicket={() => {}}
          />
          <TabBar active={activeTab} onChange={changeTab} readyCount={totalReadyCount} />
        </>
      );
    }
    if (activeTab === 'me') {
      return (
        <>
          <MeScreen
            tables={tables}
            ticketsByTable={ticketsByTable}
            auditLog={auditLog}
            onEndShift={() => { setSignedIn(false); setRoute({ screen: 'tables' }); setActiveTab('tables'); }}
          />
          <TabBar active={activeTab} onChange={changeTab} readyCount={totalReadyCount} />
        </>
      );
    }

    // Tables tab — inner state machine
    switch (route.screen) {
      case 'tables':
        return (
          <>
            <TopBar activeZone={activeZone} onSwitchZone={() => {}} sync={sync} />
            <TablesScreen
              activeZone={activeZone}
              onZoneChange={setActiveZone}
              onSelectTable={(id) => goTable(id)}
              tables={tables}
            />
            <TabBar
              active={activeTab}
              onChange={changeTab}
              readyCount={totalReadyCount}
            />
          </>
        );

      case 'tableDetail':
        return (
          <TableDetailScreen
            tableId={selectedTable}
            table={selTable}
            tickets={selTickets}
            onAdd={openAddMenu}
            onBack={() => setRoute({ screen: 'tables' })}
            onMarkServed={markServed}
            onFireCourse={fireCourse}
            onTicketTap={openTicketAction}
          />
        );

      case 'menu':
        return (
          <>
            <MenuScreen
              tableId={selectedTable}
              table={selTable}
              cart={cart}
              onOpenItem={openItem}
              onReview={() => setRoute({ screen: 'review' })}
              onBack={() => setRoute({ screen: 'tableDetail' })}
            />
            {modifierItem && (
              <ModifierSheet
                item={modifierItem}
                onAdd={addToCart}
                onClose={() => setModifierItem(null)}
              />
            )}
          </>
        );

      case 'review':
        return (
          <ReviewScreen
            tableId={selectedTable}
            table={selTable}
            cart={cart}
            onRemove={removeFromCart}
            onEdit={() => {}}
            onSend={sendOrder}
            onBack={() => setRoute({ screen: 'menu' })}
          />
        );

      case 'sent':
        return (
          <SentScreen
            stations={route.stations || ['Kitchen']}
            tableId={selectedTable}
            latency={120 + Math.floor(Math.random() * 180)}
            onDone={() => setRoute({ screen: 'tableDetail' })}
          />
        );

      default:
        return null;
    }
  }

  function changeTab(tab) {
    setActiveTab(tab);
    if (tab === 'tables' && (route.screen === 'menu' || route.screen === 'review' || route.screen === 'sent')) {
      // mid-flow tab change — keep them in their flow
      return;
    }
    if (tab === 'tables') setRoute({ screen: 'tables' });
  }

  // ── Scale the device to fit the viewport ──────────────────────────
  const stageRef = useRef(null);
  const [scale, setScale] = useState(1);
  useEffect(() => {
    function recompute() {
      const w = window.innerWidth;
      const h = window.innerHeight;
      const dw = 402, dh = 874;
      const s = Math.min((w - 24) / dw, (h - 24) / dh, 1);
      setScale(s);
    }
    recompute();
    window.addEventListener('resize', recompute);
    return () => window.removeEventListener('resize', recompute);
  }, []);

  // The frame uses dark mode chrome; in light mode we still want dark device exterior
  const deviceDark = true;

  return (
    <div className="stage" ref={stageRef}>
      <div style={{ transform: `scale(${scale})`, transformOrigin: 'center center' }}>
        {t.showFrame ? (
          <IOSDevice width={402} height={874} dark={deviceDark}>
            <div className={'app ' + (t.density === 'compact' ? 'compact' : '')}>
              {renderScreen()}
              {actionFlow && (
                <LineItemActionSheet
                  ticket={actionFlow.ticket}
                  table={selTable}
                  step={actionFlow.step}
                  onClose={closeFlow}
                  onPick={pickAction}
                  onVoidReason={pickVoidReason}
                  onApprove={approveVoid}
                  onComplete={completeFlow}
                />
              )}
              {readyAlert && (
                <ReadyToast
                  alert={readyAlert}
                  onView={viewAlert}
                  onDismiss={dismissAlert}
                />
              )}
            </div>
          </IOSDevice>
        ) : (
          <div style={{ width: 402, height: 874, borderRadius: 24, overflow: 'hidden', position: 'relative', background: 'var(--bg-0)', boxShadow: '0 30px 60px rgba(0,0,0,0.4)' }}>
            <div className={'app ' + (t.density === 'compact' ? 'compact' : '')}>
              {renderScreen()}
              {actionFlow && (
                <LineItemActionSheet
                  ticket={actionFlow.ticket}
                  table={selTable}
                  step={actionFlow.step}
                  onClose={closeFlow}
                  onPick={pickAction}
                  onVoidReason={pickVoidReason}
                  onApprove={approveVoid}
                  onComplete={completeFlow}
                />
              )}
              {readyAlert && (
                <ReadyToast
                  alert={readyAlert}
                  onView={viewAlert}
                  onDismiss={dismissAlert}
                />
              )}
            </div>
          </div>
        )}
      </div>

      <TweaksPanel>
        <TweakSection label="Tema">
          <TweakRadio
            label="Mode"
            value={t.theme}
            onChange={(v) => setTweak('theme', v)}
            options={[
              { value: 'dark',  label: 'Gelap' },
              { value: 'light', label: 'Terang' },
            ]}
          />
          <TweakRadio
            label="Kerapatan"
            value={t.density}
            onChange={(v) => setTweak('density', v)}
            options={[
              { value: 'comfy',   label: 'Lega' },
              { value: 'compact', label: 'Padat' },
            ]}
          />
          <TweakToggle
            label="Frame iPhone"
            value={t.showFrame}
            onChange={(v) => setTweak('showFrame', v)}
          />
        </TweakSection>

        <TweakSection label="Status sistem">
          <TweakRadio
            label="Konektivitas"
            value={t.syncMode}
            onChange={(v) => setTweak('syncMode', v)}
            options={[
              { value: 'live',    label: 'LAN + Cloud' },
              { value: 'offline', label: 'Hanya LAN' },
            ]}
          />
        </TweakSection>

        <TweakSection label="Demo alur">
          <div style={{ fontSize: 11, opacity: 0.7, marginBottom: 8, lineHeight: 1.45 }}>
            Lompat ke layar tertentu, atau picu alert “siap di pass” seperti saat dapur baru menekan tombol siap.
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 6 }}>
            <TweakButton label="Login PIN" onClick={() => { setSignedIn(false); setRoute({ screen: 'tables' }); }} />
            <TweakButton label="Meja" onClick={() => { setSignedIn(true); setRoute({ screen: 'tables' }); }} />
            <TweakButton label="Detail meja (T1)" onClick={() => { setSignedIn(true); setSelectedTable('T1'); setRoute({ screen: 'tableDetail' }); }} />
            <TweakButton label="Menu / tambah" onClick={() => { setSignedIn(true); setSelectedTable('T1'); setRoute({ screen: 'menu' }); }} />
            <TweakButton label="Opsi item" onClick={() => {
              const item = SATSET_DATA.items.find((i) => i.id === 'nasi-goreng');
              setSignedIn(true); setSelectedTable('T1'); setRoute({ screen: 'menu' });
              setModifierItem(item);
            }} />
            <TweakButton label="Review (terisi)" onClick={() => {
              setSignedIn(true);
              setSelectedTable('T1');
              setCart([
                { id: 'D1', itemId: 'rendang', name: 'Rendang Sapi', station: 'kitchen', variantName: '',
                  modifiers: ['Nasi putih'], modifierIds: {}, special: '', course: 'mains', qty: 1,
                  unitPrice: 145000, allergens: ['nut'] },
                { id: 'D2', itemId: 'nasi-goreng', name: 'Nasi Goreng', station: 'kitchen', variantName: 'Reguler',
                  modifiers: ['Udang', 'Sedang', '+ Krupuk'], modifierIds: {}, special: '', course: 'mains', qty: 1,
                  unitPrice: 113000, allergens: ['shellfish', 'egg', 'gluten'] },
                { id: 'D3', itemId: 'margarita', name: 'Margarita Pedas', station: 'bar', variantName: '',
                  modifiers: [], modifierIds: {}, special: '', course: 'drinks-now', qty: 2,
                  unitPrice: 110000, allergens: [] },
                { id: 'D4', itemId: 'pisang', name: 'Pisang Goreng', station: 'kitchen', variantName: '',
                  modifiers: ['Vanila'], modifierIds: {}, special: '', course: 'desserts', qty: 1,
                  unitPrice: 55000, allergens: ['gluten', 'dairy', 'egg'] },
              ]);
              setRoute({ screen: 'review' });
            }} />
            <TweakButton label="Konfirmasi kirim" onClick={() => { setSignedIn(true); setSelectedTable('T1'); setRoute({ screen: 'sent', stations: ['Dapur', 'Bar'] }); }} />
            <TweakButton label="Alert siap" onClick={triggerReadyAlert} />
            <TweakButton label="Tab Pesanan" onClick={() => { setSignedIn(true); setActiveTab('orders'); }} />
            <TweakButton label="Tab Saya" onClick={() => { setSignedIn(true); setActiveTab('me'); }} />
            <TweakButton label="Alur pembatalan" onClick={() => {
              setSignedIn(true);
              setSelectedTable('T1');
              setRoute({ screen: 'tableDetail' });
              const t = ticketsByTable['T1'].find((tt) => tt.status === 'prep');
              if (t) setActionFlow({ ticket: { ...t, tableId: 'T1' }, step: 'actions' });
            }} />
            <TweakButton label="PIN manajer" onClick={() => {
              setSignedIn(true);
              setSelectedTable('T1');
              setRoute({ screen: 'tableDetail' });
              const t = ticketsByTable['T1'].find((tt) => tt.status === 'prep');
              if (t) setActionFlow({
                ticket: { ...t, tableId: 'T1' },
                step: 'manager-pin',
                reason: { id: 'allergy', label: 'Alergi / diet', text: null },
              });
            }} />
          </div>
        </TweakSection>
      </TweaksPanel>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App/>);

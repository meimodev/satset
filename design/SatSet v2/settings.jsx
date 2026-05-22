// SatSet — Settings / Server & configuration screen.
/* global React, Icons */

function SettingsScreen({ sync = 'live', onToggleSync }) {
  const offline = sync === 'offline';

  return (
    <div className="set-wrap">
      <div className="set-head">
        <div>
          <div style={{ fontSize: 22, fontWeight: 600, letterSpacing: '-0.015em' }}>Sistem · server & konfigurasi</div>
          <div style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--text-lo)', letterSpacing: '0.06em', textTransform: 'uppercase', marginTop: 6 }}>
            WARUNG SEBELAH · BERAWA, BALI · v2.0.0
          </div>
        </div>
        <div style={{ marginLeft: 'auto', display: 'flex', gap: 10 }}>
          <button className="set-btn">Pair device baru</button>
          <button className="set-btn">Failover ke spare tablet</button>
        </div>
      </div>

      <div className="set-grid">
        {/* Server health hero */}
        <div className={'set-hero ' + (offline ? 'warn' : 'ok')}>
          <div className="lbl">SERVER · LOCAL</div>
          <div className="v">{offline ? 'CLOUD PAUSED' : 'ALL SYSTEMS NORMAL'}</div>
          <div className="d">
            {offline
              ? 'Internet down — operasi lokal jalan normal. Antrian cloud sedang menunggu.'
              : 'LAN OK · 6 client paired · cloud sync delay 12 s · uptime 14 j 12 m'}
          </div>
          <div className="meter">
            {[1,2,3,4,5,6,7,8,9,10,11,12].map(i => <span key={i} className={offline && i > 8 ? 'idle' : ''}></span>)}
          </div>
          <div className="meter-l">LATENCY · 5 MIN · P50 124 MS · P95 312 MS</div>
        </div>

        {/* KPI tiles */}
        <div className="set-tile">
          <div className="set-tile-h"><span>Connected clients</span><Icons.Wifi size={16} stroke="var(--text-lo)"/></div>
          <div className="set-tile-v">6 / 8</div>
          <div className="set-tile-d">3 HP pelayan · 2 expo · 1 manajer</div>
        </div>

        <div className="set-tile">
          <div className="set-tile-h"><span>Cloud sync</span><Icons.Sparkle size={16} stroke="var(--text-lo)"/></div>
          <div className="set-tile-v" style={{ color: offline ? 'var(--warn)' : 'var(--success)' }}>{offline ? 'PAUSED' : 'SYNCED'}</div>
          <div className="set-tile-d">{offline ? '142 events queued · resume saat internet kembali' : '142 events · push tiap 10 s'}</div>
        </div>

        <div className="set-tile">
          <div className="set-tile-h"><span>Battery · KDS tablet</span></div>
          <div className="set-tile-v">98%</div>
          <div className="set-tile-d">Charging · dock OK · health 96%</div>
        </div>

        <div className="set-tile">
          <div className="set-tile-h"><span>Storage</span></div>
          <div className="set-tile-v">8.6%</div>
          <div className="set-tile-d">5.2 GB / 64 GB · audit log retain 90 hari</div>
        </div>

        <div className="set-tile">
          <div className="set-tile-h"><span>Uptime</span></div>
          <div className="set-tile-v">14j 12m</div>
          <div className="set-tile-d">Restart terakhir · Sab 04:02 (jadwal)</div>
        </div>

        <div className="set-tile">
          <div className="set-tile-h"><span>Last cloud push</span></div>
          <div className="set-tile-v">12 d</div>
          <div className="set-tile-d">184 ms · OK · 142 events delivered</div>
        </div>
      </div>

      {/* Two-column section grid */}
      <div className="set-cols">

        <div className="set-card">
          <div className="set-card-h">
            Koneksi & jaringan
            <span className="set-card-sub">VENUE LAN · WIFI</span>
          </div>
          <SetRow label="Server" value="192.168.4.21:8443" mono />
          <SetRow label="WiFi SSID" value="WarungSebelah-OPS · 5 GHz" mono />
          <SetRow label="Signal saat ini" value="−54 dBm · sangat baik" mono />
          <SetRow label="Cabang WiFi" value="3 access point · semua zona terjangkau" />
          <SetRow label="Internet uplink" value={offline ? '— · putus, retry tiap 30 s' : 'Telkomsel · 24 Mbps'} mono />
          <div className="set-row" style={{ borderBottom: 0 }}>
            <div className="lbl">Mode konektivitas</div>
            <div style={{ display: 'flex', gap: 8, marginLeft: 'auto' }}>
              <button className={'set-pill ' + (!offline ? 'on' : '')} onClick={onToggleSync}>LAN + Cloud</button>
              <button className={'set-pill ' + (offline ? 'on' : '')} onClick={onToggleSync}>Hanya LAN</button>
            </div>
          </div>
        </div>

        <div className="set-card">
          <div className="set-card-h">
            Keamanan & sertifikat
            <span className="set-card-sub">TLS · PAIRING</span>
          </div>
          <SetRow label="TLS sertifikat" value="self-signed · ECDSA P-256" mono />
          <SetRow label="Cert fingerprint" value="5F 3A C2 9D 71 88 04 EB" mono />
          <SetRow label="Kadaluarsa" value="2026-11-08 · 168 hari lagi" />
          <SetRow label="Devices paired" value="6 aktif · 4 revoked sejak setup" />
          <div className="set-row" style={{ borderBottom: 0 }}>
            <div className="lbl">Aksi</div>
            <div style={{ display: 'flex', gap: 8, marginLeft: 'auto' }}>
              <button className="set-pill">Tampilkan QR pair</button>
              <button className="set-pill danger">Regenerate cert</button>
            </div>
          </div>
        </div>

        <div className="set-card">
          <div className="set-card-h">
            Backup & recovery
            <span className="set-card-sub">FAILOVER · CLOUD</span>
          </div>
          <SetRow label="Spare tablet" value="terdeteksi · ::5d3a · battery 88%" />
          <SetRow label="Local backup storage" value="USB · 32 GB · 2.8 GB used" />
          <SetRow label="Cloud backup terakhir" value="12 detik lalu · sukses" mono />
          <SetRow label="Recovery target" value="5–15 menit manual (V1) · auto V1.1" />
          <div className="set-row" style={{ borderBottom: 0 }}>
            <div className="lbl">Aksi</div>
            <div style={{ display: 'flex', gap: 8, marginLeft: 'auto' }}>
              <button className="set-pill">Test restore</button>
              <button className="set-pill danger">Failover sekarang</button>
            </div>
          </div>
        </div>

        <div className="set-card">
          <div className="set-card-h">
            Tampilan & perilaku
            <span className="set-card-sub">DISPLAY · SLEEP</span>
          </div>
          <SetRow label="Display always-on" value="aktif · server tablet locked-on" right={<span className="set-toggle on"></span>} />
          <SetRow label="Doze mode" value="dinonaktifkan (background service jalan)" right={<span className="set-toggle on"></span>} />
          <SetRow label="Auto-fire drinks-now" value="aktif · langsung kirim ke bar" right={<span className="set-toggle on"></span>} />
          <SetRow label="Audio alerts" value="dapur 80% · pelayan getar + nada" right={<span className="set-toggle on"></span>} />
          <SetRow label="Tema" value="dark · primary · light tersedia" right={<span className="set-toggle"></span>} />
          <SetRow label="Density" value="comfortable" right={<button className="set-pill">comfortable ⌄</button>} />
        </div>

        <div className="set-card">
          <div className="set-card-h">
            Stasiun & routing
            <span className="set-card-sub">KITCHEN · BAR · CUSTOM</span>
          </div>
          <SetRow label="Dapur · Utama" value="aktif · prep target 9:00 · refire dari Budi" />
          <SetRow label="Dapur · Pembuka" value="aktif · prep target 5:00" />
          <SetRow label="Dapur · Penutup" value="aktif · prep target 6:00" />
          <SetRow label="Bar · Cocktail" value="aktif · prep target 4:00" />
          <SetRow label="Bar · Soft" value="aktif · prep target 1:30" />
          <SetRow label="Expo · pass" value="aktif · venues &gt; 80 covers (Wira)" />
          <div className="set-row" style={{ borderBottom: 0 }}>
            <div className="lbl">Aksi</div>
            <div style={{ display: 'flex', gap: 8, marginLeft: 'auto' }}>
              <button className="set-pill">Edit station</button>
              <button className="set-pill">+ Station baru</button>
            </div>
          </div>
        </div>

        <div className="set-card">
          <div className="set-card-h">
            Printer & add-ons
            <span className="set-card-sub">OPSIONAL · OPT-IN</span>
          </div>
          <SetRow label="Printer · dapur" value="—  ·  belum di-pair" right={<button className="set-pill">+ Pair</button>} />
          <SetRow label="Printer · bar" value="—  ·  belum di-pair" right={<button className="set-pill">+ Pair</button>} />
          <SetRow label="Cetak struk otomatis" value="dimatikan · cetak manual dari order detail" right={<span className="set-toggle"></span>} />
          <SetRow label="POS handoff" value="external · pembayaran di luar SatSet" />
        </div>

        <div className="set-card">
          <div className="set-card-h">
            Permissions & PIN
            <span className="set-card-sub">ROLES · AUDIT</span>
          </div>
          <SetRow label="Owner PINs" value="2 aktif · komang, dewi" />
          <SetRow label="Manager PINs" value="2 aktif · sari, koko · void approve" />
          <SetRow label="Floor supervisor" value="1 aktif · made · comp ≤ Rp 50.000" />
          <SetRow label="Waiter PINs" value="6 aktif · shift expiry otomatis" />
          <SetRow label="Audit log retention" value="90 hari di-server · selamanya di cloud" />
        </div>

        <div className="set-card">
          <div className="set-card-h">
            Hardware
            <span className="set-card-sub">KDS · CLIENTS · ROUTER</span>
          </div>
          <SetRow label="Server tablet" value="Lenovo M10 · 8″ · Android 13 · 4 GB / 64 GB" />
          <SetRow label="Case" value="IP54 splash-resistant · wall-mounted" />
          <SetRow label="Dock & charging" value="OK · cable management bersih" />
          <SetRow label="Spare tablet" value="identical · disimpan di office, charging" />
          <SetRow label="Router" value="Asus RT-AX55 · dual-band · venue-owned" />
          <SetRow label="Replacement reminder" value="Jul 2026 · 24-bulan cadence" />
        </div>

      </div>

      <div className="set-foot">
        <div>
          <div style={{ fontFamily: 'var(--font-mono)', fontSize: 10, color: 'var(--text-lo)', letterSpacing: '0.12em', textTransform: 'uppercase', fontWeight: 600 }}>HEALTH ALERTS</div>
          <div style={{ fontSize: 13, color: 'var(--text-md)', marginTop: 4 }}>Tidak ada peringatan aktif · sistem berjalan normal sejak 04:02.</div>
        </div>
        <div style={{ display: 'flex', gap: 10, marginLeft: 'auto' }}>
          <button className="set-btn">Lihat audit log</button>
          <button className="set-btn">Download diagnostic bundle</button>
        </div>
      </div>
    </div>
  );
}

function SetRow({ label, value, mono, right }) {
  return (
    <div className="set-row">
      <div className="lbl">{label}</div>
      <div className={'val ' + (mono ? 'mono' : '')}>{value}</div>
      {right}
    </div>
  );
}

window.SettingsScreen = SettingsScreen;

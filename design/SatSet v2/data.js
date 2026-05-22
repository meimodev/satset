// SatSet — sample data for the prototype. Indonesian + Western fusion bistro.

window.formatIDR = function (n) {
  if (!n && n !== 0) return '';
  return 'Rp ' + n.toLocaleString('id-ID');
};

window.SATSET_DATA = {
  venue: {
    name: 'Warung Sebelah',
    address: 'Berawa, Bali',
    cover: 120,
  },

  user: {
    id: 'maya',
    name: 'Maya',
    initials: 'MA',
    role: 'Pelayan',
    shiftStartedAt: '17:30',
    zoneAssigned: 'Teras',
  },

  zones: [
    { id: 'terrace', name: 'Teras',  short: 'Ter' },
    { id: 'garden',  name: 'Taman',  short: 'Tam' },
    { id: 'indoor',  name: 'Dalam',  short: 'Dlm' },
    { id: 'bar',     name: 'Bar',    short: 'Bar' },
  ],

  tables: [
    // Terrace
    { id: 'T1',  zone: 'terrace', pax: 2, status: 'occupied',     elapsed: '0:18', mine: true,  open: 245000 },
    { id: 'T2',  zone: 'terrace', pax: 4, status: 'ready',        elapsed: '0:42', mine: true,  open: 612000, readyCount: 2 },
    { id: 'T3',  zone: 'terrace', pax: 2, status: 'available' },
    { id: 'T4',  zone: 'terrace', pax: 6, status: 'pending',      elapsed: '0:08', mine: true,  open: 0 },
    { id: 'T5',  zone: 'terrace', pax: 3, status: 'occupied',     elapsed: '1:14',             open: 880000 },
    { id: 'T6',  zone: 'terrace', pax: 2, status: 'available' },

    // Garden
    { id: 'G1',  zone: 'garden',  pax: 4, status: 'occupied',     elapsed: '0:32',             open: 425000 },
    { id: 'G2',  zone: 'garden',  pax: 2, status: 'available' },
    { id: 'G3',  zone: 'garden',  pax: 5, status: 'occupied',     elapsed: '0:54',             open: 690000 },
    { id: 'G4',  zone: 'garden',  pax: 2, status: 'ready',        elapsed: '0:21',             open: 180000, readyCount: 1 },

    // Indoor
    { id: 'I1',  zone: 'indoor',  pax: 2, status: 'available' },
    { id: 'I2',  zone: 'indoor',  pax: 4, status: 'occupied',     elapsed: '0:46',             open: 535000 },
    { id: 'I3',  zone: 'indoor',  pax: 2, status: 'pending',      elapsed: '0:03',             open: 0 },
    { id: 'I4',  zone: 'indoor',  pax: 4, status: 'occupied',     elapsed: '1:32',             open: 1120000 },
    { id: 'I5',  zone: 'indoor',  pax: 6, status: 'available' },
    { id: 'I6',  zone: 'indoor',  pax: 2, status: 'occupied',     elapsed: '0:12',             open: 95000 },

    // Bar
    { id: 'B1',  zone: 'bar',     pax: 2, status: 'occupied',     elapsed: '0:24',             open: 145000 },
    { id: 'B2',  zone: 'bar',     pax: 1, status: 'available' },
    { id: 'B3',  zone: 'bar',     pax: 3, status: 'available' },
    { id: 'B4',  zone: 'bar',     pax: 2, status: 'occupied',     elapsed: '0:38',             open: 270000 },
  ],

  categories: [
    { id: 'all',      name: 'Semua' },
    { id: 'starters', name: 'Pembuka' },
    { id: 'mains',    name: 'Utama' },
    { id: 'sides',    name: 'Pendamping' },
    { id: 'desserts', name: 'Penutup' },
    { id: 'cocktails',name: 'Cocktail' },
    { id: 'wine',     name: 'Anggur' },
    { id: 'beer',     name: 'Bir' },
    { id: 'soft',     name: 'Non-alkohol' },
  ],

  courses: [
    { id: 'drinks-now', name: 'Minum dulu',  short: 'Min',    color: '#6db5ff' },
    { id: 'starters',   name: 'Pembuka',     short: 'Pem',    color: '#ffc04d' },
    { id: 'mains',      name: 'Utama',       short: 'Ut',     color: '#4dd487' },
    { id: 'sides',      name: 'Bersama Utama', short: 'B/Ut', color: '#4dd487' },
    { id: 'desserts',   name: 'Penutup',     short: 'Pnp',    color: '#c08aff' },
    { id: 'fire-now',   name: 'Langsung',    short: 'Lgs',    color: '#ff9233' },
  ],

  // Tickets already on the demo tables — T1 active, T2 ready-for-pickup, T4 just sent
  initialTicketsByTable: {
    T1: [
      {
        id: 'L01', itemId: 'gado-gado', name: 'Gado-Gado', course: 'starters',
        variantName: '', station: 'kitchen', qty: 1,
        modifiers: ['Sedikit pedas'], price: 65000,
        status: 'ready', sentAt: '17:42',
      },
      {
        id: 'L02', itemId: 'es-teh', name: 'Es Teh Manis', course: 'drinks-now',
        variantName: '', station: 'bar', qty: 2,
        modifiers: ['Kurang manis'], price: 25000,
        status: 'served', sentAt: '17:42',
      },
      {
        id: 'L03', itemId: 'nasi-goreng', name: 'Nasi Goreng', course: 'mains',
        variantName: 'Reguler', station: 'kitchen', qty: 1,
        modifiers: ['Ayam', 'Sedang', '+ Krupuk'], price: 93000,
        status: 'prep', sentAt: '17:46',
      },
      {
        id: 'L04', itemId: 'rendang', name: 'Rendang Sapi', course: 'mains',
        variantName: '', station: 'kitchen', qty: 1,
        modifiers: ['Tanpa nasi uduk', 'Ganti nasi putih'], price: 145000,
        specialInstructions: 'Tamu alergi kacang — tanpa garnish sate',
        status: 'prep', sentAt: '17:46',
      },
      {
        id: 'L05', itemId: 'pisang', name: 'Pisang Goreng + Es Krim', course: 'desserts',
        variantName: '', station: 'kitchen', qty: 2,
        modifiers: ['Vanila'], price: 55000,
        status: 'held', sentAt: '17:46',
      },
    ],
    T2: [
      {
        id: 'L10', itemId: 'sate-ayam', name: 'Sate Ayam', course: 'starters',
        variantName: '', station: 'kitchen', qty: 2,
        modifiers: [], price: 75000,
        status: 'served', sentAt: '17:21',
      },
      {
        id: 'L11', itemId: 'rose', name: 'Rosé House', course: 'drinks-now',
        variantName: 'Botol', station: 'bar', qty: 1,
        modifiers: [], price: 485000,
        status: 'served', sentAt: '17:22',
      },
      {
        id: 'L12', itemId: 'crispy-tempeh', name: 'Tempe Sambal Bowl', course: 'mains',
        variantName: '', station: 'kitchen', qty: 1,
        modifiers: ['Sambal di pinggir'], price: 95000,
        status: 'ready', sentAt: '17:48',
      },
      {
        id: 'L13', itemId: 'mie-goreng', name: 'Mie Goreng', course: 'mains',
        variantName: '', station: 'kitchen', qty: 1,
        modifiers: [], price: 80000,
        status: 'ready', sentAt: '17:48',
      },
    ],
    T4: [
      {
        id: 'L20', itemId: 'bintang', name: 'Bir Bintang', course: 'drinks-now',
        variantName: '', station: 'bar', qty: 6,
        modifiers: [], price: 45000,
        status: 'sent', sentAt: '18:02',
      },
      {
        id: 'L21', itemId: 'lumpia', name: 'Lumpia Renyah', course: 'starters',
        variantName: '', station: 'kitchen', qty: 2,
        modifiers: [], price: 55000,
        status: 'sent', sentAt: '18:02',
      },
    ],
  },

  items: [
    {
      id: 'gado-gado',
      name: 'Gado-Gado',
      category: 'starters',
      station: 'kitchen',
      description: 'Sayur kukus, tahu, tempe, telur rebus, saus kacang',
      allergens: ['nut', 'soy', 'egg'],
      prepTime: 8,
      basePrice: 65000,
      variants: [{ id: 'reg', name: '', price: 65000 }],
      modifierGroups: [
        {
          id: 'sauce', name: 'Saus kacang', required: true, multi: false,
          options: [
            { id: 'mild',   name: 'Sedikit pedas', price: 0 },
            { id: 'medium', name: 'Sedang',        price: 0 },
            { id: 'spicy',  name: 'Pedas',         price: 0 },
            { id: 'side',   name: 'Saus di pinggir', price: 0 },
          ]
        },
      ],
    },
    {
      id: 'lumpia',
      name: 'Lumpia Renyah (4 buah)',
      category: 'starters',
      station: 'kitchen',
      description: 'Lumpia goreng isi sayur dan ayam, saus cabai manis',
      allergens: ['gluten', 'egg'],
      prepTime: 7,
      basePrice: 55000,
      variants: [{ id: 'reg', name: '', price: 55000 }],
      modifierGroups: [],
    },
    {
      id: 'sate-ayam',
      name: 'Sate Ayam (4 tusuk)',
      category: 'starters',
      station: 'kitchen',
      description: 'Sate ayam bakar, saus kacang, lontong',
      allergens: ['nut', 'soy'],
      prepTime: 10,
      basePrice: 75000,
      variants: [{ id: 'reg', name: '', price: 75000 }],
      modifierGroups: [],
    },
    {
      id: 'nasi-goreng',
      name: 'Nasi Goreng',
      category: 'mains',
      station: 'kitchen',
      description: 'Nasi goreng dengan terasi, bawang goreng, telur, krupuk',
      allergens: ['shellfish', 'egg', 'gluten'],
      prepTime: 12,
      basePrice: 85000,
      variants: [
        { id: 'reg', name: 'Reguler', price: 85000 },
        { id: 'lg',  name: 'Besar',   price: 110000 },
      ],
      modifierGroups: [
        {
          id: 'protein', name: 'Pilih protein', required: true, multi: false,
          options: [
            { id: 'chicken', name: 'Ayam',  price: 0 },
            { id: 'beef',    name: 'Sapi',  price: 15000 },
            { id: 'prawn',   name: 'Udang', price: 20000 },
            { id: 'tofu',    name: 'Tahu',  price: -5000 },
            { id: 'none',    name: 'Tanpa protein', price: -10000 },
          ],
        },
        {
          id: 'spice', name: 'Tingkat pedas', required: true, multi: false,
          options: [
            { id: 'no',  name: 'Tidak pedas',  price: 0 },
            { id: 'mi',  name: 'Sedikit pedas', price: 0 },
            { id: 'md',  name: 'Sedang',       price: 0 },
            { id: 'hot', name: 'Pedas',        price: 0 },
            { id: 'xhot', name: 'Sangat pedas', price: 0 },
          ],
        },
        {
          id: 'extras', name: 'Tambahan', required: false, multi: true,
          options: [
            { id: 'krupuk',  name: 'Krupuk ekstra',    price: 8000 },
            { id: 'satay',   name: 'Sate Ayam (2 tusuk)', price: 25000 },
            { id: 'egg',     name: 'Telur ceplok ekstra', price: 10000 },
            { id: 'sambal',  name: 'Sambal di pinggir',   price: 5000 },
          ],
        },
      ],
    },
    {
      id: 'rendang',
      name: 'Rendang Sapi',
      category: 'mains',
      station: 'kitchen',
      description: 'Sapi rendang Padang, santan, serai, cabai. Dengan nasi uduk.',
      allergens: ['nut'],
      prepTime: 14,
      basePrice: 145000,
      variants: [{ id: 'reg', name: '', price: 145000 }],
      modifierGroups: [
        {
          id: 'rice', name: 'Nasi', required: true, multi: false,
          options: [
            { id: 'coconut',  name: 'Nasi uduk',  price: 0 },
            { id: 'steamed',  name: 'Nasi putih', price: 0 },
            { id: 'no-rice',  name: 'Tanpa nasi', price: -10000 },
          ],
        },
      ],
    },
    {
      id: 'mie-goreng',
      name: 'Mie Goreng',
      category: 'mains',
      station: 'kitchen',
      description: 'Mie telur tumis, sayur, bawang goreng',
      allergens: ['gluten', 'egg', 'soy'],
      prepTime: 10,
      basePrice: 80000,
      variants: [{ id: 'reg', name: '', price: 80000 }],
      modifierGroups: [],
    },
    {
      id: 'burger',
      name: 'Burger Wagyu',
      category: 'mains',
      station: 'kitchen',
      description: 'Daging wagyu, keju, roti brioche, acar rumahan, kentang goreng',
      allergens: ['gluten', 'dairy', 'egg'],
      prepTime: 13,
      basePrice: 165000,
      unavailable: true, // demo: kill-switch aktif
      variants: [{ id: 'reg', name: '', price: 165000 }],
      modifierGroups: [],
    },
    {
      id: 'crispy-tempeh',
      name: 'Tempe Sambal Bowl',
      category: 'mains',
      station: 'kitchen',
      description: 'Tempe sambal, nasi uduk, sayur acar, telur ceplok',
      allergens: ['soy', 'egg', 'gluten'],
      prepTime: 11,
      basePrice: 95000,
      variants: [{ id: 'reg', name: '', price: 95000 }],
      modifierGroups: [],
    },
    {
      id: 'krupuk-side',
      name: 'Krupuk',
      category: 'sides',
      station: 'kitchen',
      description: 'Krupuk udang',
      allergens: ['shellfish'],
      prepTime: 2,
      basePrice: 15000,
      variants: [{ id: 'reg', name: '', price: 15000 }],
      modifierGroups: [],
    },
    {
      id: 'pisang',
      name: 'Pisang Goreng',
      category: 'desserts',
      station: 'kitchen',
      description: 'Pisang goreng, saus gula merah, es krim vanila',
      allergens: ['gluten', 'dairy', 'egg'],
      prepTime: 8,
      basePrice: 55000,
      variants: [{ id: 'reg', name: '', price: 55000 }],
      modifierGroups: [
        {
          id: 'ic', name: 'Es krim', required: true, multi: false,
          options: [
            { id: 'vanilla', name: 'Vanila', price: 0 },
            { id: 'coconut', name: 'Kelapa', price: 0 },
            { id: 'none',    name: 'Tanpa es krim', price: -10000 },
          ],
        },
      ],
    },
    {
      id: 'es-teh',
      name: 'Es Teh Manis',
      category: 'soft',
      station: 'bar',
      description: 'Es teh melati manis',
      allergens: [],
      prepTime: 2,
      basePrice: 25000,
      variants: [{ id: 'reg', name: '', price: 25000 }],
      modifierGroups: [
        {
          id: 'sweet', name: 'Tingkat manis', required: false, multi: false,
          options: [
            { id: 'less', name: 'Kurang manis', price: 0 },
            { id: 'norm', name: 'Normal',       price: 0 },
            { id: 'extra', name: 'Ekstra manis', price: 0 },
          ]
        }
      ],
    },
    {
      id: 'bintang',
      name: 'Bir Bintang',
      category: 'beer',
      station: 'bar',
      description: '330 ml. Lager Indonesia paling populer.',
      allergens: ['gluten'],
      prepTime: 1,
      basePrice: 45000,
      variants: [{ id: 'reg', name: '', price: 45000 }],
      modifierGroups: [],
    },
    {
      id: 'margarita',
      name: 'Margarita Pedas',
      category: 'cocktails',
      station: 'bar',
      description: 'Tequila, jeruk nipis, agave, cabai segar, garam asap',
      allergens: [],
      prepTime: 4,
      basePrice: 110000,
      variants: [{ id: 'reg', name: '', price: 110000 }],
      modifierGroups: [],
    },
    {
      id: 'negroni',
      name: 'Negroni',
      category: 'cocktails',
      station: 'bar',
      description: 'Gin, Campari, vermouth manis, kulit jeruk',
      allergens: [],
      prepTime: 4,
      basePrice: 130000,
      variants: [{ id: 'reg', name: '', price: 130000 }],
      modifierGroups: [],
    },
    {
      id: 'rose',
      name: 'Rosé House',
      category: 'wine',
      station: 'bar',
      description: 'Segar, kering, gaya Provence',
      allergens: ['sulfites'],
      prepTime: 1,
      basePrice: 95000,
      variants: [
        { id: 'glass',  name: 'Gelas',   price: 95000 },
        { id: 'bottle', name: 'Botol',   price: 485000 },
      ],
      modifierGroups: [],
    },
    {
      id: 'kombucha',
      name: 'Kombucha Rumahan',
      category: 'soft',
      station: 'bar',
      description: 'Jahe-jeruk nipis, fermentasi sendiri',
      allergens: [],
      prepTime: 1,
      basePrice: 38000,
      variants: [{ id: 'reg', name: '', price: 38000 }],
      modifierGroups: [],
    },
  ],
};

// Allergen short codes for the chip in item cards
window.ALLERGEN_CODES = {
  gluten:    'GL',
  nut:       'NU',
  dairy:     'DA',
  shellfish: 'SH',
  egg:       'EG',
  soy:       'SO',
  sesame:    'SE',
  sulfites:  'SU',
};

window.ALLERGEN_NAMES = {
  gluten:    'Gluten',
  nut:       'Kacang',
  dairy:     'Susu',
  shellfish: 'Kerang',
  egg:       'Telur',
  soy:       'Kedelai',
  sesame:    'Wijen',
  sulfites:  'Sulfit',
};

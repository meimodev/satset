// Inline SVG icons for SatSet. Stroked, 1.6 weight, 20×20 by default.

const I = ({ children, size = 20, stroke = 'currentColor', sw = 1.6, fill = 'none' }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill={fill} stroke={stroke} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round">
    {children}
  </svg>
);

const Icons = {
  Tables: (p) => (<I {...p}><rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/></I>),
  Orders: (p) => (<I {...p}><path d="M4 4h12l4 4v12H4z"/><path d="M16 4v4h4"/><path d="M8 13h8M8 17h5"/></I>),
  Menu:   (p) => (<I {...p}><path d="M4 7h16M4 12h16M4 17h10"/></I>),
  Me:     (p) => (<I {...p}><circle cx="12" cy="8" r="4"/><path d="M4 20c0-4 3.6-7 8-7s8 3 8 7"/></I>),
  Plus:   (p) => (<I {...p}><path d="M12 5v14M5 12h14"/></I>),
  Minus:  (p) => (<I {...p}><path d="M5 12h14"/></I>),
  Chev:   (p) => (<I {...p}><path d="M9 6l6 6-6 6"/></I>),
  ChevDn: (p) => (<I {...p}><path d="M6 9l6 6 6-6"/></I>),
  Check:  (p) => (<I {...p}><path d="M5 12.5l4.5 4.5L19 7.5"/></I>),
  Close:  (p) => (<I {...p}><path d="M6 6l12 12M18 6L6 18"/></I>),
  Back:   (p) => (<I {...p}><path d="M15 6l-6 6 6 6"/></I>),
  Bell:   (p) => (<I {...p}><path d="M6 16V11a6 6 0 0 1 12 0v5l2 2H4z"/><path d="M10 20a2 2 0 0 0 4 0"/></I>),
  Bag:    (p) => (<I {...p}><path d="M5 8h14l-1 12H6z"/><path d="M9 8V6a3 3 0 0 1 6 0v2"/></I>),
  Search: (p) => (<I {...p}><circle cx="11" cy="11" r="6.5"/><path d="M20 20l-3.5-3.5"/></I>),
  Wifi:   (p) => (<I {...p}><path d="M2 9a16 16 0 0 1 20 0"/><path d="M5.5 12.5a11 11 0 0 1 13 0"/><path d="M9 16a6 6 0 0 1 6 0"/><circle cx="12" cy="19.5" r="0.5" fill="currentColor"/></I>),
  Fire:   (p) => (<I {...p}><path d="M12 3c2 4 5 5 5 9a5 5 0 0 1-10 0c0-2 1-3 2-4 0 2 1 3 2 3 0-3-1-5 1-8z"/></I>),
  Clock:  (p) => (<I {...p}><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></I>),
  Alert:  (p) => (<I {...p}><path d="M12 3l10 17H2z"/><path d="M12 10v5M12 17.5v.01"/></I>),
  Sparkle:(p) => (<I {...p}><path d="M12 4l1.5 5L19 11l-5.5 1.5L12 18l-1.5-5.5L5 11l5.5-1.5z"/></I>),
  Edit:   (p) => (<I {...p}><path d="M4 20l4-1 11-11-3-3L5 16z"/></I>),
  Trash:  (p) => (<I {...p}><path d="M4 7h16M9 7V5a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2M6 7l1 13a2 2 0 0 0 2 2h6a2 2 0 0 0 2-2l1-13"/></I>),
  Pin:    (p) => (<I {...p}><path d="M12 21l-5-7a6 6 0 1 1 10 0z"/><circle cx="12" cy="10" r="2"/></I>),
};

window.Icons = Icons;

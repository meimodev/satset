/// Developer WhatsApp, E.164 without the `+`, for a `wa.me` link.
///
/// Baked into the app because this button is pressed exactly when the device is
/// unpaired or offline — a number that has to be fetched over the network is no
/// use at that moment. See ADR-0059.
///
/// Deliberately **not** an ARB entry: a phone number is configuration, not copy,
/// and a translator has no business editing it.
const String devWhatsApp = '6289525699078';

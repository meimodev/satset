import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:satset/data/repositories/auth_repository.dart';
import 'package:satset/data/repositories/venue_subscription.dart';
import 'package:satset/domain/models/capability.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/core/design/format.dart';
import 'package:satset/ui/core/design/skin.dart';
import 'package:satset/ui/core/design/spacing.dart';
import 'package:satset/ui/core/design/typography.dart';
import 'package:satset/core/localization/locale_view_model.dart';
import 'package:satset/core/localization/dev_contact.dart';

/// Shell-level notice that this venue's subscription is ending or has lapsed.
/// Sits beside [AdminGraceBanner] and borrows its shape deliberately — same
/// slot, same warn→urgent escalation, same "renders nothing when fine".
///
/// **Gated on [Capability.editSettings], which the grace banner is not.** The
/// grace banner tells anyone holding the host tablet to reconnect the wifi, and
/// anyone can do that. This one is commercial: "the restaurant has not paid"
/// read by a waiter mid-shift is a different message than the same words read by
/// the person who pays the bill, and only one of them can act on it.
///
/// **It names the day service stops.** ADR-0074 forbade that, on the grounds
/// that nothing auto-suspended and so the threat would have been a lie. ADR-0076
/// made it true — the cutoff sweep suspends a lapsed trial on its end date and a
/// lapsed partner seven days after — so the banner states the date as a fact.
/// The alternative is a venue that finds out by hitting it mid-service.
class VenueBillingBanner extends ConsumerWidget {
  const VenueBillingBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notice = ref.watch(venueBillingNoticeProvider);
    if (notice == null) return const SizedBox.shrink();
    if (!ref.watch(authStateProvider).has(Capability.editSettings)) {
      return const SizedBox.shrink();
    }

    final sc = context.sat;
    final lapsed = notice.tier == VenueBillingTier.lapsed;
    final fg = lapsed ? sc.urgent : sc.warn;
    final bg = lapsed ? sc.urgentSoft : sc.warnSoft;
    final head = lapsed
        ? context.l10n.billingLapsed
        : context.l10n.billingEndsIn(notice.remaining?.inDays ?? 0);
    // The cutoff, when there is one. A term with no end date never lapses, so
    // that banner keeps the old shape — it has no date to promise.
    final line = switch (notice.cutoffAt) {
      final at? =>
        '$head ${context.l10n.billingStopsOn(formatShortDateId(at))}',
      null => head,
    };

    return Semantics(
      button: true,
      label: '$line ${context.l10n.billingCta}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _contact(context, ref),
          borderRadius: SatR.a(12),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(Sp.s3, Sp.s2, Sp.s3, 0),
            padding: const EdgeInsets.symmetric(
              horizontal: Sp.s3,
              vertical: Sp.s2h,
            ),
            decoration: SatBox.d(
              color: bg,
              borderRadius: SatR.a(12),
              border: SatB.all(color: fg.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Icon(
                  lapsed ? Icons.receipt_long_rounded : Icons.schedule_rounded,
                  size: 16,
                  color: fg,
                ),
                const SizedBox(width: Sp.s2),
                Expanded(
                  child: Text(
                    '$line ${context.l10n.billingCta}',
                    style: SatType.labelS(color: fg),
                  ),
                ),
                Icon(Icons.chat_rounded, size: 16, color: fg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Same hand-off as "Lupa password?" (ADR-0059): `wa.me` is an https link, so
  /// it resolves to WhatsApp when installed and to the browser otherwise, and on
  /// Android something always answers an https VIEW — no `canLaunchUrl` gate.
  ///
  /// Carries the venue id as well as its name because the super admin's console
  /// lists venues by name and names repeat; the id is what makes the venue
  /// findable in one tap on the other end.
  Future<void> _contact(BuildContext context, WidgetRef ref) async {
    final v = ref.read(venueCloudDocProvider);
    if (v == null) return;
    final uri = Uri.parse(
      'https://wa.me/$devWhatsApp?text='
      '${Uri.encodeComponent(context.l10n.billingRequestMessage(v.name, v.id))}',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.resetRequestFailed)));
    }
  }
}

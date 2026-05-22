import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:satset/ui/core/design/colors.dart';
import 'package:satset/ui/features/admin/menu_admin_item_editor.dart';

/// Phone-only full-screen wrapper for [MenuAdminItemEditor].
/// `:id == 'new'` opens a blank create form.
class MenuAdminItemScreen extends StatelessWidget {
  final String id;
  const MenuAdminItemScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final sc = context.sat;
    final effectiveId = id == 'new' ? null : id;
    return Scaffold(
      backgroundColor: sc.bg1,
      body: SafeArea(
        child: MenuAdminItemEditor(
          itemId: effectiveId,
          onClose: () => context.pop(),
          onDeleted: () => context.pop(),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../design/colors.dart';
import '../../../design/spacing.dart';
import '../../../models/menu_item.dart';
import '../../../design/format.dart';

class MenuItemTile extends StatelessWidget {
  const MenuItemTile({super.key, required this.item});

  final MenuItem item;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Material(
      color: AppColors.surfaceLowest,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: isWide ? AppSpacing.xs : AppSpacing.sm,
            horizontal: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                width: isWide ? 32 : 36,
                height: isWide ? 32 : 36,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppShapes.sm),
                ),
                child: Center(
                  child: Icon(
                    item.categoryId == 'c3' ? Icons.local_drink : Icons.restaurant,
                    size: isWide ? 16 : 20,
                    color: AppColors.primaryOverride,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: item.isAvailable ? AppColors.urgencyGreen : AppColors.urgencyAmber,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isWide ? 12 : 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isWide ? 1 : 2),
                    Text(
                      'Rp ${formatRupiah(item.price)}',
                      style: TextStyle(
                        fontSize: isWide ? 11 : 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppShapes {
  AppShapes._();
  static const double sm = 4;
}

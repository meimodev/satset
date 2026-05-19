enum OrderStatus { received, cooking, ready, served, cancelled }

extension OrderStatusLabel on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.received:
        return 'Diterima';
      case OrderStatus.cooking:
        return 'Dimasak';
      case OrderStatus.ready:
        return 'Siap';
      case OrderStatus.served:
        return 'Disajikan';
      case OrderStatus.cancelled:
        return 'Dibatalkan';
    }
  }

  String get actionLabel {
    switch (this) {
      case OrderStatus.received:
        return 'Masak';
      case OrderStatus.cooking:
        return 'Siap';
      default:
        return '';
    }
  }
}

class Order {
  final String id;
  final String tableId;
  final String waiterId;
  final String tableLabel;
  final String? customerName;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItem> items;

  const Order({
    required this.id,
    required this.tableId,
    required this.waiterId,
    required this.tableLabel,
    this.customerName,
    this.status = OrderStatus.received,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
  });

  Duration get elapsed => DateTime.now().difference(createdAt);

  String get displayType => customerName != null ? 'Bungkus' : 'Makan di Tempat';

  String get displayLabel {
    if (customerName != null) return customerName!;
    return 'Meja $tableLabel';
  }

  Order copyWith({
    String? id,
    String? tableId,
    String? waiterId,
    String? tableLabel,
    String? customerName,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<OrderItem>? items,
  }) {
    return Order(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      waiterId: waiterId ?? this.waiterId,
      tableLabel: tableLabel ?? this.tableLabel,
      customerName: customerName ?? this.customerName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }
}

class OrderItem {
  final String id;
  final String orderId;
  final String menuItemId;
  final String name;
  final int quantity;
  final String? notes;
  final List<String> modifierNames;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.menuItemId,
    required this.name,
    this.quantity = 1,
    this.notes,
    this.modifierNames = const [],
  });
}

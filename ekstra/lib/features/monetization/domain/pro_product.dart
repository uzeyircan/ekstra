class ProProduct {
  const ProProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.isAvailable,
  });

  static const lifetimeProductId = String.fromEnvironment(
    'IAP_PRO_LIFETIME_PRODUCT_ID',
    defaultValue: 'ekstra_pro_lifetime',
  );

  final String id;
  final String title;
  final String description;
  final String price;
  final bool isAvailable;

  factory ProProduct.unavailable() {
    return const ProProduct(
      id: lifetimeProductId,
      title: 'Ekstra Pro',
      description: 'Tek seferlik Pro satın alma',
      price: '',
      isAvailable: false,
    );
  }
}

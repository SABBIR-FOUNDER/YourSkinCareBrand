import 'package:intl/intl.dart';

int? wholeTaka(Object? value) => value is int && value >= 0 ? value : null;

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.size,
    required this.description,
    required this.image,
    required this.price,
    this.currencyCode,
    this.formerPrice,
    this.shades = const [],
    this.sale = false,
    this.canAddSingle = false,
  });
  final String id, name, brand, category, size, description, image;
  final int? price, formerPrice;
  final String? currencyCode;
  final List<String> shades;
  final bool sale, canAddSingle;
  String _label(int? value) =>
      value == null || (currencyCode?.trim().isEmpty ?? true)
      ? 'Price unavailable'
      : '$currencyCode ${_amount.format(value)}';
  String get priceLabel => _label(price);
  String get formerPriceLabel => _label(formerPrice);
}

final _amount = NumberFormat('#,##0', 'en_US');
String money(int? amount) =>
    amount == null ? 'Price unavailable' : 'BDT ${_amount.format(amount)}';

const demoProducts = [
  Product(
    id: 'serum',
    name: 'Petal Serum',
    brand: 'Studio 01',
    category: 'Serums',
    size: '30 mL',
    description: 'A rose-tinted glass bottle with a dropper closure.',
    image: 'assets/serum.webp',
    price: 1250,
    currencyCode: 'BDT',
  ),
  Product(
    id: 'cream',
    name: 'Daily Face Cream',
    brand: 'Studio 02',
    category: 'Moisturizers',
    size: '50 mL',
    description: 'An ivory jar with a screw-top lid.',
    image: 'assets/cream.webp',
    price: 980,
    currencyCode: 'BDT',
  ),
  Product(
    id: 'lip',
    name: 'Rose Satin Lipstick',
    brand: 'Studio 01',
    category: 'Makeup',
    size: '3.5 g',
    description: 'A rose-colored lipstick in a twist-up case.',
    image: 'assets/lip.webp',
    price: 760,
    formerPrice: 950,
    currencyCode: 'BDT',
    sale: true,
    shades: ['Rose', 'Mauve'],
  ),
  Product(
    id: 'cleanser',
    name: 'Soft Cream Cleanser',
    brand: 'Studio 02',
    category: 'Cleansers',
    size: '100 mL',
    description: 'A soft tube with a flip-top cap.',
    image: 'assets/cleanser.webp',
    price: null,
    currencyCode: 'BDT',
  ),
];

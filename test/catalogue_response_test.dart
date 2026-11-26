import 'package:flutter_test/flutter_test.dart';
import 'package:your_skin_care_brand/core/network/catalogue_repository.dart';

void main() {
  test('staging maps catalogue identity and whole-taka prices', () {
    final products = decodeCataloguePage({
      'status': 'success',
      'code': 200,
      'data': {
        'results': [
          {
            '_id': 'item-one',
            'title': 'Example',
            'brand': {'title': 'Brand'},
            'categories': [
              {'title': 'Category'},
            ],
            'current_price': 250,
          },
        ],
      },
    });
    final item = products.single;
    expect(item.id, 'item-one');
    expect(item.brand, 'Brand');
    expect(item.category, 'Category');
    expect(item.priceLabel, 'BDT 250');
  });

  test('malformed catalogue responses fail closed', () {
    expect(() => decodeCataloguePage({}), throwsFormatException);
    expect(
      () => decodeCataloguePage({
        'status': 'success',
        'code': 200,
        'data': {
          'results': [
            {'title': 'Missing identity'},
          ],
        },
      }),
      throwsFormatException,
    );
  });
}

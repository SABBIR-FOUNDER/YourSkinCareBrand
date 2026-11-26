import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/store.dart';

class DemoControls extends ConsumerStatefulWidget {
  const DemoControls({super.key});
  @override
  ConsumerState<DemoControls> createState() => _DemoControlsState();
}

class _DemoControlsState extends ConsumerState<DemoControls> {
  late String catalogue, offers, outcome;
  @override
  void initState() {
    super.initState();
    final s = ref.read(shopProvider);
    catalogue = s.catalogueState;
    offers = s.offerState;
    outcome = s.outcome;
  }

  Widget section(
    String label,
    String selected,
    Map<String, String> options,
    ValueChanged<String> change,
    String action,
    VoidCallback apply,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final e in options.entries)
                ChoiceChip(
                  label: Text(e.value),
                  selected: selected == e.key,
                  onSelected: (_) => setState(() => change(e.key)),
                ),
            ],
          ),
          TextButton(onPressed: apply, child: Text(action)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.read(shopProvider);
    return ListView(
      padding: const EdgeInsets.all(17),
      children: [
        Text('Demo controls', style: Theme.of(context).textTheme.headlineLarge),
        const Text(
          'All products, prices and orders are illustrative. Restart the app for a fresh demo.',
        ),
        section(
          'Catalogue loading',
          catalogue,
          {
            'sample': 'Available',
            'loading': 'Loading preview',
            'error': 'Loading error',
          },
          (v) => catalogue = v,
          'Preview products',
          () {
            s.setCatalogue(catalogue);
            context.push('/products');
          },
        ),
        section(
          'Preview a collection',
          offers,
          {
            'sample': 'Sample offers',
            'empty': 'Empty collection',
            'error': 'Loading error',
          },
          (v) => offers = v,
          'Preview Sale',
          () {
            s.setOffers(offers);
            context.go('/sale');
          },
        ),
        section(
          'Checkout outcome',
          outcome,
          {
            'success': 'Success',
            'failure': 'Failure before submission',
            'unknown': 'Unresolved online payment',
          },
          (v) => outcome = v,
          'Apply outcome',
          () {
            s.setOutcome(outcome);
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        const Text(
          'The selected outcome applies to one attempt. Unresolved payment applies to the online method.',
        ),
        const SizedBox(height: 24),
        Text('Browse designs', style: Theme.of(context).textTheme.titleLarge),
        Wrap(
          spacing: 8,
          children: [
            for (final e in {
              'Product': '/product/serum',
              'Missing price': '/product/cleanser',
              'Brand directory': '/brands',
              'Shopping bag': '/bag',
              'Orders': '/orders',
              'Help': '/policy/Contact%20%26%20help',
            }.entries)
              TextButton(
                onPressed: () => context.push(e.value),
                child: Text(e.key),
              ),
          ],
        ),
      ],
    );
  }
}

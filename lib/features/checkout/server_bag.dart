import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/catalog.dart';
import '../../core/config.dart';
import '../../core/network/customer_api.dart';
import '../../core/network/shopping_responses.dart';
import '../account/account_state.dart';

final _cartPage = FutureProvider.autoDispose.family<StoreCartPage, int>((
  ref,
  page,
) {
  ref.watch(accountProvider.select((account) => account.email));
  return ref
      .watch(apiProvider)
      .execute(
        CustomerRequest.cart(page: page),
        contract: const VerifiedResponse(CustomerOperation.cart, decodeCart),
      );
});

class ServerBag extends ConsumerStatefulWidget {
  const ServerBag({super.key});
  @override
  ConsumerState<ServerBag> createState() => _ServerBagState();
}

class _ServerBagState extends ConsumerState<ServerBag> {
  int page = 1;
  int preceding = 0;
  @override
  Widget build(BuildContext context) {
    final data = ref.watch(_cartPage(page));
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text('Shopping bag', style: Theme.of(context).textTheme.headlineMedium),
        data.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, _) =>
              Text(error is ApiFailure ? error.message : 'Could not load bag.'),
          data: (bag) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (bag.items.isEmpty) const Text('No items on this page.'),
              for (final line in bag.items)
                ListTile(
                  title: Text(line.title),
                  subtitle: Text(
                    [
                      'Qty ${line.quantity}',
                      if (line.color != null) line.color!,
                      if (line.size != null) line.size!,
                    ].join(' · '),
                  ),
                  trailing: Text(
                    money(
                      line.price == null ? null : line.price! * line.quantity,
                    ),
                  ),
                ),
              if (bag.items.isNotEmpty &&
                  preceding + bag.items.length < bag.total)
                TextButton(
                  onPressed: () => setState(() {
                    preceding += bag.items.length;
                    page++;
                  }),
                  child: const Text('Next page'),
                ),
              if (page == 1 &&
                  bag.items.isNotEmpty &&
                  bag.items.length == bag.total &&
                  bag.items.every((line) => line.price != null) &&
                  AppConfig.environment == 'staging' &&
                  AppConfig.checkoutReturnUrl.isNotEmpty)
                FilledButton(
                  child: const Text('Test cash on delivery'),
                  onPressed: () async {
                    final owner = ref.read(accountProvider).email!;
                    final summary = bag.items.fold<int>(
                      0,
                      (v, line) => v + line.price! * line.quantity,
                    );
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            _CodForm(owner: owner, subtotal: summary),
                      ),
                    );
                    if (mounted) ref.invalidate(_cartPage);
                  },
                ),
            ],
          ),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              page = 1;
              preceding = 0;
            });
            ref.invalidate(_cartPage);
          },
          child: const Text('Refresh bag'),
        ),
      ],
    );
  }
}

class _CodForm extends ConsumerStatefulWidget {
  const _CodForm({required this.owner, required this.subtotal});
  final String owner;
  final int subtotal;
  @override
  ConsumerState<_CodForm> createState() => _CodFormState();
}

class _CodFormState extends ConsumerState<_CodForm> {
  final form = GlobalKey<FormState>();
  final values = <String, String>{};
  bool busy = false, finished = false, blocked = false;
  String message = '';

  Future<void> submit() async {
    if (busy || finished || blocked || !form.currentState!.validate()) return;
    form.currentState!.save();
    final service = ref.read(apiProvider);
    final marker = SecureTokenVault(
      'pending-cod|${AppConfig.baseUrl}|${widget.owner}',
    );
    setState(() => busy = true);
    try {
      final request = CustomerRequest.createOrder(
        method: StorePayment.cod,
        delivery: DeliveryDetails(
          fullName: values['Full name']!,
          address: values['Address']!,
          city: values['City']!,
          postalCode: values['Postal code']!,
          phone: values['Phone']!,
        ),
        format: VerifiedOrderFormat(
          StorePayment.cod,
          RedirectPlacement.atTopLevel,
          returnUrl: Uri.tryParse(AppConfig.checkoutReturnUrl),
        ),
      );
      if (await marker.read() != null) throw ApiFailure.unknownOrder;
      await marker.write('pending');
      if (!mounted || ref.read(accountProvider).email != widget.owner) {
        await marker.clear();
        return;
      }
      late StoreOrder order;
      try {
        order = await service.execute(
          request,
          contract: const VerifiedResponse(
            CustomerOperation.createOrder,
            decodeCodReceipt,
          ),
        );
      } on ApiFailure catch (failure) {
        if ({
          ApiProblem.signInRequired,
          ApiProblem.validation,
          ApiProblem.forbidden,
          ApiProblem.configuration,
        }.contains(failure.problem)) {
          await marker.clear();
          rethrow;
        }
        throw ApiFailure.unknownOrder;
      }
      finished = true;
      message =
          'Order ${order.id}\nTotal ${money(order.total)} · Payment ${order.paymentStatus}';
      await marker.clear();
    } on ApiFailure catch (e) {
      blocked = e.problem == ApiProblem.unknownOrder;
      message = blocked
          ? "This attempt needs store confirmation. Check your orders before placing another."
          : e.message;
    } catch (_) {
      if (!finished) {
        message =
            'Unable to confirm this attempt. Check your orders before trying again.';
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final owner = ref.watch(accountProvider.select((a) => a.email));
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('Test cash on delivery')),
        body: owner != widget.owner
            ? const Text('Sign in again to continue.')
            : Form(
                key: form,
                child: ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    Text('Item subtotal ${money(widget.subtotal)}'),
                    const Text(
                      'Staging test order. Use test delivery details.',
                    ),
                    if (!finished)
                      for (final label in [
                        'Full name',
                        'Address',
                        'City',
                        'Postal code',
                        'Phone',
                      ])
                        TextFormField(
                          enabled: !busy,
                          decoration: InputDecoration(labelText: label),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                          onSaved: (v) => values[label] = v!.trim(),
                        ),
                    if (message.isNotEmpty) SelectableText(message),
                    if (!finished)
                      FilledButton(
                        onPressed: busy || blocked ? null : submit,
                        child: const Text('Place test order'),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

final _recentOrders = FutureProvider.autoDispose<List<StoreOrder>>((ref) {
  ref.watch(accountProvider.select((a) => a.email));
  return ref
      .watch(apiProvider)
      .execute(
        CustomerRequest.orders(),
        contract: const VerifiedResponse(
          CustomerOperation.orders,
          decodeOrderList,
        ),
      );
});

class ServerOrderLookup extends ConsumerStatefulWidget {
  const ServerOrderLookup({super.key, this.id = ''});
  final String id;
  @override
  ConsumerState<ServerOrderLookup> createState() => _ServerOrderLookupState();
}

class _ServerOrderLookupState extends ConsumerState<ServerOrderLookup> {
  late final input = TextEditingController(text: widget.id);
  StoreOrder? order;
  String message = '';
  bool busy = false;
  @override
  void initState() {
    super.initState();
    if (widget.id.isNotEmpty) lookup();
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  Future<void> lookup() async {
    final id = input.text.trim();
    if (id.isEmpty || busy) return;
    setState(() {
      busy = true;
      order = null;
      message = '';
    });
    try {
      final result = await ref
          .read(apiProvider)
          .execute(CustomerRequest.order(id), contract: orderDetails(id));
      if (mounted) setState(() => order = result);
    } on ApiFailure catch (e) {
      if (mounted) setState(() => message = e.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      Text('Find an order', style: Theme.of(context).textTheme.headlineMedium),
      TextField(
        controller: input,
        enabled: !busy,
        decoration: const InputDecoration(labelText: 'Order ID'),
      ),
      FilledButton(
        onPressed: busy ? null : lookup,
        child: const Text('View order'),
      ),
      if (message.isNotEmpty) Text(message),
      if (widget.id.isEmpty)
        ref
            .watch(_recentOrders)
            .when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const Text(
                'Recent orders could not be loaded. You can still look up a known order ID.',
              ),
              data: (items) => Column(
                children: [
                  for (final item in items)
                    ListTile(
                      title: Text(item.id),
                      subtitle: Text('${money(item.total)} · ${item.status}'),
                      onTap: busy
                          ? null
                          : () {
                              input.text = item.id;
                              lookup();
                            },
                    ),
                ],
              ),
            ),
      if (order case final result?)
        SelectableText(
          'Order ${result.id}\nTotal ${money(result.total)}\nOrder ${result.status} · Payment ${result.paymentStatus} (${result.paymentMethod})',
        ),
    ],
  );
}

class ServerSignIn extends StatelessWidget {
  const ServerSignIn({super.key});
  @override
  Widget build(BuildContext context) => Center(
    child: FilledButton(
      onPressed: () => context.push('/signin'),
      child: const Text('Sign in'),
    ),
  );
}

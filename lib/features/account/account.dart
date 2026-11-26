import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/store.dart';
import '../../core/network/api_failure.dart';
import '../checkout/checkout_state.dart';
import 'account_state.dart';

const _policies = {
  'Contact & help': 'Store contact details will appear here once supplied.',
  'Privacy': 'The store’s privacy policy is awaiting approval.',
  'Terms': 'The store’s terms are awaiting approval.',
  'Delivery':
      'Delivery regions, costs and time estimates are awaiting confirmation.',
  'Returns & refunds':
      'Return conditions, deadlines and refund instructions are awaiting confirmation.',
};

String _destination(String next) => switch (next) {
  'checkout' => '/checkout/address',
  'profile' => '/profile',
  'addresses' => '/addresses',
  _ => '/account',
};
String _authPath(String path, String next) => next.isEmpty
    ? path
    : Uri(path: path, queryParameters: {'next': next}).toString();

void _returnTo(BuildContext context, String fallback) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallback);
  }
}

class AccountScreen extends ConsumerWidget {
  const AccountScreen({
    super.key,
    required this.page,
    this.value = '',
    this.next = '',
  });
  final String page;
  final String value;
  final String next;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountProvider);
    const memberPages = {
      'profile',
      'editProfile',
      'addresses',
      'addAddress',
      'editAddress',
    };
    if (memberPages.contains(page) && account.email == null) {
      final resume = page.toLowerCase().contains('address')
          ? 'addresses'
          : 'profile';
      return _AccountForm(
        key: ValueKey('signin-$resume'),
        page: 'signin',
        next: resume,
      );
    }
    if (page == 'account') return _AccountHome(account: account);
    if (page == 'policy') {
      final title = _policies.keys.firstWhere(
        (name) => name.toLowerCase() == value.toLowerCase(),
        orElse: () => 'Help & policies',
      );
      return _Page(
        title: title,
        children: [_Panel(child: Text(_policies[title] ?? 'Content pending.'))],
      );
    }
    if (!account.demo &&
        {
          'editProfile',
          'addresses',
          'addAddress',
          'editAddress',
        }.contains(page)) {
      return const _Page(
        title: 'Account',
        children: [_Panel(child: Text(AccountState.unavailable))],
      );
    }
    if (page == 'profile') {
      final p = account.profile!;
      return _Page(
        title: 'Profile',
        children: [
          for (final field in {
            'Name': p.fullName,
            'Email': account.email!,
            'Phone': p.phone,
            'Address': p.street,
            'City': p.city,
          }.entries)
            _ProfileRow(label: field.key, value: field.value),
          const SizedBox(height: 16),
          if (account.demo)
            FilledButton(
              onPressed: () => context.push('/profile/edit'),
              child: const Text('Edit profile'),
            ),
        ],
      );
    }
    if (page == 'addresses') {
      return _Page(
        title: 'Saved addresses',
        description: 'Example addresses last for this session.',
        children: [
          if (account.addresses.isEmpty)
            _Panel(
              color: Brand.petal,
              child: Column(
                children: [
                  const CircleAvatar(
                    backgroundColor: Brand.blush,
                    child: Icon(Icons.location_on_outlined),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No saved addresses',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Add an example address to use at checkout.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            for (final entry in account.addresses.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.$2.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(entry.$2.street),
                      Text('${entry.$2.city} ${entry.$2.postalCode}'),
                      Text(entry.$2.phone),
                      Wrap(
                        spacing: 12,
                        children: [
                          TextButton(
                            onPressed: () =>
                                context.push('/addresses/${entry.$1}/edit'),
                            child: const Text('Edit'),
                          ),
                          TextButton(
                            onPressed: () => account.removeAddress(entry.$1),
                            child: const Text('Remove'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.push('/addresses/new'),
            child: const Text('Add address'),
          ),
        ],
      );
    }
    if (page == 'editAddress') {
      final index = int.tryParse(value);
      if (index == null || index < 0 || index >= account.addresses.length) {
        return _Page(
          title: 'Address unavailable',
          children: [
            TextButton(
              onPressed: () => context.go('/addresses'),
              child: const Text('View saved addresses'),
            ),
          ],
        );
      }
    }
    return _AccountForm(
      key: ValueKey('$page-$value-$next'),
      page: page,
      value: value,
      next: next,
    );
  }
}

class _AccountHome extends ConsumerWidget {
  const _AccountHome({required this.account});
  final AccountState account;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signed = account.email != null;
    final orderCount = ref.watch(
      shopProvider.select((store) => store.orders.length),
    );
    return _Page(
      title: 'Account',
      children: [
        _Panel(
          color: Brand.blush,
          bordered: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                account.profile?.fullName ?? 'Shopping as a guest',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              TextButton(
                onPressed: () => context.push(signed ? '/profile' : '/signin'),
                child: Text(signed ? 'View profile' : 'Sign in'),
              ),
            ],
          ),
        ),
        _LinkRow(
          label: 'Orders',
          detail: account.demo ? '$orderCount in this session' : null,
          onTap: () => context.push('/orders'),
        ),
        if (signed && account.demo)
          _LinkRow(
            label: 'Saved addresses',
            detail: '${account.addresses.length} in this session',
            onTap: () => context.push('/addresses'),
          )
        else if (!signed && account.demo)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.push('/register'),
              child: Text(
                account.demo ? 'Create a demo account' : 'Create an account',
              ),
            ),
          ),
        const SizedBox(height: 20),
        Semantics(
          header: true,
          child: Text(
            'Help & policies',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        for (final policy in _policies.keys)
          _LinkRow(
            label: policy,
            onTap: () => context.push('/policy/${Uri.encodeComponent(policy)}'),
          ),
        if (signed)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () async {
                try {
                  await account.signOut();
                  if (context.mounted) context.go('/account');
                } on ApiFailure catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(error.message)));
                  }
                }
              },
              child: const Text('Switch to guest'),
            ),
          ),
      ],
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.title, this.description, required this.children});
  final String title;
  final String? description;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => ListView(
    key: PageStorageKey('account-$title'),
    padding: const EdgeInsets.fromLTRB(17, 19, 17, 26),
    children: [
      Semantics(
        header: true,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            letterSpacing: -1.4,
            height: 1.14,
          ),
        ),
      ),
      if (description != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(description!, style: const TextStyle(color: Brand.muted)),
        ),
      const SizedBox(height: 16),
      ...children,
    ],
  );
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.child,
    this.color = Colors.white,
    this.bordered = true,
  });
  final Widget child;
  final Color color;
  final bool bordered;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(14),
      border: bordered ? Border.all(color: Brand.taupe) : null,
    ),
    child: child,
  );
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.label, required this.onTap, this.detail});
  final String label;
  final String? detail;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      ListTile(
        contentPadding: EdgeInsets.zero,
        minVerticalPadding: 9,
        onTap: onTap,
        title: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        subtitle: detail == null ? null : Text(detail!),
        trailing: const Icon(Icons.chevron_right, size: 18),
      ),
      const Divider(height: 1, color: Brand.taupe),
    ],
  );
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Brand.taupe)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(flex: 2, child: Text(label)),
        const SizedBox(width: 10),
        Expanded(
          flex: 5,
          child: Text(
            value.isEmpty ? '—' : value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _AccountForm extends ConsumerStatefulWidget {
  const _AccountForm({
    super.key,
    required this.page,
    this.value = '',
    this.next = '',
  });
  final String page;
  final String value;
  final String next;
  @override
  ConsumerState<_AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends ConsumerState<_AccountForm> {
  final _key = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  String? _message;
  String get page => widget.page;

  @override
  void initState() {
    super.initState();
    final account = ref.read(accountProvider);
    final profile = account.profile;
    final index = int.tryParse(widget.value);
    final address =
        page == 'editAddress' &&
            index != null &&
            index >= 0 &&
            index < account.addresses.length
        ? account.addresses[index]
        : null;
    final fields = <String, String>{
      'first': page == 'register' && account.demo
          ? 'Demo'
          : profile?.firstName ?? '',
      'last': page == 'register' && account.demo
          ? 'Shopper'
          : profile?.lastName ?? '',
      'email': account.email ?? (account.demo ? AccountState.exampleEmail : ''),
      'password': (page == 'signin' || page == 'register') && account.demo
          ? AccountState.examplePassword
          : '',
      'code': '',
      'fullName': address?.fullName ?? '',
      'street': page == 'editProfile'
          ? profile?.street ?? ''
          : address?.street ?? '',
      'city': page == 'editProfile' ? profile?.city ?? '' : address?.city ?? '',
      'postalCode': address?.postalCode ?? '',
      'phone': page == 'editProfile'
          ? profile?.phone ?? ''
          : address?.phone ?? '',
    };
    for (final item in fields.entries) {
      _controllers[item.key] = TextEditingController(text: item.value);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _value(String key) => _controllers[key]!.text.trim();

  Widget _field(
    String id,
    String label, {
    TextInputType? keyboard,
    String? hint,
    bool optional = false,
    bool obscure = false,
    bool readOnly = false,
    bool last = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      key: ValueKey('account-field-$id'),
      controller: _controllers[id],
      readOnly: readOnly,
      keyboardType: keyboard,
      obscureText: obscure,
      autocorrect: !obscure && keyboard != TextInputType.emailAddress,
      enableSuggestions: !obscure,
      autofillHints: hint == null ? null : [hint],
      textInputAction: last ? TextInputAction.done : TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      validator: (value) {
        if (!optional && (value == null || value.trim().isEmpty)) {
          return 'Enter $label.';
        }
        if (id == 'email' && !(value ?? '').contains('@')) {
          return 'Enter a valid email address.';
        }
        return null;
      },
      onFieldSubmitted: last ? (_) => _submit() : null,
    ),
  );

  Widget _pair(Widget left, Widget right) => LayoutBuilder(
    builder: (context, box) {
      if (box.maxWidth < 300 ||
          MediaQuery.textScalerOf(context).scale(14) > 20) {
        return Column(children: [left, right]);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          const SizedBox(width: 10),
          Expanded(child: right),
        ],
      );
    },
  );

  void _fillAddress() {
    const a = ShippingAddress.example;
    final fixture = {
      'fullName': a.fullName,
      'street': a.street,
      'city': a.city,
      'postalCode': a.postalCode,
      'phone': a.phone,
    };
    for (final field in fixture.entries) {
      _controllers[field.key]!.text = field.value;
    }
  }

  bool _busy = false;

  Future<void> _submit() async {
    if (_busy) return;
    if (!(_key.currentState?.validate() ?? false)) return;
    final state = ref.read(accountProvider);
    String? error;
    switch (page) {
      case 'signin':
        final email = _value('email');
        final password = _controllers['password']!.text;
        if (state.demo) {
          error = state.signIn(email, password);
        } else {
          setState(() => _busy = true);
          error = await state.signInOnline(email, password);
          if (!mounted) return;
          setState(() => _busy = false);
        }
      case 'register':
        error = state.register(
          _value('first'),
          _value('last'),
          _value('email'),
          _controllers['password']!.text,
        );
      case 'verify':
        error = state.verify(_value('code'));
      case 'editProfile':
        if (state.email == null) return;
        state.updateProfile(
          MemberProfile(
            firstName: _value('first'),
            lastName: _value('last'),
            phone: _value('phone'),
            street: _value('street'),
            city: _value('city'),
          ),
        );
      case 'addAddress' || 'editAddress':
        if (state.email == null) return;
        final index = int.tryParse(widget.value);
        if (page == 'editAddress' &&
            (index == null || index < 0 || index >= state.addresses.length)) {
          context.go('/addresses');
          return;
        }
        state.saveAddress(
          ShippingAddress(
            fullName: _value('fullName'),
            street: _value('street'),
            city: _value('city'),
            postalCode: _value('postalCode'),
            phone: _value('phone'),
          ),
          index: page == 'editAddress' ? index : null,
        );
      default:
        return;
    }
    if (error != null) {
      setState(() => _message = error);
      return;
    }
    FocusScope.of(context).unfocus();
    switch (page) {
      case 'register':
        context.push(_authPath('/verify', widget.next));
      case 'signin' || 'verify':
        context.go(_destination(widget.next));
      case 'editProfile':
        _returnTo(context, '/profile');
      default:
        _returnTo(context, '/addresses');
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(accountProvider);
    final title = switch (page) {
      'signin' => 'Sign in',
      'register' => 'Create an account',
      'verify' => 'Verify your email',
      'editProfile' => 'Edit profile',
      'addAddress' => 'Add address',
      'editAddress' => 'Edit address',
      _ => 'Account',
    };
    final authForm = page == 'signin' || page == 'register';
    if (!account.demo && (page != 'signin' || account.api == null)) {
      return _Page(
        title: title,
        children: const [_Panel(child: Text(AccountState.unavailable))],
      );
    }
    if (page == 'verify' && !account.verificationPending) {
      return _Page(
        title: title,
        children: [
          const Text('Start registration to verify your email.'),
          TextButton(
            onPressed: () => context.go(_authPath('/register', widget.next)),
            child: const Text('Create a demo account'),
          ),
        ],
      );
    }
    final addressBook = page == 'addAddress' || page == 'editAddress';
    final first = _field('first', 'First name', hint: AutofillHints.givenName);
    final last = _field('last', 'Last name', hint: AutofillHints.familyName);
    return _Page(
      title: title,
      description: authForm && account.demo
          ? 'Use the example account for this demo.'
          : page == 'verify'
          ? AccountState.exampleEmail
          : null,
      children: [
        Form(
          key: _key,
          child: AutofillGroup(
            onDisposeAction: AutofillContextAction.cancel,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (page == 'register') _pair(first, last),
                if (page == 'editProfile') ...[first, last],
                if (authForm) ...[
                  _field(
                    'email',
                    'Email',
                    keyboard: TextInputType.emailAddress,
                    hint: AutofillHints.email,
                  ),
                  _field(
                    'password',
                    account.demo ? 'Demo password' : 'Password',
                    obscure: true,
                    last: true,
                  ),
                  if (account.demo)
                    const Text(
                      'Example password: sample-only',
                      style: TextStyle(fontSize: 12),
                    ),
                ],
                if (page == 'verify') ...[
                  const _Panel(
                    color: Brand.petal,
                    child: Text('Use demo code 246810.'),
                  ),
                  const SizedBox(height: 12),
                  _field(
                    'code',
                    'Verification code',
                    keyboard: TextInputType.number,
                    last: true,
                  ),
                ],
                if (page == 'editProfile') ...[
                  _field('email', 'Email', readOnly: true),
                  _field(
                    'phone',
                    'Phone',
                    keyboard: TextInputType.phone,
                    optional: true,
                  ),
                  _field('street', 'Address', optional: true),
                  _field('city', 'City', optional: true, last: true),
                ],
                if (addressBook) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _fillAddress,
                      child: const Text('Fill sample address'),
                    ),
                  ),
                  _field('fullName', 'Full name', hint: AutofillHints.name),
                  _field(
                    'street',
                    'Street address',
                    hint: AutofillHints.streetAddressLine1,
                  ),
                  _pair(
                    _field('city', 'City', hint: AutofillHints.addressCity),
                    _field(
                      'postalCode',
                      'Postal code',
                      hint: AutofillHints.postalCode,
                    ),
                  ),
                  _field(
                    'phone',
                    'Phone',
                    keyboard: TextInputType.phone,
                    hint: AutofillHints.telephoneNumber,
                    last: true,
                  ),
                ],
                if (_message != null)
                  Semantics(
                    liveRegion: true,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _message!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: Text(switch (page) {
                    'signin' =>
                      account.demo
                          ? 'Sign in to demo'
                          : (_busy ? 'Signing in…' : 'Sign in'),
                    'register' => 'Continue to verification',
                    'verify' => 'Verify code',
                    'editProfile' => 'Save changes',
                    _ => 'Save address',
                  }),
                ),
              ],
            ),
          ),
        ),
        if (page == 'signin' && account.demo)
          TextButton(
            onPressed: () => context.push(_authPath('/register', widget.next)),
            child: const Text('Create a demo account'),
          ),
        if (page == 'verify')
          TextButton(
            onPressed: () => setState(() => _message = account.resend()),
            child: const Text('Resend demo code'),
          ),
      ],
    );
  }
}

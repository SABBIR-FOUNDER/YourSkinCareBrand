part of 'checkout.dart';

class _DeliveryForm extends ConsumerStatefulWidget {
  const _DeliveryForm();
  @override
  ConsumerState<_DeliveryForm> createState() => _DeliveryFormState();
}

class _DeliveryFormState extends ConsumerState<_DeliveryForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _street = TextEditingController();
  final _city = TextEditingController();
  final _postal = TextEditingController();
  final _phone = TextEditingController();
  bool _save = false;
  @override
  void initState() {
    super.initState();
    _fill(ref.read(shopProvider).draft);
  }

  void _fill(ShippingAddress address) {
    _name.text = address.fullName;
    _street.text = address.street;
    _city.text = address.city;
    _postal.text = address.postalCode;
    _phone.text = address.phone;
  }

  ShippingAddress get _current => ShippingAddress(
    fullName: _name.text.trim(),
    street: _street.text.trim(),
    city: _city.text.trim(),
    postalCode: _postal.text.trim(),
    phone: _phone.text.trim(),
  );
  @override
  void dispose() {
    for (final field in [_name, _street, _city, _postal, _phone]) {
      field.dispose();
    }
    super.dispose();
  }

  Widget _field(
    String label,
    TextEditingController controller,
    String hint, {
    TextInputType type = TextInputType.text,
    bool last = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        autofillHints: [hint],
        textInputAction: last ? TextInputAction.done : TextInputAction.next,
        textCapitalization: type == TextInputType.text
            ? TextCapitalization.words
            : TextCapitalization.none,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (v) => v == null || v.trim().isEmpty
            ? 'Enter ${label.toLowerCase()}'
            : null,
        onChanged: (_) => ref.read(shopProvider).setDraft(_current),
      ),
    );
  }

  void _advance() {
    if (!(_form.currentState?.validate() ?? false)) return;
    final account = ref.read(accountProvider);
    final store = ref.read(shopProvider);
    final address = _current;
    store.setDraft(address);
    if (store.demo && _save && account.email != null) {
      account.saveAddress(address);
    }
    FocusScope.of(context).unfocus();
    context.push('/checkout/payment');
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(accountProvider);
    final store = ref.watch(shopProvider);
    return _Page(
      children: [
        const _Steps(0),
        _Title(
          'Delivery address',
          store.demo ? 'Use sample details for this walkthrough.' : null,
        ),
        if (account.email == null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {
                store.setDraft(_current);
                context.push('/signin?next=checkout');
              },
              child: Text(store.demo ? 'Sign in to this demo' : 'Sign in'),
            ),
          ),
        if (store.demo && account.email != null)
          for (final item in account.addresses)
            OutlinedButton(
              onPressed: () {
                _fill(item);
                store.setDraft(item);
                context.push('/checkout/payment');
              },
              child: Text('Use ${item.street}'),
            ),
        if (store.demo)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {
                _fill(ShippingAddress.example);
                store.setDraft(ShippingAddress.example);
              },
              child: const Text('Fill sample address'),
            ),
          ),
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _field('Full name', _name, AutofillHints.name),
                _field(
                  'Street address',
                  _street,
                  AutofillHints.streetAddressLine1,
                  type: TextInputType.streetAddress,
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final city = _field(
                      'City',
                      _city,
                      AutofillHints.addressCity,
                    );
                    final postal = _field(
                      'Postal code',
                      _postal,
                      AutofillHints.postalCode,
                    );
                    if (constraints.maxWidth < 250 ||
                        MediaQuery.textScalerOf(context).scale(14) > 21) {
                      return Column(children: [city, postal]);
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: city),
                        const SizedBox(width: 10),
                        Expanded(child: postal),
                      ],
                    );
                  },
                ),
                _field(
                  'Phone',
                  _phone,
                  AutofillHints.telephoneNumber,
                  type: TextInputType.phone,
                  last: true,
                ),
                if (store.demo && account.email != null)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _save,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('Save to demo addresses'),
                    onChanged: (v) => setState(() => _save = v ?? false),
                  ),
                FilledButton(
                  onPressed: _advance,
                  child: const Text('Continue to payment'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Payment extends StatelessWidget {
  const _Payment(this.store);
  final ShopStore store;
  @override
  Widget build(BuildContext context) {
    if (!store.demo) {
      return const _Page(
        children: [
          _Steps(1),
          _Title('Payment method'),
          _Note(
            'Payment options and the final amount are unavailable. Your bag is saved for this session.',
          ),
        ],
      );
    }
    return _Page(
      children: [
        const _Steps(1),
        const _Title('Payment method'),
        RadioGroup<PaymentChoice>(
          groupValue: store.payment,
          onChanged: (v) {
            if (v != null) store.setPayment(v);
          },
          child: Column(
            children: [
              for (final option in PaymentChoice.values)
                Container(
                  margin: const EdgeInsets.only(bottom: 9),
                  decoration: BoxDecoration(
                    color: store.payment == option ? _petal : Colors.white,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: store.payment == option ? _rose : _taupe,
                    ),
                  ),
                  child: RadioListTile<PaymentChoice>(
                    value: option,
                    title: Text(option.label),
                    activeColor: _rose,
                  ),
                ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 4, bottom: 17),
          child: Text(
            'Both choices use a simulated order. No payment details are needed.',
            style: TextStyle(fontSize: 12, color: _muted),
          ),
        ),
        FilledButton(
          onPressed: () => context.push('/checkout/review'),
          child: const Text('Review order'),
        ),
      ],
    );
  }
}

class _AddressPanel extends StatelessWidget {
  const _AddressPanel(this.address);
  final ShippingAddress address;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: _taupe),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          address.fullName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        Text(address.street),
        Text('${address.city} ${address.postalCode}'),
        Text(address.phone),
      ],
    ),
  );
}

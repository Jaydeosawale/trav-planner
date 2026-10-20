import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class BookingLinksPage extends StatefulWidget {
  const BookingLinksPage({
    super.key,
    this.destination,
    this.startDate,
    this.endDate,
    this.travelers,
  });
  final String? destination;
  final DateTime? startDate, endDate;
  final int? travelers;
  @override
  State<BookingLinksPage> createState() => _BookingLinksPageState();
}

class _BookingLinksPageState extends State<BookingLinksPage> {
  String _mode = 'Flights';
  String _country = 'India';
  static const rail = {
    'India': ('IRCTC', 'https://www.irctc.co.in/nget/train-search'),
    'United States': ('Amtrak', 'https://www.amtrak.com/home.html'),
    'France': ('SNCF Connect', 'https://www.sncf-connect.com/en-en'),
    'Germany': ('Deutsche Bahn', 'https://int.bahn.de/en'),
  };
  Future<void> _open(String address) async {
    try {
      if (!await launchUrl(
        Uri.parse(address),
        mode: LaunchMode.externalApplication,
      )) {
        throw Exception();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Couldn’t open the provider. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Compare & book')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Find your way there.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              const Text(
                'Compare travel options, then book and pay securely on the supplier’s website.',
              ),
              if (widget.destination?.trim().isNotEmpty == true ||
                  widget.startDate != null ||
                  widget.travelers != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your trip reference',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (widget.destination?.trim().isNotEmpty == true)
                          Text(widget.destination!.trim()),
                        if (widget.startDate != null)
                          Text(
                            '${_date(widget.startDate!)}${widget.endDate == null ? '' : ' – ${_date(widget.endDate!)}'}',
                          ),
                        if (widget.travelers != null && widget.travelers! > 0)
                          Text(
                            '${widget.travelers} traveler${widget.travelers == 1 ? '' : 's'}',
                          ),
                        const SizedBox(height: 8),
                        const Text(
                          'Enter these details on the supplier’s site. They are not transferred automatically.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                children: ['Flights', 'Trains', 'Buses', 'Stays']
                    .map(
                      (m) => ChoiceChip(
                        label: Text(m),
                        selected: _mode == m,
                        onSelected: (_) => setState(() => _mode = m),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              if (_mode == 'Flights') ...[
                const ListTile(
                  leading: Icon(Icons.flight_takeoff),
                  title: Text('Find flights worldwide'),
                  subtitle: Text(
                    'Compare routes and dates on Google Flights, then complete your booking with the airline or seller.',
                  ),
                ),
                FilledButton.icon(
                  onPressed: () =>
                      _open('https://www.google.com/travel/flights'),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Search flights'),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => _open('https://www.airindia.com/'),
                      child: const Text('Air India'),
                    ),
                    TextButton(
                      onPressed: () => _open('https://www.goindigo.in/'),
                      child: const Text('IndiGo'),
                    ),
                  ],
                ),
              ] else if (_mode == 'Trains') ...[
                DropdownButtonFormField<String>(
                  initialValue: _country,
                  decoration: const InputDecoration(
                    labelText: 'Country or rail network',
                  ),
                  items: rail.keys
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (c) => setState(() => _country = c!),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _open(rail[_country]!.$2),
                  icon: const Icon(Icons.train_outlined),
                  label: Text('Continue to ${rail[_country]!.$1}'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'For other countries, book with the relevant local rail operator. More verified providers can be added later.',
                ),
              ],
              if (_mode == 'Buses') ...[
                const ListTile(
                  leading: Icon(Icons.directions_bus_outlined),
                  title: Text('City to city, your way'),
                  subtitle: Text(
                    'Choose routes, dates and seats with the bus provider. Coverage varies by country.',
                  ),
                ),
                FilledButton(
                  onPressed: () => _open('https://www.redbus.in/'),
                  child: const Text('redBus · India'),
                ),
                TextButton(
                  onPressed: () => _open('https://www.flixbus.com/'),
                  child: const Text('FlixBus · supported routes'),
                ),
              ],
              if (_mode == 'Stays') ...[
                const ListTile(
                  leading: Icon(Icons.bed_outlined),
                  title: Text('Find your home for the night'),
                  subtitle: Text(
                    'Check current room prices, policies and availability with the accommodation provider.',
                  ),
                ),
                FilledButton(
                  onPressed: () => _open('https://www.booking.com/'),
                  child: const Text('Find stays on Booking.com'),
                ),
              ],
              const SizedBox(height: 24),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'You’ll choose passengers, dates, fares and payment on the provider’s website. Opening a link does not reserve a ticket. Trav does not issue tickets, confirm availability or collect payment in this flow.',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

String _date(DateTime value) => '${value.day}/${value.month}/${value.year}';

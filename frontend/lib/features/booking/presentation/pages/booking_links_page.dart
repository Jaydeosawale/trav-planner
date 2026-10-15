import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class BookingLinksPage extends StatefulWidget {
  const BookingLinksPage({super.key});
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
    appBar: AppBar(title: const Text('Book travel')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Your journey, your choice.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              const Text(
                'Search and book directly with a travel provider. You don’t need the AI planner.',
              ),
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

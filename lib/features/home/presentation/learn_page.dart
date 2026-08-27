import 'package:flutter/material.dart';

class LearnPage extends StatefulWidget {
  const LearnPage({super.key});
  @override
  State<LearnPage> createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage> {
  final _searchController = TextEditingController();
  String _query = '';
  String _filter = 'All';
  String _standard = 'All Standards';
  bool _expertOnly = false;

  final List<_LearnItem> _items = const [
    _LearnItem(type: 'Teacher', title: 'Dr. Asha Kulkarni', subtitle: 'Science • Biology', standard: '10', rating: 4.9, reviews: 128, verified: true),
    _LearnItem(type: 'Teacher', title: 'Rahul Deshmukh', subtitle: 'Mathematics', standard: '8', rating: 4.8, reviews: 211, verified: true),
    _LearnItem(type: 'Teacher', title: 'Neha Patil', subtitle: 'English • Communication', standard: '6', rating: 4.6, reviews: 63, verified: false),
    _LearnItem(type: 'Teacher', title: 'Amit Joshi', subtitle: 'General Science', standard: '5', rating: 4.7, reviews: 91, verified: true),
    _LearnItem(type: 'Teacher', title: 'Sneha More', subtitle: 'Mathematics • Foundation', standard: '3', rating: 4.7, reviews: 84, verified: true),
    _LearnItem(type: 'Teacher', title: 'Vivek Shinde', subtitle: 'All Subjects • Primary', standard: '2', rating: 4.9, reviews: 176, verified: true),
    _LearnItem(type: 'Class', title: 'Physics Fundamentals', subtitle: 'Physics • Class 11–12', standard: '11–12', rating: 4.8, reviews: 94, verified: true),
    _LearnItem(type: 'Class', title: 'Python for Beginners', subtitle: 'Programming • Beginner', standard: 'All', rating: 4.7, reviews: 76, verified: true),
    _LearnItem(type: 'Class', title: 'Digital Marketing Masterclass', subtitle: 'Business • Beginner–Advanced', standard: 'All', rating: 4.5, reviews: 51, verified: true),
  ];

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  List<_LearnItem> get _results {
    final q = _query.trim().toLowerCase();
    final filtered = _items.where((item) {
      final typeOk = _filter == 'All' || item.type == _filter;
      final standardOk = _standard == 'All Standards' || item.standard == _standard;
      final expertOk = !_expertOnly || (item.type == 'Teacher' && item.verified && item.rating >= 4.7);
      final textOk = q.isEmpty || '${item.title} ${item.subtitle} Standard ${item.standard}'.toLowerCase().contains(q);
      return typeOk && standardOk && expertOk && textOk;
    }).toList();
    filtered.sort((a, b) { final rating = b.rating.compareTo(a.rating); return rating != 0 ? rating : b.reviews.compareTo(a.reviews); });
    return filtered;
  }

  void _rate(_LearnItem item) async {
    final rating = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Rate ${item.type.toLowerCase()}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6), Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 18),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: List.generate(5, (index) => IconButton(tooltip: '${index + 1} star', onPressed: () => Navigator.of(sheetContext).pop(index + 1), icon: Icon(index < 4 ? Icons.star_rounded : Icons.star_border_rounded, size: 34)))),
        ]),
      )),
    );
    if (!mounted || rating == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Your $rating-star rating was recorded.')));
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    final standards = ['All Standards', ...List.generate(10, (index) => '${index + 1}')];
    return Scaffold(
      appBar: AppBar(title: const Text('Learn', style: TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 32), children: [
        Text('Learn from trusted teachers and classes', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text('Search any subject or skill. Higher-quality ratings get more visibility.'),
        const SizedBox(height: 16),
        TextField(controller: _searchController, onChanged: (value) => setState(() => _query = value), textInputAction: TextInputAction.search, decoration: InputDecoration(hintText: 'Search subject, class, skill or teacher', prefixIcon: const Icon(Icons.search_rounded), suffixIcon: _query.isEmpty ? null : IconButton(onPressed: () { _searchController.clear(); setState(() => _query = ''); }, icon: const Icon(Icons.clear_rounded)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)))),
        const SizedBox(height: 12),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['All', 'Teacher', 'Class'].map((value) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(value), selected: _filter == value, onSelected: (_) => setState(() => _filter = value)))).toList())),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const Icon(Icons.school_outlined), const SizedBox(width: 8), const Text('Teachers • Standard 1 to 10', style: TextStyle(fontWeight: FontWeight.w900))]),
          const SizedBox(height: 10),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: standards.map((value) => Padding(padding: const EdgeInsets.only(right: 6), child: ChoiceChip(label: Text(value == 'All Standards' ? 'All' : 'Std $value'), selected: _standard == value, onSelected: (_) => setState(() => _standard = value)))).toList())),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, secondary: const Icon(Icons.workspace_premium_outlined), title: const Text('Expert teachers only', style: TextStyle(fontWeight: FontWeight.w800)), subtitle: const Text('Verified teachers with strong ratings appear first'), value: _expertOnly, onChanged: (value) => setState(() => _expertOnly = value)),
        ]))),
        const SizedBox(height: 12),
        Row(children: [const Icon(Icons.auto_awesome_rounded, size: 20), const SizedBox(width: 8), Text('${results.length} recommended results', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))]),
        const SizedBox(height: 10),
        if (results.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 48), child: Column(children: [Icon(Icons.search_off_rounded, size: 48), SizedBox(height: 12), Text('No matching teachers or classes yet.', style: TextStyle(fontWeight: FontWeight.w700)), SizedBox(height: 6), Text('Try another subject, standard or teacher filter.', textAlign: TextAlign.center)])) else ...results.map((item) => _LearnCard(item: item, onRate: () => _rate(item))),
        const SizedBox(height: 12),
        const Card(child: Padding(padding: EdgeInsets.all(16), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.verified_user_outlined), SizedBox(width: 12), Expanded(child: Text('Ratings influence discovery, but relevance and quality signals are also considered. MANOX should validate ratings server-side to reduce fake or duplicate reviews.'))]))),
      ]),
    );
  }
}

class _LearnCard extends StatelessWidget {
  final _LearnItem item;
  final VoidCallback onRate;
  const _LearnCard({required this.item, required this.onRate});
  @override
  Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(bottom: 10), child: InkWell(borderRadius: BorderRadius.circular(12), onTap: onRate, child: Padding(padding: const EdgeInsets.all(14), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    CircleAvatar(radius: 25, child: Icon(item.type == 'Teacher' ? Icons.person_rounded : Icons.menu_book_rounded)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text(item.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))), if (item.verified) const Icon(Icons.verified_rounded, size: 18)]),
      const SizedBox(height: 4), Text(item.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      if (item.type == 'Teacher') Padding(padding: const EdgeInsets.only(top: 4), child: Text('Standard ${item.standard}', style: const TextStyle(fontWeight: FontWeight.w700))),
      const SizedBox(height: 8), Row(children: [const Icon(Icons.star_rounded, size: 19), const SizedBox(width: 4), Text(item.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(width: 5), Text('(${item.reviews})'), const Spacer(), OutlinedButton(onPressed: onRate, child: const Text('Rate'))]),
    ])),
  ])));
}

class _LearnItem {
  final String type;
  final String title;
  final String subtitle;
  final String standard;
  final double rating;
  final int reviews;
  final bool verified;
  const _LearnItem({required this.type, required this.title, required this.subtitle, required this.standard, required this.rating, required this.reviews, required this.verified});
}

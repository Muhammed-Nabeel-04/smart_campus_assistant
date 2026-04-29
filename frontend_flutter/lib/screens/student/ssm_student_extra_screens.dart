import 'package:flutter/material.dart';
import '../../services/api_service.dart';

// ════════════════════════════════════════════════════════════════
// Form Timeline Screen
// ════════════════════════════════════════════════════════════════

class SSMFormTimelineScreen extends StatefulWidget {
  final int formId;
  const SSMFormTimelineScreen({required this.formId, super.key});

  @override
  State<SSMFormTimelineScreen> createState() => _SSMFormTimelineScreenState();
}

class _SSMFormTimelineScreenState extends State<SSMFormTimelineScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final d = await ApiService.ssmGetFormTimeline(widget.formId);
      setState(() { _data = d; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final status = _data?['status'] ?? 'draft';
    final stages = [
      ('draft', 'Draft', 'Form created'),
      ('submitted', 'Submitted', 'Awaiting mentor'),
      ('mentor_review', 'Mentor Review', 'Being checked'),
      ('hod_review', 'HOD Review', 'Final approval'),
      ('approved', 'Approved', 'Score locked'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Form Timeline')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(children: [
        ...stages.asMap().entries.map((e) {
          final i = e.key;
          final s = e.value;
          final isDone = _isStageDone(status, s.$1);
          return Row(children: [
            Column(children: [
              Icon(isDone ? Icons.check_circle : Icons.circle_outlined, color: isDone ? Colors.green : Colors.grey),
              if (i < stages.length - 1) Container(width: 2, height: 40, color: isDone ? Colors.green : Colors.grey),
            ]),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.$2, style: TextStyle(fontWeight: FontWeight.bold, color: isDone ? null : Colors.grey)),
              Text(s.$3, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 30),
            ]),
          ]);
        }),
      ])),
    );
  }
  bool _isStageDone(String current, String stage) {
    const order = ['draft', 'submitted', 'mentor_review', 'hod_review', 'approved'];
    return order.indexOf(current) >= order.indexOf(stage);
  }
}

// ════════════════════════════════════════════════════════════════
// Score Screen
// ════════════════════════════════════════════════════════════════

class SSMScoreScreen extends StatefulWidget {
  final int formId;
  const SSMScoreScreen({required this.formId, super.key});
  @override
  State<SSMScoreScreen> createState() => _SSMScoreScreenState();
}

class _SSMScoreScreenState extends State<SSMScoreScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final d = await ApiService.ssmGetScore(widget.formId);
      setState(() { _data = d; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final scores = _data?['scores'];
    if (scores == null) return const Scaffold(body: Center(child: Text('Score not found')));

    return Scaffold(
      appBar: AppBar(title: const Text('SSM Performance Score')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        _scoreHeader(scores),
        const SizedBox(height: 20),
        _cat('Academic', scores['academic'], Colors.blue),
        _cat('Development', scores['development'], Colors.green),
        _cat('Skill', scores['skill'], Colors.purple),
        _cat('Discipline', scores['discipline'], Colors.orange),
        _cat('Leadership', scores['leadership'], Colors.red),
      ])),
    );
  }

  Widget _scoreHeader(Map s) => Container(
    width: double.infinity, padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(16)),
    child: Column(children: [
      const Text('GRAND TOTAL', style: TextStyle(color: Colors.white70, fontSize: 12)),
      Text('${(s['grand_total'] ?? 0).toStringAsFixed(0)} / 500', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
      Row(mainAxisSize: MainAxisSize.min, children: List.generate(5, (i) => Icon(i < (s['star_rating'] ?? 0) ? Icons.star : Icons.star_border, color: Colors.white))),
    ]),
  );

  Widget _cat(String l, dynamic v, Color c) => Card(child: ListTile(
    title: Text(l),
    trailing: Text('${(v ?? 0).toInt()} / 100', style: TextStyle(color: c, fontWeight: FontWeight.bold)),
  ));
}

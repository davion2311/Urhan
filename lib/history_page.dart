// lib/history_page.dart
// ✅ TOP CAPSULES (Name/Serial/Phone) = ALWAYS BLACK TEXT
// ✅ Other texts: Light=Black, Dark=Master Gold Gradient

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings.dart';
import 'app_localizations.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with SingleTickerProviderStateMixin {
  static const String _prefsHistoryKey = 'history_records_v1';

  static const List<Color> masterGoldGradient = [
    Color(0xFFBF953F),
    Color(0xFFFCF6BA),
    Color(0xFFD4AF37),
    Color(0xFFBF953F),
  ];

  LinearGradient get _goldGrad => const LinearGradient(
        colors: masterGoldGradient,
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );

  late final AnimationController _shimmerCtl =
      AnimationController(vsync: this, duration: const Duration(seconds: 2));

  final TextEditingController _searchCtrl = TextEditingController();

  bool _gridMode = false;
  List<Map<String, dynamic>> _all = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _filtered = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _syncShimmer();
    AppSettings.shimmerVN.addListener(_syncShimmer);
    _searchCtrl.addListener(_applyFilter);
    _load();
  }

  void _syncShimmer() {
    final on = AppSettings.shimmerVN.value;
    if (on) {
      if (!_shimmerCtl.isAnimating) _shimmerCtl.repeat();
    } else {
      if (_shimmerCtl.isAnimating) _shimmerCtl.stop();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AppSettings.shimmerVN.removeListener(_syncShimmer);
    _searchCtrl.removeListener(_applyFilter);
    _searchCtrl.dispose();
    _shimmerCtl.dispose();
    super.dispose();
  }

  Future<List<dynamic>> _loadHistoryList() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsHistoryKey);
    try {
      final decoded = raw == null || raw.isEmpty ? [] : jsonDecode(raw);
      if (decoded is List) return decoded;
      return <dynamic>[];
    } catch (_) {
      return <dynamic>[];
    }
  }

  Future<void> _saveHistoryList(List<dynamic> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsHistoryKey, jsonEncode(list));
  }

  int _createdAtOf(dynamic x) {
    if (x is Map) {
      final v = x['createdAt'];
      if (v is int) return v;
      if (v is num) return v.toInt();
    }
    return 0;
  }

  Map<String, dynamic> _asMap(dynamic x) {
    if (x is Map) return x.cast<String, dynamic>();
    return <String, dynamic>{};
  }

  Future<void> _load() async {
    final list = await _loadHistoryList();
    final mapped = list.map(_asMap).where((m) => m.isNotEmpty).toList();

    if (!mounted) return;
    setState(() {
      _all = mapped;
      _applyFilter();
    });
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) {
      _filtered = List<Map<String, dynamic>>.from(_all);
      if (mounted) setState(() {});
      return;
    }

    bool matches(Map<String, dynamic> r) {
      final customer = (r['customer'] is Map)
          ? (r['customer'] as Map).cast<String, dynamic>()
          : <String, dynamic>{};
      final name = (customer['name'] ?? '').toString().toLowerCase();
      final phone = (customer['phone'] ?? '').toString().toLowerCase();
      final serial = (customer['serial'] ?? '').toString().toLowerCase();
      final tplName = (r['template_name'] ?? '').toString().toLowerCase();
      return name.contains(q) || phone.contains(q) || serial.contains(q) || tplName.contains(q);
    }

    _filtered = _all.where(matches).toList();
    if (mounted) setState(() {});
  }

  Future<void> _deleteRecord(int createdAt) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        title: const Text('Delete?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        content: const Text('کیا آپ واقعی یہ ریکارڈ ڈیلیٹ کرنا چاہتے ہیں؟', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (ok != true) return;

    final list = await _loadHistoryList();
    list.removeWhere((x) => _createdAtOf(x) == createdAt);
    await _saveHistoryList(list);
    await _load();
  }

  Future<void> _openRecord(Map<String, dynamic> r) async {
    final hasTemplateLayout = r['template_layout'] is List;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => hasTemplateLayout
            ? CustomHistoryDetail(historyRecord: r)
            : ByDefaultHistoryDetail(historyRecord: r),
      ),
    );

    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: AppSettings.languageCodeVN,
      builder: (context, code, _) {
        final locale = AppLocalizations.parseLocaleCode(code ?? 'ur');
        return Localizations.override(
          context: context,
          locale: locale,
          child: ValueListenableBuilder<bool>(
            valueListenable: AppSettings.darkModeVN,
            builder: (context, isDark, _) {
              final shimmerOn = AppSettings.shimmerVN.value;
              final loc = AppLocalizations.t(context);

              final pageBg = isDark ? Colors.black : Colors.white;

              return Directionality(
                textDirection: TextDirection.rtl,
                child: Scaffold(
                  backgroundColor: pageBg,
                  body: SafeArea(
                    child: Stack(
                      children: [
                        if (isDark)
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(gradient: _goldGrad),
                              child: Container(color: Colors.black.withOpacity(0.18)),
                            ),
                          )
                        else
                          Positioned.fill(
                            child: Container(color:Colors.white),
                          ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    width: 46,
                                    height: 46,
                                    child: InkWell(
                                      onTap: () => Navigator.pop(context),
                                      child: _GradientBorderBox(
                                        controller: _shimmerCtl,
                                        radius: 999,
                                        strokeWidth: 2.2,
                                        enabled: shimmerOn,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: _goldGrad,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.35),
                                                blurRadius: 12,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(Icons.arrow_back, color: Colors.black, size: 22),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _GradientBorderBox(
                                      controller: _shimmerCtl,
                                      radius: 999,
                                      strokeWidth: 2.2,
                                      enabled: shimmerOn,
                                      child: Container(
                                        height: 46,
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.white.withOpacity(0.35) : Colors.white.withOpacity(0.9),
                                          borderRadius: BorderRadius.circular(999),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.18),
                                              blurRadius: 12,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 14),
                                        child: Center(
                                          child: TextField(
                                            controller: _searchCtrl,
                                            cursorColor: Colors.black,
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 16,
                                            ),
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              isDense: true,
                                              hintText: 'نام / فون / سیریل سے تلاش کریں',
                                              hintStyle: TextStyle(
                                                color: Colors.black.withOpacity(0.55),
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  SizedBox(
                                    width: 46,
                                    height: 46,
                                    child: InkWell(
                                      onTap: () => setState(() => _gridMode = !_gridMode),
                                      child: _GradientBorderBox(
                                        controller: _shimmerCtl,
                                        radius: 999,
                                        strokeWidth: 2.2,
                                        enabled: shimmerOn,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: _goldGrad,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.35),
                                                blurRadius: 12,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            _gridMode ? Icons.view_list : Icons.grid_view_rounded,
                                            color: Colors.black,
                                            size: 22,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: _filtered.isEmpty
                                    ? Center(
                                        child: _GradientText(
                                          text: loc.tr('no_history') == 'no_history'
                                              ? 'کوئی ہسٹری نہیں ملی'
                                              : loc.tr('no_history'),
                                          isDark: isDark,
                                          shimmerCtl: _shimmerCtl,
                                          shimmerOn: shimmerOn,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                          ),
                                        ),
                                      )
                                    : _gridMode
                                        ? _gridList(shimmerOn, isDark)
                                        : _verticalList(shimmerOn, isDark),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _verticalList(bool shimmerOn, bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 10),
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final r = _filtered[i];
        return _historyCard(r, shimmerOn, isDark, compact: false);
      },
    );
  }

  Widget _gridList(bool shimmerOn, bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.55,
      ),
      itemCount: _filtered.length,
      itemBuilder: (context, i) {
        final r = _filtered[i];
        return _historyCard(r, shimmerOn, isDark, compact: true);
      },
    );
  }

  Widget _historyCard(Map<String, dynamic> r, bool shimmerOn, bool isDark, {required bool compact}) {
    final customer = (r['customer'] is Map)
        ? (r['customer'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    final name = (customer['name'] ?? '').toString().trim();
    final phone = (customer['phone'] ?? '').toString().trim();
    final serial = (customer['serial'] ?? '').toString().trim();

    final createdAt = _createdAtOf(r);
    final dt = DateTime.fromMillisecondsSinceEpoch(createdAt == 0 ? DateTime.now().millisecondsSinceEpoch : createdAt);
    final timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
    final dateStr = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

    final isCustom = r['template_layout'] is List;

    return InkWell(
      onTap: () => _openRecord(r),
      child: _GradientBorderBox(
        controller: _shimmerCtl,
        radius: 16,
        strokeWidth: 2.6,
        enabled: shimmerOn,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withOpacity(0.75) : Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: InkWell(
                  onTap: () => _deleteRecord(createdAt),
                  child: _GradientBorderBox(
                    controller: _shimmerCtl,
                    radius: 999,
                    strokeWidth: 2.2,
                    enabled: shimmerOn,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _goldGrad,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.delete_outline, color: Colors.black, size: 22),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _GradientText(
                      text: '${name.isEmpty ? '---' : name}   •   سیریل: ${serial.isEmpty ? '---' : serial}',
                      isDark: isDark,
                      shimmerCtl: _shimmerCtl,
                      shimmerOn: shimmerOn,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _GradientText(
                      text: 'فون: ${phone.isEmpty ? '---' : phone}   •   $timeStr  $dateStr',
                      isDark: isDark,
                      shimmerCtl: _shimmerCtl,
                      shimmerOn: shimmerOn,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 6),
                      _GradientText(
                        text: isCustom ? 'کسٹم ٹیمپلیٹ' : 'بائی ڈیفالٹ',
                        isDark: isDark,
                        shimmerCtl: _shimmerCtl,
                        shimmerOn: shimmerOn,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================== PART 2 START ===============================

class ByDefaultHistoryDetail extends StatefulWidget {
  final Map<String, dynamic> historyRecord;
  const ByDefaultHistoryDetail({super.key, required this.historyRecord});

  @override
  State<ByDefaultHistoryDetail> createState() => _ByDefaultHistoryDetailState();
}

class _ByDefaultHistoryDetailState extends State<ByDefaultHistoryDetail>
    with SingleTickerProviderStateMixin {
  static const String _prefsHistoryKey = 'history_records_v1';

  static const List<Color> masterGoldGradient = [
    Color(0xFFBF953F),
    Color(0xFFFCF6BA),
    Color(0xFFD4AF37),
    Color(0xFFBF953F),
  ];

  LinearGradient get _goldGrad => const LinearGradient(
        colors: masterGoldGradient,
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );

  late final AnimationController _shimmerCtl =
      AnimationController(vsync: this, duration: const Duration(seconds: 2));

  final _nameCtrl = TextEditingController();
  final _serialCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _editOn = false;

  int? _createdAt;

  static const List<String> _measurementKeys = [
    'length',
    'sleeve',
    'tera',
    'chest',
    'waist',
    'neck',
    'ghera',
    'half',
    'shalwar',
    'pancha',
    'cuff',
    'shoulder',
    'shalwar_aasan',
    'shalwar_ghera',
  ];

  late final Map<String, TextEditingController> _m = {
    for (final k in _measurementKeys) k: TextEditingController(),
  };

  List<List<Map<String, dynamic>>> _smallActionPairs = [
    [
      {'key': 'round', 'custom': null},
      {'key': 'square', 'custom': null},
    ],
    [
      {'key': 'half_bain', 'custom': null},
      {'key': 'full_bain', 'custom': null},
    ],
    [
      {'key': 'bain_square', 'custom': null},
      {'key': 'bain_round', 'custom': null},
    ],
    [
      {'key': 'normal_collar', 'custom': null},
      {'key': 'collar_tip_s', 'custom': null},
    ],
    [
      {'key': 'bain_patti_thin', 'custom': null},
      {'key': 'chaak_patti_kaaj', 'custom': null},
    ],
    [
      {'key': 'simple_double', 'custom': null},
      {'key': 'silky_double', 'custom': null},
    ],
    [
      {'key': 'kanta', 'custom': null},
      {'key': 'jaali', 'custom': null},
    ],
    [
      {'key': 'open_sleeves', 'custom': null},
      {'key': 'fancy_button', 'custom': null},
    ],
    [
      {'key': 'simple_pajama', 'custom': null},
      {'key': 'pocket_pajama', 'custom': null},
    ],
  ];

  List<Map<String, dynamic>> _bigActions = [
    {'key': 'one_front_one_side_shalwar', 'custom': null},
    {'key': 'one_front_two_side_shalwar', 'custom': null},
    {'key': 'one_side_one_shalwar', 'custom': null},
    {'key': 'two_side_one_shalwar', 'custom': null},
    {'key': 'two_side', 'custom': null},
  ];

  final Set<String> _selectedActionKeys = <String>{};

  @override
  void initState() {
    super.initState();
    _syncShimmer();
    AppSettings.shimmerVN.addListener(_syncShimmer);
    _hydrate();
  }

  void _syncShimmer() {
    final on = AppSettings.shimmerVN.value;
    if (on) {
      if (!_shimmerCtl.isAnimating) _shimmerCtl.repeat();
    } else {
      if (_shimmerCtl.isAnimating) _shimmerCtl.stop();
    }
    if (mounted) setState(() {});
  }

  void _hydrate() {
    final r = widget.historyRecord;
    _createdAt = (r['createdAt'] is int)
        ? (r['createdAt'] as int)
        : (r['createdAt'] is num)
            ? (r['createdAt'] as num).toInt()
            : null;

    final customer = (r['customer'] is Map)
        ? (r['customer'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};

    _nameCtrl.text = (customer['name'] ?? '').toString();
    _serialCtrl.text = (customer['serial'] ?? '').toString();
    _phoneCtrl.text = (customer['phone'] ?? '').toString();

    final meas = (r['measurements'] is Map)
        ? (r['measurements'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};

    for (final k in _measurementKeys) {
      _m[k]!.text = (meas[k] ?? '').toString();
    }

    _selectedActionKeys.clear();
    final acts = r['actions'];
    if (acts is List) {
      for (final a in acts) {
        final s = a.toString().trim();
        if (s.isNotEmpty) _selectedActionKeys.add(s);
      }
    }

    _editOn = false;
  }

  @override
  void dispose() {
    AppSettings.shimmerVN.removeListener(_syncShimmer);
    _nameCtrl.dispose();
    _serialCtrl.dispose();
    _phoneCtrl.dispose();
    for (final c in _m.values) {
      c.dispose();
    }
    _shimmerCtl.dispose();
    super.dispose();
  }

  Future<List<dynamic>> _loadHistoryList() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsHistoryKey);
    try {
      final decoded = raw == null || raw.isEmpty ? [] : jsonDecode(raw);
      if (decoded is List) return decoded;
      return <dynamic>[];
    } catch (_) {
      return <dynamic>[];
    }
  }

  Future<void> _saveHistoryList(List<dynamic> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsHistoryKey, jsonEncode(list));
  }

  int _createdAtOf(dynamic x) {
    if (x is Map) {
      final v = x['createdAt'];
      if (v is int) return v;
      if (v is num) return v.toInt();
    }
    return 0;
  }

  Map<String, dynamic> _buildUpdatedRecord() {
    final measurements = <String, String>{};
    for (final k in _measurementKeys) {
      measurements[k] = _m[k]!.text.trim();
    }

    return <String, dynamic>{
      ...widget.historyRecord,
      'createdAt': _createdAt ?? widget.historyRecord['createdAt'],
      'customer': {
        'name': _nameCtrl.text.trim(),
        'serial': _serialCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      },
      'measurements': measurements,
      'actions': _selectedActionKeys.toList(),
      'source': 'by_default',
    };
  }

  Future<void> _save() async {
    if (!_editOn) return;
    if (_createdAt == null) return;

    final list = await _loadHistoryList();
    int idx = -1;
    for (int i = 0; i < list.length; i++) {
      if (_createdAtOf(list[i]) == _createdAt) {
        idx = i;
        break;
      }
    }

    final updated = _buildUpdatedRecord();
    if (idx == -1) {
      list.insert(0, updated);
    } else {
      list[idx] = updated;
    }

    await _saveHistoryList(list);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('اپڈیٹ ہو گیا ✅'), backgroundColor: Colors.green),
    );
    setState(() => _editOn = false);
  }

  Future<void> _delete() async {
    if (_createdAt == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        title: const Text('Delete?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        content: const Text('کیا آپ واقعی یہ ریکارڈ ڈیلیٹ کرنا چاہتے ہیں؟', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (ok != true) return;

    final list = await _loadHistoryList();
    list.removeWhere((x) => _createdAtOf(x) == _createdAt);
    await _saveHistoryList(list);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ڈیلیٹ ہو گیا ✅'), backgroundColor: Colors.green),
    );
    Navigator.pop(context);
  }

  void _toggleAction(String key) {
    if (!_editOn) return;
    setState(() {
      if (_selectedActionKeys.contains(key)) {
        _selectedActionKeys.remove(key);
      } else {
        _selectedActionKeys.add(key);
      }
    });
  }

  String _actionLabel(AppLocalizations loc, Map<String, dynamic> item) {
    final custom = item['custom'];
    if (custom is String && custom.trim().isNotEmpty) return custom.trim();
    return loc.tr('a_${item['key']}');
  }

  String _measurementLabel(AppLocalizations loc, String key) => loc.tr('m_$key');

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: AppSettings.languageCodeVN,
      builder: (context, code, _) {
        final locale = AppLocalizations.parseLocaleCode(code ?? 'ur');
        return Localizations.override(
          context: context,
          locale: locale,
          child: ValueListenableBuilder<bool>(
            valueListenable: AppSettings.darkModeVN,
            builder: (context, isDark, _) {
              final shimmerOn = AppSettings.shimmerVN.value;
              final loc = AppLocalizations.t(context);

              return Directionality(
                textDirection: TextDirection.rtl,
                child: Scaffold(
                  backgroundColor: isDark ? Colors.black : Colors.white,
                  body: SafeArea(
                    child: LayoutBuilder(
                      builder: (context, c) {
                        const baseW = 390.0;
                        const baseH = 780.0;
                        final scale = math.min(c.maxWidth / baseW, c.maxHeight / baseH);

                        return Stack(
                          children: [
                            if (isDark)
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(gradient: _goldGrad),
                                  child: Container(color: Colors.black.withOpacity(0.18)),
                                ),
                              )
                            else
                              Positioned.fill(
                                child: Container(color: Colors.white),
                              ),
                            Center(
                              child: SizedBox(
                                width: baseW * scale,
                                height: baseH * scale,
                                child: FittedBox(
                                  fit: BoxFit.contain,
                                  child: SizedBox(
                                    width: baseW,
                                    height: baseH,
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              _topIconButton(
                                                icon: Icons.arrow_back,
                                                shimmerOn: shimmerOn,
                                                onTap: () => Navigator.pop(context),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                flex: 7,
                                                child: _topCapsuleField(
                                                  controller: _nameCtrl,
                                                  hintText: loc.name,
                                                  enabled: _editOn,
                                                  shimmerOn: shimmerOn,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                flex: 3,
                                                child: _topCapsuleField(
                                                  controller: _serialCtrl,
                                                  hintText: loc.serial,
                                                  enabled: _editOn,
                                                  shimmerOn: shimmerOn,
                                                  keyboardType: TextInputType.number,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              _topIconButton(
                                                icon: Icons.delete_outline,
                                                shimmerOn: shimmerOn,
                                                onTap: _delete,
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: _topCapsuleField(
                                                  controller: _phoneCtrl,
                                                  hintText: loc.phone,
                                                  enabled: _editOn,
                                                  shimmerOn: shimmerOn,
                                                  keyboardType: TextInputType.phone,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              _topIconButton(
                                                icon: _editOn ? Icons.check : Icons.edit,
                                                shimmerOn: shimmerOn,
                                                onTap: () async {
                                                  if (_editOn) {
                                                    await _save();
                                                  } else {
                                                    setState(() => _editOn = true);
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 14),
                                          Expanded(
                                            child: LayoutBuilder(
                                              builder: (context, inner) {
                                                const gap = 6.0;
                                                const idealH = 40.0;

                                                final available = inner.maxHeight;
                                                final totalIdeal = 14 * idealH + 13 * gap;
                                                final rowH = totalIdeal <= available
                                                    ? idealH
                                                    : ((available - 13 * gap) / 14).clamp(30.0, 40.0);

                                                return Directionality(
                                                  textDirection: TextDirection.ltr,
                                                  child: Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Expanded(
                                                        flex: 11,
                                                        child: _buildActionsColumn(
                                                          loc: loc,
                                                          rowH: rowH,
                                                          gap: gap,
                                                          shimmerOn: shimmerOn,
                                                          isDark: isDark,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        flex: 9,
                                                        child: Align(
                                                          alignment: Alignment.topRight,
                                                          child: _buildMeasureColumn(
                                                            loc: loc,
                                                            rowH: rowH,
                                                            gap: gap,
                                                            shimmerOn: shimmerOn,
                                                            isDark: isDark,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          _saveButtonBottom(shimmerOn: shimmerOn),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _saveButtonBottom({required bool shimmerOn}) {
    return InkWell(
      onTap: _editOn ? _save : null,
      child: Container(
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: _goldGrad,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Center(
          child: Text(
            _editOn ? 'تبدیلی محفوظ کریں' : 'ایڈٹ کے لیے پینسل دبائیں',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _topIconButton({
    required IconData icon,
    required bool shimmerOn,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 46,
      height: 46,
      child: InkWell(
        onTap: onTap,
        child: _GradientBorderBox(
          controller: _shimmerCtl,
          radius: 999,
          strokeWidth: 2.2,
          enabled: shimmerOn,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _goldGrad,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.black, size: 22),
          ),
        ),
      ),
    );
  }

  // ✅ TOP CAPSULES: ALWAYS BLACK TEXT (No gold shimmer)
  Widget _topCapsuleField({
    required TextEditingController controller,
    required String hintText,
    required bool enabled,
    required bool shimmerOn,
    TextInputType? keyboardType,
  }) {
    // ALWAYS BLACK - in both Light and Dark mode
    final baseField = TextField(
      controller: controller,
      readOnly: !enabled,
      keyboardType: keyboardType,
      cursorColor: Colors.black,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.2,
        color: Colors.black, // ✅ PERMANENTLY BLACK
      ),
      decoration: InputDecoration(
        border: InputBorder.none,
        isDense: true,
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.black.withOpacity(0.55), // ✅ Black hint
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    // No shimmer mask for top capsules - always clear black
    return _GradientBorderBox(
      controller: _shimmerCtl,
      radius: 999,
      strokeWidth: 2.2,
      enabled: shimmerOn,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          gradient: _goldGrad,
          borderRadius: const BorderRadius.all(Radius.circular(999)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.28),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Center(child: baseField), // ✅ Direct, no gold shimmer
      ),
    );
  }

  Widget _buildActionsColumn({
    required AppLocalizations loc,
    required double rowH,
    required double gap,
    required bool shimmerOn,
    required bool isDark,
  }) {
    final List<Widget> rows = [];

    for (int i = 0; i < _smallActionPairs.length; i++) {
      final a = _smallActionPairs[i][0];
      final b = _smallActionPairs[i][1];

      final aKey = a['key'] as String;
      final bKey = b['key'] as String;

      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: gap),
          child: SizedBox(
            height: rowH,
            child: Row(
              children: [
                Expanded(
                  child: _ActionPillHistory(
                    height: rowH,
                    label: _actionLabel(loc, a),
                    selected: _selectedActionKeys.contains(aKey),
                    onTap: () => _toggleAction(aKey),
                    shimmerCtl: _shimmerCtl,
                    goldGrad: _goldGrad,
                    shimmerOn: shimmerOn,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionPillHistory(
                    height: rowH,
                    label: _actionLabel(loc, b),
                    selected: _selectedActionKeys.contains(bKey),
                    onTap: () => _toggleAction(bKey),
                    shimmerCtl: _shimmerCtl,
                    goldGrad: _goldGrad,
                    shimmerOn: shimmerOn,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    for (int j = 0; j < _bigActions.length; j++) {
      final btn = _bigActions[j];
      final k = btn['key'] as String;

      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: j == _bigActions.length - 1 ? 0 : gap),
          child: SizedBox(
            height: rowH,
            child: _ActionPillHistory(
              height: rowH,
              label: _actionLabel(loc, btn),
              selected: _selectedActionKeys.contains(k),
              onTap: () => _toggleAction(k),
              shimmerCtl: _shimmerCtl,
              goldGrad: _goldGrad,
              shimmerOn: shimmerOn,
              isBig: true,
              isDark: isDark,
            ),
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _buildMeasureColumn({
    required AppLocalizations loc,
    required double rowH,
    required double gap,
    required bool shimmerOn,
    required bool isDark,
  }) {
    return Column(
      children: List.generate(_measurementKeys.length, (i) {
        final key = _measurementKeys[i];
        final ctrl = _m[key]!;
        final label = _measurementLabel(loc, key);

        return Padding(
          padding: EdgeInsets.only(bottom: i == _measurementKeys.length - 1 ? 0 : gap),
          child: _MeasureCapsuleHistory(
            height: rowH,
            label: label,
            controller: ctrl,
            shimmerCtl: _shimmerCtl,
            goldGrad: _goldGrad,
            enabled: _editOn,
            shimmerOn: shimmerOn,
            isDark: isDark,
          ),
        );
      }),
    );
  }
}

// =============================== PART 3 START ===============================

class CustomHistoryDetail extends StatefulWidget {
  final Map<String, dynamic> historyRecord;
  const CustomHistoryDetail({super.key, required this.historyRecord});

  @override
  State<CustomHistoryDetail> createState() => _CustomHistoryDetailState();
}

class _CustomHistoryDetailState extends State<CustomHistoryDetail> with SingleTickerProviderStateMixin {
  static const String _prefsHistoryKey = 'history_records_v1';

  static const List<Color> masterGoldGradient = [
    Color(0xFFBF953F),
    Color(0xFFFCF6BA),
    Color(0xFFD4AF37),
    Color(0xFFBF953F),
  ];

  LinearGradient get _goldGrad => const LinearGradient(
        colors: masterGoldGradient,
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );

  late final AnimationController _shimmerCtl =
      AnimationController(vsync: this, duration: const Duration(seconds: 2));

  final _nameCtrl = TextEditingController();
  final _serialCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _editOn = false;
  int? _createdAt;

  final Map<String, TextEditingController> _tf = <String, TextEditingController>{};
  final Set<String> _selectedActions = <String>{};

  List<Map<String, dynamic>> _layout = <Map<String, dynamic>>[];

  final GlobalKey _canvasKey = GlobalKey();
  Size _canvasSize = const Size(1, 1);

  @override
  void initState() {
    super.initState();
    _syncShimmer();
    AppSettings.shimmerVN.addListener(_syncShimmer);
    _hydrate();
  }

  void _syncShimmer() {
    final on = AppSettings.shimmerVN.value;
    if (on) {
      if (!_shimmerCtl.isAnimating) _shimmerCtl.repeat();
    } else {
      if (_shimmerCtl.isAnimating) _shimmerCtl.stop();
    }
    if (mounted) setState(() {});
  }

  void _hydrate() {
    final r = widget.historyRecord;

    _createdAt = (r['createdAt'] is int)
        ? (r['createdAt'] as int)
        : (r['createdAt'] is num)
            ? (r['createdAt'] as num).toInt()
            : null;

    final customer = (r['customer'] is Map)
        ? (r['customer'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};

    _nameCtrl.text = (customer['name'] ?? '').toString();
    _serialCtrl.text = (customer['serial'] ?? '').toString();
    _phoneCtrl.text = (customer['phone'] ?? '').toString();

    _layout = (r['template_layout'] is List)
        ? (r['template_layout'] as List).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList()
        : <Map<String, dynamic>>[];

    final meas = (r['measurements'] is Map)
        ? (r['measurements'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};

    _tf.clear();
    for (final item in _layout) {
      if (item['type'] == 'text_field') {
        final key = (item['label'] ?? '').toString();
        _tf[key] = TextEditingController(text: (meas[key] ?? '').toString());
      }
    }

    _selectedActions.clear();
    final acts = r['actions'];
    if (acts is List) {
      for (final a in acts) {
        final s = a.toString().trim();
        if (s.isNotEmpty) _selectedActions.add(s);
      }
    }

    _editOn = false;
  }

  @override
  void dispose() {
    AppSettings.shimmerVN.removeListener(_syncShimmer);
    _nameCtrl.dispose();
    _serialCtrl.dispose();
    _phoneCtrl.dispose();
    for (final c in _tf.values) {
      c.dispose();
    }
    _shimmerCtl.dispose();
    super.dispose();
  }

  void _captureCanvasSize() {
    final box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final newSize = box.size;
    if (_canvasSize != newSize) {
      if (mounted) {
        setState(() {
          _canvasSize = newSize;
        });
      }
    }
  }

  double _clampLeft(double left, double w) {
    final maxX = math.max(0.0, _canvasSize.width - w);
    return left.clamp(0.0, maxX).toDouble();
  }

  double _clampTop(double top, double h) {
    final maxY = math.max(0.0, _canvasSize.height - h);
    return top.clamp(0.0, maxY).toDouble();
  }

  Future<List<dynamic>> _loadHistoryList() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsHistoryKey);
    try {
      final decoded = raw == null || raw.isEmpty ? [] : jsonDecode(raw);
      if (decoded is List) return decoded;
      return <dynamic>[];
    } catch (_) {
      return <dynamic>[];
    }
  }

  Future<void> _saveHistoryList(List<dynamic> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsHistoryKey, jsonEncode(list));
  }

  int _createdAtOf(dynamic x) {
    if (x is Map) {
      final v = x['createdAt'];
      if (v is int) return v;
      if (v is num) return v.toInt();
    }
    return 0;
  }

  Map<String, dynamic> _buildUpdatedRecord() {
    final measurements = <String, String>{};
    for (final e in _tf.entries) {
      measurements[e.key] = e.value.text.trim();
    }

    return <String, dynamic>{
      ...widget.historyRecord,
      'createdAt': _createdAt ?? widget.historyRecord['createdAt'],
      'customer': {
        'name': _nameCtrl.text.trim(),
        'serial': _serialCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      },
      'measurements': measurements,
      'actions': _selectedActions.toList(),
      'template_layout': _layout,
      'source': 'custom_template_filled',
    };
  }

  Future<void> _save() async {
    if (!_editOn) return;
    if (_createdAt == null) return;

    final list = await _loadHistoryList();
    int idx = -1;
    for (int i = 0; i < list.length; i++) {
      if (_createdAtOf(list[i]) == _createdAt) {
        idx = i;
        break;
      }
    }

    final updated = _buildUpdatedRecord();
    if (idx == -1) {
      list.insert(0, updated);
    } else {
      list[idx] = updated;
    }

    await _saveHistoryList(list);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('اپڈیٹ ہو گیا ✅'), backgroundColor: Colors.green),
    );
    setState(() => _editOn = false);
  }

  Future<void> _delete() async {
    if (_createdAt == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        title: const Text('Delete?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        content: const Text('کیا آپ واقعی یہ ریکارڈ ڈیلیٹ کرنا چاہتے ہیں؟', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (ok != true) return;

    final list = await _loadHistoryList();
    list.removeWhere((x) => _createdAtOf(x) == _createdAt);
    await _saveHistoryList(list);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ڈیلیٹ ہو گیا ✅'), backgroundColor: Colors.green),
    );
    Navigator.pop(context);
  }

  void _toggleAction(String key) {
    if (!_editOn) return;
    setState(() {
      if (_selectedActions.contains(key)) {
        _selectedActions.remove(key);
      } else {
        _selectedActions.add(key);
      }
    });
  }

  String _displayLabel(AppLocalizations loc, Map<String, dynamic> item) {
    final type = (item['type'] ?? '').toString();
    final label = (item['label'] ?? '').toString();
    if (type == 'text_field') {
      if (label.startsWith('m_')) return loc.tr(label);
      if (_looksLikeKey(label)) return loc.tr('m_$label');
      return label;
    } else {
      if (label.startsWith('a_')) return loc.tr(label);
      if (_looksLikeKey(label)) return loc.tr('a_$label');
      return label;
    }
  }

  bool _looksLikeKey(String s) {
    if (s.isEmpty) return false;
    for (final ch in s.codeUnits) {
      final c = String.fromCharCode(ch);
      final ok = (c.compareTo('a') >= 0 && c.compareTo('z') <= 0) || c == '_' || (c.compareTo('0') >= 0 && c.compareTo('9') <= 0);
      if (!ok) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: AppSettings.languageCodeVN,
      builder: (context, code, _) {
        final locale = AppLocalizations.parseLocaleCode(code ?? 'ur');
        return Localizations.override(
          context: context,
          locale: locale,
          child: ValueListenableBuilder<bool>(
            valueListenable: AppSettings.darkModeVN,
            builder: (context, isDark, _) {
              final shimmerOn = AppSettings.shimmerVN.value;
              final loc = AppLocalizations.t(context);

              return Directionality(
                textDirection: TextDirection.rtl,
                child: Scaffold(
                  backgroundColor: isDark ? Colors.black : Colors.white,
                  body: SafeArea(
                    child: LayoutBuilder(
                      builder: (context, c) {
                        const baseW = 390.0;
                        const baseH = 780.0;
                        final scale = math.min(c.maxWidth / baseW, c.maxHeight / baseH);

                        return Stack(
                          children: [
                            if (isDark)
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(gradient: _goldGrad),
                                  child: Container(color: Colors.black.withOpacity(0.18)),
                                ),
                              )
                            else
                              Positioned.fill(
                                child: Container(color: Colors.white),
                              ),
                            Center(
                              child: SizedBox(
                                width: baseW * scale,
                                height: baseH * scale,
                                child: FittedBox(
                                  fit: BoxFit.contain,
                                  child: SizedBox(
                                    width: baseW,
                                    height: baseH,
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              _topIconButton(
                                                icon: Icons.arrow_back,
                                                shimmerOn: shimmerOn,
                                                onTap: () => Navigator.pop(context),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                flex: 7,
                                                child: _topCapsuleField(
                                                  controller: _nameCtrl,
                                                  hintText: loc.name,
                                                  enabled: _editOn,
                                                  shimmerOn: shimmerOn,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                flex: 3,
                                                child: _topCapsuleField(
                                                  controller: _serialCtrl,
                                                  hintText: loc.serial,
                                                  enabled: _editOn,
                                                  shimmerOn: shimmerOn,
                                                  keyboardType: TextInputType.number,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              _topIconButton(
                                                icon: Icons.delete_outline,
                                                shimmerOn: shimmerOn,
                                                onTap: _delete,
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: _topCapsuleField(
                                                  controller: _phoneCtrl,
                                                  hintText: loc.phone,
                                                  enabled: _editOn,
                                                  shimmerOn: shimmerOn,
                                                  keyboardType: TextInputType.phone,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              _topIconButton(
                                                icon: _editOn ? Icons.check : Icons.edit,
                                                shimmerOn: shimmerOn,
                                                onTap: () async {
                                                  if (_editOn) {
                                                    await _save();
                                                  } else {
                                                    setState(() => _editOn = true);
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Expanded(
                                            child: Container(
                                              key: _canvasKey,
                                              width: double.infinity,
                                              height: double.infinity,
                                              color: Colors.transparent,
                                              child: LayoutBuilder(
                                                builder: (context, _) {
                                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                                    _captureCanvasSize();
                                                  });

                                                  return Stack(
                                                    clipBehavior: Clip.none,
                                                    children: [
                                                      for (final item in _layout) _buildItem(item, loc, shimmerOn, isDark),
                                                    ],
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          InkWell(
                                            onTap: _editOn ? _save : null,
                                            child: Container(
                                              height: 54,
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                gradient: _goldGrad,
                                                borderRadius: BorderRadius.circular(999),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.35),
                                                    blurRadius: 18,
                                                    offset: const Offset(0, 12),
                                                  ),
                                                ],
                                              ),
                                              child: Center(
                                                child: Text(
                                                  _editOn ? 'تبدیلی محفوظ کریں' : 'ایڈٹ کے لیے پینسل دبائیں',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w900,
                                                    letterSpacing: 1.2,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildItem(Map<String, dynamic> item, AppLocalizations loc, bool shimmerOn, bool isDark) {
    final type = (item['type'] ?? '').toString();
    final rawLabel = (item['label'] ?? '').toString();
    final display = _displayLabel(loc, item);

    final w = (item['width'] is num) ? (item['width'] as num).toDouble() : 140.0;
    final h = (item['height'] is num) ? (item['height'] as num).toDouble() : 44.0;

    final left0 = (item['left'] is num) ? (item['left'] as num).toDouble() : 0.0;
    final top0 = (item['top'] is num) ? (item['top'] as num).toDouble() : 0.0;

    final left = _clampLeft(left0, w);
    final top = _clampTop(top0, h);

    if (type == 'text_field') {
      final ctrl = _tf.putIfAbsent(rawLabel, () => TextEditingController());
      return Positioned(
        left: left,
        top: top,
        width: w,
        height: h,
        child: _MeasureCapsuleCustom(
          height: h,
          label: display,
          controller: ctrl,
          shimmerCtl: _shimmerCtl,
          goldGrad: _goldGrad,
          shimmerOn: shimmerOn,
          enabled: _editOn,
          isDark: isDark,
          valueOnLeft: true,
        ),
      );
    } else {
      final isBig = (item['isBig'] == true);
      final selected = _selectedActions.contains(rawLabel);
      return Positioned(
        left: left,
        top: top,
        width: w,
        height: h,
        child: GestureDetector(
          onTap: () => _toggleAction(rawLabel),
          child: _ActionPillHistory(
            height: h,
            label: display,
            selected: selected,
            onTap: () => _toggleAction(rawLabel),
            shimmerCtl: _shimmerCtl,
            goldGrad: _goldGrad,
            shimmerOn: shimmerOn,
            isBig: isBig,
            isDark: isDark,
          ),
        ),
      );
    }
  }

  Widget _topIconButton({
    required IconData icon,
    required bool shimmerOn,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 46,
      height: 46,
      child: InkWell(
        onTap: onTap,
        child: _GradientBorderBox(
          controller: _shimmerCtl,
          radius: 999,
          strokeWidth: 2.2,
          enabled: shimmerOn,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _goldGrad,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.black, size: 22),
          ),
        ),
      ),
    );
  }

  // ✅ TOP CAPSULES: ALWAYS BLACK TEXT (No gold shimmer ever)
  Widget _topCapsuleField({
    required TextEditingController controller,
    required String hintText,
    required bool enabled,
    required bool shimmerOn,
    TextInputType? keyboardType,
  }) {
    // ALWAYS BLACK TEXT - No shimmer, no gold
    final baseField = TextField(
      controller: controller,
      readOnly: !enabled,
      keyboardType: keyboardType,
      cursorColor: Colors.black,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.2,
        color: Colors.black, // ✅ PERMANENTLY BLACK both modes
        shadows: [
          Shadow(
            blurRadius: 0.5,
            color: Colors.black,
            offset: Offset(0, 0),
          ),
        ], // ✅ Sharp black text
      ),
      decoration: InputDecoration(
        border: InputBorder.none,
        isDense: true,
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.black.withOpacity(0.6), // ✅ Darker hint for visibility
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    return _GradientBorderBox(
      controller: _shimmerCtl,
      radius: 999,
      strokeWidth: 2.2,
      enabled: shimmerOn,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          gradient: _goldGrad,
          borderRadius: const BorderRadius.all(Radius.circular(999)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.28),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Center(child: baseField), // ✅ No gold shimmer mask
      ),
    );
  }
}

// ======================= SHARED UI WIDGETS =======================

class _ActionPillHistory extends StatelessWidget {
  final double height;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final AnimationController shimmerCtl;
  final LinearGradient goldGrad;
  final bool shimmerOn;
  final bool isBig;
  final bool isDark;

  const _ActionPillHistory({
    required this.height,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.shimmerCtl,
    required this.goldGrad,
    required this.shimmerOn,
    required this.isDark,
    this.isBig = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? Colors.black.withOpacity(0.72) : Colors.grey.shade200;

    return GestureDetector(
      onTap: onTap,
      child: _GradientBorderBox(
        controller: shimmerCtl,
        radius: 999,
        strokeWidth: 2.0,
        enabled: shimmerOn,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: selected ? null : bg,
            borderRadius: const BorderRadius.all(Radius.circular(999)),
            gradient: selected ? goldGrad : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(
            horizontal: math.max(10, height * 0.15),
            vertical: math.max(4, height * 0.1),
          ),
          child: Center(
            child: selected
                ? Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isBig ? 14 : 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  )
                : _GradientText(
                    text: label,
                    isDark: isDark,
                    shimmerCtl: shimmerCtl,
                    shimmerOn: shimmerOn,
                    style: TextStyle(
                      fontSize: isBig ? 14 : 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _MeasureCapsuleHistory extends StatelessWidget {
  final double height;
  final String label;
  final TextEditingController controller;
  final AnimationController shimmerCtl;
  final LinearGradient goldGrad;
  final bool enabled;
  final bool shimmerOn;
  final bool isDark;

  const _MeasureCapsuleHistory({
    required this.height,
    required this.label,
    required this.controller,
    required this.shimmerCtl,
    required this.goldGrad,
    required this.enabled,
    required this.shimmerOn,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? Colors.black.withOpacity(0.72) : Colors.grey.shade200;

    final valueStyle = isDark
        ? const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: Color(0xFFD4AF37),
          )
        : const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          );

    final baseValueField = TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.text,
      textAlign: TextAlign.center,
      cursorColor: const Color(0xFFD4AF37),
      style: valueStyle,
      decoration: const InputDecoration(
        isDense: true,
        border: InputBorder.none,
        hintText: '',
        contentPadding: EdgeInsets.zero,
      ),
    );

    final valueChild = isDark
        ? _GoldShimmerMask(controller: shimmerCtl, child: baseValueField)
        : baseValueField;

    return _GradientBorderBox(
      controller: shimmerCtl,
      radius: 999,
      strokeWidth: 2.0,
      enabled: shimmerOn,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.all(Radius.circular(999)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            SizedBox(width: 70, child: valueChild),
            const SizedBox(width: 8),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: _GradientText(
                  text: label,
                  isDark: isDark,
                  shimmerCtl: shimmerCtl,
                  shimmerOn: shimmerOn,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeasureCapsuleCustom extends StatelessWidget {
  final double height;
  final String label;
  final TextEditingController controller;
  final AnimationController shimmerCtl;
  final LinearGradient goldGrad;
  final bool shimmerOn;
  final bool enabled;
  final bool isDark;
  final bool valueOnLeft;

  const _MeasureCapsuleCustom({
    required this.height,
    required this.label,
    required this.controller,
    required this.shimmerCtl,
    required this.goldGrad,
    required this.shimmerOn,
    required this.enabled,
    required this.isDark,
    required this.valueOnLeft,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? Colors.black.withOpacity(0.72) : Colors.grey.shade200;

    final valueStyle = isDark
        ? TextStyle(
            fontSize: math.max(14, height * 0.40),
            fontWeight: FontWeight.w900,
            color: const Color(0xFFD4AF37),
          )
        : TextStyle(
            fontSize: math.max(14, height * 0.40),
            fontWeight: FontWeight.w900,
            color: Colors.black,
          );

    final valueField = TextField(
      controller: controller,
      enabled: enabled,
      textAlign: TextAlign.center,
      cursorColor: const Color(0xFFD4AF37),
      style: valueStyle,
      decoration: const InputDecoration(
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
    );

    final valueChild = isDark
        ? _GoldShimmerMask(controller: shimmerCtl, child: valueField)
        : valueField;

    return _GradientBorderBox(
      controller: shimmerCtl,
      radius: 999,
      strokeWidth: 2.0,
      enabled: shimmerOn,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.all(Radius.circular(999)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 3,
              child: Align(
                alignment: Alignment.centerRight,
                child: _GradientText(
                  text: label,
                  isDark: isDark,
                  shimmerCtl: shimmerCtl,
                  shimmerOn: shimmerOn,
                  style: TextStyle(
                    fontSize: math.max(12, height * 0.30),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: valueChild,
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ Unified gradient text: Light=Black, Dark=Master Gold
class _GradientText extends StatelessWidget {
  final String text;
  final bool isDark;
  final AnimationController shimmerCtl;
  final bool shimmerOn;
  final TextStyle style;

  const _GradientText({
    required this.text,
    required this.isDark,
    required this.shimmerCtl,
    required this.shimmerOn,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    if (!isDark) {
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style.copyWith(color: Colors.black),
      );
    }

    final goldText = Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style.copyWith(color: Colors.white),
    );

    return _GoldShimmerMask(controller: shimmerCtl, child: goldText);
  }
}

class _GradientBorderBox extends StatelessWidget {
  final Widget child;
  final AnimationController controller;
  final double radius;
  final double strokeWidth;
  final bool enabled;

  const _GradientBorderBox({
    required this.child,
    required this.controller,
    required this.radius,
    required this.strokeWidth,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return CustomPaint(
        foregroundPainter: _GradientBorderPainter(t: 0.25, radius: radius, strokeWidth: strokeWidth),
        child: ClipRRect(borderRadius: BorderRadius.circular(radius), child: child),
      );
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return CustomPaint(
          foregroundPainter: _GradientBorderPainter(t: controller.value, radius: radius, strokeWidth: strokeWidth),
          child: ClipRRect(borderRadius: BorderRadius.circular(radius), child: child),
        );
      },
    );
  }
}

class _GradientBorderPainter extends CustomPainter {
  final double t;
  final double radius;
  final double strokeWidth;

  _GradientBorderPainter({required this.t, required this.radius, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final begin = Alignment(-1.0 + 2.0 * t, -0.2);
    final end = Alignment(begin.x + 1.2, 0.2);

    final shader = LinearGradient(
      begin: begin,
      end: end,
      colors: _HistoryPageState.masterGoldGradient,
      stops: const [0.0, 0.35, 0.65, 1.0],
    ).createShader(rect);

    final paint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rrect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      Radius.circular(radius),
    );

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _GradientBorderPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.radius != radius || oldDelegate.strokeWidth != strokeWidth;
  }
}

class _GoldShimmerMask extends StatelessWidget {
  final AnimationController controller;
  final Widget child;

  const _GoldShimmerMask({required this.controller, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final v = controller.value;
        final begin = Alignment(-1.0 + 2.0 * v, -0.2);
        final end = Alignment(begin.x + 1.2, 0.2);

        return ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              begin: begin,
              end: end,
              colors: const [
                Color(0xFFBF953F),
                Color(0xFFFCF6BA),
                Color(0xFFD4AF37),
                Color(0xFFBF953F),
              ],
              stops: const [0.0, 0.35, 0.65, 1.0],
            ).createShader(rect);
          },
          blendMode: BlendMode.srcIn,
          child: child,
        );
      },
    );
  }
}
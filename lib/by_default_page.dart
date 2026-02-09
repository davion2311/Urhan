// lib/by_default_page.dart
// ✅ UI layout same (NO position changes)
// ✅ Real-time language change via AppSettings.languageCodeVN (35 languages)
// ✅ NO RTL/LTR system usage (layout direction FIXED)
// ✅ History safe: measurements/actions saved by KEYS (not translated text)

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings.dart';
import 'app_localizations.dart';

class ByDefaultPage extends StatefulWidget {
  final bool openFromHistory;
  final Map<String, dynamic>? historyRecord;
  final bool historyEditable;

  const ByDefaultPage({
    super.key,
    this.openFromHistory = false,
    this.historyRecord,
    this.historyEditable = false,
  });

  @override
  State<ByDefaultPage> createState() => _ByDefaultPageState();
}

class _ByDefaultPageState extends State<ByDefaultPage>
    with SingleTickerProviderStateMixin {
  // ✅ Master Gold Gradient
  static const List<Color> masterGoldGradient = [
    Color(0xFFBF953F),
    Color(0xFFFCF6BA),
    Color(0xFFD4AF37),
    Color(0xFFBF953F),
  ];

  static const Color _masterGold = Color(0xFFD4AF37);

  LinearGradient get _goldGrad => const LinearGradient(
        colors: masterGoldGradient,
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );

  // Controllers
  final _nameCtrl = TextEditingController();
  final _serialCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // ================== NEW: FIXED KEYS (History-safe) ==================
  // Measurements KEYS (14)
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

  // Measurements controllers by KEY (14)
  late final Map<String, TextEditingController> _m = {
    for (final k in _measurementKeys) k: TextEditingController(),
  };

  // Small Actions KEYS (18 -> 9 pairs)
  // NOTE: We keep "editable" behavior, but edit will override translation (custom label).
  List<List<Map<String, dynamic>>> _smallActionPairs = [
    [
      {'key': 'round', 'custom': null, 'editable': true},
      {'key': 'square', 'custom': null, 'editable': true},
    ],
    [
      {'key': 'half_bain', 'custom': null, 'editable': true},
      {'key': 'full_bain', 'custom': null, 'editable': true},
    ],
    [
      {'key': 'bain_square', 'custom': null, 'editable': true},
      {'key': 'bain_round', 'custom': null, 'editable': true},
    ],
    [
      {'key': 'normal_collar', 'custom': null, 'editable': true},
      {'key': 'collar_tip_s', 'custom': null, 'editable': true},
    ],
    [
      {'key': 'bain_patti_thin', 'custom': null, 'editable': true},
      {'key': 'chaak_patti_kaaj', 'custom': null, 'editable': true},
    ],
    [
      {'key': 'simple_double', 'custom': null, 'editable': true},
      {'key': 'silky_double', 'custom': null, 'editable': true},
    ],
    [
      {'key': 'kanta', 'custom': null, 'editable': true},
      {'key': 'jaali', 'custom': null, 'editable': true},
    ],
    [
      {'key': 'open_sleeves', 'custom': null, 'editable': true},
      {'key': 'fancy_button', 'custom': null, 'editable': true},
    ],
    [
      {'key': 'simple_pajama', 'custom': null, 'editable': true},
      {'key': 'pocket_pajama', 'custom': null, 'editable': true},
    ],
  ];

  // Big Actions KEYS (5)
  List<Map<String, dynamic>> _bigActions = [
    {'key': 'one_front_one_side_shalwar', 'custom': null, 'editable': true},
    {'key': 'one_front_two_side_shalwar', 'custom': null, 'editable': true},
    {'key': 'one_side_one_shalwar', 'custom': null, 'editable': true},
    {'key': 'two_side_one_shalwar', 'custom': null, 'editable': true},
    {'key': 'two_side', 'custom': null, 'editable': true},
  ];

  // Selected actions are stored by KEY (history-safe)
  final Set<String> _selectedActionKeys = <String>{};

  // shimmer controller (runs only when shimmerOn)
  late final AnimationController _shimmerCtl =
      AnimationController(vsync: this, duration: const Duration(seconds: 2));

  // ================== HISTORY STORAGE ==================
  static const String _prefsHistoryKey = 'history_records_v1';

  int? _openedHistoryCreatedAt;

  bool get _viewOnly => widget.openFromHistory && !widget.historyEditable;

  // ================== BACKWARD COMPAT (old Urdu text -> keys) ==================
  // If you already have old history saved with Urdu labels, we auto-map it.
  static const Map<String, String> _oldUrduMeasurementToKey = {
    'لمبائی': 'length',
    'بازو': 'sleeve',
    'تیرا': 'tera',
    'چھاتی': 'chest',
    'کمر': 'waist',
    'گلا': 'neck',
    'گھیرا': 'ghera',
    'ہاف': 'half',
    'شلوار': 'shalwar',
    'پانچہ': 'pancha',
    'کف': 'cuff',
    'کندھا': 'shoulder',
    'شلوار آسن': 'shalwar_aasan',
    'شلوار گھیرا': 'shalwar_ghera',
  };

  static const Map<String, String> _oldUrduActionToKey = {
    'گول': 'round',
    'چورس': 'square',
    'بین ہاف': 'half_bain',
    'فل بین': 'full_bain',
    'بین چورس': 'bain_square',
    'بین گول': 'bain_round',
    'نارمل کالر': 'normal_collar',
    'کالر نوک S': 'collar_tip_s',
    'بین پٹی باریک': 'bain_patti_thin',
    'چاک پٹی کاج': 'chaak_patti_kaaj',
    'سمپل ڈبل': 'simple_double',
    'ریشمی ڈبل': 'silky_double',
    'کانٹا': 'kanta',
    'جالی': 'jaali',
    'کھلے بازو': 'open_sleeves',
    'فینس بٹن': 'fancy_button',
    'سمپل پاجامہ': 'simple_pajama',
    'پاکٹ پاجامہ': 'pocket_pajama',

    'ایک سامنے ایک سائیڈ شلوار': 'one_front_one_side_shalwar',
    'ایک سامنے دو سائیڈ شلوار': 'one_front_two_side_shalwar',
    'ایک سائیڈ ایک شلوار': 'one_side_one_shalwar',
    'دو سائیڈ ایک شلوار': 'two_side_one_shalwar',
    'دو سائیڈ': 'two_side',
  };

  @override
  void initState() {
    super.initState();
    _hydrateFromHistoryIfNeeded();

    _syncShimmer();
    AppSettings.shimmerVN.addListener(_syncShimmer);
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

    _nameCtrl.dispose();
    _serialCtrl.dispose();
    _phoneCtrl.dispose();
    for (final c in _m.values) {
      c.dispose();
    }
    _shimmerCtl.dispose();
    super.dispose();
  }

  // ================== HISTORY HYDRATE ==================
  void _hydrateFromHistoryIfNeeded() {
    if (!widget.openFromHistory) return;
    final r = widget.historyRecord;
    if (r == null) return;

    final createdAt = r['createdAt'];
    if (createdAt is int) _openedHistoryCreatedAt = createdAt;
    if (createdAt is num) _openedHistoryCreatedAt = createdAt.toInt();

    final customer = (r['customer'] is Map)
        ? (r['customer'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};

    _nameCtrl.text = (customer['name'] ?? '').toString();
    _serialCtrl.text = (customer['serial'] ?? '').toString();
    _phoneCtrl.text = (customer['phone'] ?? '').toString();

    final meas = (r['measurements'] is Map)
        ? (r['measurements'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};

    // NEW: measurements stored by KEY
    // OLD: measurements stored by Urdu label -> convert
    for (final key in _measurementKeys) {
      final v = meas[key];
      if (v != null) {
        _m[key]!.text = v.toString();
        continue;
      }

      // backward compatibility
      final oldUr = _oldUrduMeasurementToKey.entries
          .firstWhere(
            (e) => e.value == key,
            orElse: () => const MapEntry('', ''),
          )
          .key;
      if (oldUr.isNotEmpty && meas[oldUr] != null) {
        _m[key]!.text = meas[oldUr].toString();
      }
    }

    _selectedActionKeys.clear();
    final acts = r['actions'];
    if (acts is List) {
      for (final a in acts) {
        final s = a.toString().trim();
        if (s.isEmpty) continue;

        // NEW: key is already stored
        if (_isKnownActionKey(s)) {
          _selectedActionKeys.add(s);
          continue;
        }

        // OLD: Urdu text -> key
        final mapped = _oldUrduActionToKey[s];
        if (mapped != null) _selectedActionKeys.add(mapped);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  bool _isKnownActionKey(String k) {
    for (final row in _smallActionPairs) {
      for (final item in row) {
        if (item['key'] == k) return true;
      }
    }
    for (final item in _bigActions) {
      if (item['key'] == k) return true;
    }
    return false;
  }

  // ================== HISTORY BUILD RECORD ==================
  Map<String, dynamic> _buildHistoryRecord({int? createdAtOverride}) {
    final measurements = <String, String>{};
    for (final k in _measurementKeys) {
      measurements[k] = _m[k]!.text.trim();
    }

    final createdAt = createdAtOverride ?? DateTime.now().millisecondsSinceEpoch;

    return <String, dynamic>{
      'source': 'by_default',
      'createdAt': createdAt,
      'customer': {
        'name': _nameCtrl.text.trim(),
        'serial': _serialCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      },
      'measurements': measurements, // ✅ keys-based
      'actions': _selectedActionKeys.toList(), // ✅ keys-based
    };
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

  Future<void> _appendToHistory(Map<String, dynamic> record) async {
    final list = await _loadHistoryList();
    list.insert(0, record); // newest first
    await _saveHistoryList(list);
  }

  int _createdAtOf(dynamic x) {
    if (x is Map) {
      final v = x['createdAt'];
      if (v is int) return v;
      if (v is num) return v.toInt();
    }
    return 0;
  }

  Future<void> _updateHistoryRecord(int createdAt, Map<String, dynamic> updated) async {
    final list = await _loadHistoryList();

    int idx = -1;
    for (int i = 0; i < list.length; i++) {
      if (_createdAtOf(list[i]) == createdAt) {
        idx = i;
        break;
      }
    }

    if (idx == -1) {
      list.insert(0, updated);
    } else {
      list[idx] = updated;
    }

    await _saveHistoryList(list);
  }

  Future<void> _deleteHistoryRecord(int createdAt) async {
    final list = await _loadHistoryList();
    list.removeWhere((x) => _createdAtOf(x) == createdAt);
    await _saveHistoryList(list);
  }

  void _clearByDefaultForm() {
    _nameCtrl.clear();
    _serialCtrl.clear();
    _phoneCtrl.clear();
    for (final c in _m.values) {
      c.clear();
    }
    _selectedActionKeys.clear();
  }

  // OCR camera - TEMPORARILY DISABLED
  Future<void> _openCameraScanner() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📸 کیمرہ سکینر فی الحال دستیاب نہیں ہے'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _save() async {
    try {
      if (widget.openFromHistory) {
        if (!widget.historyEditable || _openedHistoryCreatedAt == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('View mode ہے (Edit کے لیے پینسل دبائیں)'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        final updated =
            _buildHistoryRecord(createdAtOverride: _openedHistoryCreatedAt);
        await _updateHistoryRecord(_openedHistoryCreatedAt!, updated);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('History اپڈیٹ ہو گئی ✅'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
        return;
      }

      final record = _buildHistoryRecord();
      await _appendToHistory(record);

      if (!mounted) return;

      setState(() {
        _clearByDefaultForm();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('History میں محفوظ ہو گیا ✅'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteFromHistory() async {
    if (!widget.openFromHistory || _openedHistoryCreatedAt == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Delete?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'کیا آپ واقعی یہ ریکارڈ ڈیلیٹ کرنا چاہتے ہیں؟',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await _deleteHistoryRecord(_openedHistoryCreatedAt!);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ڈیلیٹ ہو گیا ✅'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  void _toggleActionKey(String key) {
    if (_viewOnly) return;
    setState(() {
      if (_selectedActionKeys.contains(key)) {
        _selectedActionKeys.remove(key);
      } else {
        _selectedActionKeys.add(key);
      }
    });
  }

  // Returns label for action by key (translation OR custom override)
  String _actionLabel(AppLocalizations loc, Map<String, dynamic> item) {
    final custom = item['custom'];
    if (custom is String && custom.trim().isNotEmpty) return custom.trim();
    return loc.tr('a_${item['key']}');
  }

  // Returns label for measurement by key (translation)
  String _measurementLabel(AppLocalizations loc, String key) {
    return loc.tr('m_$key');
  }

  Future<void> _editButtonText(int type, int rowIndex, int colIndex, AppLocalizations loc) async {
    if (_viewOnly) return;

    Map<String, dynamic> item;
    if (type == 0) {
      item = _smallActionPairs[rowIndex][colIndex];
    } else {
      item = _bigActions[rowIndex];
    }

    final currentText = _actionLabel(loc, item);
    final editCtrl = TextEditingController(text: currentText);

    final newText = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        title: const Text('بٹن ایڈٹ کریں', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: editCtrl,
          autofocus: true,
          keyboardType: TextInputType.text,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'نیا متن درج کریں',
            hintStyle: const TextStyle(color: Colors.grey),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.yellow[700]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.yellow[700]!, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('منسوخ', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, editCtrl.text.trim()),
            child: const Text('محفوظ کریں',
                style: TextStyle(color: Colors.yellow)),
          ),
        ],
      ),
    );

    if (newText != null) {
      setState(() {
        // If empty -> remove custom override so translations work again
        item['custom'] = newText.trim().isEmpty ? null : newText.trim();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Real-time language change:
    // We override locale locally using AppSettings.languageCodeVN, so ByDefault updates immediately.
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
              final loc = AppLocalizations.t(context);
              final shimmerOn = AppSettings.shimmerVN.value;

              final pageBg = isDark ? Colors.black : Colors.white;
              final cardBg = isDark ? const Color(0xFF0A0A0A) : Colors.white;
              final textMain = isDark ? _masterGold : Colors.black;

              // ✅ Direction fixed (NO RTL/LTR system usage)
              return Directionality(
                textDirection: TextDirection.rtl, // (fixed) same UI as your screenshot
                child: Scaffold(
                  backgroundColor: pageBg,
                  resizeToAvoidBottomInset: true,
                  body: SafeArea(
                    child: LayoutBuilder(
                      builder: (context, c) {
                        const baseW = 390.0;
                        const baseH = 780.0;
                        final scale =
                            math.min(c.maxWidth / baseW, c.maxHeight / baseH);

                        return Center(
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
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      _topRowNameSerial(
                                        loc: loc,
                                        isDark: isDark,
                                        shimmerOn: shimmerOn,
                                        textMain: textMain,
                                        cardBg: cardBg,
                                      ),
                                      const SizedBox(height: 10),
                                      _rowPhoneScanner(
                                        loc: loc,
                                        isDark: isDark,
                                        shimmerOn: shimmerOn,
                                        textMain: textMain,
                                        cardBg: cardBg,
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
                                                : ((available - 13 * gap) / 14)
                                                    .clamp(30.0, 40.0);

                                            // ✅ keep inner row direction fixed to preserve layout
                                            return Directionality(
                                              textDirection: TextDirection.ltr,
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    flex: 11,
                                                    child: _buildActionsColumn(
                                                      loc: loc,
                                                      rowH: rowH,
                                                      gap: gap,
                                                      isDark: isDark,
                                                      shimmerOn: shimmerOn,
                                                      textMain: textMain,
                                                      cardBg: cardBg,
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
                                                        isDark: isDark,
                                                        shimmerOn: shimmerOn,
                                                        textMain: textMain,
                                                        cardBg: cardBg,
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
                                      _saveButton(
                                        loc: loc,
                                        isDark: isDark,
                                        shimmerOn: shimmerOn,
                                        textMain: textMain,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
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

  Widget _topRowNameSerial({
    required AppLocalizations loc,
    required bool isDark,
    required bool shimmerOn,
    required Color textMain,
    required Color cardBg,
  }) {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.of(context).pop(),
          child: SizedBox(
            width: 46,
            height: 46,
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
                      color: (isDark ? Colors.black54 : Colors.black26),
                      blurRadius: 12,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.black,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
        if (widget.openFromHistory) ...[
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              if (_openedHistoryCreatedAt == null) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => ByDefaultPage(
                    openFromHistory: true,
                    historyRecord: widget.historyRecord,
                    historyEditable: true,
                  ),
                ),
              );
            },
            child: SizedBox(
              width: 46,
              height: 46,
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
                        color: (isDark ? Colors.black54 : Colors.black26),
                        blurRadius: 12,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _deleteFromHistory,
            child: SizedBox(
              width: 46,
              height: 46,
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
                        color: (isDark ? Colors.black54 : Colors.black26),
                        blurRadius: 12,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.black,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(width: 10),
        Expanded(
          flex: 7,
          child: _topCapsuleField(
            controller: _nameCtrl,
            hintText: loc.name, // ✅ localized
            enabled: !_viewOnly,
            isDark: isDark,
            shimmerOn: shimmerOn,
            textMain: textMain,
            cardBg: cardBg,
            keyboardType: TextInputType.name,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: _topCapsuleField(
            controller: _serialCtrl,
            hintText: loc.serial, // ✅ localized
            enabled: !_viewOnly,
            isDark: isDark,
            shimmerOn: shimmerOn,
            textMain: textMain,
            cardBg: cardBg,
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  Widget _rowPhoneScanner({
    required AppLocalizations loc,
    required bool isDark,
    required bool shimmerOn,
    required Color textMain,
    required Color cardBg,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 7,
          child: _topCapsuleField(
            controller: _phoneCtrl,
            hintText: loc.phone, // ✅ localized
            enabled: !_viewOnly,
            isDark: isDark,
            shimmerOn: shimmerOn,
            textMain: textMain,
            cardBg: cardBg,
            keyboardType: TextInputType.phone,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: Align(
            alignment: Alignment.centerRight,
            child: IgnorePointer(
              ignoring: true,
              child: Opacity(
                opacity: 0.5,
                child: InkWell(
                  onTap: _openCameraScanner,
                  child: SizedBox(
                    height: 46,
                    width: 46,
                    child: _GradientBorderBox(
                      controller: _shimmerCtl,
                      radius: 999,
                      strokeWidth: 2.4,
                      enabled: shimmerOn,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _goldGrad,
                          boxShadow: [
                            BoxShadow(
                              color: (isDark ? Colors.black54 : Colors.black26),
                              blurRadius: 12,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _topCapsuleField({
    required TextEditingController controller,
    required String hintText,
    required bool enabled,
    required bool isDark,
    required bool shimmerOn,
    required Color textMain,
    required Color cardBg,
    TextInputType? keyboardType,
  }) {
    final valueColor = isDark ? _masterGold : Colors.black;

    final baseField = TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      cursorColor: _masterGold,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.2,
        color: valueColor,
      ),
      decoration: InputDecoration(
        border: InputBorder.none,
        isDense: true,
        hintText: hintText,
        hintStyle: TextStyle(
          color: (isDark ? _masterGold : Colors.black).withOpacity(isDark ? 0.65 : 0.55),
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    final valueChild = (isDark && shimmerOn)
        ? _GoldShimmerMask(
            controller: _shimmerCtl,
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: Colors.white),
              child: baseField,
            ),
          )
        : baseField;

    return _GradientBorderBox(
      controller: _shimmerCtl,
      radius: 999,
      strokeWidth: 2.2,
      enabled: shimmerOn,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.all(Radius.circular(999)),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black54 : Colors.black12),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Center(child: valueChild),
      ),
    );
  }

  Widget _buildActionsColumn({
    required AppLocalizations loc,
    required double rowH,
    required double gap,
    required bool isDark,
    required bool shimmerOn,
    required Color textMain,
    required Color cardBg,
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
                  child: _ActionPill(
                    height: rowH,
                    label: _actionLabel(loc, a),
                    selected: _selectedActionKeys.contains(aKey),
                    onTap: () => _toggleActionKey(aKey),
                    onLongPress: () => _editButtonText(0, i, 0, loc),
                    shimmerCtl: _shimmerCtl,
                    goldGrad: _goldGrad,
                    disabled: _viewOnly,
                    isDark: isDark,
                    shimmerOn: shimmerOn,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionPill(
                    height: rowH,
                    label: _actionLabel(loc, b),
                    selected: _selectedActionKeys.contains(bKey),
                    onTap: () => _toggleActionKey(bKey),
                    onLongPress: () => _editButtonText(0, i, 1, loc),
                    shimmerCtl: _shimmerCtl,
                    goldGrad: _goldGrad,
                    disabled: _viewOnly,
                    isDark: isDark,
                    shimmerOn: shimmerOn,
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
            child: _ActionPill(
              height: rowH,
              label: _actionLabel(loc, btn),
              selected: _selectedActionKeys.contains(k),
              onTap: () => _toggleActionKey(k),
              onLongPress: () => _editButtonText(1, j, -1, loc),
              shimmerCtl: _shimmerCtl,
              goldGrad: _goldGrad,
              disabled: _viewOnly,
              isBig: true,
              isDark: isDark,
              shimmerOn: shimmerOn,
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
    required bool isDark,
    required bool shimmerOn,
    required Color textMain,
    required Color cardBg,
  }) {
    return Column(
      children: List.generate(_measurementKeys.length, (i) {
        final key = _measurementKeys[i];
        final ctrl = _m[key]!;
        final label = _measurementLabel(loc, key);

        return Padding(
          padding: EdgeInsets.only(bottom: i == _measurementKeys.length - 1 ? 0 : gap),
          child: _MeasureCapsule(
            height: rowH,
            label: label,
            controller: ctrl,
            shimmerCtl: _shimmerCtl,
            goldGrad: _goldGrad,
            enabled: !_viewOnly,
            isDark: isDark,
            shimmerOn: shimmerOn,
          ),
        );
      }),
    );
  }

  Widget _saveButton({
    required AppLocalizations loc,
    required bool isDark,
    required bool shimmerOn,
    required Color textMain,
  }) {
    final btnText = widget.openFromHistory
        ? (widget.historyEditable ? loc.update : loc.view)
        : loc.save;

    return InkWell(
      onTap: _save,
      child: Container(
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: _goldGrad,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black54 : Colors.black26),
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Center(
          child: _AdaptiveShimmerText(
            text: btnText, // ✅ localized
            controller: _shimmerCtl,
            shimmerOn: shimmerOn,
            isDark: true,
            baseStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.2,
              color: Colors.black,
            ),
            baseColorLightMode: Colors.black,
          ),
        ),
      ),
    );
  }
}

// ================== REST OF YOUR UI WIDGETS (UNCHANGED) ==================
// _ActionPill, _MeasureCapsule, _GradientBorderBox, _GradientBorderPainter,
// _GoldShimmerMask, _AdaptiveShimmerText
// ✅ below code is same as your original (no layout changes)

class _ActionPill extends StatelessWidget {
  final double height;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final AnimationController shimmerCtl;
  final LinearGradient goldGrad;
  final bool isBig;
  final bool disabled;

  final bool isDark;
  final bool shimmerOn;

  const _ActionPill({
    required this.height,
    required this.label,
    required this.selected,
    required this.onTap,
    this.onLongPress,
    required this.shimmerCtl,
    required this.goldGrad,
    this.isBig = false,
    this.disabled = false,
    required this.isDark,
    required this.shimmerOn,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF0A0A0A) : Colors.white;
    final shadow = isDark ? Colors.black54 : Colors.black12;

    return GestureDetector(
      onTap: disabled ? null : onTap,
      onLongPress: disabled ? null : onLongPress,
      child: Opacity(
        opacity: disabled ? 0.65 : 1.0,
        child: _GradientBorderBox(
          controller: shimmerCtl,
          radius: 999,
          strokeWidth: 2.0,
          enabled: shimmerOn,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.all(Radius.circular(999)),
              gradient: selected ? goldGrad : null,
              boxShadow: [
                BoxShadow(
                  color: shadow,
                  blurRadius: 12,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Center(
              child: selected
                  ? FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: isBig ? 14 : 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    )
                  : _AdaptiveShimmerText(
                      text: label,
                      controller: shimmerCtl,
                      shimmerOn: shimmerOn,
                      isDark: isDark,
                      baseStyle: TextStyle(
                        fontSize: isBig ? 14 : 13,
                        fontWeight: FontWeight.w900,
                        color: isDark ? const Color(0xFFD4AF37) : Colors.black,
                      ),
                      baseColorLightMode: Colors.black,
                      fitDown: true,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MeasureCapsule extends StatelessWidget {
  final double height;
  final String label;
  final TextEditingController controller;
  final AnimationController shimmerCtl;
  final LinearGradient goldGrad;
  final bool enabled;

  final bool isDark;
  final bool shimmerOn;

  const _MeasureCapsule({
    required this.height,
    required this.label,
    required this.controller,
    required this.shimmerCtl,
    required this.goldGrad,
    required this.enabled,
    required this.isDark,
    required this.shimmerOn,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF0A0A0A) : Colors.white;
    final shadow = isDark ? Colors.black54 : Colors.black12;

    final valueColor = isDark ? const Color(0xFFD4AF37) : Colors.black;

    final baseValueField = TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.text,
      textAlign: TextAlign.center,
      cursorColor: const Color(0xFFD4AF37),
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w900,
        color: valueColor,
      ),
      decoration: const InputDecoration(
        isDense: true,
        border: InputBorder.none,
        hintText: '',
      ),
    );

    final valueChild = (isDark && shimmerOn)
        ? _GoldShimmerMask(
            controller: shimmerCtl,
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: Colors.white),
              child: baseValueField,
            ),
          )
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
              color: shadow,
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              child: valueChild,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: _AdaptiveShimmerText(
                  text: label,
                  controller: shimmerCtl,
                  shimmerOn: shimmerOn,
                  isDark: isDark,
                  baseStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: isDark ? const Color(0xFFD4AF37) : Colors.black,
                  ),
                  baseColorLightMode: Colors.black,
                  fitDown: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- The rest widgets are exactly same as your original code ----

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
        foregroundPainter: _GradientBorderPainter(
          t: 0.25,
          radius: radius,
          strokeWidth: strokeWidth,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: child,
        ),
      );
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return CustomPaint(
          foregroundPainter: _GradientBorderPainter(
            t: controller.value,
            radius: radius,
            strokeWidth: strokeWidth,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: child,
          ),
        );
      },
    );
  }
}

class _GradientBorderPainter extends CustomPainter {
  final double t;
  final double radius;
  final double strokeWidth;

  _GradientBorderPainter({
    required this.t,
    required this.radius,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final begin = Alignment(-1.0 + 2.0 * t, -0.2);
    final end = Alignment(begin.x + 1.2, 0.2);

    final shader = LinearGradient(
      begin: begin,
      end: end,
      colors: _ByDefaultPageState.masterGoldGradient,
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
    return oldDelegate.t != t ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class _GoldShimmerMask extends StatelessWidget {
  final AnimationController controller;
  final Widget child;

  const _GoldShimmerMask({
    required this.controller,
    required this.child,
  });

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

class _AdaptiveShimmerText extends StatelessWidget {
  final String text;
  final AnimationController controller;
  final bool shimmerOn;
  final bool isDark;
  final TextStyle baseStyle;
  final bool fitDown;
  final Color baseColorLightMode;

  const _AdaptiveShimmerText({
    required this.text,
    required this.controller,
    required this.shimmerOn,
    required this.isDark,
    required this.baseStyle,
    required this.baseColorLightMode,
    this.fitDown = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!shimmerOn) {
      final plain = Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.visible,
        style: baseStyle.copyWith(
          color: isDark ? const Color(0xFFD4AF37) : baseColorLightMode,
        ),
      );
      return fitDown ? FittedBox(fit: BoxFit.scaleDown, child: plain) : plain;
    }

    if (isDark) {
      final baseText = Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.visible,
        style: baseStyle.copyWith(color: Colors.white),
      );

      final masked = _GoldShimmerMask(
        controller: controller,
        child: baseText,
      );

      return fitDown ? FittedBox(fit: BoxFit.scaleDown, child: masked) : masked;
    }

    final baseText = Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.visible,
      style: baseStyle.copyWith(color: baseColorLightMode),
    );

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final v = controller.value;
        final begin = Alignment(-1.0 + 2.0 * v, -0.2);
        final end = Alignment(begin.x + 1.2, 0.2);

        final shader = LinearGradient(
          begin: begin,
          end: end,
          colors: [
            baseColorLightMode,
            baseColorLightMode.withOpacity(0.35),
            baseColorLightMode,
          ],
          stops: const [0.0, 0.5, 1.0],
        );

        final masked = ShaderMask(
          shaderCallback: (rect) => shader.createShader(rect),
          blendMode: BlendMode.srcIn,
          child: baseText,
        );

        return fitDown ? FittedBox(fit: BoxFit.scaleDown, child: masked) : masked;
      },
    );
  }
}
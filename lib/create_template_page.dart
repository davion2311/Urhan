// lib/create_template_page.dart
// ✅ Real-time language change (35 languages)
// ✅ Action buttons text CENTERED (18 small + 5 big)
// ✅ TextField buttons text RIGHT aligned (RTL)
// ✅ Template name dialog on save (Create Mode)
// ✅ Custom Template Mode: Action buttons selectable (golden)
// ✅ History saves exact custom template layout
// ✅ Context Menu: Delete, Resize, Edit all present
// ✅ Resize handle working properly (fixed)

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_settings.dart';
import 'app_localizations.dart';

// ======================= TEMPLATE MODELS =======================
class ItemData {
  final String id;
  final String type;
  final String label;
  final bool isBig;
  final double left;
  final double top;
  final double width;
  final double height;

  const ItemData({
    required this.id,
    required this.type,
    required this.label,
    required this.isBig,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
}

class TemplateData {
  final String name;
  final List<ItemData> items;
  final List<String> deletedIds;

  const TemplateData({
    required this.name,
    required this.items,
    this.deletedIds = const <String>[],
  });
}

// ======================= CANVAS ITEM (RUNTIME) =======================
class CanvasItem {
  final String id;
  final String type;
  bool isBig;
  final TextEditingController? controller;
  String label;

  final ValueNotifier<Offset> pos = ValueNotifier<Offset>(Offset.zero);
  final ValueNotifier<Size> size = ValueNotifier<Size>(const Size(140, 44));
  final ValueNotifier<bool> selected = ValueNotifier<bool>(false);

  double minW;
  double maxW;
  double minH;
  double maxH;

  DateTime? _lastTap;

  CanvasItem({
    required this.id,
    required this.type,
    required this.label,
    required this.isBig,
    this.controller,
    this.minW = 70,
    this.maxW = 360,
    this.minH = 34,
    this.maxH = 160,
  });

  bool checkDoubleTap() {
    final now = DateTime.now();
    if (_lastTap != null && now.difference(_lastTap!).inMilliseconds < 400) {
      _lastTap = null;
      return true;
    }
    _lastTap = now;
    return false;
  }

  void dispose() {
    controller?.dispose();
    pos.dispose();
    size.dispose();
    selected.dispose();
  }
}

// ======================= CREATE TEMPLATE PAGE =======================
class CreateTemplatePage extends StatefulWidget {
  final TemplateData? initialTemplate;
  final bool isCustomTemplateMode;

  const CreateTemplatePage({super.key})
      : initialTemplate = null,
        isCustomTemplateMode = false;

  const CreateTemplatePage.open({super.key, required this.initialTemplate})
      : isCustomTemplateMode = true;

  @override
  State<CreateTemplatePage> createState() => _CreateTemplatePageState();
}

class _CreateTemplatePageState extends State<CreateTemplatePage>
    with TickerProviderStateMixin {
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

  final _nameCtrl = TextEditingController();
  final _serialCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  static const String _prefsHistoryKey = 'history_records_v1';

  bool _sidebarOpen = false;
  final GlobalKey _canvasKey = GlobalKey();
  Size _canvasSize = const Size(1, 1);

  final Map<String, CanvasItem> _canvasItems = <String, CanvasItem>{};
  final List<String> _zOrder = <String>[];

  String? _movingItemId;
  OverlayEntry? _menuOverlay;

  late final AnimationController _shimmerCtl;

  bool get _hasLoadedTemplate => widget.initialTemplate != null;

  final Set<String> _selectedActionKeys = <String>{};

  static const List<String> _textFieldKeys = [
    'length', 'sleeve', 'tera', 'chest', 'waist', 'neck', 
    'ghera', 'half', 'shalwar', 'pancha', 'cuff', 'shoulder', 
    'shalwar_aasan', 'shalwar_ghera'
  ];

  static const List<String> _smallActionKeys = [
    'round', 'square', 'half_bain', 'full_bain', 
    'bain_square', 'bain_round', 'normal_collar', 'collar_tip_s',
    'bain_patti_thin', 'chaak_patti_kaaj', 'simple_double', 'silky_double',
    'kanta', 'jaali', 'open_sleeves', 'fancy_button',
    'simple_pajama', 'pocket_pajama',
  ];

  static const List<String> _bigActionKeys = [
    'one_front_one_side_shalwar', 'one_front_two_side_shalwar',
    'one_side_one_shalwar', 'two_side_one_shalwar', 'two_side',
  ];

  @override
  void initState() {
    super.initState();
    _shimmerCtl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    if (_hasLoadedTemplate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyTemplate(widget.initialTemplate!);
      });
    }
  }

  @override
  void dispose() {
    _closeMenu();
    _nameCtrl.dispose();
    _serialCtrl.dispose();
    _phoneCtrl.dispose();
    for (final it in _canvasItems.values) {
      it.dispose();
    }
    _canvasItems.clear();
    _zOrder.clear();
    _shimmerCtl.dispose();
    super.dispose();
  }

  Color _pageBg(bool isDark) => isDark ? Colors.black : Colors.white;
  Color _cardBg(bool isDark) => isDark ? const Color(0xFF0A0A0A) : Colors.white;
  Color _textColor(bool isDark) => isDark ? Colors.white : Colors.black;
  Color _hintColor(bool isDark) =>
      isDark ? Colors.white70 : Colors.black.withOpacity(0.65);
  Color _shadowColor(bool isDark) =>
      isDark ? Colors.black54 : Colors.black.withOpacity(0.18);

  String _trMeasurement(AppLocalizations loc, String key) {
    return loc.tr('m_$key');
  }

  String _trAction(AppLocalizations loc, String key) {
    return loc.tr('a_$key');
  }

  String _displayLabel(AppLocalizations loc, CanvasItem item) {
    if (item.type == 'text_field') {
      if (_textFieldKeys.contains(item.label)) {
        return _trMeasurement(loc, item.label);
      }
      return item.label;
    } else {
      if (_smallActionKeys.contains(item.label) || _bigActionKeys.contains(item.label)) {
        return _trAction(loc, item.label);
      }
      return item.label;
    }
  }

  void _captureCanvasSize() {
    final box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    _canvasSize = box.size;
  }

  Offset _centerPosFor(Size s) {
    final maxX = math.max(0.0, _canvasSize.width - s.width);
    final maxY = math.max(0.0, _canvasSize.height - s.height);
    return Offset(maxX / 2, maxY / 2);
  }

  Offset _clampPos(Offset p, Size s) {
    return Offset(
      p.dx.clamp(-s.width * 0.5, _canvasSize.width - s.width * 0.5),
      p.dy.clamp(-s.height * 0.5, _canvasSize.height - s.height * 0.5),
    );
  }

  void _bringToTop(String id) {
    _zOrder.remove(id);
    _zOrder.add(id);
  }

  void _selectOnly(String? id) {
    for (final e in _canvasItems.entries) {
      e.value.selected.value = (e.key == id);
    }
  }

  void _openSidebar() {
    if (widget.isCustomTemplateMode) return;
    setState(() => _sidebarOpen = true);
  }

  void _closeSidebar() {
    setState(() => _sidebarOpen = false);
  }

  void _onCanvasTap() {
    if (_sidebarOpen) _closeSidebar();
    _closeMenu();
    _selectOnly(null);
    if (_resizeId != null) {
      _endResizeMode();
    }
  }

  void _addTextFieldItem(String key) {
    _captureCanvasSize();
    final id = 'tf_${DateTime.now().microsecondsSinceEpoch}';
    final it = CanvasItem(
      id: id,
      type: 'text_field',
      label: key,
      isBig: false,
      controller: TextEditingController(),
      minW: 120,
      maxW: 320,
      minH: 34,
      maxH: 120,
    );
    final s = it.size.value;
    it.pos.value = _centerPosFor(s);
    _canvasItems[id] = it;
    _zOrder.add(id);
    _selectOnly(id);
    _closeMenu();
    setState(() {});
  }

  void _addActionItem(String key, {required bool isBig}) {
    _captureCanvasSize();
    final id = 'ab_${DateTime.now().microsecondsSinceEpoch}';
    final it = CanvasItem(
      id: id,
      type: 'action_button',
      label: key,
      isBig: isBig,
      controller: null,
      minW: isBig ? 120 : 70,
      maxW: isBig ? 360 : 240,
      minH: 34,
      maxH: isBig ? 140 : 120,
    );
    final s = it.size.value;
    it.pos.value = _centerPosFor(s);
    _canvasItems[id] = it;
    _zOrder.add(id);
    _selectOnly(id);
    _closeMenu();
    setState(() {});
  }

  void _closeMenu() {
    _menuOverlay?.remove();
    _menuOverlay = null;
  }

  String? _resizeId;

  void _startResizeMode(String id) {
    if (widget.isCustomTemplateMode) return;
    _resizeId = id;
    _selectOnly(id);
    setState(() {});
  }

  void _endResizeMode() {
    _resizeId = null;
    setState(() {});
  }

  void _updateResize(String id, Offset delta) {
    final it = _canvasItems[id];
    if (it == null) return;

    final cs = it.size.value;
    final nw = (cs.width + delta.dx).clamp(it.minW, it.maxW).toDouble();
    final nh = (cs.height + delta.dy).clamp(it.minH, it.maxH).toDouble();
    it.size.value = Size(nw, nh);
    it.pos.value = _clampPos(it.pos.value, it.size.value);

    if (mounted) setState(() {});
  }

  void _showMenuFor(CanvasItem it, Offset globalAnchor, AppLocalizations loc) {
    if (widget.isCustomTemplateMode) return;
    _closeMenu();
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    _menuOverlay = OverlayEntry(
      builder: (_) {
        final w = 210.0;
        final h = 210.0;
        final left = globalAnchor.dx - (w / 2);
        final top = globalAnchor.dy - h - 8;

        return Positioned(
          left: left,
          top: top,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: w,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFD4AF37),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.menu, color: Colors.black, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _displayLabel(loc, it),
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: _closeMenu,
                          child: const Icon(Icons.close,
                              color: Colors.black, size: 20),
                        ),
                      ],
                    ),
                  ),
                  _MenuItem(
                    icon: Icons.delete,
                    text: 'ڈیلیٹ کریں',
                    color: Colors.red,
                    onTap: () {
                      _closeMenu();
                      _deleteItem(it.id);
                    },
                  ),
                  _MenuItem(
                    icon: Icons.zoom_out_map,
                    text: 'ریسائز',
                    color: Colors.orange,
                    onTap: () {
                      _closeMenu();
                      _startResizeMode(it.id);
                    },
                  ),
                  _MenuItem(
                    icon: Icons.edit,
                    text: 'ایڈٹ کریں',
                    color: Colors.blue,
                    onTap: () {
                      _closeMenu();
                      _editLabel(it.id, loc);
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_menuOverlay!);
  }

  void _deleteItem(String id) {
    if (widget.isCustomTemplateMode) return;
    final it = _canvasItems.remove(id);
    if (it == null) return;
    it.dispose();
    _zOrder.remove(id);
    if (_movingItemId == id) _movingItemId = null;
    _selectOnly(null);
    setState(() {});
  }

  Future<void> _editLabel(String id, AppLocalizations loc) async {
    if (widget.isCustomTemplateMode) return;
    final it = _canvasItems[id];
    if (it == null) return;

    final currentDisplay = _displayLabel(loc, it);
    final ctrl = TextEditingController(text: currentDisplay);
    
    final newText = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'ٹیکسٹ ایڈٹ کریں',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'نیا متن',
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
            onPressed: () => Navigator.pop(ctx),
            child: const Text('منسوخ', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('محفوظ کریں',
                style: TextStyle(color: Colors.yellow)),
          ),
        ],
      ),
    );

    if (newText != null && newText.trim().isNotEmpty) {
      it.label = newText.trim();
      setState(() {});
    }
  }

  void _toggleActionButton(String id, String key) {
    setState(() {
      if (_selectedActionKeys.contains(key)) {
        _selectedActionKeys.remove(key);
      } else {
        _selectedActionKeys.add(key);
      }
    });
  }

  void _startMove(String id, Offset localPosition) {
    if (widget.isCustomTemplateMode) return;
    if (_resizeId != null) return;
    final it = _canvasItems[id];
    if (it == null) return;
    _closeMenu();
    _selectOnly(id);
    _bringToTop(id);
    _movingItemId = id;
  }

  void _updateMove(String id, Offset delta) {
    if (widget.isCustomTemplateMode) return;
    if (_resizeId != null) return;
    if (_movingItemId != id) return;
    final it = _canvasItems[id];
    if (it == null) return;
    final currentPos = it.pos.value;
    it.pos.value = _clampPos(currentPos + delta, it.size.value);
  }

  void _endMove(String id) {
    if (_movingItemId == id) {
      _movingItemId = null;
    }
  }

  void _applyTemplate(TemplateData tpl) {
    _nameCtrl.text = '';
    _serialCtrl.text = '';
    _phoneCtrl.text = '';
    _selectedActionKeys.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureCanvasSize();

      for (final it in _canvasItems.values) {
        it.dispose();
      }
      _canvasItems.clear();
      _zOrder.clear();

      for (final item in tpl.items) {
        final cid = item.id.isNotEmpty
            ? item.id
            : 'it_${DateTime.now().microsecondsSinceEpoch}';

        final isText = item.type == 'text_field';
        final canvasIt = CanvasItem(
          id: cid,
          type: item.type,
          label: item.label,
          isBig: item.isBig,
          controller: isText ? TextEditingController() : null,
          minW: isText ? 120 : (item.isBig ? 120 : 70),
          maxW: isText ? 320 : (item.isBig ? 360 : 240),
          minH: 34,
          maxH: isText ? 120 : (item.isBig ? 140 : 120),
        );

        canvasIt.size.value = Size(item.width, item.height);
        canvasIt.pos.value =
            _clampPos(Offset(item.left, item.top), canvasIt.size.value);

        _canvasItems[cid] = canvasIt;
        _zOrder.add(cid);
      }

      _selectOnly(null);
      if (mounted) setState(() {});
    });
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
    list.insert(0, record);
    await _saveHistoryList(list);
  }

  Future<String?> _askTemplateName({String initial = ''}) async {
    final ctrl = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        title: const Text('Type your template name',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Template name',
            hintStyle: TextStyle(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Save', style: TextStyle(color: Colors.yellow)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTemplate() async {
    _captureCanvasSize();

    if (widget.isCustomTemplateMode) {
      try {
        final measurements = <String, String>{};
        for (final it in _canvasItems.values) {
          if (it.type == 'text_field' && it.controller != null) {
            measurements[it.label] = it.controller!.text.trim();
          }
        }

        final selectedActions = _selectedActionKeys.toList();

        final templateItems = <Map<String, dynamic>>[];
        for (final id in _zOrder) {
          final it = _canvasItems[id];
          if (it == null) continue;
          templateItems.add({
            'id': it.id,
            'type': it.type,
            'label': it.label,
            'isBig': it.isBig,
            'left': it.pos.value.dx,
            'top': it.pos.value.dy,
            'width': it.size.value.width,
            'height': it.size.value.height,
          });
        }

        final historyRecord = {
          'source': 'custom_template_filled',
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'customer': {
            'name': _nameCtrl.text.trim(),
            'serial': _serialCtrl.text.trim(),
            'phone': _phoneCtrl.text.trim(),
          },
          'measurements': measurements,
          'actions': selectedActions,
          'template_layout': templateItems,
          'template_name': widget.initialTemplate?.name,
        };

        await _appendToHistory(historyRecord);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('پیما‎ئشیں ہسٹری میں محفوظ ہو گئیں ✅'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context);
        return;
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('محفوظ کرنے میں خرابی: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final name = await _askTemplateName();
    if (!mounted) return;
    if (name == null || name.trim().isEmpty) return;

    final items = <ItemData>[];
    for (final id in _zOrder) {
      final it = _canvasItems[id];
      if (it == null) continue;

      final p = it.pos.value;
      final s = it.size.value;

      items.add(ItemData(
        id: it.id,
        type: it.type,
        label: it.label,
        isBig: it.isBig,
        left: p.dx,
        top: p.dy,
        width: s.width,
        height: s.height,
      ));
    }

    final tpl = TemplateData(
      name: name.trim(),
      items: items,
      deletedIds: const <String>[],
    );

    Navigator.pop(context, tpl);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: AppSettings.languageCodeVN,
      builder: (context, code, _) {
        final locale = AppLocalizations.parseLocaleCode(code ?? 'ur');
        final isButtonRTL = locale.languageCode == 'ur' || 
                           locale.languageCode == 'ar';

        return Localizations.override(
          context: context,
          locale: locale,
          child: ValueListenableBuilder<bool>(
            valueListenable: AppSettings.darkModeVN,
            builder: (context, isDark, _) {
              return ValueListenableBuilder<bool>(
                valueListenable: AppSettings.shimmerVN,
                builder: (context, shimmerOn, __) {
                  final loc = AppLocalizations.t(context);

                  return Directionality(
                    textDirection: TextDirection.rtl,
                    child: Scaffold(
                      backgroundColor: _pageBg(isDark),
                      body: SafeArea(
                        child: LayoutBuilder(
                          builder: (context, c) {
                            const baseW = 390.0, baseH = 780.0;
                            final scale =
                                math.min(c.maxWidth / baseW, c.maxHeight / baseH);

                            return Stack(
                              children: [
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
                                          padding: const EdgeInsets.fromLTRB(
                                              14, 12, 14, 14),
                                          child: Column(
                                            children: [
                                              _topRow(isDark, shimmerOn, loc),
                                              const SizedBox(height: 10),
                                              _phoneRow(isDark, shimmerOn, loc),
                                              const SizedBox(height: 12),
                                              Expanded(
                                                child: _canvasArea(isDark, shimmerOn, loc, isButtonRTL),
                                              ),
                                              const SizedBox(height: 12),
                                              _saveButton(isDark, shimmerOn, loc),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (_sidebarOpen && !widget.isCustomTemplateMode) 
                                  _sidebarOverlay(isDark, shimmerOn, loc, isButtonRTL),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _topRow(bool isDark, bool shimmerOn, AppLocalizations loc) {
    return Row(
      children: [
        _backButton(isDark, shimmerOn),
        const SizedBox(width: 10),
        Expanded(
          flex: 7,
          child: _topField(
            isDark: isDark,
            shimmerOn: shimmerOn,
            ctrl: _nameCtrl,
            hint: loc.name,
            type: TextInputType.name,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: _topField(
            isDark: isDark,
            shimmerOn: shimmerOn,
            ctrl: _serialCtrl,
            hint: loc.serial,
            type: TextInputType.number,
          ),
        ),
      ],
    );
  }

  Widget _phoneRow(bool isDark, bool shimmerOn, AppLocalizations loc) {
    return Row(
      children: [
        Expanded(
          flex: 7,
          child: _topField(
            isDark: isDark,
            shimmerOn: shimmerOn,
            ctrl: _phoneCtrl,
            hint: loc.phone,
            type: TextInputType.phone,
          ),
        ),
        const SizedBox(width: 10),
        if (!widget.isCustomTemplateMode)
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: _plusButton(isDark, shimmerOn),
            ),
          ),
      ],
    );
  }

  Widget _backButton(bool isDark, bool shimmerOn) {
    return SizedBox(
      height: 46,
      width: 46,
      child: InkWell(
        onTap: () => Navigator.pop(context),
        child: _GradientBorderBox(
          controller: _shimmerCtl,
          enabled: shimmerOn,
          radius: 999,
          strokeWidth: 2.4,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _goldGrad,
              boxShadow: [
                BoxShadow(
                  color: _shadowColor(isDark),
                  blurRadius: 12,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: const Icon(Icons.arrow_back, color: Colors.black),
          ),
        ),
      ),
    );
  }

  Widget _plusButton(bool isDark, bool shimmerOn) {
    return SizedBox(
      height: 46,
      width: 46,
      child: InkWell(
        onTap: () {
          _closeMenu();
          _openSidebar();
        },
        child: _GradientBorderBox(
          controller: _shimmerCtl,
          enabled: shimmerOn,
          radius: 999,
          strokeWidth: 2.4,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _goldGrad,
              boxShadow: [
                BoxShadow(
                  color: _shadowColor(isDark),
                  blurRadius: 12,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: const Icon(Icons.add, color: Colors.black),
          ),
        ),
      ),
    );
  }

  Widget _topField({
    required bool isDark,
    required bool shimmerOn,
    required TextEditingController ctrl,
    required String hint,
    required TextInputType type,
  }) {
    return _GradientBorderBox(
      controller: _shimmerCtl,
      enabled: shimmerOn,
      radius: 999,
      strokeWidth: 2.2,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: _cardBg(isDark),
          borderRadius: const BorderRadius.all(Radius.circular(999)),
          boxShadow: [
            BoxShadow(
              color: _shadowColor(isDark),
              blurRadius: 12,
              offset: const Offset(0, 8),
            )
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Center(
          child: _GoldShimmerMask(
            controller: _shimmerCtl,
            enabled: shimmerOn && isDark,
            child: TextField(
              controller: ctrl,
              keyboardType: type,
              cursorColor: isDark ? const Color(0xFFD4AF37) : Colors.black,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: _textColor(isDark),
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: hint,
                hintStyle: TextStyle(
                  color: _hintColor(isDark),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _canvasArea(bool isDark, bool shimmerOn, AppLocalizations loc, bool isButtonRTL) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onCanvasTap,
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
                for (final id in _zOrder) _buildCanvasItem(id, isDark, shimmerOn, loc, isButtonRTL),
                if (_resizeId != null && !widget.isCustomTemplateMode) 
                  _resizeHintChip(isDark),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _resizeHintChip(bool isDark) {
    return Positioned(
      left: 12,
      top: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: _goldGrad,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: _shadowColor(isDark),
              blurRadius: 14,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: const Text(
          'ریسائز موڈ: ہینڈل پکڑ کر کھینچیں، خالی جگہ پر ٹیپ = بند',
          style: TextStyle(
            color: Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildCanvasItem(String id, bool isDark, bool shimmerOn, AppLocalizations loc, bool isButtonRTL) {
    final it = _canvasItems[id];
    if (it == null) return const SizedBox.shrink();

    return ValueListenableBuilder<Offset>(
      valueListenable: it.pos,
      builder: (context, p, _) {
        return ValueListenableBuilder<Size>(
          valueListenable: it.size,
          builder: (context, s, __) {
            final isSelected = it.type == 'action_button' && 
                              _selectedActionKeys.contains(it.label);

            return Positioned(
              left: p.dx,
              top: p.dy,
              width: s.width,
              height: s.height,
              child: _CanvasItemWidget(
                item: it,
                isDark: isDark,
                shimmerOn: shimmerOn,
                shimmerCtl: _shimmerCtl,
                goldGrad: _goldGrad,
                shadowColor: _shadowColor(isDark),
                isCustomMode: widget.isCustomTemplateMode,
                isButtonRTL: isButtonRTL,
                displayLabel: _displayLabel(loc, it),
                isSelected: isSelected,
                showResizeHandle: _resizeId == it.id && !widget.isCustomTemplateMode,
                onResizeUpdate: (delta) {
                  _updateResize(it.id, delta);
                },
                onTapDown: (d) {
                  if (widget.isCustomTemplateMode) {
                    if (it.type == 'text_field') {
                      _selectOnly(it.id);
                    } else if (it.type == 'action_button') {
                      _toggleActionButton(it.id, it.label);
                    }
                    return;
                  }
                  
                  if (it.checkDoubleTap()) {
                    _selectOnly(it.id);
                    final box = context.findRenderObject() as RenderBox?;
                    if (box != null) {
                      final g = box.localToGlobal(box.size.center(Offset.zero));
                      _showMenuFor(it, g, loc);
                    }
                  } else {
                    _closeMenu();
                    _selectOnly(it.id);
                  }
                },
                onPanStart: (d) {
                  if (_resizeId != null) return;
                  _startMove(it.id, d.localPosition);
                },
                onPanUpdate: (d) {
                  if (_resizeId != null) return;
                  _updateMove(it.id, d.delta);
                },
                onPanEnd: (_) {
                  if (_resizeId != null) return;
                  _endMove(it.id);
                },
                onPanCancel: () {
                  if (_resizeId != null) return;
                  _endMove(it.id);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _saveButton(bool isDark, bool shimmerOn, AppLocalizations loc) {
    return InkWell(
      onTap: _saveTemplate,
      child: Container(
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: _goldGrad,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: _shadowColor(isDark),
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Center(
          child: _GoldShimmerText(
            text: widget.isCustomTemplateMode ? 'مکمل کریں' : loc.save,
            controller: _shimmerCtl,
            enabled: shimmerOn,
            baseStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.2,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sidebarOverlay(bool isDark, bool shimmerOn, AppLocalizations loc, bool isButtonRTL) {
    const panelW = 180.0;

    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _closeSidebar,
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: panelW,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: _GradientBorderBox(
                  controller: _shimmerCtl,
                  enabled: shimmerOn,
                  radius: 0,
                  strokeWidth: 3.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: _shadowColor(isDark),
                          blurRadius: 40,
                          spreadRadius: 8,
                          offset: const Offset(-15, 0),
                        )
                      ],
                    ),
                    child: SafeArea(
                      child: Column(
                        children: [
                          _sidebarHeader(isDark, shimmerOn),
                          const SizedBox(height: 10),
                          Expanded(
                            child: _sidebarVerticalList(isDark, shimmerOn, loc, isButtonRTL),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sidebarHeader(bool isDark, bool shimmerOn) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            height: 40,
            width: 40,
            child: InkWell(
              onTap: _closeSidebar,
              child: _GradientBorderBox(
                controller: _shimmerCtl,
                enabled: shimmerOn,
                radius: 999,
                strokeWidth: 2.0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _goldGrad,
                    boxShadow: [
                      BoxShadow(
                        color: _shadowColor(isDark),
                        blurRadius: 12,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: const Icon(Icons.arrow_forward, color: Colors.black, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarVerticalList(bool isDark, bool shimmerOn, AppLocalizations loc, bool isButtonRTL) {
    final chips = <_SidebarChipData>[];

    for (final key in _textFieldKeys) {
      chips.add(_SidebarChipData(
        label: _trMeasurement(loc, key),
        rawKey: key,
        isTextField: true,
        onTap: () {
          _addTextFieldItem(key);
          _closeSidebar();
        },
      ));
    }

    for (final key in _smallActionKeys) {
      chips.add(_SidebarChipData(
        label: _trAction(loc, key),
        rawKey: key,
        isTextField: false,
        onTap: () {
          _addActionItem(key, isBig: false);
          _closeSidebar();
        },
      ));
    }

    for (final key in _bigActionKeys) {
      chips.add(_SidebarChipData(
        label: _trAction(loc, key),
        rawKey: key,
        isTextField: false,
        onTap: () {
          _addActionItem(key, isBig: true);
          _closeSidebar();
        },
      ));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          for (final c in chips)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: 140,
                child: _SidebarChip(
                  label: c.label,
                  isTextField: c.isTextField,
                  isDark: isDark,
                  shimmerOn: shimmerOn,
                  shimmerCtl: _shimmerCtl,
                  goldGrad: _goldGrad,
                  shadow: _shadowColor(isDark),
                  onTap: c.onTap,
                  isRTL: isButtonRTL,
                ),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SidebarChipData {
  final String label;
  final String rawKey;
  final VoidCallback onTap;
  final bool isTextField;
  const _SidebarChipData({
    required this.label,
    required this.rawKey,
    required this.onTap, 
    this.isTextField = false,
  });
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.text,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarChip extends StatelessWidget {
  final String label;
  final bool isTextField;
  final bool isDark;
  final bool shimmerOn;
  final AnimationController shimmerCtl;
  final LinearGradient goldGrad;
  final Color shadow;
  final VoidCallback onTap;
  final bool isRTL;

  const _SidebarChip({
    required this.label,
    required this.isTextField,
    required this.isDark,
    required this.shimmerOn,
    required this.shimmerCtl,
    required this.goldGrad,
    required this.shadow,
    required this.onTap,
    required this.isRTL,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final txt = isDark ? Colors.white : Colors.black;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: shadow, blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Center(
          child: _GoldShimmerText(
            text: label,
            controller: shimmerCtl,
            enabled: shimmerOn && isDark,
            baseStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: txt,
            ),
            alignment: isRTL ? Alignment.centerRight : Alignment.centerLeft,
            fitDown: true,
          ),
        ),
      ),
    );
  }
}

// ======================= CANVAS ITEM WIDGET =======================
class _CanvasItemWidget extends StatelessWidget {
  final CanvasItem item;
  final bool isDark;
  final bool shimmerOn;
  final AnimationController shimmerCtl;
  final LinearGradient goldGrad;
  final Color shadowColor;
  final bool isCustomMode;
  final bool isButtonRTL;
  final String displayLabel;
  final bool isSelected;
  final bool showResizeHandle;
  final void Function(Offset delta) onResizeUpdate;

  final GestureTapDownCallback onTapDown;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;
  final VoidCallback onPanCancel;

  const _CanvasItemWidget({
    required this.item,
    required this.isDark,
    required this.shimmerOn,
    required this.shimmerCtl,
    required this.goldGrad,
    required this.shadowColor,
    required this.isCustomMode,
    required this.isButtonRTL,
    required this.displayLabel,
    required this.isSelected,
    required this.showResizeHandle,
    required this.onResizeUpdate,
    required this.onTapDown,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onPanCancel,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: item.selected,
      builder: (context, sel, _) {
        return ValueListenableBuilder<Size>(
          valueListenable: item.size,
          builder: (context, size, __) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: onTapDown,
              onPanStart: isCustomMode ? null : onPanStart,
              onPanUpdate: isCustomMode ? null : onPanUpdate,
              onPanEnd: isCustomMode ? null : onPanEnd,
              onPanCancel: isCustomMode ? null : onPanCancel,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: item.type == 'text_field'
                        ? _MeasureCapsuleFixed(
                            height: size.height,
                            label: displayLabel,
                            controller: item.controller!,
                            shimmerCtl: shimmerCtl,
                            shimmerOn: shimmerOn,
                            isDark: isDark,
                            goldGrad: goldGrad,
                            isEditable: isCustomMode,
                            isRTL: isButtonRTL,
                          )
                        : _ActionPill(
                            height: size.height,
                            label: displayLabel,
                            selected: isSelected,
                            shimmerCtl: shimmerCtl,
                            shimmerOn: shimmerOn,
                            isDark: isDark,
                            goldGrad: goldGrad,
                            isBig: item.isBig,
                          ),
                  ),
                  if (sel && item.type == 'text_field' && !isCustomMode)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.yellow, width: 2),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  if (showResizeHandle)
                    Positioned(
                      right: -16,
                      bottom: -16,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (_) {},
                        onPanUpdate: (d) => onResizeUpdate(d.delta),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFCF6BA),
                                Color(0xFFD4AF37),
                                Color(0xFFBF953F),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.6),
                                blurRadius: 15,
                                spreadRadius: 3,
                                offset: const Offset(0, 6),
                              ),
                              BoxShadow(
                                color: const Color(0xFFD4AF37).withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 5,
                                offset: Offset.zero,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.open_with,
                            color: Colors.black,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ======================= MEASURE CAPSULE (TextField) =======================
class _MeasureCapsuleFixed extends StatelessWidget {
  final double height;
  final String label;
  final TextEditingController controller;
  final AnimationController shimmerCtl;
  final bool shimmerOn;
  final bool isDark;
  final LinearGradient goldGrad;
  final bool isEditable;
  final bool isRTL;

  const _MeasureCapsuleFixed({
    required this.height,
    required this.label,
    required this.controller,
    required this.shimmerCtl,
    required this.shimmerOn,
    required this.isDark,
    required this.goldGrad,
    required this.isEditable,
    required this.isRTL,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF0A0A0A) : Colors.white;
    final shadow = isDark ? Colors.black54 : Colors.black.withOpacity(0.18);
    final txt = isDark ? Colors.white : Colors.black;

    return _GradientBorderBox(
      controller: shimmerCtl,
      enabled: shimmerOn,
      radius: 999,
      strokeWidth: 2.0,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.all(Radius.circular(999)),
          boxShadow: [
            BoxShadow(
                color: shadow, blurRadius: 12, offset: const Offset(0, 8)),
          ],
        ),
        padding: EdgeInsets.symmetric(
          horizontal: math.max(12, height * 0.2),
          vertical: math.max(4, height * 0.1),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: _FixedPositionText(
                  text: label,
                  height: height,
                  baseStyle: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: txt,
                  ),
                  shimmerCtl: shimmerCtl,
                  shimmerOn: shimmerOn && isDark,
                  alignment: Alignment.centerRight,
                ),
              ),
            ),
            if (isEditable)
              Expanded(
                flex: 3,
                child: isDark
                  ? ShaderMask(
                      shaderCallback: (bounds) => goldGrad.createShader(bounds),
                      blendMode: BlendMode.srcIn,
                      child: TextField(
                        controller: controller,
                        keyboardType: TextInputType.text,
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: math.max(16, height * 0.45),
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '',
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    )
                  : TextField(
                      controller: controller,
                      keyboardType: TextInputType.text,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: math.max(16, height * 0.45),
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '',
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
              )
            else
              const Expanded(flex: 3, child: SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}

// ======================= ACTION PILL (Action Buttons) =======================
class _ActionPill extends StatelessWidget {
  final double height;
  final String label;
  final bool selected;
  final AnimationController shimmerCtl;
  final bool shimmerOn;
  final bool isDark;
  final LinearGradient goldGrad;
  final bool isBig;

  const _ActionPill({
    required this.height,
    required this.label,
    required this.selected,
    required this.shimmerCtl,
    required this.shimmerOn,
    required this.isDark,
    required this.goldGrad,
    this.isBig = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF0A0A0A) : Colors.white;
    final shadow = isDark ? Colors.black54 : Colors.black.withOpacity(0.18);
    final txt = isDark ? Colors.white : Colors.black;

    return _GradientBorderBox(
      controller: shimmerCtl,
      enabled: shimmerOn,
      radius: 999,
      strokeWidth: 2.0,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: selected ? null : bg,
          borderRadius: const BorderRadius.all(Radius.circular(999)),
          gradient: selected ? goldGrad : null,
          boxShadow: [
            BoxShadow(
                color: shadow, blurRadius: 12, offset: const Offset(0, 8)),
          ],
        ),
        padding: EdgeInsets.symmetric(
          horizontal: math.max(10, height * 0.15),
          vertical: math.max(4, height * 0.1),
        ),
        child: Center(
          child: _FixedPositionText(
            text: label,
            height: height,
            baseStyle: TextStyle(
              fontWeight: FontWeight.w900,
              color: selected ? Colors.black : txt,
            ),
            shimmerCtl: shimmerCtl,
            shimmerOn: shimmerOn && isDark && !selected,
            alignment: Alignment.center,
          ),
        ),
      ),
    );
  }
}

// ======================= FIXED POSITION TEXT =======================
class _FixedPositionText extends StatelessWidget {
  final String text;
  final double height;
  final TextStyle baseStyle;
  final AnimationController? shimmerCtl;
  final bool shimmerOn;
  final Alignment alignment;

  const _FixedPositionText({
    required this.text,
    required this.height,
    required this.baseStyle,
    this.shimmerCtl,
    this.shimmerOn = false,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = math.max(14.0, height * 0.40);

    final textWidget = Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: alignment == Alignment.centerRight ? TextAlign.right : 
                   alignment == Alignment.centerLeft ? TextAlign.left : 
                   TextAlign.center,
      style: baseStyle.copyWith(
        fontSize: fontSize,
      ),
    );

    if (!shimmerOn || shimmerCtl == null) {
      return SizedBox(
        width: double.infinity,
        child: Align(
          alignment: alignment,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: textWidget,
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: shimmerCtl!,
      builder: (context, _) {
        final v = shimmerCtl!.value;
        final begin = Alignment(-1.0 + 2.0 * v, -0.2);
        final end = Alignment(begin.x + 1.2, 0.2);

        final masked = ShaderMask(
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
          child: textWidget,
        );

        return SizedBox(
          width: double.infinity,
          child: Align(
            alignment: alignment,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: masked,
            ),
          ),
        );
      },
    );
  }
}

// ======================= GRADIENT BORDER BOX =======================
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
      colors: const [Color(0xFFBF953F), Color(0xFFFCF6BA), Color(0xFFD4AF37), Color(0xFFBF953F)],
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
    return oldDelegate.t != t || oldDelegate.radius != radius || oldDelegate.strokeWidth != oldDelegate.strokeWidth;
  }
}

// ======================= SHIMMER MASK =======================
class _GoldShimmerMask extends StatelessWidget {
  final AnimationController controller;
  final Widget child;
  final bool enabled;

  const _GoldShimmerMask({
    required this.controller,
    required this.child,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    
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

// ======================= SHIMMER TEXT =======================
class _GoldShimmerText extends StatelessWidget {
  final String text;
  final AnimationController controller;
  final TextStyle baseStyle;
  final bool fitDown;
  final bool enabled;
  final Alignment alignment;

  const _GoldShimmerText({
    required this.text,
    required this.controller,
    required this.baseStyle,
    required this.enabled,
    this.fitDown = false,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      final plain = Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: alignment == Alignment.centerRight ? TextAlign.right : 
                     alignment == Alignment.centerLeft ? TextAlign.left : 
                     TextAlign.center,
        style: baseStyle,
      );
      return fitDown 
        ? FittedBox(fit: BoxFit.scaleDown, child: Align(alignment: alignment, child: plain)) 
        : Align(alignment: alignment, child: plain);
    }

    final textWidget = Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.visible,
      textAlign: alignment == Alignment.centerRight ? TextAlign.right : 
                   alignment == Alignment.centerLeft ? TextAlign.left : 
                   TextAlign.center,
      style: baseStyle.copyWith(color: Colors.white),
    );

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final v = controller.value;
        final begin = Alignment(-1.0 + 2.0 * v, -0.2);
        final end = Alignment(begin.x + 1.2, 0.2);

        final masked = ShaderMask(
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
          child: textWidget,
        );

        final aligned = Align(
          alignment: alignment,
          child: fitDown
            ? FittedBox(fit: BoxFit.scaleDown, child: masked)
            : masked,
        );

        return aligned;
      },
    );
  }
}
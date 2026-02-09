import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_header.dart';
import 'ui_kit.dart';
import 'receipt_page.dart';

const String kSavedReceiptTemplatesKey = 'saved_receipt_templates_v2';

enum TemplateKind { image }

class TemplateAsset {
  final TemplateKind kind;
  final String path;

  const TemplateAsset._(this.kind, this.path);

  factory TemplateAsset.image({required String imagePath}) =>
      TemplateAsset._(TemplateKind.image, imagePath);

  String get previewImagePathForGrid => path;

  Map<String, dynamic> toJson() => {
        'kind': 'img',
        'path': path,
      };

  static TemplateAsset? fromJson(Map<String, dynamic> j) {
    final path = (j['path'] ?? '').toString().trim();
    if (path.isEmpty) return null;
    return TemplateAsset.image(imagePath: path);
  }
}

class ReceiptTemplates {
  static List<TemplateAsset> buildAll() {
    return List<TemplateAsset>.generate(
      10,
      (i) => TemplateAsset.image(imagePath: 'assets/images/receipt_${i + 1}.png'),
    );
  }
}

/// ====================== SAVED TEMPLATE MODEL ======================
class SavedReceiptTemplate {
  final String id;
  final TemplateAsset asset;
  final List<PlacedTextModel> texts;

  SavedReceiptTemplate({
    required this.id,
    required this.asset,
    required this.texts,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'asset': asset.toJson(),
        'texts': texts.map((e) => e.toJson()).toList(),
      };

  static SavedReceiptTemplate? fromJson(Map<String, dynamic> j) {
    final id = (j['id'] ?? '').toString().trim();
    final a = j['asset'];
    if (id.isEmpty || a is! Map) return null;

    final asset = TemplateAsset.fromJson(Map<String, dynamic>.from(a));
    if (asset == null) return null;

    final list = <PlacedTextModel>[];
    final rawTexts = j['texts'];
    if (rawTexts is List) {
      for (final item in rawTexts) {
        if (item is Map) {
          final m = PlacedTextModel.fromJson(Map<String, dynamic>.from(item));
          if (m != null) list.add(m);
        }
      }
    }
    return SavedReceiptTemplate(id: id, asset: asset, texts: list);
  }
}

/// ====================== PLACED TEXT MODEL ======================
class PlacedTextModel {
  final String id;
  String text;

  Offset posNorm; // 0..1
  double baseWidth;
  double baseBox;
  double fontScale;
  double scaleX;
  double scaleY;
  bool wrapEnabled;
  double wrapMaxWidth;

  PlacedTextModel({
    required this.id,
    required this.text,
    required this.posNorm,
    this.baseWidth = 220,
    this.baseBox = 100,
    this.fontScale = 1.0,
    this.scaleX = 1.0,
    this.scaleY = 1.0,
    this.wrapEnabled = false,
    this.wrapMaxWidth = 220,
  });

  PlacedTextModel copy() => PlacedTextModel(
        id: id,
        text: text,
        posNorm: posNorm,
        baseWidth: baseWidth,
        baseBox: baseBox,
        fontScale: fontScale,
        scaleX: scaleX,
        scaleY: scaleY,
        wrapEnabled: wrapEnabled,
        wrapMaxWidth: wrapMaxWidth,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'x': posNorm.dx,
        'y': posNorm.dy,
        'bw': baseWidth,
        'bb': baseBox,
        'fs': fontScale,
        'sx': scaleX,
        'sy': scaleY,
        'we': wrapEnabled,
        'wmw': wrapMaxWidth,
      };

  static PlacedTextModel? fromJson(Map<String, dynamic> j) {
    final id = (j['id'] ?? '').toString().trim();
    if (id.isEmpty) return null;

    double _d(dynamic v, double fallback) {
      if (v is num) return v.toDouble();
      return fallback;
    }

    final text = (j['text'] ?? '').toString();
    final x = _d(j['x'], 0.5).clamp(0.0, 1.0);
    final y = _d(j['y'], 0.3).clamp(0.0, 1.0);

    return PlacedTextModel(
      id: id,
      text: text,
      posNorm: Offset(x, y),
      baseWidth: _d(j['bw'], 220),
      baseBox: _d(j['bb'], 100),
      fontScale: _d(j['fs'], 1.0).clamp(0.35, 4.0),
      scaleX: _d(j['sx'], 1.0).clamp(0.35, 3.0),
      scaleY: _d(j['sy'], 1.0).clamp(0.35, 3.0),
      wrapEnabled: (j['we'] == true),
      wrapMaxWidth: _d(j['wmw'], 220).clamp(60.0, 900.0),
    );
  }
}

class ReceiptTemplatePage extends StatelessWidget {
  const ReceiptTemplatePage({super.key});

  @override
  Widget build(BuildContext context) {
    final assets = ReceiptTemplates.buildAll();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            SettingsHeader(onBack: () => Navigator.pop(context)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: GridView.builder(
                  itemCount: assets.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 9 / 16,
                  ),
                  itemBuilder: (context, index) {
                    final a = assets[index];
                    return _TemplateCard(
                      asset: a,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ReceiptTemplateEditorPage(asset: a),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final TemplateAsset asset;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.asset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final preview = asset.previewImagePathForGrid;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withOpacity(0.25)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.asset(preview, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

// =================================== EDITOR ======================================
class ReceiptTemplateEditorPage extends StatefulWidget {
  final TemplateAsset asset;

  const ReceiptTemplateEditorPage({super.key, required this.asset});

  @override
  State<ReceiptTemplateEditorPage> createState() =>
      _ReceiptTemplateEditorPageState();
}

class _ReceiptTemplateEditorPageState extends State<ReceiptTemplateEditorPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _templateContainerKey = GlobalKey();

  final List<PlacedTextModel> _texts = [];
  String? _activeId;

  late final AnimationController _shimmer;

  // Drag state
  Offset _dragStartGlobal = Offset.zero;
  Offset _startPosNorm = Offset.zero;
  double _startFontScale = 1.0;
  double _startScaleX = 1.0;
  double _startScaleY = 1.0;
  double _startWrapMaxW = 220;

  final List<String> _sidebarItems = const [
    'DIGITAL DARZI',
    'THANKS FOR COMING TO DIGITAL DARZI',
    'NAME',
    'SERIAL',
    'QUANTITY',
    'RUPEES',
    'RETURN',
    'ADVANCE',
  ];

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  void _openSidebar() => _scaffoldKey.currentState?.openEndDrawer();

  PlacedTextModel? _find(String id) {
    try {
      return _texts.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  void _addTextFromSidebar(String text) {
    Navigator.of(context).maybePop();

    final id =
        '${DateTime.now().microsecondsSinceEpoch}_${math.Random().nextInt(9999)}';

    setState(() {
      _texts.add(
        PlacedTextModel(
          id: id,
          text: text,
          posNorm: const Offset(0.5, 0.30),
          baseWidth: 220,
          baseBox: 100,
          fontScale: 1.0,
          scaleX: 1.0,
          scaleY: 1.0,
          wrapEnabled: false,
          wrapMaxWidth: 220,
        ),
      );
      _activeId = id;
    });
  }

  Future<void> _editText(String id) async {
    final t = _find(id);
    if (t == null) return;

    final c = TextEditingController(text: t.text);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('EDIT TEXT'),
        content: TextField(
          controller: c,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (v) {
            Navigator.of(context).pop(v);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(c.text);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (result == null) return;
    final v = result.trim();
    if (v.isEmpty) return;

    setState(() => t.text = v);
  }

  void _deleteText(String id) {
    setState(() {
      _texts.removeWhere((e) => e.id == id);
      if (_activeId == id) _activeId = null;
    });
  }

  // ================== MOVE ==================
  void _onMoveStart(String id, DragStartDetails d) {
    final t = _find(id);
    if (t == null) return;
    _activeId = id;
    _dragStartGlobal = d.globalPosition;
    _startPosNorm = t.posNorm;
  }

  void _onMoveUpdate(String id, DragUpdateDetails d) {
    final t = _find(id);
    if (t == null) return;

    final renderBox = _templateContainerKey.currentContext?.findRenderObject() as RenderBox?;
    final templateSize = renderBox?.size ?? Size(MediaQuery.of(context).size.width, 400);

    final delta = d.globalPosition - _dragStartGlobal;
    final dn = Offset(delta.dx / templateSize.width, delta.dy / templateSize.height);

    final newDx = (_startPosNorm.dx + dn.dx).clamp(0.05, 0.95);
    final newDy = (_startPosNorm.dy + dn.dy).clamp(0.05, 0.95);

    setState(() {
      t.posNorm = Offset(newDx, newDy);
    });
  }

  // ================== SCALE (fontScale) ==================
  void _onScaleStart(String id) {
    final t = _find(id);
    if (t == null) return;
    _activeId = id;
    _startFontScale = t.fontScale;
  }

  void _onScaleUpdate(String id, DragUpdateDetails d) {
    final t = _find(id);
    if (t == null) return;

    final delta = (d.delta.dx + d.delta.dy) / 100.0;
    final ns = (_startFontScale + delta).clamp(0.35, 4.0);

    setState(() {
      t.fontScale = ns;
    });
  }

  // ================== WIDTH squeeze ==================
  void _onWidthStart(String id) {
    final t = _find(id);
    if (t == null) return;
    _activeId = id;
    _startScaleX = t.scaleX;
  }

  void _onWidthUpdate(String id, DragUpdateDetails d) {
    final t = _find(id);
    if (t == null) return;

    final delta = -d.delta.dx / 100.0;
    final nx = (_startScaleX + delta).clamp(0.35, 3.0);

    setState(() {
      t.scaleX = nx;
    });
  }

  // ================== HEIGHT ==================
  void _onHeightStart(String id) {
    final t = _find(id);
    if (t == null) return;
    _activeId = id;
    _startScaleY = t.scaleY;
  }

  void _onHeightUpdate(String id, DragUpdateDetails d, {required bool invert}) {
    final t = _find(id);
    if (t == null) return;

    final dy = invert ? -d.delta.dy : d.delta.dy;
    final delta = dy / 100.0;
    final ny = (_startScaleY + delta).clamp(0.35, 3.0);

    setState(() {
      t.scaleY = ny;
    });
  }

  // ================== WRAP ==================
  void _onWrapStart(String id) {
    final t = _find(id);
    if (t == null) return;
    _activeId = id;
    _startWrapMaxW = t.wrapMaxWidth;
  }

  void _onWrapUpdate(String id, DragUpdateDetails d) {
    final t = _find(id);
    if (t == null) return;

    final nw = (_startWrapMaxW - d.delta.dx).clamp(60.0, 900.0);

    setState(() {
      t.wrapEnabled = true;
      t.wrapMaxWidth = nw;
    });
  }

  // ================== SAVE ==================
  Future<void> _saveTemplate() async {
    try {
      if (_texts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add some text first!'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final saved = SavedReceiptTemplate(
        id: 'tpl_${DateTime.now().millisecondsSinceEpoch}',
        asset: widget.asset,
        texts: _texts.map((e) => e.copy()).toList(),
      );

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(kSavedReceiptTemplatesKey) ?? <String>[];

      raw.add(jsonEncode(saved.toJson()));
      await prefs.setStringList(kSavedReceiptTemplatesKey, raw);

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Template saved successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 1500));
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ReceiptPage()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      endDrawer: Container(
        margin: const EdgeInsets.only(top: 60, bottom: 70),
        width: MediaQuery.of(context).size.width * 0.8,
        child: Drawer(
          child: SafeArea(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    'ADD TEXT',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    itemCount: _sidebarItems.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final t = _sidebarItems[i];
                      return ListTile(
                        title: Text(t),
                        onTap: () => _addTextFromSidebar(t),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Stack(
              children: [
                SettingsHeader(onBack: () => Navigator.pop(context)),
                Positioned(
                  left: 16,
                  top: 12,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: masterGoldGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.28),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _openSidebar,
                      icon: const Icon(
                        Icons.add,
                        color: Colors.black,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      tooltip: 'Add Text',
                    ),
                  ),
                ),
              ],
            ),

            // ✅ FIXED HEIGHT TEMPLATE AREA
            Expanded(
              child: Container(
                key: _templateContainerKey,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final templateSize = Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              widget.asset.path,
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ),

                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () => setState(() => _activeId = null),
                            child: Container(color: Colors.transparent),
                          ),
                        ),

                        for (final t in _texts)
                          _PlacedTextWidget(
                            key: ValueKey(t.id),
                            model: t,
                            active: _activeId == t.id,
                            templateSize: templateSize,
                            shimmer: _shimmer,
                            onActivate: () => setState(() => _activeId = t.id),
                            onDelete: () => _deleteText(t.id),
                            onEdit: () => _editText(t.id),
                            onMoveStart: (d) => _onMoveStart(t.id, d),
                            onMoveUpdate: (d) => _onMoveUpdate(t.id, d),
                            onScaleStart: () => _onScaleStart(t.id),
                            onScaleUpdate: (d) => _onScaleUpdate(t.id),
                            onWidthStart: () => _onWidthStart(t.id),
                            onWidthUpdate: (d) => _onWidthUpdate(t.id),
                            onHeightStart: () => _onHeightStart(t.id),
                            onTopHeightUpdate: (d) =>
                                _onHeightUpdate(t.id, d, invert: true),
                            onBottomHeightUpdate: (d) =>
                                _onHeightUpdate(t.id, d, invert: false),
                            onWrapStart: () => _onWrapStart(t.id),
                            onWrapUpdate: (d) => _onWrapUpdate(t.id, d),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // ✅ SAVE button
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
              child: AnimatedBuilder(
                animation: _shimmer,
                builder: (_, __) {
                  final v = _shimmer.value;
                  final dx = (v * 2) - 1;

                  final shimmer = LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.65),
                      Colors.transparent,
                    ],
                    stops: const [0.2, 0.5, 0.8],
                    begin: Alignment(-1 + dx, 0),
                    end: Alignment(1 + dx, 0),
                  );

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Stack(
                      children: [
                        Container(
                          height: 52,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: masterGoldGradient,
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _saveTemplate,
                              child: const Center(
                                child: Text(
                                  'SAVE',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: ShaderMask(
                              shaderCallback: (r) => shimmer.createShader(r),
                              blendMode: BlendMode.srcATop,
                              child: Container(
                                color: Colors.white.withOpacity(0.30),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ====================== PLACED TEXT WIDGET ======================
class _PlacedTextWidget extends StatelessWidget {
  final PlacedTextModel model;
  final bool active;
  final Size templateSize;
  final AnimationController shimmer;

  final VoidCallback onActivate;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  final void Function(DragStartDetails d) onMoveStart;
  final void Function(DragUpdateDetails d) onMoveUpdate;

  final VoidCallback onScaleStart;
  final void Function(DragUpdateDetails d) onScaleUpdate;

  final VoidCallback onWidthStart;
  final void Function(DragUpdateDetails d) onWidthUpdate;

  final VoidCallback onHeightStart;
  final void Function(DragUpdateDetails d) onTopHeightUpdate;
  final void Function(DragUpdateDetails d) onBottomHeightUpdate;

  final VoidCallback onWrapStart;
  final void Function(DragUpdateDetails d) onWrapUpdate;

  const _PlacedTextWidget({
    super.key,
    required this.model,
    required this.active,
    required this.templateSize,
    required this.shimmer,
    required this.onActivate,
    required this.onDelete,
    required this.onEdit,
    required this.onMoveStart,
    required this.onMoveUpdate,
    required this.onScaleStart,
    required this.onScaleUpdate,
    required this.onWidthStart,
    required this.onWidthUpdate,
    required this.onHeightStart,
    required this.onTopHeightUpdate,
    required this.onBottomHeightUpdate,
    required this.onWrapStart,
    required this.onWrapUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final left = (model.posNorm.dx * templateSize.width).clamp(
      20.0,
      templateSize.width - model.baseBox - 20,
    );
    final top = (model.posNorm.dy * templateSize.height).clamp(
      20.0,
      templateSize.height - model.baseBox - 20,
    );

    final baseBox = model.baseBox;
    final wrapW = model.wrapEnabled ? model.wrapMaxWidth : model.baseWidth;

    const double hs = 20;
    const double offsetOut = 12;

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onActivate,
        onDoubleTap: onEdit,
        onPanStart: onMoveStart,
        onPanUpdate: onMoveUpdate,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: baseBox,
              height: baseBox,
              alignment: Alignment.center,
              decoration: active
                  ? BoxDecoration(
                      border: Border.all(color: Colors.white, width: 1.8),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.black.withOpacity(0.15),
                    )
                  : null,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.diagonal3Values(
                  model.scaleX,
                  model.scaleY,
                  1.0,
                ),
                child: SizedBox(
                  width: wrapW,
                  child: _GoldShimmerText(
                    anim: shimmer,
                    text: model.text,
                    fontScale: model.fontScale,
                    wrapEnabled: model.wrapEnabled,
                  ),
                ),
              ),
            ),

            if (active) ...[
              Positioned(
                left: -offsetOut,
                top: -offsetOut,
                child: _WhiteHandle(
                  size: hs,
                  child: const Icon(Icons.close, size: 14, color: Colors.black),
                  onTap: onDelete,
                ),
              ),

              Positioned(
                right: -offsetOut,
                bottom: -offsetOut,
                child: _WhiteDragHandle(
                  size: hs,
                  child: const Icon(Icons.open_in_full, size: 12, color: Colors.black),
                  onPanStart: (_) => onScaleStart(),
                  onPanUpdate: onScaleUpdate,
                ),
              ),

              Positioned(
                left: (baseBox / 2) - (hs / 2),
                top: -offsetOut,
                child: _WhiteDragHandle(
                  size: hs,
                  child: const Icon(Icons.more_horiz, size: 14, color: Colors.black),
                  onPanStart: (_) => onHeightStart(),
                  onPanUpdate: onTopHeightUpdate,
                ),
              ),

              Positioned(
                left: (baseBox / 2) - (hs / 2),
                bottom: -offsetOut,
                child: _WhiteDragHandle(
                  size: hs,
                  child: const Icon(Icons.more_horiz, size: 14, color: Colors.black),
                  onPanStart: (_) => onHeightStart(),
                  onPanUpdate: onBottomHeightUpdate,
                ),
              ),

              Positioned(
                left: -offsetOut,
                top: (baseBox / 2) - (hs / 2),
                child: _WhiteDragHandle(
                  size: hs,
                  child: const Icon(Icons.circle, size: 8, color: Colors.black),
                  onPanStart: (_) => onWidthStart(),
                  onPanUpdate: onWidthUpdate,
                ),
              ),

              Positioned(
                right: -offsetOut,
                top: (baseBox / 2) - (hs / 2),
                child: _WhiteDragHandle(
                  size: hs,
                  child: const Icon(Icons.circle, size: 8, color: Colors.black),
                  onPanStart: (_) => onWrapStart(),
                  onPanUpdate: onWrapUpdate,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Gold shimmer text
class _GoldShimmerText extends StatelessWidget {
  final AnimationController anim;
  final String text;
  final double fontScale;
  final bool wrapEnabled;

  const _GoldShimmerText({
    required this.anim,
    required this.text,
    required this.fontScale,
    required this.wrapEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final fs = (22.0 * fontScale).clamp(10.0, 140.0);
    final strokeW = (fs * 0.06).clamp(1.2, 6.0);

    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) {
        final t = anim.value;
        final dx = (t * 2) - 1;

        final shimmer = LinearGradient(
          colors: const [
            Color(0xFFD4AF37),
            Color(0xFFFFF3B0),
            Color(0xFFD4AF37),
          ],
          stops: const [0.2, 0.5, 0.8],
          begin: Alignment(-1 + dx, -0.2),
          end: Alignment(1 + dx, 0.2),
        );

        Widget strokeText = Text(
          text,
          textAlign: TextAlign.center,
          softWrap: wrapEnabled,
          maxLines: wrapEnabled ? null : 1,
          overflow: TextOverflow.visible,
          style: TextStyle(
            fontSize: fs,
            fontWeight: FontWeight.w900,
            height: 1.0,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeW
              ..color = Colors.black,
          ),
        );

        Widget fillText = ShaderMask(
          shaderCallback: (rect) => shimmer.createShader(rect),
          blendMode: BlendMode.srcIn,
          child: Text(
            text,
            textAlign: TextAlign.center,
            softWrap: wrapEnabled,
            maxLines: wrapEnabled ? null : 1,
            overflow: TextOverflow.visible,
            style: TextStyle(
              fontSize: fs,
              fontWeight: FontWeight.w900,
              height: 1.0,
              color: Colors.white,
            ),
          ),
        );

        if (!wrapEnabled) {
          return FittedBox(
            fit: BoxFit.scaleDown,
            child: Stack(
              alignment: Alignment.center,
              children: [strokeText, fillText],
            ),
          );
        }

        return Stack(
          alignment: Alignment.center,
          children: [strokeText, fillText],
        );
      },
    );
  }
}

class _WhiteHandle extends StatelessWidget {
  final double size;
  final Widget child;
  final VoidCallback onTap;

  const _WhiteHandle({
    required this.size,
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(width: size, height: size, child: Center(child: child)),
      ),
    );
  }
}

class _WhiteDragHandle extends StatelessWidget {
  final double size;
  final Widget child;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;

  const _WhiteDragHandle({
    required this.size,
    required this.child,
    required this.onPanStart,
    required this.onPanUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 3,
        child: SizedBox(width: size, height: size, child: Center(child: child)),
      ),
    );
  }
}

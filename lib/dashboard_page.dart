// lib/dashboard_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings.dart'; // ✅ DarkMode ON/OFF
import 'ui_kit.dart';
import 'create_template_page.dart'; // ✅ TemplateData + ItemData

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  String _shopName = "WAQAR TAILOR'S";

  bool get _isDark => AppSettings.darkModeVN.value;
  Color get _pageBg => _isDark ? Colors.black : Colors.white;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _editShopName() async {
    final ctrl = TextEditingController(text: _shopName);
    final val = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        title:
            const Text('Edit Header Name', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter name',
            hintStyle: TextStyle(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (!mounted || val == null || val.isEmpty) return;
    setState(() => _shopName = val.toUpperCase());
  }

  void _openSettings() => Navigator.pushNamed(context, '/settings');

  @override
  Widget build(BuildContext context) {
    // ✅ ONLY DarkMode OFF/ON background (UI/layout unchanged)
    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.darkModeVN,
      builder: (context, __, _) {
        return Scaffold(
          backgroundColor: _pageBg,
          body: SafeArea(
            child: Column(
              children: [
                _MainDashboardShell(
                  anim: _anim,
                  headerTitle: _shopName,
                  leftIcon: Icons.settings,
                  rightIcon: Icons.edit_note,
                  onLeftTap: _openSettings,
                  onRightTap: _editShopName,
                  tiles: [
                    // ✅ FIX 1: TileData -> _TileData
                    _TileData(
                      icon: Icons.person_add_alt_1,
                      lines: const ['NEW', 'CUSTOMER'],
                      onTap: () => Navigator.push(
                        context,
                        // ✅ FIX 2: builder must take context
                        MaterialPageRoute(
                          builder: (_) => const NewCustomerDashboardPage(),
                        ),
                      ),
                    ),
                    _TileData(
                      icon: Icons.history,
                      lines: const ['HISTORY'],
                      onTap: () => Navigator.pushNamed(context, '/history'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// ====================== NEW CUSTOMER DASHBOARD ======================
class NewCustomerDashboardPage extends StatefulWidget {
  const NewCustomerDashboardPage({super.key});
  @override
  State<NewCustomerDashboardPage> createState() =>
      _NewCustomerDashboardPageState();
}

class _NewCustomerDashboardPageState extends State<NewCustomerDashboardPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  final List<TemplateData> _templates = []; // ✅ create_template_page والا TemplateData
  static const String _prefsKey = 'saved_templates_v3';

  bool get _isDark => AppSettings.darkModeVN.value;
  Color get _pageBg => _isDark ? Colors.black : Colors.white;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat();

    _loadTemplates();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;

      final decoded = jsonDecode(raw);
      if (decoded is! List) return;

      final list = <TemplateData>[];
      for (final x in decoded) {
        final t = _templateFromJson(x);
        if (t != null) list.add(t);
      }

      if (!mounted) return;
      setState(() {
        _templates
          ..clear()
          ..addAll(list);
      });
    } catch (_) {}
  }

  Future<void> _saveTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_templates.map(_templateToJson).toList());
    await prefs.setString(_prefsKey, encoded);
  }

  Map<String, dynamic> _templateToJson(TemplateData t) => {
        'name': t.name,
        'items': t.items
            .map((i) => {
                  'id': i.id,
                  'type': i.type,
                  'label': i.label,
                  'isBig': i.isBig,
                  'left': i.left,
                  'top': i.top,
                  'width': i.width,
                  'height': i.height,
                })
            .toList(),
      };

  TemplateData? _templateFromJson(dynamic raw) {
    try {
      if (raw is! Map) return null;
      final name = (raw['name'] ?? '').toString();
      final itemsRaw = raw['items'];
      if (name.isEmpty || itemsRaw is! List) return null;

      final items = <ItemData>[];
      for (final x in itemsRaw) {
        if (x is! Map) continue;
        items.add(ItemData(
          id: (x['id'] ?? '').toString(),
          type: (x['type'] ?? '').toString(),
          label: (x['label'] ?? '').toString(),
          isBig: (x['isBig'] ?? false) == true,
          left: (x['left'] as num?)?.toDouble() ?? 0,
          top: (x['top'] as num?)?.toDouble() ?? 0,
          width: (x['width'] as num?)?.toDouble() ?? 120,
          height: (x['height'] as num?)?.toDouble() ?? 40,
        ));
      }

      return TemplateData(name: name, items: items);
    } catch (_) {
      return null;
    }
  }

  Future<void> _openCreateTemplate() async {
    final res = await Navigator.push<TemplateData>(
      context,
      // ✅ FIX: builder must take context
      MaterialPageRoute(builder: (_) => const CreateTemplatePage()),
    );

    if (!mounted || res == null) return;

    setState(() {
      final idx = _templates.indexWhere(
        (t) => t.name.trim().toLowerCase() == res.name.trim().toLowerCase(),
      );
      if (idx >= 0) {
        _templates[idx] = res;
      } else {
        _templates.add(res);
      }
    });

    await _saveTemplates();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Template Saved: ${res.name} ✅'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _openTemplate(TemplateData tpl) async {
    final res = await Navigator.push<TemplateData>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateTemplatePage.open(initialTemplate: tpl),
      ),
    );

    if (!mounted || res == null) return;

    setState(() {
      final idx = _templates.indexWhere(
        (t) => t.name.trim().toLowerCase() == res.name.trim().toLowerCase(),
      );
      if (idx >= 0) {
        _templates[idx] = res;
      } else {
        _templates.add(res);
      }
    });

    await _saveTemplates();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Template Updated: ${res.name} ✅'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _deleteTemplate(TemplateData tpl) async {
    setState(() {
      _templates.removeWhere(
        (t) => t.name.trim().toLowerCase() == tpl.name.trim().toLowerCase(),
      );
    });
    await _saveTemplates();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted: ${tpl.name} 🗑️'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _openSettings() => Navigator.pushNamed(context, '/settings');

  @override
  Widget build(BuildContext context) {
    final tiles = <_TileData>[
      _TileData(
        icon: Icons.tune,
        lines: const ['BY', 'DEFAULT'],
        onTap: () => Navigator.pushNamed(context, '/by_default'),
      ),
      _TileData(
        icon: Icons.dashboard_customize_outlined,
        lines: const ['CREATE', 'TEMPLATE'],
        onTap: _openCreateTemplate,
      ),
    ];

    return ValueListenableBuilder<bool>(
      valueListenable: AppSettings.darkModeVN,
      builder: (context, __, _) {
        return Scaffold(
          backgroundColor: _pageBg,
          body: SafeArea(
            child: Column(
              children: [
                _NewCustomerDashboardShell(
                  anim: _anim,
                  headerTitle: 'NEW CUSTOMER',
                  leftIcon: Icons.settings,
                  rightIcon: Icons.arrow_forward,
                  onLeftTap: _openSettings,
                  onRightTap: () => Navigator.pop(context),
                  tiles: tiles,
                ),
                if (_templates.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'SAVED TEMPLATES',
                      style: TextStyle(
                        color: (_isDark ? Colors.white : Colors.black)
                            .withOpacity(0.7),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      child: GridView.builder(
                        padding: const EdgeInsets.only(top: 8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 18,
                          mainAxisSpacing: 18,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: _templates.length,
                        itemBuilder: (context, index) {
                          final tpl = _templates[index];
                          return _SavedTemplateTileGoldDesign(
                            anim: _anim,
                            templateName: tpl.name,
                            onTap: () => _openTemplate(tpl),
                            onDelete: () => _deleteTemplate(tpl),
                          );
                        },
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: Center(
                      child: Text(
                        'No templates saved yet',
                        style: TextStyle(
                          color: (_isDark ? Colors.white : Colors.black)
                              .withOpacity(0.5),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
class _MainDashboardShell extends StatelessWidget {
  final AnimationController anim;
  final String headerTitle;
  final IconData leftIcon;
  final IconData rightIcon;
  final VoidCallback onLeftTap;
  final VoidCallback onRightTap;
  final List<_TileData> tiles;

  const _MainDashboardShell({
    required this.anim,
    required this.headerTitle,
    required this.leftIcon,
    required this.rightIcon,
    required this.onLeftTap,
    required this.onRightTap,
    required this.tiles,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 210,
          width: double.infinity,
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: masterGoldGradient,
                      stops: [0.0, 0.45, 0.72, 1.0],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(70),
                      bottomRight: Radius.circular(70),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: GoldIcon3D(icon: leftIcon, onTap: onLeftTap),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: GoldIcon3D(icon: rightIcon, onTap: onRightTap),
              ),
              Center(
                child: AnimatedBuilder(
                  animation: anim,
                  builder: (_, __) =>
                      Header3DShineText(text: headerTitle, t: anim.value),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        LayoutBuilder(
          builder: (_, c) {
            const gap = 18.0;
            const tileSpacing = 14.0;
            double tileSize = (c.maxWidth - gap - (2 * tileSpacing)) / 2;
            tileSize = tileSize.clamp(120.0, 160.0);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: tileSpacing),
              child: Row(
                children: [
                  Expanded(
                    child: _GoldTile(
                      anim: anim,
                      size: tileSize,
                      icon: tiles[0].icon,
                      lines: tiles[0].lines,
                      onTap: tiles[0].onTap,
                    ),
                  ),
                  const SizedBox(width: gap),
                  Expanded(
                    child: _GoldTile(
                      anim: anim,
                      size: tileSize,
                      icon: tiles[1].icon,
                      lines: tiles[1].lines,
                      onTap: tiles[1].onTap,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _NewCustomerDashboardShell extends StatelessWidget {
  final AnimationController anim;
  final String headerTitle;
  final IconData leftIcon;
  final IconData rightIcon;
  final VoidCallback onLeftTap;
  final VoidCallback onRightTap;
  final List<_TileData> tiles;

  const _NewCustomerDashboardShell({
    required this.anim,
    required this.headerTitle,
    required this.leftIcon,
    required this.rightIcon,
    required this.onLeftTap,
    required this.onRightTap,
    required this.tiles,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 210,
          width: double.infinity,
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: masterGoldGradient,
                      stops: [0.0, 0.45, 0.72, 1.0],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(70),
                      bottomRight: Radius.circular(70),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: GoldIcon3D(icon: leftIcon, onTap: onLeftTap),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: GoldIcon3D(icon: rightIcon, onTap: onRightTap),
              ),
              Center(
                child: AnimatedBuilder(
                  animation: anim,
                  builder: (_, __) =>
                      Header3DShineText(text: headerTitle, t: anim.value),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        LayoutBuilder(
          builder: (_, c) {
            const gap = 18.0;
            const tileSpacing = 14.0;
            double tileSize = (c.maxWidth - gap - (2 * tileSpacing)) / 2;
            tileSize = tileSize.clamp(120.0, 160.0);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: tileSpacing),
              child: Row(
                children: [
                  Expanded(
                    child: _GoldTile(
                      anim: anim,
                      size: tileSize,
                      icon: tiles[0].icon,
                      lines: tiles[0].lines,
                      onTap: tiles[0].onTap,
                    ),
                  ),
                  const SizedBox(width: gap),
                  Expanded(
                    child: _GoldTile(
                      anim: anim,
                      size: tileSize,
                      icon: tiles[1].icon,
                      lines: tiles[1].lines,
                      onTap: tiles[1].onTap,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _TileData {
  final IconData icon;
  final List<String> lines;
  final VoidCallback onTap;
  const _TileData({required this.icon, required this.lines, required this.onTap});
}

class _GoldTile extends StatelessWidget {
  final Animation<double> anim;
  final double size;
  final IconData icon;
  final List<String> lines;
  final VoidCallback onTap;

  const _GoldTile({
    required this.anim,
    required this.size,
    required this.icon,
    required this.lines,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const radius = 32.0;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: anim,
        builder: (_, __) {
          return Transform.translate(
            offset: const Offset(0, -2),
            child: CustomPaint(
              painter: BorderShimmerPainter(
                t: anim.value,
                radius: radius,
                strokeWidth: 3.4,
              ),
              child: Container(
                height: size,
                width: size,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF141414), Color(0xFF090909)],
                  ),
                  borderRadius: BorderRadius.circular(radius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.78),
                      blurRadius: 24,
                      offset: const Offset(0, 16),
                    ),
                    BoxShadow(
                      color: masterGoldGradient.first.withOpacity(0.12),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShaderMask(
                      shaderCallback: (rect) => const LinearGradient(
                        colors: masterGoldGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(rect),
                      blendMode: BlendMode.srcIn,
                      child: Icon(icon, size: 58, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    ...lines.map(
                      (line) => Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: GoldTextShimmer(
                          text: line,
                          t: anim.value,
                          fontSize: 15.5,
                          letterSpacing: 1.6,
                        ),
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
  }
}

class _SavedTemplateTileGoldDesign extends StatelessWidget {
  final Animation<double> anim;
  final String templateName;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SavedTemplateTileGoldDesign({
    required this.anim,
    required this.templateName,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const radius = 32.0;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedBuilder(
              animation: anim,
              builder: (_, __) {
                return Transform.translate(
                  offset: const Offset(0, -2),
                  child: CustomPaint(
                    painter: BorderShimmerPainter(
                      t: anim.value,
                      radius: radius,
                      strokeWidth: 3.4,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF141414), Color(0xFF090909)],
                        ),
                        borderRadius: BorderRadius.circular(radius),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.78),
                            blurRadius: 24,
                            offset: const Offset(0, 16),
                          ),
                          BoxShadow(
                            color: masterGoldGradient.first.withOpacity(0.12),
                            blurRadius: 18,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ShaderMask(
                            shaderCallback: (rect) => const LinearGradient(
                              colors: masterGoldGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(rect),
                            blendMode: BlendMode.srcIn,
                            child: const Icon(Icons.bookmark_added,
                                size: 58, color: Colors.white),
                          ),
                          const SizedBox(height: 12),
                          GoldTextShimmer(
                            text: templateName.toUpperCase(),
                            t: anim.value,
                            fontSize: 15.5,
                            letterSpacing: 1.6,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          top: 8,
          left: 8,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onDelete,
            child: Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black54,
                      blurRadius: 8,
                      offset: Offset(0, 4)),
                ],
              ),
              child:
                  const Icon(Icons.delete, color: Color(0xFFD4AF37), size: 18),
            ),
          ),
        ),
      ],
    );
  }
}
// lib/receipt_page.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings.dart';
import 'ui_kit.dart';
import 'settings_header.dart';
import 'receipt_template_page.dart';

const String _kSavedReceiptTemplatesKey = 'saved_receipt_templates_v2';

class ReceiptPage extends StatefulWidget {
  const ReceiptPage({super.key});

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  bool _loading = true;
  List<SavedReceiptTemplate> _saved = const [];

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kSavedReceiptTemplatesKey) ?? <String>[];

    final parsed = <SavedReceiptTemplate>[];
    for (final s in raw) {
      try {
        final j = jsonDecode(s) as Map<String, dynamic>;
        final t = SavedReceiptTemplate.fromJson(j);
        if (t != null) parsed.add(t);
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _saved = parsed;
      _loading = false;
    });
  }

  Future<void> _deleteTemplate(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: const Text('Are you sure you want to delete this template?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kSavedReceiptTemplatesKey) ?? <String>[];

    final next = <String>[];
    for (final s in raw) {
      try {
        final j = jsonDecode(s) as Map<String, dynamic>;
        final t = SavedReceiptTemplate.fromJson(j);
        if (t == null) continue;
        if (t.id != id) next.add(s);
      } catch (_) {
        next.add(s);
      }
    }

    await prefs.setStringList(_kSavedReceiptTemplatesKey, next);
    await _loadSaved();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Template deleted successfully'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppSettings.darkModeVN.value;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? null : Colors.white,
          gradient: isDark
              ? const LinearGradient(
                  colors: masterGoldGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: SafeArea(
          child: Column(
            children: [
              SettingsHeader(onBack: () => Navigator.pop(context)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                  child: _loading
                      ? const Center(
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(strokeWidth: 4),
                          ),
                        )
                      : (_saved.isEmpty)
                          ? const Center(
                              child: Text(
                                'NO SAVED RECEIPTS YET',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            )
                          : GridView.builder(
                              itemCount: _saved.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 9 / 16,
                              ),
                              itemBuilder: (context, index) {
                                final t = _saved[index];
                                return _SavedTemplateCard(
                                  tpl: t,
                                  onTap: () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ReceiptFillSharePage(template: t),
                                      ),
                                    );
                                    _loadSaved();
                                  },
                                  onDelete: () => _deleteTemplate(t.id),
                                );
                              },
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedTemplateCard extends StatelessWidget {
  final SavedReceiptTemplate tpl;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SavedTemplateCard({
    required this.tpl,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final preview = tpl.asset.previewImagePathForGrid;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withOpacity(0.25), width: 2),
          color: Colors.white.withOpacity(0.10),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                preview,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),

              Positioned(
                left: 8,
                top: 8,
                child: GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ======================= FILL + SHARE PAGE =======================
class ReceiptFillSharePage extends StatefulWidget {
  final SavedReceiptTemplate template;

  const ReceiptFillSharePage({super.key, required this.template});

  @override
  State<ReceiptFillSharePage> createState() => _ReceiptFillSharePageState();
}

class _ReceiptFillSharePageState extends State<ReceiptFillSharePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  final GlobalKey _templateContainerKey = GlobalKey();
  final Map<String, String> _values = {};

  static const Set<String> _placeholders = {
    'NAME',
    'SERIAL',
    'QUANTITY',
    'RUPEES',
    'RETURN',
    'ADVANCE',
  };

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  Future<void> _editValue(String key) async {
    final controller = TextEditingController(text: _values[key] ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Enter $key'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (result == null) return;
    setState(() => _values[key] = result.trim());
  }

  void _share() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('SHARE functionality coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tpl = widget.template;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            SettingsHeader(onBack: () => Navigator.pop(context)),

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
                    final size = Size(
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
                              tpl.asset.previewImagePathForGrid,
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ),

                        // ✅ ALL TEXTS DISPLAY
                        if (tpl.texts.isNotEmpty)
                          for (final txt in tpl.texts)
                            _FillPlacedText(
                              key: ValueKey(txt.id),
                              anim: _ac,
                              model: txt,
                              values: _values,
                              onPlaceholderTap: (k) => _editValue(k),
                              templateSize: size,
                            ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // ✅ SHARE button
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: AnimatedBuilder(
                animation: _ac,
                builder: (_, __) {
                  final t = _ac.value;
                  final dx = (t * 2) - 1;

                  final shimmer = LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.7),
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
                          height: 54,
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
                                color: Colors.black.withOpacity(0.30),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _share,
                              child: const Center(
                                child: Text(
                                  'SHARE',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.1,
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

class _FillPlacedText extends StatelessWidget {
  final AnimationController anim;
  final PlacedTextModel model;
  final Map<String, String> values;
  final void Function(String key) onPlaceholderTap;
  final Size templateSize;

  const _FillPlacedText({
    super.key,
    required this.anim,
    required this.model,
    required this.values,
    required this.onPlaceholderTap,
    required this.templateSize,
  });

  static const Set<String> _placeholders = {
    'NAME',
    'SERIAL',
    'QUANTITY',
    'RUPEES',
    'RETURN',
    'ADVANCE',
  };

  @override
  Widget build(BuildContext context) {
    final key = model.text.trim().toUpperCase();
    final isPh = _placeholders.contains(key);

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

    Widget child;
    if (!isPh) {
      child = Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(model.scaleX, model.scaleY, 1.0),
        child: SizedBox(
          width: wrapW,
          child: _GoldShimmerStatic(
            anim: anim,
            text: model.text,
            fontScale: model.fontScale,
            wrapEnabled: model.wrapEnabled,
          ),
        ),
      );
    } else {
      final v = values[key] ?? '';
      child = Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(model.scaleX, model.scaleY, 1.0),
        child: SizedBox(
          width: wrapW,
          child: _GoldShimmerPlaceholderRow(
            anim: anim,
            label: '$key:',
            value: v,
            fontScale: model.fontScale,
          ),
        ),
      );
    }

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: isPh ? () => onPlaceholderTap(key) : null,
        child: SizedBox(
          width: baseBox,
          height: baseBox,
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _GoldShimmerStatic extends StatelessWidget {
  final AnimationController anim;
  final String text;
  final double fontScale;
  final bool wrapEnabled;

  const _GoldShimmerStatic({
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

class _GoldShimmerPlaceholderRow extends StatelessWidget {
  final AnimationController anim;
  final String label;
  final String value;
  final double fontScale;

  const _GoldShimmerPlaceholderRow({
    required this.anim,
    required this.label,
    required this.value,
    required this.fontScale,
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

        Widget strokeRow = Row(
          children: [
            Flexible(
              flex: 0,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: fs,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = strokeW
                    ..color = Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  value.isEmpty ? '' : value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: fs,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = strokeW
                      ..color = Colors.black,
                  ),
                ),
              ),
            ),
          ],
        );

        Widget fillRow = ShaderMask(
          shaderCallback: (rect) => shimmer.createShader(rect),
          blendMode: BlendMode.srcIn,
          child: Row(
            children: [
              Flexible(
                flex: 0,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: fs,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    value.isEmpty ? '' : value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: fs,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [strokeRow, fillRow],
          ),
        );
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'receipt_template_page.dart';
import 'receipt_export_service.dart';
import 'settings_header.dart';

class ReceiptFillPage extends StatefulWidget {
  final TemplateAsset asset;

  const ReceiptFillPage({super.key, required this.asset});

  @override
  State<ReceiptFillPage> createState() => _ReceiptFillPageState();
}

class _ReceiptFillPageState extends State<ReceiptFillPage> {
  final Map<String, TextEditingController> _fields = {
    'NAME': TextEditingController(),
    'SERIAL': TextEditingController(),
    'QUANTITY': TextEditingController(),
    'RUPEES': TextEditingController(),
    'RETURN': TextEditingController(),
    'ADVANCE': TextEditingController(),
  };

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _shareReceipt() async {
    final emptyFields = _fields.entries
        .where((entry) => entry.value.text.trim().isEmpty)
        .map((entry) => entry.key)
        .toList();

    if (emptyFields.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill: ${emptyFields.join(", ")}'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await ReceiptExportService.exportAndShare(
      context: context,
      asset: widget.asset,
      values: _fields.map((k, v) => MapEntry(k, v.text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            SettingsHeader(onBack: () => Navigator.pop(context)),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: _fields.entries.map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: TextField(
                      controller: e.value,
                      decoration: InputDecoration(
                        labelText: e.key,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9),
                      ),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _shareReceipt,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.share, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'SHARE RECEIPT',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
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
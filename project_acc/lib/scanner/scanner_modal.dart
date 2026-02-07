import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerModal extends StatefulWidget {
  final Function(String) onScan;

  const ScannerModal({
    super.key,
    required this.onScan,
  });

  @override
  State<ScannerModal> createState() => _ScannerModalState();
}

class _ScannerModalState extends State<ScannerModal> {

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF14141A) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1C1C28);
    final textMuted = isDark ? Colors.white70 : Colors.grey.shade600;
    final border = isDark ? Colors.white12 : Colors.grey.shade300;

    return Dialog(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Header
          Container(
            color: Colors.deepPurple.shade700,
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Icon(Icons.qr_code_2, color: Colors.white, size: 24),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scan Barcode/QR Code',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Point your camera at a barcode or QR code',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),

          // Content - Camera Scanner
          Container(
            height: 400,
            width: 400,
            color: Colors.black,
            child: MobileScanner(
              onDetect: (capture) {
                final barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final rawValue = barcodes.first.rawValue;
                  if (rawValue != null && rawValue.isNotEmpty) {
                    print("Barcode detected: $rawValue");
                    widget.onScan(rawValue);
                    Navigator.pop(context);
                  }
                }
              },
            ),
          ),

          // Cancel Button
          Container(
            color: surface,
            padding: EdgeInsets.all(8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  foregroundColor: textPrimary,
                  side: BorderSide(color: border),
                ),
                child: Text('Cancel'),
              ),
            ),
          ),
        ],
      ),
    )
    );
  }
}

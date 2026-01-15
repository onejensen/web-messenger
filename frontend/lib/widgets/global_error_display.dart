import 'package:flutter/material.dart';
import 'dart:async';

class GlobalErrorDisplay extends StatefulWidget {
  final FlutterErrorDetails? errorDetails;
  final VoidCallback onRetry;

  const GlobalErrorDisplay({
    super.key,
    this.errorDetails,
    required this.onRetry,
  });

  @override
  State<GlobalErrorDisplay> createState() => _GlobalErrorDisplayState();
}

class _GlobalErrorDisplayState extends State<GlobalErrorDisplay> {
  int _countdown = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          timer.cancel();
          widget.onRetry();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.redAccent,
                  size: 64,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Unexpected error detected',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'The messenger will now reload automatically to the last stable state to ensure your security and data integrity.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: widget.onRetry,
                  icon: const Icon(Icons.restore_rounded),
                  label: Text('Restore Messenger ($_countdown)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              if (widget.errorDetails != null) ...[
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Error Details'),
                        content: SingleChildScrollView(
                          child: Text(
                            widget.errorDetails.toString(),
                            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                          ),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))
                        ],
                      ),
                    );
                  },
                  child: const Text(
                    'View Technical Details',
                    style: TextStyle(color: Colors.white38),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

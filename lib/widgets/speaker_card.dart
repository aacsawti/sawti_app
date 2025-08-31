import 'package:flutter/material.dart';
import 'dart:async';

class _SpeakerCard extends StatefulWidget {
  final Map<String, dynamic> speaker;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onPlay;

  const _SpeakerCard({
    required this.speaker,
    required this.isSelected,
    required this.onSelect,
    required this.onPlay,
  });

  @override
  __SpeakerCardState createState() => __SpeakerCardState();
}

class __SpeakerCardState extends State<_SpeakerCard> {
  bool _isPlaying = false;
  Timer? _playTimer;

  @override
  void dispose() {
    _playTimer?.cancel();
    super.dispose();
  }

  Future<void> _handlePlay() async {
    if (_isPlaying) return;

    setState(() => _isPlaying = true);
    widget.onPlay();

    // محاكاة مدة التشغيل (3 ثواني)
    _playTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final speakerDialect = widget.speaker['dialect'] ?? 'MSA';
    final dialectName =
        speakerDialect == 'MSA'
            ? 'الفصحى'
            : speakerDialect == 'Egyptian'
            ? 'مصري'
            : 'إماراتي';

    return GestureDetector(
      onTap: widget.onSelect,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color:
              widget.isSelected
                  ? Theme.of(context).primaryColor.withOpacity(0.2)
                  : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color:
                widget.isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage(
                widget.speaker['avatar_path'] as String? ??
                    'assets/images/default_avatar.png',
              ),
              radius: 30,
            ),
            const SizedBox(height: 5),
            Text(
              '${widget.speaker['name']} ($dialectName)',
              style: TextStyle(
                fontWeight:
                    widget.isSelected ? FontWeight.bold : FontWeight.normal,
                color:
                    widget.isSelected
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            // زر تجربة الصوت
            IconButton(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color:
                      _isPlaying
                          ? Colors.green
                          : Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.volume_up, color: Colors.white, size: 20),
              ),
              onPressed: _handlePlay,
            ),
          ],
        ),
      ),
    );
  }
}
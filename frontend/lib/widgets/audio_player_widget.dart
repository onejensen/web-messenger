import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../config/config.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final bool isMe;

  const AudioPlayerWidget({super.key, required this.audioUrl, required this.isMe});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((state) {
      if(mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
    });

    _player.onDurationChanged.listen((d) {
      if(mounted) setState(() => _duration = d);
    });

    _player.onPositionChanged.listen((p) {
      if(mounted) setState(() => _position = p);
    });

    _player.onPlayerComplete.listen((_) {
      if(mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
        // No manual seek/pause needed here, play() in toggle will handle restart
      }
    });

    // Preload source to get duration
    _initSource();
  }

  Future<void> _initSource() async {
     try {
       String url = widget.audioUrl;
       if(!url.startsWith('http')) {
            url = '${Config.baseUrl}/$url';
       }
       await _player.setSource(UrlSource(url));
     } catch(e) {
       print('Error loading audio source: $e');
     }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
  
  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _togglePlay() async {
    try {
      if (_isPlaying) {
        await _player.pause();
      } else {
          // Construct full URL if relative
          String url = widget.audioUrl;
          if(!url.startsWith('http')) {
              url = '${Config.baseUrl}/$url';
          }
          final source = UrlSource(url);
          
          if(_player.state == PlayerState.paused) {
             await _player.resume();
          } else {
             // If stopped or completed, use play() to ensuring restarting
             await _player.play(source);
          }
      }
    } catch (e) {
      print('Audio Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Row(
        children: [
          IconButton(
            icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
            color: widget.isMe ? Colors.white : Colors.deepPurpleAccent,
            iconSize: 32,
            onPressed: _togglePlay,
          ),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Slider(
                      value: _position.inSeconds.toDouble(),
                      min: 0,
                      max: _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1.0,
                      onChanged: (v) {}, // Seek not implemented for simplicity
                      activeColor: widget.isMe ? Colors.white : Colors.deepPurpleAccent,
                      inactiveColor: Colors.grey,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                          '${_formatTime(_position)} / ${_formatTime(_duration)}',
                          style: TextStyle(fontSize: 10, color: widget.isMe ? Colors.white70 : Colors.black54),
                      ),
                    )
                ]
            )
          ),
        ],
      ),
    );
  }
}

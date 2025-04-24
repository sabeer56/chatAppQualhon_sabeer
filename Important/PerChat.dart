import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;

class PersonalChat extends StatefulWidget {
  @override
  PersonalChatScreen createState() => PersonalChatScreen();
}

class PersonalChatScreen extends State<PersonalChat>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final List<Message> _messages = [
    Message(isSender: true, message: 'Good Morning!', time: '10:00 am'),
    Message(isSender: false, message: 'Good Morning!', time: '10:01 am'),
    Message(isSender: true, message: 'Epdi Iruka', time: '10:02 am'),
    Message(isSender: false, message: 'Nalla Irukeyn..!', time: '10:03 am'),
    Message(isSender: true, message: 'Enna panra', time: '10:03 am'),
    Message(isSender: false, message: 'Saaptutu Irukeyn', time: '10:04 am'),
  ];
  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  String? _recordedFilePath;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Map<int, bool> _isDeleting = {};
  double _glowRadius = 20;
  Offset _micOffset = Offset(0, 0);
  Timer? _glowTimer;
  bool _isCancelled = false;
  double _micScale = 1.0;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  String _transcribedText = '';

  @override
  void initState() {
    super.initState();
    _initRecorder();
    _requestPermissions();
  }

  Future<void> _initRecorder() async {
    if (kIsWeb) {
      return;
    }
    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
  }

  Future<void> _requestPermissions() async {
    if (kIsWeb) return;
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Microphone permission is required')),
      );
    }
  }

  void _startGlowAnimation() {
    _glowTimer = Timer.periodic(Duration(milliseconds: 600), (timer) {
      if (_isRecording) {
        setState(() {
          _glowRadius = _glowRadius == 20 ? 40 : 20;
        });
      }
    });
  }

  Future<void> _startRecording() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recording not supported on web')),
      );
      return;
    }
    try {
      String path;
      if (Platform.isAndroid) {
        path =
            '/sdcard/Download/voice_message_${DateTime.now().millisecondsSinceEpoch}.aac';
      } else if (Platform.isIOS) {
        path =
            '${(await getApplicationDocumentsDirectory()).path}/voice_message_${DateTime.now().millisecondsSinceEpoch}.aac';
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recording not supported on this platform')),
        );
        return;
      }
      _recordedFilePath = path;
      await _recorder!
          .startRecorder(toFile: _recordedFilePath, codec: Codec.aacADTS);

      _recordingDuration = Duration.zero;
      _recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration += Duration(seconds: 1);
        });
      });

      _transcribedText = '';
      Timer.periodic(Duration(seconds: 2), (timer) {
        if (_isRecording) {
          setState(() {
            _transcribedText += 'Sample text... ';
          });
        } else {
          timer.cancel();
        }
      });

      setState(() {
        _isRecording = true;
        _isCancelled = false;
        _micScale = 1.2;
      });
      _startGlowAnimation();
    } catch (e) {
      print('Error starting recording: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start recording: $e')),
      );
      setState(() {
        _isRecording = false;
        _micOffset = Offset.zero;
        _glowRadius = 20;
        _micScale = 1.0;
        _recordingDuration = Duration.zero;
        _transcribedText = '';
      });
    }
  }

  Future<void> _stopRecording() async {
    if (kIsWeb) return;
    _glowTimer?.cancel();
    _recordingTimer?.cancel();
    try {
      await _recorder!.stopRecorder();
      if (_isCancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Recording Cancelled")),
        );
        if (_recordedFilePath != null &&
            await File(_recordedFilePath!).exists()) {
          await File(_recordedFilePath!).delete();
        }
      } else {
        if (_recordedFilePath != null &&
            await File(_recordedFilePath!).exists()) {
          setState(() {
            _messages.add(
              Message(
                isSender: true,
                message: _transcribedText.isNotEmpty ? _transcribedText : '',
                time: _formatCurrentTime(),
                voicePath: _recordedFilePath,
              ),
            );
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Recording Saved")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: Recorded file not found')),
          );
        }
      }
    } catch (e) {
      print('Error stopping recording: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to stop recording: $e')),
      );
    }
    setState(() {
      _isRecording = false;
      _micOffset = Offset.zero;
      _glowRadius = 20;
      _micScale = 1.0;
      _recordingDuration = Duration.zero;
      _transcribedText = '';
    });
  }

  void _cancelRecording() {
    if (!_isCancelled) {
      HapticFeedback.lightImpact();
      setState(() {
        _isCancelled = true;
      });
    }
  }

  void _resetCancel() {
    if (_isCancelled) {
      HapticFeedback.lightImpact();
      setState(() {
        _isCancelled = false;
      });
    }
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        _messages.add(
          Message(
              isSender: true,
              message: _controller.text,
              time: _formatCurrentTime()),
        );
        _controller.clear();
      });
    }
  }

  void _deleteMessage(int index) {
    if (index >= 0 && index < _messages.length) {
      setState(() {
        _isDeleting[index] = true;
      });
      Future.delayed(Duration(milliseconds: 1000), () {
        if (index < _messages.length) {
          setState(() {
            _messages.removeAt(index);
            _isDeleting.remove(index);
          });
        }
      });
    }
  }

  void _showMessageOptions(BuildContext context, int index) {
    if (index >= 0 && index < _messages.length) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Message Options'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text('Delete for Me'),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmationDialog(context, index);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
            ],
          );
        },
      );
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Message'),
          content: Text('Are you sure you want to delete this message?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteMessage(index);
                Navigator.pop(context);
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showPersonSettings(BuildContext context, String personName) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Stack(
          children: [
            Positioned(
              top: 60,
              right: 50,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  width: 185,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Info',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.edit),
                        title: const Text('Edit Name',
                            style: TextStyle(fontSize: 12)),
                        onTap: () {
                          Navigator.pop(context);
                          _showEditDialog(context, 'Edit Name');
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.delete),
                        title: const Text('Delete Chat',
                            style: TextStyle(fontSize: 12)),
                        onTap: () {
                          Navigator.pop(context);
                          _deleteChat();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMoreOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Stack(
          children: [
            Positioned(
              top: 60,
              right: 10,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  width: 185,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Options',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.settings),
                        title: const Text('Settings',
                            style: TextStyle(fontSize: 12)),
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.block),
                        title:
                            const Text('Block', style: TextStyle(fontSize: 12)),
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.logout),
                        title: const Text('Logout',
                            style: TextStyle(fontSize: 12)),
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteChat() {
    setState(() {
      _messages.clear();
    });
  }

  void _showEditDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController _editController = TextEditingController();
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: _editController,
            decoration: InputDecoration(
              hintText:
                  title == 'Edit Name' ? 'Enter new name' : 'Enter new message',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  String _formatCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : now.hour;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'pm' : 'am';
    return '$hour:$minute $period';
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      _recorder?.closeRecorder();
    }
    _controller.dispose();
    _audioPlayer.dispose();
    _glowTimer?.cancel();
    _recordingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    var isSmallScreen = screenSize.width < 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.teal[100],
              child: FaIcon(FontAwesomeIcons.user, color: Colors.teal[800]),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Person Name',
                    style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.bold)),
                Text('Online',
                    style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        color: Colors.teal[100])),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            color: Colors.teal[100],
            onPressed: () {
              _showPersonSettings(context, 'Person Name');
            },
          ),
          IconButton(
            icon: FaIcon(FontAwesomeIcons.ellipsisVertical,
                size: isSmallScreen ? 20 : 24, color: Colors.teal[100]),
            onPressed: () {
              _showMoreOptionsDialog(context);
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal[50]!, Colors.white],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final GlobalKey contentKey = GlobalKey();
                  return DustAnimation(
                    isDeleting: _isDeleting[index] ?? false,
                    onAnimationComplete: () {
                      if (index < _messages.length) {
                        setState(() {
                          _messages.removeAt(index);
                          _isDeleting.remove(index);
                        });
                      }
                    },
                    child: GestureDetector(
                      onLongPress: () => _showMessageOptions(context, index),
                      child: ChatBubble(
                        isSender: message.isSender,
                        message: message.message,
                        time: message.time,
                        voicePath: message.voicePath,
                        audioPlayer: _audioPlayer,
                        contentKey: contentKey,
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  if (_isRecording)
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.teal[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _transcribedText.isEmpty
                                  ? 'Listening...'
                                  : _transcribedText,
                              style: TextStyle(
                                color: Colors.teal[800],
                                fontSize: 14,
                                overflow: TextOverflow.ellipsis,
                              ),
                              maxLines: 1,
                            ),
                          ),
                          Text(
                            _formatDuration(_recordingDuration),
                            style: TextStyle(
                              color: Colors.teal[800],
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          AnimatedOpacity(
                            opacity: _isCancelled ? 1.0 : 0.0,
                            duration: Duration(milliseconds: 200),
                            child: Padding(
                              padding: EdgeInsets.only(left: 10),
                              child: Text(
                                'Drag to cancel',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  TextField(
                                    style: TextStyle(color: Colors.teal[800]),
                                    controller: _controller,
                                    decoration: InputDecoration(
                                      hintText: 'Write a message...',
                                      hintStyle:
                                          TextStyle(color: Colors.teal[300]),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 10),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_isRecording && _micOffset.dx < -50)
                              Positioned(
                                bottom: 3,
                                right: 60,
                                child: AnimatedOpacity(
                                  opacity: _micOffset.dx < -50 ? 1.0 : 0.0,
                                  duration: Duration(milliseconds: 200),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.red[400],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            Positioned(
                              bottom: 3,
                              right: 10,
                              child: Transform.translate(
                                offset: _micOffset,
                                child: Transform.scale(
                                  scale: _micScale,
                                  child: GestureDetector(
                                    onLongPressStart: (_) => _startRecording(),
                                    onLongPressEnd: (_) => _stopRecording(),
                                    onLongPressMoveUpdate: (details) {
                                      setState(() {
                                        double newDx = _micOffset.dx +
                                            details.offsetFromOrigin.dx;
                                        double newDy = _micOffset.dy +
                                            details.offsetFromOrigin.dy;

                                        newDx = newDx.clamp(-200.0, 10.0);
                                        newDy = newDy.clamp(-30.0, 30.0);

                                        _micOffset = Offset(newDx, newDy);

                                        if (_micOffset.dx < -120) {
                                          _cancelRecording();
                                        } else {
                                          _resetCancel();
                                        }

                                        _micScale =
                                            1.2 - (_micOffset.dx.abs() / 2000);
                                        _micScale = _micScale.clamp(1.0, 1.2);
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: Duration(milliseconds: 300),
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: _isCancelled
                                              ? [
                                                  Colors.grey[600]!,
                                                  Colors.grey[800]!
                                                ]
                                              : [
                                                  Colors.teal,
                                                  Colors.teal[700]!
                                                ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: _isRecording
                                            ? [
                                                BoxShadow(
                                                  color: Colors.teal
                                                      .withOpacity(0.6),
                                                  blurRadius: _glowRadius,
                                                  spreadRadius: 2,
                                                )
                                              ]
                                            : [
                                                BoxShadow(
                                                  color: Colors.black26,
                                                  blurRadius: 5,
                                                  offset: Offset(0, 2),
                                                )
                                              ],
                                      ),
                                      child: Icon(
                                        _isRecording
                                            ? (_isCancelled
                                                ? Icons.delete
                                                : Icons.mic)
                                            : Icons.mic,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 10),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.teal, Colors.teal[700]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(Icons.send, color: Colors.white),
                          onPressed: _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DustAnimation extends StatefulWidget {
  final bool isDeleting;
  final Widget child;
  final VoidCallback onAnimationComplete;

  DustAnimation({
    required this.isDeleting,
    required this.child,
    required this.onAnimationComplete,
  });

  @override
  _DustAnimationState createState() => _DustAnimationState();
}

class _DustAnimationState extends State<DustAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _particles = List.generate(100, (_) => Particle());

    if (widget.isDeleting) {
      _controller.forward().then((_) => widget.onAnimationComplete());
    }

    _controller.addListener(() {
      setState(() {
        for (var p in _particles) {
          p.update(_controller.value);
        }
      });
    });
  }

  @override
  void didUpdateWidget(covariant DustAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDeleting && !oldWidget.isDeleting) {
      _controller.forward().then((_) => widget.onAnimationComplete());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Opacity(
          opacity: 1 - _controller.value,
          child: widget.child,
        ),
        if (widget.isDeleting)
          ..._particles.map((p) {
            return Positioned(
              left: p.position.dx,
              top: p.position.dy,
              child: Opacity(
                opacity: p.opacity.clamp(0.0, 1.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                    child: Container(
                      width: p.size,
                      height: p.size,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.teal[300]!, Colors.teal[600]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
      ],
    );
  }
}

class Particle {
  Offset position;
  Offset velocity;
  double size;
  double opacity;

  Particle()
      : position =
            Offset(Random().nextDouble() * 300, Random().nextDouble() * 100),
        velocity = Offset(
            Random().nextDouble() * 2 - 1, Random().nextDouble() * 2 - 1),
        size = Random().nextDouble() * 8 + 2,
        opacity = 1.0;

  void update(double t) {
    position += velocity * 4;
    opacity = max(0, 1 - t * 2);
  }
}

class ChatBubble extends StatelessWidget {
  final bool isSender;
  final String message;
  final String time;
  final String? voicePath;
  final AudioPlayer audioPlayer;
  final GlobalKey contentKey;

  ChatBubble({
    Key? key,
    required this.isSender,
    required this.message,
    required this.time,
    this.voicePath,
    required this.audioPlayer,
    required this.contentKey,
  }) : super(key: key);

  Future<void> _playAudio(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await audioPlayer.play(DeviceFileSource(path));
      } else {
        print('Error: Audio file not found at $path');
      }
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    var isSmallScreen = screenSize.width < 600;

    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Column(
          crossAxisAlignment:
              isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: isSender ? Radius.circular(20) : Radius.circular(0),
                topRight: isSender ? Radius.circular(20) : Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight:
                    isSender ? Radius.circular(20) : Radius.circular(20),
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: screenSize.width * 0.7,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isSender
                        ? [Colors.teal[400]!, Colors.teal[600]!]
                        : [Colors.grey[200]!, Colors.grey[300]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    color: Colors.transparent,
                    child: Column(
                      crossAxisAlignment: isSender
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        if (voicePath != null)
                          Row(
                            key: contentKey,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.play_circle_filled,
                                  color: isSender
                                      ? Colors.white.withOpacity(0.9)
                                      : Colors.teal[800],
                                ),
                                onPressed: () => _playAudio(voicePath!),
                              ),
                              Text(
                                'Voice Message',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  color: isSender
                                      ? Colors.white.withOpacity(0.9)
                                      : Colors.teal[800],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            message,
                            key: contentKey,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              color: isSender
                                  ? Colors.white.withOpacity(0.9)
                                  : Colors.teal[800],
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 6),
            Text(
              time,
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Message {
  final bool isSender;
  final String message;
  final String time;
  final String? voicePath;

  Message({
    required this.isSender,
    required this.message,
    required this.time,
    this.voicePath,
  });
}

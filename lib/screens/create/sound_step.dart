// File location: lib/screens/create/sound_step.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class SoundStep extends StatefulWidget {
  final File? audioFile;
  final double audioRating;
  final Function(File?) onAudioFileChanged;
  final Function(double) onAudioRatingChanged;

  const SoundStep({
    super.key,
    this.audioFile,
    required this.audioRating,
    required this.onAudioFileChanged,
    required this.onAudioRatingChanged,
  });

  @override
  _SoundStepState createState() => _SoundStepState();
}

class _SoundStepState extends State<SoundStep> {
  final FlutterSoundRecorder _soundRecorder = FlutterSoundRecorder();
  bool _isRecording = false;
  bool _isRecorderInitialized = false;
  String? _recordingPath;
  bool _isMounted = true; // Track mounted state

  @override
  void initState() {
    super.initState();
    // Initialize the recorder after a short delay to ensure widget is properly mounted
    Future.delayed(Duration.zero, () {
      if (_isMounted) {
        _initRecorder();
      }
    });
  }

  @override
  void dispose() {
    _isMounted = false; // Mark as unmounted first
    _cleanupRecorder();
    super.dispose();
  }

  // Safely cleanup recorder resources
  Future<void> _cleanupRecorder() async {
    try {
      if (_isRecorderInitialized) {
        if (_isRecording) {
          await _soundRecorder.stopRecorder();
          _isRecording = false;
        }
        await _soundRecorder.closeRecorder();
        _isRecorderInitialized = false;
      }
    } catch (e) {
      print('Error cleaning up recorder: $e');
    }
  }

  // Initialize audio recorder with better error handling
  Future<void> _initRecorder() async {
    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        print('Microphone permission not granted: $status');
        return;
      }

      // Open recorder with proper error handling
      await _soundRecorder.openRecorder();
      if (_isMounted) {
        setState(() {
          _isRecorderInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing recorder: $e');
      // Only update UI if still mounted
      if (_isMounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to initialize audio recorder: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Start recording audio
  Future<void> _startRecording() async {
    if (!_isRecorderInitialized) {
      print('Recorder not initialized');
      return;
    }

    try {
      // Create temp file path
      final Directory tempDir = await getTemporaryDirectory();
      _recordingPath =
          '${tempDir.path}/temp_recording_${DateTime.now().millisecondsSinceEpoch}.aac';

      await _soundRecorder.startRecorder(
        toFile: _recordingPath,
        codec: Codec.aacMP4,
      );

      if (_isMounted) {
        setState(() {
          _isRecording = true;
        });
      }
    } catch (e) {
      print('Error starting recording: $e');
      // Only update UI if still mounted
      if (_isMounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting recording: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Stop recording audio
  Future<void> _stopRecording() async {
    if (!_isRecorderInitialized || !_isRecording) {
      return;
    }

    try {
      final path = await _soundRecorder.stopRecorder();

      if (_isMounted) {
        setState(() {
          _isRecording = false;
        });

        if (path != null) {
          widget.onAudioFileChanged(File(path));
        }
      }
    } catch (e) {
      print('Error stopping recording: $e');
      if (_isMounted) {
        setState(() {
          _isRecording = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving recording: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recording status
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[800]!, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.mic, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Audio Recording',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (widget.audioFile != null)
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: () {
                        widget.onAudioFileChanged(null);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Recording visualization (simplified)
              Container(
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    _isRecording
                        ? Center(
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 60,
                            itemBuilder: (context, index) {
                              // Simulated audio visualization
                              final double height = 10 + (index % 3) * 20.0;

                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 1,
                                ),
                                width: 3,
                                height: height,
                                decoration: BoxDecoration(
                                  color: Colors.blue[400],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              );
                            },
                          ),
                        )
                        : widget.audioFile != null
                        ? const Center(
                          child: Text(
                            'Recording saved',
                            style: TextStyle(color: Colors.green, fontSize: 16),
                          ),
                        )
                        : const Center(
                          child: Text(
                            'No recording yet',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ),
              ),
              const SizedBox(height: 20),

              // Record button
              Center(
                child: GestureDetector(
                  onTap: _isRecording ? _stopRecording : _startRecording,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _isRecording ? Colors.red : Colors.blue[700],
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              _isRecording
                                  ? Colors.red.withOpacity(0.3)
                                  : Colors.blue.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Recording status text
              Center(
                child: Text(
                  _isRecording
                      ? 'Recording audio... Tap to stop'
                      : 'Tap to start recording',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Audio quality rating
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[800]!, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rate Audio Quality',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'How good is the ambient sound at this location?',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Poor',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  Text(
                    'Excellent',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
              Slider(
                value: widget.audioRating,
                min: 1.0,
                max: 5.0,
                divisions: 8,
                label: widget.audioRating.toStringAsFixed(1),
                activeColor: Colors.green,
                inactiveColor: Colors.grey[800],
                onChanged: widget.onAudioRatingChanged,
              ),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.volume_up, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Rating: ${widget.audioRating.toStringAsFixed(1)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

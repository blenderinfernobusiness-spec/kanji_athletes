import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import 'input_resources.dart';
import 'revision_resources.dart';
import 'lessons_resources.dart';
import 'other_resources.dart';

class LibraryScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const LibraryScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  ui.Image? _exitImage;
  ByteData? _exitImageData;
  bool _isHovering = false;
  
  ui.Image? _inputImage;
  ByteData? _inputImageData;
  bool _isHoveringInput = false;
  
  ui.Image? _revisionImage;
  ByteData? _revisionImageData;
  bool _isHoveringRevision = false;
  
  ui.Image? _lessonsImage;
  ByteData? _lessonsImageData;
  bool _isHoveringLessons = false;
  
  ui.Image? _otherImage;
  ByteData? _otherImageData;
  bool _isHoveringOther = false;
  
  @override
  void initState() {
    super.initState();
    // Force landscape orientation when entering library
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _loadExitImage();
    _loadInputImage();
    _loadRevisionImage();
    _loadLessonsImage();
    _loadOtherImage();
  }

  Future<void> _loadExitImage() async {
    final ByteData data = await rootBundle.load('assets/libraryexit.png');
    final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ByteData? byteData = await frameInfo.image.toByteData(format: ui.ImageByteFormat.rawRgba);
    setState(() {
      _exitImage = frameInfo.image;
      _exitImageData = byteData;
    });
  }

  Future<void> _loadInputImage() async {
    final ByteData data = await rootBundle.load('assets/libraryinput.png');
    final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ByteData? byteData = await frameInfo.image.toByteData(format: ui.ImageByteFormat.rawRgba);
    setState(() {
      _inputImage = frameInfo.image;
      _inputImageData = byteData;
    });
  }

  Future<void> _loadRevisionImage() async {
    final ByteData data = await rootBundle.load('assets/libraryrevision.png');
    final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ByteData? byteData = await frameInfo.image.toByteData(format: ui.ImageByteFormat.rawRgba);
    setState(() {
      _revisionImage = frameInfo.image;
      _revisionImageData = byteData;
    });
  }

  Future<void> _loadLessonsImage() async {
    final ByteData data = await rootBundle.load('assets/librarylessons.png');
    final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ByteData? byteData = await frameInfo.image.toByteData(format: ui.ImageByteFormat.rawRgba);
    setState(() {
      _lessonsImage = frameInfo.image;
      _lessonsImageData = byteData;
    });
  }

  Future<void> _loadOtherImage() async {
    final ByteData data = await rootBundle.load('assets/libraryother.png');
    final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ByteData? byteData = await frameInfo.image.toByteData(format: ui.ImageByteFormat.rawRgba);
    setState(() {
      _otherImage = frameInfo.image;
      _otherImageData = byteData;
    });
  }

  @override
  void dispose() {
    // Restore all orientations when leaving library
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _exitImage?.dispose();
    _inputImage?.dispose();
    _revisionImage?.dispose();
    _lessonsImage?.dispose();
    _otherImage?.dispose();
    super.dispose();
  }

  Future<bool> _isPixelTransparent(Offset localPosition, Size imageSize, ui.Image? image, ByteData? imageData) async {
    if (image == null || imageData == null) return false;

    // Convert tap position to image coordinates
    final double scaleX = image.width / imageSize.width;
    final double scaleY = image.height / imageSize.height;
    
    final int x = (localPosition.dx * scaleX).floor().clamp(0, image.width - 1);
    final int y = (localPosition.dy * scaleY).floor().clamp(0, image.height - 1);

    // Calculate pixel position (RGBA = 4 bytes per pixel)
    final int pixelOffset = (y * image.width + x) * 4;
    final int alpha = imageData.getUint8(pixelOffset + 3);

    // Return true if transparent (alpha < threshold)
    return alpha < 10;
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool rotateVertically = screenSize.height > screenSize.width;
    final double innerWidth = rotateVertically ? screenSize.height : screenSize.width;
    final double innerHeight = rotateVertically ? screenSize.width : screenSize.height;

    // Prepare the FAB so it can be placed inside the rotated content when needed.
    final Widget fab = FloatingActionButton(
      onPressed: () async {
          final List<String> images = [
            'assets/bookclosed.png',
            'assets/bookopen.png',
            'assets/bookopencard1.png',
            'assets/bookopencard2.png',
            'assets/bookopencard3.png',
            'assets/bookopencard4.png',
          ];
          // Precache images to avoid decode/display flicker between taps
          try {
            await Future.wait(images.map((p) => precacheImage(AssetImage(p), context)));
          } catch (_) {
            // ignore precache errors and continue to show dialog
          }

          showGeneralDialog(
            context: context,
            barrierDismissible: true,
            barrierLabel: 'Book',
            barrierColor: Colors.black54,
            transitionDuration: const Duration(milliseconds: 200),
            pageBuilder: (context, animation1, animation2) {
              int stage = 0;
              return StatefulBuilder(
                builder: (context, setDialogState) {
                  return GestureDetector(
                    // Tapping outside the centered image will dismiss the dialog
                    onTap: () => Navigator.of(context).pop(),
                    child: Material(
                      color: Colors.transparent,
                      child: Center(
                        child: GestureDetector(
                          // Tapping the image advances to the next stage
                          onTap: () async {
                            if (stage < images.length - 1) {
                              setDialogState(() {
                                stage++;
                              });
                              return;
                            }

                            // On final stage, open the sapphire overlay with download button
                            await precacheImage(const AssetImage('assets/sapphire1S22.png'), context);
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: Colors.transparent,
                                content: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ConstrainedBox(
                                        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
                                        child: Image.asset('assets/sapphire1S22.png', fit: BoxFit.contain),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.download),
                                        label: const Text('Download'),
                                        onPressed: () async {
                                          try {
                                            final bd = await rootBundle.load('assets/sapphire1S22.png');
                                            final bytes = bd.buffer.asUint8List();
                                            final dir = await getApplicationDocumentsDirectory();
                                            final filePath = p.join(dir.path, 'sapphire1S22.png');
                                            final f = File(filePath);
                                            await f.writeAsBytes(bytes);
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to $filePath')));
                                            }
                                          } catch (e) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Download failed')));
                                            }
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.link),
                                        label: const Text('Download link'),
                                        onPressed: () async {
                                          final uri = Uri.parse('https://drive.google.com/file/d/10ckiMiVZ6ski4y9PH4sB-aAByVFhbuTU/view?usp=sharing');
                                          try {
                                            if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open link')));
                                            }
                                          } catch (_) {
                                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open link')));
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                actionsAlignment: MainAxisAlignment.center,
                                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                              ),
                            );
                          },
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
                            child: Image.asset(
                              images[stage],
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      backgroundColor: Colors.transparent,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      child: const Icon(Icons.add, color: Colors.transparent),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      // When rotating the whole library content we place the FAB inside the
      // rotated stack so it moves/rotates with the content. Otherwise keep
      // the normal scaffold FAB placement.
      floatingActionButtonLocation: rotateVertically ? null : FloatingActionButtonLocation.startFloat,
      floatingActionButton: rotateVertically ? null : fab,
      body: SafeArea(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Center(
            child: Builder(
              builder: (context) {
                Widget contentStack = Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      'assets/librarybg.png',
                      fit: BoxFit.contain,
                      width: innerWidth,
                      height: innerHeight,
                    ),
                    Image.asset(
                      'assets/librarylessons.png',
                      fit: BoxFit.contain,
                      width: innerWidth,
                      height: innerHeight,
                    ),
                    Image.asset(
                      'assets/libraryrevision.png',
                      fit: BoxFit.contain,
                      width: innerWidth,
                      height: innerHeight,
                    ),
                    Image.asset(
                      'assets/libraryinput.png',
                      fit: BoxFit.contain,
                      width: innerWidth,
                      height: innerHeight,
                    ),
                    // Place the exit artwork beneath the 'other' artwork so that
                    // 'libraryother.png' can appear on top when the images
                    // overlap at smaller sizes.
                    Image.asset(
                      'assets/libraryexit.png',
                      fit: BoxFit.contain,
                      width: innerWidth,
                      height: innerHeight,
                    ),
                    Image.asset(
                      'assets/libraryother.png',
                      fit: BoxFit.contain,
                      width: innerWidth,
                      height: innerHeight,
                    ),
                    if (_isHovering || _isHoveringInput || _isHoveringRevision || _isHoveringLessons || _isHoveringOther)
                      Container(
                        width: innerWidth,
                        height: innerHeight,
                        color: Colors.black.withOpacity(0.4),
                      ),
                    // Show the hovered button on top, undimmed. Render exit
                    // first and then 'other' so that 'other' appears above
                    // exit when both would otherwise overlap.
                    if (_isHoveringLessons)
                      Image.asset(
                        'assets/librarylessons.png',
                        fit: BoxFit.contain,
                        width: innerWidth,
                        height: innerHeight,
                      ),
                    if (_isHoveringRevision)
                      Image.asset(
                        'assets/libraryrevision.png',
                        fit: BoxFit.contain,
                        width: innerWidth,
                        height: innerHeight,
                      ),
                    if (_isHoveringInput)
                      Image.asset(
                        'assets/libraryinput.png',
                        fit: BoxFit.contain,
                        width: innerWidth,
                        height: innerHeight,
                      ),
                    if (_isHovering)
                      Image.asset(
                        'assets/libraryexit.png',
                        fit: BoxFit.contain,
                        width: innerWidth,
                        height: innerHeight,
                      ),
                    if (_isHoveringOther)
                      Image.asset(
                        'assets/libraryother.png',
                        fit: BoxFit.contain,
                        width: innerWidth,
                        height: innerHeight,
                      ),
                    MouseRegion(
                      cursor: (_isHovering || _isHoveringInput || _isHoveringRevision || _isHoveringLessons || _isHoveringOther) ? SystemMouseCursors.click : SystemMouseCursors.basic,
                      onHover: (event) async {
                        final RenderBox? box = context.findRenderObject() as RenderBox?;
                        if (box == null) return;

                        final Offset rawLocal = box.globalToLocal(event.position);
                        // Use the rendered image size (innerWidth x innerHeight).
                        final Size imageSize = Size(innerWidth, innerHeight);
                        // When rotated, map the pointer into the original (unrotated)
                        // image coordinate space so pixel tests align with the visuals.
                        final Offset localPosition = rotateVertically
                            ? Offset(rawLocal.dy, innerWidth - rawLocal.dx)
                            : rawLocal;

                        // Check buttons in order (top to bottom in stack)
                        // Check buttons in visual top-to-bottom order: other is
                        // now rendered above exit, so test it first.
                        final bool otherTransparent = await _isPixelTransparent(localPosition, imageSize, _otherImage, _otherImageData);
                        if (!otherTransparent) {
                          if (mounted) {
                            setState(() {
                              _isHovering = false;
                              _isHoveringInput = false;
                              _isHoveringRevision = false;
                              _isHoveringLessons = false;
                              _isHoveringOther = true;
                            });
                          }
                          return;
                        }

                        final bool exitTransparent = await _isPixelTransparent(localPosition, imageSize, _exitImage, _exitImageData);
                        if (!exitTransparent) {
                          if (mounted) {
                            setState(() {
                              _isHovering = true;
                              _isHoveringInput = false;
                              _isHoveringRevision = false;
                              _isHoveringLessons = false;
                              _isHoveringOther = false;
                            });
                          }
                          return;
                        }

                        final bool inputTransparent = await _isPixelTransparent(localPosition, imageSize, _inputImage, _inputImageData);
                        if (!inputTransparent) {
                          if (mounted) {
                            setState(() {
                              _isHovering = false;
                              _isHoveringInput = true;
                              _isHoveringRevision = false;
                              _isHoveringLessons = false;
                              _isHoveringOther = false;
                            });
                          }
                          return;
                        }

                        final bool revisionTransparent = await _isPixelTransparent(localPosition, imageSize, _revisionImage, _revisionImageData);
                        if (!revisionTransparent) {
                          if (mounted) {
                            setState(() {
                              _isHovering = false;
                              _isHoveringInput = false;
                              _isHoveringRevision = true;
                              _isHoveringLessons = false;
                              _isHoveringOther = false;
                            });
                          }
                          return;
                        }

                        final bool lessonsTransparent = await _isPixelTransparent(localPosition, imageSize, _lessonsImage, _lessonsImageData);
                        if (mounted) {
                          setState(() {
                            _isHovering = false;
                            _isHoveringInput = false;
                            _isHoveringRevision = false;
                            _isHoveringLessons = !lessonsTransparent;
                            _isHoveringOther = false;
                          });
                        }
                      },
                      onExit: (_) => setState(() {
                        _isHovering = false;
                        _isHoveringInput = false;
                        _isHoveringRevision = false;
                        _isHoveringLessons = false;
                        _isHoveringOther = false;
                      }),
                      child: GestureDetector(
                        onTapDown: (details) async {
                          final RenderBox box = context.findRenderObject() as RenderBox;
                          final Offset rawLocal = box.globalToLocal(details.globalPosition);
                          final Size imageSize = Size(innerWidth, innerHeight);
                          final Offset localPosition = rotateVertically
                              ? Offset(rawLocal.dy, innerWidth - rawLocal.dx)
                              : rawLocal;

                          // Check buttons in order (top to bottom in stack)
                          // Test 'other' first since it now renders above 'exit'.
                          final bool otherTransparent = await _isPixelTransparent(localPosition, imageSize, _otherImage, _otherImageData);
                          if (!otherTransparent && mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => OtherResourcesScreen(isDarkMode: widget.isDarkMode, onThemeChanged: widget.onThemeChanged)),
                            );
                            return;
                          }

                          final bool exitTransparent = await _isPixelTransparent(localPosition, imageSize, _exitImage, _exitImageData);
                          if (!exitTransparent && mounted) {
                            Navigator.pop(context);
                            return;
                          }

                          final bool inputTransparent = await _isPixelTransparent(localPosition, imageSize, _inputImage, _inputImageData);
                          if (!inputTransparent && mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => InputResourcesScreen(isDarkMode: widget.isDarkMode, onThemeChanged: widget.onThemeChanged)),
                            );
                            return;
                          }

                          final bool revisionTransparent = await _isPixelTransparent(localPosition, imageSize, _revisionImage, _revisionImageData);
                          if (!revisionTransparent && mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => RevisionResourcesScreen(isDarkMode: widget.isDarkMode, onThemeChanged: widget.onThemeChanged)),
                            );
                            return;
                          }

                          final bool lessonsTransparent = await _isPixelTransparent(localPosition, imageSize, _lessonsImage, _lessonsImageData);
                          if (!lessonsTransparent && mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => LessonsResourcesScreen(isDarkMode: widget.isDarkMode, onThemeChanged: widget.onThemeChanged)),
                            );
                          }
                        },
                        child: Container(
                          width: innerWidth,
                          height: innerHeight,
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                    // If rotating the whole content, render the FAB inside the
                    // content stack so it rotates and keeps its relative
                    // position to the library artwork.
                    if (rotateVertically)
                      Positioned(
                        left: 16,
                        bottom: 16,
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: fab,
                        ),
                      ),

                    // A large 'Other' button placed inside the content stack so
                    // it rotates together with the library artwork. It performs
                    // the same navigation as tapping the 'libraryother' area.
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Opacity(
                        opacity: 0.0,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 70), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), backgroundColor: Colors.transparent, shadowColor: Colors.transparent, elevation: 0),
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Other'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => OtherResourcesScreen(isDarkMode: widget.isDarkMode, onThemeChanged: widget.onThemeChanged)),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );

                Widget screenContent;
                if (rotateVertically) {
                  screenContent = RotatedBox(
                    quarterTurns: 1,
                    child: SizedBox(width: innerWidth, height: innerHeight, child: contentStack),
                  );
                } else {
                  screenContent = contentStack;
                }

                return screenContent;
              },
            ),
          ),
        ),
      ),
    );
  }
}

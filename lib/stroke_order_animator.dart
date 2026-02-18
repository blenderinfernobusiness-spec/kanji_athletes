import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import 'package:http/http.dart' as http;

class StrokeOrderAnimator extends StatefulWidget {
  final String? kanjiVGCode;
  final List<String>? kanjiVGCodes;
  final bool isDarkMode;

  const StrokeOrderAnimator({
    super.key,
    this.kanjiVGCode,
    this.kanjiVGCodes,
    required this.isDarkMode,
  }) : assert(kanjiVGCode != null || kanjiVGCodes != null, 'Either kanjiVGCode or kanjiVGCodes must be provided');

  @override
  State<StrokeOrderAnimator> createState() => _StrokeOrderAnimatorState();
}

class _StrokeOrderAnimatorState extends State<StrokeOrderAnimator> {
  List<String> _strokePaths = [];
  List<int> _strokeKanjiIndices = []; // Track which kanji each stroke belongs to
  int _kanjiCount = 1;
  int _currentStroke = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStrokes();
  }

  Future<void> _loadStrokes() async {
    try {
      List<String> allStrokes = [];
      List<int> strokeIndices = [];
      
      // Get list of codes to load
      final codes = widget.kanjiVGCodes ?? [widget.kanjiVGCode!];
      _kanjiCount = codes.length;
      
      // Load strokes from each kanji
      for (int kanjiIndex = 0; kanjiIndex < codes.length; kanjiIndex++) {
        final code = codes[kanjiIndex];
        final url = 'https://raw.githubusercontent.com/KanjiVG/kanjivg/master/kanji/$code.svg';
        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final document = XmlDocument.parse(response.body);
          
          // Find all path elements with stroke IDs
          final allPaths = document.findAllElements('path');
          
          // KanjiVG stroke paths have IDs like "kvg:xxxxx-s1", "kvg:xxxxx-s2", etc.
          for (var path in allPaths) {
            final id = path.getAttribute('id');
            final d = path.getAttribute('d');
            
            if (d != null && d.isNotEmpty && id != null) {
              // Check if this is a stroke (has -s followed by digit)
              final regex = RegExp(r'-s\d+$');
              if (regex.hasMatch(id)) {
                allStrokes.add(d);
                strokeIndices.add(kanjiIndex);
              }
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _strokePaths = allStrokes;
          _strokeKanjiIndices = strokeIndices;
          _isLoading = false;
          _currentStroke = allStrokes.isNotEmpty ? 1 : 0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }
  void _nextStroke() {
    if (_currentStroke < _strokePaths.length && mounted) {
      setState(() {
        _currentStroke++;
      });
    }
  }

  void _previousStroke() {
    if (_currentStroke > 1 && mounted) {
      setState(() {
        _currentStroke--;
      });
    }
  }

  void _reset() {
    if (mounted) {
      setState(() {
        _currentStroke = 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: 300,
        height: 350,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const CircularProgressIndicator(),
      );
    }

    if (_error != null || _strokePaths.isEmpty) {
      return Container(
        width: 300,
        height: 350,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _error ?? 'No stroke data',
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
      );
    }

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Step-by-step display
          Container(
            width: 300,
            height: 300,
            padding: const EdgeInsets.all(20),
            child: CustomPaint(
              painter: StrokePainter(
                strokePaths: _strokePaths,
                strokeKanjiIndices: _strokeKanjiIndices,
                kanjiCount: _kanjiCount,
                currentStroke: _currentStroke,
                isDarkMode: widget.isDarkMode,
              ),
            ),
          ),
          // Controls
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                Text(
                  'Stroke $_currentStroke of ${_strokePaths.length}',
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white : Colors.black,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _reset,
                      color: const Color(0xFF9A00FE),
                      tooltip: 'Reset',
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _currentStroke > 1 ? _previousStroke : null,
                      color: _currentStroke > 1 ? const Color(0xFF9A00FE) : Colors.grey,
                      tooltip: 'Previous',
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: _currentStroke < _strokePaths.length ? _nextStroke : null,
                      color: _currentStroke < _strokePaths.length ? const Color(0xFF9A00FE) : Colors.grey,
                      tooltip: 'Next',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StrokePainter extends CustomPainter {
  final List<String> strokePaths;
  final List<int> strokeKanjiIndices;
  final int kanjiCount;
  final int currentStroke;
  final bool isDarkMode;

  StrokePainter({
    required this.strokePaths,
    required this.strokeKanjiIndices,
    required this.kanjiCount,
    required this.currentStroke,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background
    final bgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // KanjiVG uses 109x109 viewBox
    // Calculate spacing between characters
    final kanjiWidth = 109.0;
    final kanjiHeight = 109.0;
    final spacing = 10.0;
    final totalWidth = (kanjiWidth * kanjiCount) + (spacing * (kanjiCount - 1));
    final scale = size.width / totalWidth;
    
    // Calculate vertical centering offset
    final scaledHeight = kanjiHeight * scale;
    final yOffset = (size.height - scaledHeight) / 2;
    
    canvas.save();
    canvas.translate(0, yOffset);
    canvas.scale(scale);

    // Stroke width should be in SVG coordinate space
    final grayPaint = Paint()
      ..color = Colors.grey[400]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final purplePaint = Paint()
      ..color = const Color(0xFF9A00FE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (int i = 0; i < currentStroke && i < strokePaths.length; i++) {
      final kanjiIndex = strokeKanjiIndices[i];
      final xOffset = kanjiIndex * (kanjiWidth + spacing);
      
      canvas.save();
      canvas.translate(xOffset, 0);
      
      final path = _parseSVGPath(strokePaths[i]);
      final paint = (i == currentStroke - 1) ? purplePaint : grayPaint;
      canvas.drawPath(path, paint);
      
      canvas.restore();
    }
    
    canvas.restore();
  }

  Path _parseSVGPath(String pathData) {
    final path = Path();
    final commands = pathData.split(RegExp(r'(?=[MLCQZHVSmlcqzhvs])'));

    double currentX = 0, currentY = 0;
    double startX = 0, startY = 0;
    double lastControlX = 0, lastControlY = 0;
    String? lastCommand;

    for (var command in commands) {
      if (command.isEmpty) continue;

      final type = command[0];
      final coordString = command.substring(1).trim();
      
      // Better coordinate parsing: split on spaces, commas, and also before minus signs
      final coords = coordString
          .replaceAll(',', ' ')
          .replaceAllMapped(RegExp(r'(\d)-'), (match) => '${match.group(1)} -')  // Add space before minus
          .split(RegExp(r'\s+'))
          .where((s) => s.isNotEmpty)
          .map((s) => double.tryParse(s) ?? 0)
          .toList();

      switch (type) {
        case 'M':
          if (coords.length >= 2) {
            currentX = coords[0];
            currentY = coords[1];
            startX = currentX;
            startY = currentY;
            path.moveTo(currentX, currentY);
          }
          break;
        case 'm':
          if (coords.length >= 2) {
            currentX += coords[0];
            currentY += coords[1];
            startX = currentX;
            startY = currentY;
            path.moveTo(currentX, currentY);
          }
          break;
        case 'L':
          for (int i = 0; i + 1 < coords.length; i += 2) {
            currentX = coords[i];
            currentY = coords[i + 1];
            path.lineTo(currentX, currentY);
          }
          break;
        case 'l':
          for (int i = 0; i + 1 < coords.length; i += 2) {
            currentX += coords[i];
            currentY += coords[i + 1];
            path.lineTo(currentX, currentY);
          }
          break;
        case 'H':
          for (var x in coords) {
            currentX = x;
            path.lineTo(currentX, currentY);
          }
          break;
        case 'h':
          for (var dx in coords) {
            currentX += dx;
            path.lineTo(currentX, currentY);
          }
          break;
        case 'V':
          for (var y in coords) {
            currentY = y;
            path.lineTo(currentX, currentY);
          }
          break;
        case 'v':
          for (var dy in coords) {
            currentY += dy;
            path.lineTo(currentX, currentY);
          }
          break;
        case 'C':
          for (int i = 0; i + 5 < coords.length; i += 6) {
            lastControlX = coords[i + 2];
            lastControlY = coords[i + 3];
            currentX = coords[i + 4];
            currentY = coords[i + 5];
            path.cubicTo(coords[i], coords[i + 1], lastControlX, lastControlY, currentX, currentY);
          }
          break;
        case 'c':
          for (int i = 0; i + 5 < coords.length; i += 6) {
            path.cubicTo(
              currentX + coords[i], currentY + coords[i + 1],
              currentX + coords[i + 2], currentY + coords[i + 3],
              currentX + coords[i + 4], currentY + coords[i + 5]
            );
            lastControlX = currentX + coords[i + 2];
            lastControlY = currentY + coords[i + 3];
            currentX += coords[i + 4];
            currentY += coords[i + 5];
          }
          break;
        case 'S':
          for (int i = 0; i + 3 < coords.length; i += 4) {
            double cp1x = currentX;
            double cp1y = currentY;
            if (lastCommand == 'C' || lastCommand == 'c' || lastCommand == 'S' || lastCommand == 's') {
              cp1x = 2 * currentX - lastControlX;
              cp1y = 2 * currentY - lastControlY;
            }
            lastControlX = coords[i];
            lastControlY = coords[i + 1];
            currentX = coords[i + 2];
            currentY = coords[i + 3];
            path.cubicTo(cp1x, cp1y, lastControlX, lastControlY, currentX, currentY);
          }
          break;
        case 's':
          for (int i = 0; i + 3 < coords.length; i += 4) {
            double cp1x = currentX;
            double cp1y = currentY;
            if (lastCommand == 'C' || lastCommand == 'c' || lastCommand == 'S' || lastCommand == 's') {
              cp1x = 2 * currentX - lastControlX;
              cp1y = 2 * currentY - lastControlY;
            }
            lastControlX = currentX + coords[i];
            lastControlY = currentY + coords[i + 1];
            path.cubicTo(
              cp1x, cp1y,
              lastControlX, lastControlY,
              currentX + coords[i + 2], currentY + coords[i + 3]
            );
            currentX += coords[i + 2];
            currentY += coords[i + 3];
          }
          break;
        case 'Q':
          for (int i = 0; i + 3 < coords.length; i += 4) {
            lastControlX = coords[i];
            lastControlY = coords[i + 1];
            currentX = coords[i + 2];
            currentY = coords[i + 3];
            path.quadraticBezierTo(lastControlX, lastControlY, currentX, currentY);
          }
          break;
        case 'q':
          for (int i = 0; i + 3 < coords.length; i += 4) {
            lastControlX = currentX + coords[i];
            lastControlY = currentY + coords[i + 1];
            currentX += coords[i + 2];
            currentY += coords[i + 3];
            path.quadraticBezierTo(lastControlX, lastControlY, currentX, currentY);
          }
          break;
        case 'Z':
        case 'z':
          path.close();
          currentX = startX;
          currentY = startY;
          break;
      }
      
      lastCommand = type;
    }

    return path;
  }

  @override
  bool shouldRepaint(StrokePainter oldDelegate) {
    return oldDelegate.currentStroke != currentStroke;
  }
}

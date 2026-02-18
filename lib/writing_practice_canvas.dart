import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import 'package:http/http.dart' as http;

class WritingPracticeCanvas extends StatefulWidget {
    final int resetCounter;
  final List<String>? kanjiVGCodes;
  final bool isDarkMode;
  final String kanji;
  final String translation;
  final double scale;
  final bool hideButtons;
  final bool hideCanvas;
  final bool showHintByDefault;

  const WritingPracticeCanvas({
    super.key,
    required this.kanjiVGCodes,
    required this.isDarkMode,
    required this.kanji,
    required this.translation,
    this.scale = 1.0,
    this.hideButtons = false,
    this.hideCanvas = false,
    this.showHintByDefault = false,
    this.resetCounter = 0,
  });

  @override
  State<WritingPracticeCanvas> createState() => _WritingPracticeCanvasState();
}

class _WritingPracticeCanvasState extends State<WritingPracticeCanvas> {
    int _lastResetCounter = 0;
  List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  List<String> _strokePaths = [];
  List<List<String>> _strokeGroups = []; // Groups of strokes per kanji
  int _hintStroke = 0;
  late bool _showHint;
  bool _showAnswer = false;
  double _thickness = 1.0; // Default thickness multiplier

  @override
  void initState() {
    super.initState();
    _showHint = widget.showHintByDefault;
    if (widget.kanjiVGCodes != null && widget.kanjiVGCodes!.isNotEmpty) {
      _loadStrokes();
    }
    _lastResetCounter = widget.resetCounter;
  }

  @override
  void didUpdateWidget(covariant WritingPracticeCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.resetCounter != _lastResetCounter) {
      _clear();
      _lastResetCounter = widget.resetCounter;
    }
  }

  Future<void> _loadStrokes() async {
    try {
      List<String> allStrokes = [];
      List<List<String>> groups = [];
      
      // Load strokes for each kanji
      for (final kanjiVGCode in widget.kanjiVGCodes!) {
        final url = 'https://raw.githubusercontent.com/KanjiVG/kanjivg/master/kanji/$kanjiVGCode.svg';
        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final document = XmlDocument.parse(response.body);
          final allPaths = document.findAllElements('path');
          List<String> kanjiStrokes = [];
          
          for (var path in allPaths) {
            final id = path.getAttribute('id');
            final d = path.getAttribute('d');
            
            if (d != null && d.isNotEmpty && id != null) {
              final regex = RegExp(r'-s\d+$');
              if (regex.hasMatch(id)) {
                allStrokes.add(d);
                kanjiStrokes.add(d);
              }
            }
          }
          
          if (kanjiStrokes.isNotEmpty) {
            groups.add(kanjiStrokes);
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _strokePaths = allStrokes;
        _strokeGroups = groups;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _strokePaths = [];
        _strokeGroups = [];
      });
    }
  }

  void _clear() {
    setState(() {
      _strokes = [];
      _currentStroke = [];
    });
  }

  void _nextHint() {
    if (_hintStroke < _strokePaths.length - 1) {
      setState(() {
        _hintStroke++;
        _showHint = true;
      });
    }
  }

  void _previousHint() {
    if (_hintStroke > 0) {
      setState(() {
        _hintStroke--;
        _showHint = true;
      });
    }
  }

  void _resetHint() {
    setState(() {
      _hintStroke = 0;
      _showHint = true;
    });
  }

  void _toggleHint() {
    setState(() {
      _showHint = !_showHint;
    });
  }

  void _toggleAnswer() {
    setState(() {
      _showAnswer = !_showAnswer;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Show kanji and translation when answer is revealed
        if (_showAnswer) ...[
          Text(
            widget.kanji,
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : Colors.black,
              fontSize: 48 * widget.scale,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            widget.translation,
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white70 : Colors.black54,
              fontSize: 18 * widget.scale,
            ),
          ),
          const SizedBox(height: 20),
        ],
        // Drawing canvas or hint display
        Container(
          width: 400 * widget.scale,
          height: 400 * widget.scale,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isDarkMode ? Colors.white24 : Colors.black12,
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: widget.hideCanvas
                ? CustomPaint(
                    size: Size(400 * widget.scale, 400 * widget.scale),
                    painter: WritingCanvasPainter(
                      strokes: _strokes,
                      currentStroke: _currentStroke,
                      strokePaths: _strokePaths,
                      strokeGroups: _strokeGroups,
                      hintStroke: _hintStroke,
                      showHint: _showHint,
                      showAnswer: _showAnswer,
                      thickness: _thickness,
                      scale: widget.scale,
                      wordText: widget.kanji,
                    ),
                  )
                : GestureDetector(
              behavior: HitTestBehavior.opaque,
              // Claim both vertical and horizontal drags so the parent ScrollView
              // does not steal gestures while the user is writing on the canvas.
              onVerticalDragStart: (details) {
                setState(() {
                  _currentStroke = [details.localPosition];
                });
              },
              onVerticalDragUpdate: (details) {
                setState(() {
                  _currentStroke.add(details.localPosition);
                });
              },
              onVerticalDragEnd: (details) {
                setState(() {
                  _strokes.add(List.from(_currentStroke));
                  _currentStroke = [];
                });
              },
              onHorizontalDragStart: (details) {
                setState(() {
                  _currentStroke = [details.localPosition];
                });
              },
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _currentStroke.add(details.localPosition);
                });
              },
              onHorizontalDragEnd: (details) {
                setState(() {
                  _strokes.add(List.from(_currentStroke));
                  _currentStroke = [];
                });
              },
              child: SizedBox(
                width: 400 * widget.scale,
                height: 400 * widget.scale,
                child: CustomPaint(
                  size: Size(400 * widget.scale, 400 * widget.scale),
                  isComplex: true,
                  willChange: true,
                  painter: WritingCanvasPainter(
                    strokes: _strokes,
                    currentStroke: _currentStroke,
                    strokePaths: _strokePaths,
                    strokeGroups: _strokeGroups,
                    hintStroke: _hintStroke,
                    showHint: _showHint,
                    showAnswer: _showAnswer,
                    thickness: _thickness,
                    scale: widget.scale,
                    wordText: widget.kanji,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (!widget.hideCanvas)
          const SizedBox(height: 15),
        // Thickness slider and clear button (clear only in writing arcade)
        if (!widget.hideCanvas)
          SizedBox(
            width: 380 * widget.scale,
            child: Column(
              children: [
                Text(
                  'Stroke Thickness',
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white : Colors.black,
                    fontSize: 16 * widget.scale,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove, size: 16 * widget.scale, color: widget.isDarkMode ? Colors.white70 : Colors.black54),
                      onPressed: () {
                        setState(() {
                          _thickness = (_thickness - 0.1).clamp(0.5, 2.0);
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Expanded(
                      child: Slider(
                        value: _thickness,
                        min: 0.5,
                        max: 2.0,
                        activeColor: const Color(0xFF9A00FE),
                        onChanged: (value) {
                          setState(() {
                            _thickness = value;
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add, size: 16 * widget.scale, color: widget.isDarkMode ? Colors.white70 : Colors.black54),
                      onPressed: () {
                        setState(() {
                          _thickness = (_thickness + 0.1).clamp(0.5, 2.0);
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                if (widget.hideButtons) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _clear,
                      icon: Icon(Icons.delete, size: 18 * widget.scale),
                      label: Text('Clear', style: TextStyle(fontSize: 16 * widget.scale)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 20 * widget.scale, vertical: 12 * widget.scale),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 20),
        // Controls
        if (!widget.hideButtons)
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _toggleHint,
                    icon: Icon(_showHint ? Icons.visibility_off : Icons.visibility, size: 18 * widget.scale),
                    label: Text(_showHint ? 'Hide Hint' : 'Show Hint', style: TextStyle(fontSize: 16 * widget.scale)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9A00FE),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 16 * widget.scale, vertical: 12 * widget.scale),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _toggleAnswer,
                    icon: Icon(_showAnswer ? Icons.check_box : Icons.check_box_outline_blank, size: 18 * widget.scale),
                    label: Text(_showAnswer ? 'Hide Answer' : 'Show Answer', style: TextStyle(fontSize: 16 * widget.scale)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9A00FE),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 16 * widget.scale, vertical: 12 * widget.scale),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _clear,
                icon: Icon(Icons.delete, size: 18 * widget.scale),
                label: Text('Clear', style: TextStyle(fontSize: 16 * widget.scale)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20 * widget.scale, vertical: 12 * widget.scale),
                ),
              ),
            ],
          ),
        if (_strokePaths.isNotEmpty && _showHint) ...[
          const SizedBox(height: 15),
          Text(
            'Hint: Stroke ${_hintStroke + 1} of ${_strokePaths.length}',
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : Colors.black,
              fontSize: 14 * widget.scale,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _resetHint,
                color: const Color(0xFF9A00FE),
                tooltip: 'Reset to first stroke',
              ),
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _hintStroke > 0 ? _previousHint : null,
                color: _hintStroke > 0 ? const Color(0xFF9A00FE) : Colors.grey,
                tooltip: 'Previous stroke',
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: _hintStroke < _strokePaths.length - 1 ? _nextHint : null,
                color: _hintStroke < _strokePaths.length - 1 ? const Color(0xFF9A00FE) : Colors.grey,
                tooltip: 'Next stroke',
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class WritingCanvasPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final List<String> strokePaths;
  final List<List<String>> strokeGroups;
  final int hintStroke;
  final bool showHint;
  final bool showAnswer;
  final double thickness;
  final double scale;
  final String wordText;

  WritingCanvasPainter({
    required this.strokes,
    required this.currentStroke,
    required this.strokePaths,
    required this.strokeGroups,
    required this.hintStroke,
    required this.showHint,
    required this.showAnswer,
    required this.thickness,
    required this.scale,
    required this.wordText,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // If no stroke paths, draw the word as light gray background text when answer is shown
    if (strokePaths.isEmpty && showAnswer) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: wordText,
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 120 * scale,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      final offset = Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      );
      textPainter.paint(canvas, offset);
    }
    // If no stroke paths but hint is shown, draw a lighter version
    else if (strokePaths.isEmpty && showHint) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: wordText,
          style: TextStyle(
            color: const Color(0xFF9A00FE).withValues(alpha: 0.2),
            fontSize: 120 * scale,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      final offset = Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      );
      textPainter.paint(canvas, offset);
    }
    
    // Draw complete answer if enabled
    if (showAnswer && strokePaths.isNotEmpty) {
      if (strokeGroups.isNotEmpty) {
        // Multiple kanji - position them side by side
        final numKanji = strokeGroups.length;
        final kanjiWidth = size.width / numKanji;
        
        int strokeIndex = 0;
        for (int kanjiIdx = 0; kanjiIdx < strokeGroups.length; kanjiIdx++) {
          canvas.save();
          // Position this kanji
          canvas.translate(kanjiIdx * kanjiWidth + kanjiWidth / 2, size.height / 2);
          final kanjiScale = (kanjiWidth * 0.8) / 109;
          canvas.scale(kanjiScale);
          canvas.translate(-54.5, -54.5); // Center the 109x109 viewBox
          
          final answerPaint = Paint()
            ..color = Colors.grey[400]!
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round;
          
          for (final strokePath in strokeGroups[kanjiIdx]) {
            final path = _parseSVGPath(strokePath);
            canvas.drawPath(path, answerPaint);
          }
          
          canvas.restore();
          strokeIndex += strokeGroups[kanjiIdx].length;
        }
      } else {
        // Single kanji - center it
        final canvasScale = size.width / 109;
        canvas.save();
        canvas.scale(canvasScale);
        
        final answerPaint = Paint()
          ..color = Colors.grey[400]!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        
        for (int i = 0; i < strokePaths.length; i++) {
          final path = _parseSVGPath(strokePaths[i]);
          canvas.drawPath(path, answerPaint);
        }
        
        canvas.restore();
      }
    }
    // Draw hint strokes if enabled (and answer is not shown)
    else if (showHint && strokePaths.isNotEmpty) {
      if (strokeGroups.isNotEmpty) {
        // Multiple kanji - position them side by side
        final numKanji = strokeGroups.length;
        final kanjiWidth = size.width / numKanji;
        
        int strokeIndex = 0;
        for (int kanjiIdx = 0; kanjiIdx < strokeGroups.length; kanjiIdx++) {
          canvas.save();
          // Position this kanji
          canvas.translate(kanjiIdx * kanjiWidth + kanjiWidth / 2, size.height / 2);
          final kanjiScale = (kanjiWidth * 0.8) / 109;
          canvas.scale(kanjiScale);
          canvas.translate(-54.5, -54.5); // Center the 109x109 viewBox
          
          // Draw completed hint strokes in light gray
          final lightGrayPaint = Paint()
            ..color = Colors.grey[300]!
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round;
          
          for (int i = 0; i < strokeGroups[kanjiIdx].length; i++) {
            if (strokeIndex < hintStroke) {
              final path = _parseSVGPath(strokeGroups[kanjiIdx][i]);
              canvas.drawPath(path, lightGrayPaint);
            } else if (strokeIndex == hintStroke) {
              // Draw current hint stroke in purple
              final purplePaint = Paint()
                ..color = const Color(0xFF9A00FE).withValues(alpha: 0.5)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 4
                ..strokeCap = StrokeCap.round
                ..strokeJoin = StrokeJoin.round;
              
              final path = _parseSVGPath(strokeGroups[kanjiIdx][i]);
              canvas.drawPath(path, purplePaint);
            }
            strokeIndex++;
          }
          
          canvas.restore();
        }
      } else {
        // Single kanji - center it
        final canvasScale = size.width / 109;
        canvas.save();
        canvas.scale(canvasScale);
        
        // Draw completed hint strokes in light gray
        final lightGrayPaint = Paint()
          ..color = Colors.grey[300]!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        
        for (int i = 0; i < hintStroke && i < strokePaths.length; i++) {
          final path = _parseSVGPath(strokePaths[i]);
          canvas.drawPath(path, lightGrayPaint);
        }
        
        // Draw current hint stroke in purple
        if (hintStroke < strokePaths.length) {
          final purplePaint = Paint()
            ..color = const Color(0xFF9A00FE).withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round;
          
          final path = _parseSVGPath(strokePaths[hintStroke]);
          canvas.drawPath(path, purplePaint);
        }
        
        canvas.restore();
      }
    }

    // Draw user's strokes with calligraphy style
    for (var stroke in strokes) {
      _drawCalligraphyStroke(canvas, stroke);
    }

    // Draw current stroke being drawn (normal style)
    if (currentStroke.isNotEmpty) {
      final tempPaint = Paint()
        ..color = Colors.black
        ..strokeWidth = 4.0 * scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      _drawStroke(canvas, currentStroke, tempPaint);
    }
  }

  void _drawCalligraphyStroke(Canvas canvas, List<Offset> points) {
    if (points.isEmpty) return;
    
    if (points.length == 1) {
      final paint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.fill;
      canvas.drawCircle(points[0], 2.0 * thickness * scale, paint);
      return;
    }
    
    // Create a path with variable width for calligraphy effect
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      
      // Calculate stroke width based on position (thicker in middle, thinner at ends)
      final progress = i / (points.length - 1);
      final width = _getCalligraphyWidth(progress, thickness);
      
      final paint = Paint()
        ..color = Colors.black
        ..strokeWidth = width * scale
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      
      canvas.drawLine(p1, p2, paint);
    }
  }

  double _getCalligraphyWidth(double progress, double thickness) {
    // Create a variable width: thin at start, thick in middle, thin at end
    // Using a sine wave for smooth variation
    final minWidth = 3.0 * thickness;
    final maxWidth = 9.0 * thickness;
    final variation = (maxWidth - minWidth) * (1 - (2 * progress - 1).abs());
    return minWidth + variation;
  }

  void _drawStroke(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.isEmpty) return;
    
    if (points.length == 1) {
      canvas.drawCircle(points[0], 2.0, paint..style = PaintingStyle.fill);
      return;
    }
    
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    
    canvas.drawPath(path, paint..style = PaintingStyle.stroke);
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
      
      final coords = coordString
          .replaceAll(',', ' ')
          .replaceAllMapped(RegExp(r'(\d)-'), (match) => '${match.group(1)} -')
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
        case 'C':
          for (int i = 0; i + 5 < coords.length; i += 6) {
            final x1 = coords[i];
            final y1 = coords[i + 1];
            final x2 = coords[i + 2];
            final y2 = coords[i + 3];
            final x = coords[i + 4];
            final y = coords[i + 5];
            path.cubicTo(x1, y1, x2, y2, x, y);
            lastControlX = x2;
            lastControlY = y2;
            currentX = x;
            currentY = y;
          }
          lastCommand = 'C';
          break;
        case 'c':
          for (int i = 0; i + 5 < coords.length; i += 6) {
            final x1 = currentX + coords[i];
            final y1 = currentY + coords[i + 1];
            final x2 = currentX + coords[i + 2];
            final y2 = currentY + coords[i + 3];
            final x = currentX + coords[i + 4];
            final y = currentY + coords[i + 5];
            path.cubicTo(x1, y1, x2, y2, x, y);
            lastControlX = x2;
            lastControlY = y2;
            currentX = x;
            currentY = y;
          }
          lastCommand = 'c';
          break;
        case 'S':
          for (int i = 0; i + 3 < coords.length; i += 4) {
            double x1, y1;
            if (lastCommand == 'C' || lastCommand == 'S' || lastCommand == 'c' || lastCommand == 's') {
              x1 = 2 * currentX - lastControlX;
              y1 = 2 * currentY - lastControlY;
            } else {
              x1 = currentX;
              y1 = currentY;
            }
            final x2 = coords[i];
            final y2 = coords[i + 1];
            final x = coords[i + 2];
            final y = coords[i + 3];
            path.cubicTo(x1, y1, x2, y2, x, y);
            lastControlX = x2;
            lastControlY = y2;
            currentX = x;
            currentY = y;
          }
          lastCommand = 'S';
          break;
        case 's':
          for (int i = 0; i + 3 < coords.length; i += 4) {
            double x1, y1;
            if (lastCommand == 'C' || lastCommand == 'S' || lastCommand == 'c' || lastCommand == 's') {
              x1 = 2 * currentX - lastControlX;
              y1 = 2 * currentY - lastControlY;
            } else {
              x1 = currentX;
              y1 = currentY;
            }
            final x2 = currentX + coords[i];
            final y2 = currentY + coords[i + 1];
            final x = currentX + coords[i + 2];
            final y = currentY + coords[i + 3];
            path.cubicTo(x1, y1, x2, y2, x, y);
            lastControlX = x2;
            lastControlY = y2;
            currentX = x;
            currentY = y;
          }
          lastCommand = 's';
          break;
        case 'Z':
        case 'z':
          path.lineTo(startX, startY);
          currentX = startX;
          currentY = startY;
          break;
      }
    }

    return path;
  }

  @override
  bool shouldRepaint(WritingCanvasPainter oldDelegate) {
    return true;
  }
}

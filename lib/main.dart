import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


void main() {
  runApp(const SnakeGameApp());
}

class SnakeGameApp extends StatelessWidget {
  const SnakeGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SnakeGame(),
    );
  }
}

class SnakeGame extends StatefulWidget {
  const SnakeGame({super.key});

  @override
  State<SnakeGame> createState() => _SnakeGameState();
}

enum Direction { up, down, left, right }

class _SnakeGameState extends State<SnakeGame> {
  static const int rows = 20;
  static const int cols = 20;
  static const Duration tickDuration = Duration(milliseconds: 200);

  late List<Point<int>> snake;
  late Direction direction;
  Timer? _timer;
  late Point<int> food;

  bool running = false;
  bool gameOver = false;
  int score = 0;
  int highScore = 0;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _startNewGame();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('highScore') ?? 0;
    });
  }

  Future<void> _saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('highScore', highScore);
  }

  void _startNewGame() {
    _timer?.cancel();
    setState(() {
      final midX = cols ~/ 2;
      final midY = rows ~/ 2;
      snake = [
        Point(midX - 1, midY),
        Point(midX, midY),
        Point(midX + 1, midY),
      ];
      direction = Direction.right;
      food = Point(midX + 3, midY);
      _spawnFood();
      running = true;
      gameOver = false;
      score = 0;
    });
    _timer = Timer.periodic(tickDuration, (_) => _tick());
  }

  void _spawnFood() {
    final rand = Random();
    Point<int> newFood;
    do {
      newFood = Point(
        rand.nextInt(cols),
        rand.nextInt(rows),
      );
    } while (snake.contains(newFood));
    food = newFood;
  }

  void _tick() {
    if (!running) return;
    final head = snake.last;
    Point<int> newHead;
    switch (direction) {
      case Direction.up:
        newHead = Point(head.x, head.y - 1);
        break;
      case Direction.down:
        newHead = Point(head.x, head.y + 1);
        break;
      case Direction.left:
        newHead = Point(head.x - 1, head.y);
        break;
      case Direction.right:
        newHead = Point(head.x + 1, head.y);
        break;
    }
    if (newHead.x < 0 ||
        newHead.y < 0 ||
        newHead.x >= cols ||
        newHead.y >= rows ||
        snake.contains(newHead)) {
      setState(() {
        running = false;
        gameOver = true;
        if (score > highScore) {
          highScore = score;
          _saveHighScore();
        }
      });
      _timer?.cancel();
      return;
    }
    setState(() {
      snake.add(newHead);
      if (newHead == food) {
        score += 10;
        if (score > highScore) {
          highScore = score;
          _saveHighScore();
        }
        _spawnFood();
      } else {
        snake.removeAt(0);
      }
    });
  }

  void _changeDirection(Direction newDirection) {
    if ((direction == Direction.up && newDirection == Direction.down) ||
        (direction == Direction.down && newDirection == Direction.up) ||
        (direction == Direction.left && newDirection == Direction.right) ||
        (direction == Direction.right && newDirection == Direction.left)) {
      return;
    }
    setState(() {
      direction = newDirection;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Remove animated background, restore static black background
    return Scaffold(
      body: SafeArea(
        child: SquareBlinkBG(
          builder: (context) => Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              Text(
                "SCORE: $score",
                style: const TextStyle(
                  color: Color(0xFF00FF00),
                  fontSize: 28,
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                ),
              ),
              Text(
                "HIGH SCORE: $highScore",
                style: const TextStyle(
                  color: Color(0xFF00FF00),
                  fontSize: 18,
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: cols / rows,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        border: Border.all(color: Color(0xFF00FF00), width: 2),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final blockSize = constraints.maxWidth / cols;
                          return CustomPaint(
                            foregroundPainter: NokiaSnakePainter(snake, food, blockSize, rows, cols),
                            child: Container(), // Add an empty child to satisfy the child parameter
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              if (gameOver)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: const Color(0xFF00FF00),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      side: const BorderSide(color: Color(0xFF00FF00), width: 2),
                      textStyle: const TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    onPressed: _startNewGame,
                    child: const Text("RESTART"),
                  ),
                ),
              const SizedBox(height: 8),
              _nokiaControls(),
              const SizedBox(height: 16),
              const DeveloperFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nokiaControls() {
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: _nokiaButton(Icons.arrow_drop_up, () => _changeDirection(Direction.up)),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _nokiaButton(Icons.arrow_drop_down, () => _changeDirection(Direction.down)),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: _nokiaButton(Icons.arrow_left, () => _changeDirection(Direction.left)),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _nokiaButton(Icons.arrow_right, () => _changeDirection(Direction.right)),
          ),
        ],
      ),
    );
  }

  Widget _nokiaButton(IconData icon, VoidCallback onPressed) {
    return Material(
      color: Colors.black,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Color(0xFF00FF00), width: 2),
          ),
          child: Icon(icon, color: Color(0xFF00FF00), size: 36),
        ),
      ),
    );
  }
}

class NokiaSnakePainter extends CustomPainter {
  final List<Point<int>> snake;
  final Point<int> food;
  final double blockSize;
  final int rows;
  final int cols;

  NokiaSnakePainter(this.snake, this.food, this.blockSize, this.rows, this.cols);

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF00FF00)
      ..strokeWidth = 1;
    // Draw grid
    for (int i = 0; i <= cols; i++) {
      canvas.drawLine(
        Offset(i * blockSize, 0),
        Offset(i * blockSize, rows * blockSize),
        gridPaint,
      );
    }
    for (int j = 0; j <= rows; j++) {
      canvas.drawLine(
        Offset(0, j * blockSize),
        Offset(cols * blockSize, j * blockSize),
        gridPaint,
      );
    }
    // Draw snake (pixel style, blue)
    final snakePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    for (final p in snake) {
      canvas.drawRect(
        Rect.fromLTWH(p.x * blockSize, p.y * blockSize, blockSize, blockSize),
        snakePaint,
      );
    }
    // Draw food (pixel style)
    final foodPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(food.x * blockSize, food.y * blockSize, blockSize, blockSize),
      foodPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SquareBlinkBG extends StatefulWidget {
  final WidgetBuilder builder;
  const SquareBlinkBG({super.key, required this.builder});
  @override
  State<SquareBlinkBG> createState() => _SquareBlinkBGState();
}

class _SquareBlinkBGState extends State<SquareBlinkBG> with SingleTickerProviderStateMixin {
  Offset? _hoverPos;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Set blink animation speed to 500ms per cycle
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        setState(() {
          _hoverPos = event.localPosition;
        });
      },
      onExit: (_) {
        setState(() {
          _hoverPos = null;
        });
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: SquareBlinkBGPainter(_hoverPos, _controller.value),
            child: widget.builder(context),
          );
        },
      ),
    );
  }
}

class SquareBlinkBGPainter extends CustomPainter {
  final Offset? hoverPos;
  final double progress;
  SquareBlinkBGPainter(this.hoverPos, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = Colors.black;
    canvas.drawRect(Offset.zero & size, bgPaint);
    if (hoverPos != null) {
      // Draw an even larger smooth gradient circle at mouse position
      final gradient = RadialGradient(
        colors: [const Color.fromARGB(255, 13, 195, 38).withOpacity(0.35), Colors.transparent],
        stops: [0.0, 1.0],
      );
      final rect = Rect.fromCircle(center: hoverPos!, radius: 320);
      final paint = Paint()
        ..shader = gradient.createShader(rect);
      canvas.drawCircle(hoverPos!, 320, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SquareBlinkBGPainter oldDelegate) => true;
}

// Add developer info and social icons at the bottom
class DeveloperFooter extends StatelessWidget {
  const DeveloperFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Developed by Anish',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            // GitHub Button
            children: [
              IconButton(
              icon: const Icon(
                FontAwesomeIcons.github,
                color: Colors.grey,
                size: 22,
              ),
              onPressed: () async {
                final url = Uri.parse('https://github.com/anishthakur408');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              tooltip: 'GitHub',
            ),

            const SizedBox(width: 16),

            // LinkedIn Button
            IconButton(
              icon: const Icon(
                FontAwesomeIcons.linkedin,
                color: Colors.grey,
                size: 22,
              ),
              onPressed: () async {
                final url = Uri.parse('https://www.linkedin.com/in/anish-kumar-456646318/');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              tooltip: 'LinkedIn',
            )
            ],
          ),
        ],
      ),
    );
  }
}
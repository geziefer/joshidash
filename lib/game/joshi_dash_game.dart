import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'level_data.dart';

class JoshiDashGame extends FlameGame with TapCallbacks, KeyboardEvents {
  late double gridUnit;
  late double groundY;
  int currentLevel = 0;
  double scrollOffset = 0;
  late double scrollSpeed;
  bool gameOver = false;
  bool levelComplete = false;
  VoidCallback? onGameOver;
  VoidCallback? onLevelComplete;

  // Player state
  late double playerX;
  late double playerY;
  bool _jumping = false;
  bool _falling = false;
  double _jumpTime = 0;
  double _jumpStartY = 0;
  double _fallSpeed = 0;
  static const double _jumpHeight = 2.0;
  static const double _jumpDuration = 0.4;

  bool get _isGrounded => !_jumping && !_falling;

  @override
  Color backgroundColor() => const Color(0xFF0A0A0A);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    gridUnit = size.y / 10;
    groundY = size.y - gridUnit;
    scrollSpeed = gridUnit * 6;
    playerX = 3 * gridUnit;
    playerY = groundY - gridUnit;
  }

  @override
  Future<void> onLoad() async {
    gridUnit = size.y / 10;
    groundY = size.y - gridUnit;
    scrollSpeed = gridUnit * 6;
    playerX = 3 * gridUnit;
    playerY = groundY - gridUnit;
  }

  void restart() {
    scrollOffset = 0;
    gameOver = false;
    levelComplete = false;
    _jumping = false;
    _falling = false;
    _fallSpeed = 0;
    playerY = groundY - gridUnit;
  }

  void _jump() {
    if (!_isGrounded) return;
    _jumping = true;
    _jumpTime = 0;
    _jumpStartY = playerY;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameOver || levelComplete) return;

    // Scroll
    scrollOffset += scrollSpeed * dt;

    // Jump / fall physics
    if (_jumping) {
      _jumpTime += dt;
      final p = _jumpTime / _jumpDuration;
      if (p >= 1.0) {
        _jumping = false;
        _falling = true;
        _fallSpeed = 0;
      } else {
        final offsetY = 4 * _jumpHeight * gridUnit * p * (1 - p);
        playerY = _jumpStartY - offsetY;
      }
    } else if (_falling) {
      final gravity = _jumpHeight * gridUnit / (_jumpDuration * _jumpDuration) * 4;
      _fallSpeed += gravity * dt;
      playerY += _fallSpeed * dt;
    }

    // Ground/platform collision
    _checkLanding();

    // Death: fell off screen
    if (playerY > size.y + gridUnit) {
      _die();
    }

    // Obstacle collision
    _checkObstacleCollision();

    // Level complete
    if (scrollOffset >= levels[currentLevel].length * gridUnit) {
      levelComplete = true;
      onLevelComplete?.call();
    }
  }

  void _checkLanding() {
    if (_isGrounded) return;
    final playerBottom = playerY + gridUnit;
    final playerLeft = playerX;
    final playerRight = playerX + gridUnit;

    final level = levels[currentLevel];
    for (final tile in level.tiles) {
      if (tile.type == TileType.triangle) continue;
      final tileScreenX = tile.x * gridUnit - scrollOffset;
      final tileTop = groundY - tile.y * gridUnit;

      if (playerRight > tileScreenX + 2 && playerLeft < tileScreenX + gridUnit - 2) {
        if (playerBottom >= tileTop && playerBottom <= tileTop + gridUnit * 0.6) {
          // Land
          playerY = tileTop - gridUnit;
          _jumping = false;
          _falling = false;
          _fallSpeed = 0;
          return;
        }
      }
    }
  }

  void _checkObstacleCollision() {
    final playerLeft = playerX;
    final playerRight = playerX + gridUnit;
    final playerTop = playerY;
    final playerBottom = playerY + gridUnit;

    final level = levels[currentLevel];
    for (final tile in level.tiles) {
      if (tile.type == TileType.ground) continue;
      final tileScreenX = tile.x * gridUnit - scrollOffset;
      final tileTop = groundY - tile.y * gridUnit;
      final tileBottom = tileTop + gridUnit;
      final tileRight = tileScreenX + gridUnit;

      // Broad check
      if (playerRight <= tileScreenX || playerLeft >= tileRight) continue;
      if (playerBottom <= tileTop || playerTop >= tileBottom) continue;

      // Overlap exists
      if (tile.type == TileType.triangle) {
        // Triangle hitbox: check if player overlaps the actual triangle shape
        // Triangle points: top-center, bottom-left, bottom-right
        final triPeakX = tileScreenX + gridUnit / 2;
        final px = playerLeft + gridUnit / 2;
        // Simple: if player bottom is below triangle top and horizontally inside
        // the triangle narrows toward top, width at height h from bottom = gridUnit * (1 - h/gridUnit)
        final h = tileBottom - playerTop; // how deep into triangle zone
        final widthAtH = gridUnit * (h / gridUnit);
        final triLeft = triPeakX - widthAtH / 2;
        final triRight = triPeakX + widthAtH / 2;
        if (px > triLeft && px < triRight) {
          _die();
          return;
        }
      } else if (tile.type == TileType.block) {
        // Side hit = death (not landing from top)
        final overlap = playerRight - tileScreenX;
        if (overlap < gridUnit * 0.4) {
          _die();
          return;
        }
      }
    }
  }

  void _die() {
    if (gameOver) return;
    gameOver = true;
    onGameOver?.call();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final level = levels[currentLevel];

    // Draw tiles
    for (final tile in level.tiles) {
      final screenX = tile.x * gridUnit - scrollOffset;
      if (screenX > size.x + gridUnit || screenX < -gridUnit) continue;
      final tileTop = groundY - tile.y * gridUnit;

      switch (tile.type) {
        case TileType.ground:
          canvas.drawRect(
            Rect.fromLTWH(screenX, tileTop, gridUnit, gridUnit),
            Paint()..color = const Color(0xFF333333),
          );
        case TileType.block:
          final rect = Rect.fromLTWH(screenX, tileTop, gridUnit, gridUnit);
          canvas.drawRect(rect, Paint()..color = const Color(0xFFFF00FF));
          canvas.drawRect(rect, Paint()..color = const Color(0xFFFF00FF)..style = PaintingStyle.stroke..strokeWidth = 1);
        case TileType.triangle:
          final path = Path()
            ..moveTo(screenX + gridUnit / 2, tileTop)
            ..lineTo(screenX + gridUnit, tileTop + gridUnit)
            ..lineTo(screenX, tileTop + gridUnit)
            ..close();
          canvas.drawPath(path, Paint()..color = const Color(0xFFFF0040));
      }
    }

    // Draw player
    final playerRect = Rect.fromLTWH(playerX, playerY, gridUnit, gridUnit);
    canvas.drawRect(playerRect, Paint()..color = const Color(0xFF00FFFF));
    canvas.drawRect(
      playerRect,
      Paint()..color = const Color(0xFF00FFFF)..style = PaintingStyle.stroke..strokeWidth = 2,
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    _jump();
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.space) {
      _jump();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
}

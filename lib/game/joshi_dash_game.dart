import 'dart:ui' as ui;
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

  // Sprites
  late ui.Image _playerImg;
  late ui.Image _baseImg;
  late ui.Image _spikeImg;
  late ui.Image _platformImg;
  late ui.Image _gateImg;
  late ui.Image _pitImg;
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
  static const double _jumpDistance = 5.0; // grid units horizontal per jump
  static const double _jumpDuration = 0.55; // total jump time
  // Three-phase jump: up (30%), float (40%), down (30%)
  static const double _risePhase = 0.3;
  static const double _floatPhase = 0.7; // end of float = _risePhase + 0.4

  // Hold-to-jump
  bool _inputHeld = false;
  double _playerRotation = 0; // current rotation angle in radians
  double _rotationBase = 0; // rotation at start of jump

  // Debug mode
  static const bool devMode = true;
  bool _godMode = false;

  bool get _isGrounded => !_jumping && !_falling;

  @override
  Color backgroundColor() => const Color(0xFF0A0A0A);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    gridUnit = size.y / 10;
    groundY = size.y - gridUnit;
    scrollSpeed = gridUnit * _jumpDistance / _jumpDuration;
    playerX = 3 * gridUnit;
    playerY = groundY - gridUnit;
  }

  @override
  Future<void> onLoad() async {
    _playerImg = await _loadImage('assets/player.png');
    _baseImg = await _loadImage('assets/base.png');
    _spikeImg = await _loadImage('assets/spike.png');
    _platformImg = await _loadImage('assets/platform.png');
    _gateImg = await _loadImage('assets/gate.png');
    _pitImg = await _loadImage('assets/pit.png');

    gridUnit = size.y / 10;
    groundY = size.y - gridUnit;
    scrollSpeed = gridUnit * _jumpDistance / _jumpDuration;
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
    _playerRotation = 0;
    _rotationBase = 0;
    playerY = groundY - gridUnit;
  }

  void _jump() {
    if (!_isGrounded) return;
    _jumping = true;
    _jumpTime = 0;
    _jumpStartY = playerY;
    _rotationBase = _playerRotation;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameOver || levelComplete) return;

    // Hold-to-jump: auto-jump when grounded and input held
    if (_inputHeld && _isGrounded) {
      _jump();
    }

    // Scroll
    scrollOffset += scrollSpeed * (_godMode ? 2.0 : 1.0) * dt;

    // God mode: stay on ground, no physics
    if (_godMode) {
      playerY = groundY - gridUnit;
      _jumping = false;
      _falling = false;
    }

    // Jump / fall physics
    if (_jumping) {
      _jumpTime += dt;
      final p = _jumpTime / _jumpDuration;
      // Rotation completes 180° during rise+float phase (0 to _floatPhase)
      _playerRotation = _rotationBase + (p / _floatPhase).clamp(0.0, 1.0) * 3.14159;
      if (p >= 1.0) {
        _jumping = false;
        _playerRotation = _rotationBase + 3.14159;
        playerY = _jumpStartY;
        // Try to land immediately, otherwise fall with initial velocity
        _falling = true;
        _fallSpeed = _jumpHeight * gridUnit / _jumpDuration * 2;
        _checkLanding();
      } else {
        // Three-phase: fast up, float at peak, fast down
        double offsetY;
        if (p < _risePhase) {
          // Rising: quadratic ease-out
          final t = p / _risePhase;
          offsetY = _jumpHeight * gridUnit * (1 - (1 - t) * (1 - t));
        } else if (p < _floatPhase) {
          // Floating at peak
          offsetY = _jumpHeight * gridUnit;
        } else {
          // Falling: quadratic ease-in
          final t = (p - _floatPhase) / (1.0 - _floatPhase);
          offsetY = _jumpHeight * gridUnit * (1 - t * t);
        }
        playerY = _jumpStartY - offsetY;
        // Check landing during float or descent
        if (p >= _risePhase) {
          final playerBottom = playerY + gridUnit;
          final playerLeft = playerX;
          final playerRight = playerX + gridUnit;
          double? bestSurface;
          final level = levels[currentLevel];
          for (final tile in level.tiles) {
            if (tile.type != TileType.ground && tile.type != TileType.block) continue;
            if (tile.y == 0) continue; // don't land on ground during jump
            final tileScreenX = tile.x * gridUnit - scrollOffset;
            final tileTop = groundY - tile.y * gridUnit;
            if (playerRight > tileScreenX && playerLeft < tileScreenX + gridUnit) {
              if (playerBottom >= tileTop - gridUnit * 0.1 && playerBottom <= tileTop + gridUnit * 0.5) {
                if (bestSurface == null || tileTop < bestSurface) {
                  bestSurface = tileTop;
                }
              }
            }
          }
          if (bestSurface != null) {
            playerY = bestSurface - gridUnit;
            _jumping = false;
            _falling = false;
            _fallSpeed = 0;
            _playerRotation = _rotationBase + 3.14159;
          }
        }
      }
    } else if (_falling) {
      final gravity =
          _jumpHeight * gridUnit / (_jumpDuration * _jumpDuration) * 4;
      _fallSpeed += gravity * dt;
      playerY += _fallSpeed * dt;
    }

    // Ground/platform collision
    _checkLanding();

    // Check if grounded player has ground beneath (gaps + platform edges)
    if (_isGrounded) {
      if (!_godMode) _checkStillSupported();
    }

    // Death: fell off screen
    if (!_godMode && playerY > size.y + gridUnit) {
      _die();
    }

    // Obstacle collision
    if (!_godMode) _checkObstacleCollision();

    // Level complete
    if (scrollOffset >= levels[currentLevel].length * gridUnit) {
      levelComplete = true;
      onLevelComplete?.call();
    }

    // Check gate contact
    if (!levelComplete) {
      final level = levels[currentLevel];
      for (final tile in level.tiles) {
        if (tile.type != TileType.gate) continue;
        final gateScreenX = tile.x * gridUnit - scrollOffset;
        if (playerX + gridUnit > gateScreenX && playerX < gateScreenX + gridUnit * 2) {
          levelComplete = true;
          onLevelComplete?.call();
        }
      }
    }
  }

  void _checkLanding() {
    if (!_falling) return; // only land when actually falling
    final playerBottom = playerY + gridUnit;
    final playerLeft = playerX;
    final playerRight = playerX + gridUnit;

    double? bestSurface;
    final level = levels[currentLevel];
    for (final tile in level.tiles) {
      if (tile.type != TileType.ground && tile.type != TileType.block) continue;
      final tileScreenX = tile.x * gridUnit - scrollOffset;
      final tileTop = groundY - tile.y * gridUnit;

      if (playerRight > tileScreenX + 2 &&
          playerLeft < tileScreenX + gridUnit - 2) {
        // Only land if player hasn't fallen far past the surface
        final maxOvershoot = _fallSpeed * 0.03 + 4;
        if (playerBottom >= tileTop &&
            playerBottom <= tileTop + maxOvershoot) {
          // Pick the highest (smallest Y) surface
          if (bestSurface == null || tileTop < bestSurface) {
            bestSurface = tileTop;
          }
        }
      }
    }
    if (bestSurface != null) {
      playerY = bestSurface - gridUnit;
      _jumping = false;
      _falling = false;
      _fallSpeed = 0;
    }
  }

  /// Check if grounded player still has support beneath. If not, start falling.
  void _checkStillSupported() {
    final playerBottom = playerY + gridUnit;
    final playerLeft = playerX;
    final playerRight = playerX + gridUnit;

    final level = levels[currentLevel];
    for (final tile in level.tiles) {
      if (tile.type != TileType.ground && tile.type != TileType.block) continue;
      final tileScreenX = tile.x * gridUnit - scrollOffset;
      final tileTop = groundY - tile.y * gridUnit;

      // Any horizontal overlap between player and tile
      if (playerRight > tileScreenX && playerLeft < tileScreenX + gridUnit) {
        // Tile top is near player bottom (player standing on it)
        if (playerBottom >= tileTop - 2 && playerBottom <= tileTop + gridUnit * 0.5) {
          return; // supported
        }
      }
    }
    // No support found — fall
    _falling = true;
    _fallSpeed = 0;
  }

  void _checkObstacleCollision() {
    final playerLeft = playerX;
    final playerRight = playerX + gridUnit;
    final playerTop = playerY;
    final playerBottom = playerY + gridUnit;

    final level = levels[currentLevel];
    for (final tile in level.tiles) {
      if (tile.type == TileType.ground || tile.type == TileType.gate || tile.type == TileType.pit) continue;
      final tileScreenX = tile.x * gridUnit - scrollOffset;
      final tileTop = groundY - tile.y * gridUnit;
      final tileBottom = tileTop + gridUnit;
      final tileRight = tileScreenX + gridUnit;

      if (playerRight <= tileScreenX || playerLeft >= tileRight) continue;
      if (playerBottom <= tileTop || playerTop >= tileBottom) continue;

      if (tile.type == TileType.triangle) {
        final triPeakX = tileScreenX + gridUnit / 2;
        final px = playerLeft + gridUnit / 2;
        final h = tileBottom - playerTop;
        final widthAtH = gridUnit * (h / gridUnit);
        final triLeft = triPeakX - widthAtH / 2;
        final triRight = triPeakX + widthAtH / 2;
        if (px > triLeft && px < triRight) {
          _die();
          return;
        }
      } else if (tile.type == TileType.block) {
        // Only side hit = death if player bottom is below block top (not landing from above)
        if (playerBottom > tileTop + gridUnit * 0.3) {
          final overlap = playerRight - tileScreenX;
          if (overlap < gridUnit * 0.4) {
            _die();
            return;
          }
        }
      }
    }
  }

  void _die() {
    if (gameOver) return;
    gameOver = true;
    onGameOver?.call();
  }

  Future<ui.Image> _loadImage(String path) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  void _drawImage(Canvas canvas, ui.Image img, double x, double y, double w, double h) {
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      Rect.fromLTWH(x, y, w, h),
      Paint(),
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final level = levels[currentLevel];

    for (final tile in level.tiles) {
      final screenX = tile.x * gridUnit - scrollOffset;
      if (screenX > size.x + gridUnit * 2 || screenX < -gridUnit * 2) continue;
      final tileTop = groundY - tile.y * gridUnit;

      switch (tile.type) {
        case TileType.ground:
          _drawImage(canvas, _baseImg, screenX, tileTop, gridUnit * 2, gridUnit);
        case TileType.block:
          _drawImage(canvas, _platformImg, screenX, tileTop, gridUnit * 2, gridUnit);
        case TileType.triangle:
          _drawImage(canvas, _spikeImg, screenX, tileTop, gridUnit, gridUnit);
        case TileType.gate:
          _drawImage(canvas, _gateImg, screenX, tileTop - gridUnit, gridUnit * 2, gridUnit * 2);
        case TileType.pit:
          _drawImage(canvas, _pitImg, screenX, tileTop, gridUnit * 2, gridUnit);
      }
    }

    // Draw player with rotation (1x1)
    final cx = playerX + gridUnit / 2;
    final cy = playerY + gridUnit / 2;
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_playerRotation);
    canvas.translate(-cx, -cy);
    _drawImage(canvas, _playerImg, playerX, playerY, gridUnit, gridUnit);
    canvas.restore();
  }

  @override
  void onTapDown(TapDownEvent event) {
    _inputHeld = true;
    _jump();
  }

  @override
  void onTapUp(TapUpEvent event) {
    _inputHeld = false;
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _inputHeld = false;
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event.logicalKey == LogicalKeyboardKey.space) {
      if (event is KeyDownEvent) {
        _inputHeld = true;
        _jump();
      } else if (event is KeyUpEvent) {
        _inputHeld = false;
      }
      return KeyEventResult.handled;
    }
    if (devMode && event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.shiftLeft) {
      _godMode = !_godMode;
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
}

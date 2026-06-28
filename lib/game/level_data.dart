// Grid-based level data.
// Each tile is 1 unit = the player square size.
// x,y positions are in grid units. y=0 is ground level.

enum TileType { ground, block, triangle }

class LevelTile {
  final int x;
  final int y;
  final TileType type;
  const LevelTile(this.x, this.y, this.type);
}

class LevelData {
  final List<LevelTile> tiles;
  final int length; // total grid units width

  const LevelData({required this.tiles, required this.length});
}

/// First level: 50 units long.
/// Ground from 0-49 with gaps and obstacles.
final level1 = LevelData(
  length: 50,
  tiles: [
    // Ground (y=0) with gaps
    for (int x = 0; x <= 9; x++) LevelTile(x, 0, TileType.ground),
    // Triangle at x=10
    LevelTile(10, 1, TileType.triangle),
    for (int x = 10; x <= 14; x++) LevelTile(x, 0, TileType.ground),
    // Gap at 15-16
    for (int x = 17; x <= 22; x++) LevelTile(x, 0, TileType.ground),
    // Block obstacle at x=23
    LevelTile(23, 1, TileType.block),
    for (int x = 23; x <= 28; x++) LevelTile(x, 0, TileType.ground),
    // Triangle at x=30
    LevelTile(30, 1, TileType.triangle),
    for (int x = 29; x <= 33; x++) LevelTile(x, 0, TileType.ground),
    // Elevated platform
    LevelTile(35, 2, TileType.block),
    LevelTile(36, 2, TileType.block),
    LevelTile(37, 2, TileType.block),
    // Gap below platform, ground continues
    for (int x = 34; x <= 38; x++) LevelTile(x, 0, TileType.ground),
    // Double triangle
    LevelTile(40, 1, TileType.triangle),
    LevelTile(43, 1, TileType.triangle),
    for (int x = 39; x <= 49; x++) LevelTile(x, 0, TileType.ground),
  ],
);

final levels = [level1];

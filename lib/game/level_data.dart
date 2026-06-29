// Grid-based level data.
// Each tile is 1 unit = the player square size.
// base/platform sprites are 2x1, so placed at even x positions.
// Gaps must be at least 2 units wide.

enum TileType { ground, block, triangle, gate, pit }

class LevelTile {
  final int x;
  final int y;
  final TileType type;
  const LevelTile(this.x, this.y, this.type);
}

class LevelData {
  final List<LevelTile> tiles;

  const LevelData({required this.tiles});

  /// Level ends when player reaches the gate tile.
  int get length {
    for (final tile in tiles) {
      if (tile.type == TileType.gate) return tile.x + 2;
    }
    return tiles.map((t) => t.x).reduce((a, b) => a > b ? a : b) + 2;
  }
}

final level1 = LevelData(
  tiles: [
    // Section 1: Ground with single obstacles
    // Ground tiles at even x (each covers 2 units)
    for (int x = 0; x <= 8; x += 2) LevelTile(x, 0, TileType.ground),
    LevelTile(10, 1, TileType.triangle),
    for (int x = 10; x <= 14; x += 2) LevelTile(x, 0, TileType.ground),
    // Gap at 16-17 (2 units wide, pit graphic)
    LevelTile(16, 0, TileType.pit),
    for (int x = 18; x <= 22; x += 2) LevelTile(x, 0, TileType.ground),
    LevelTile(24, 1, TileType.block),
    for (int x = 24; x <= 28; x += 2) LevelTile(x, 0, TileType.ground),
    LevelTile(30, 1, TileType.triangle),
    for (int x = 30; x <= 34; x += 2) LevelTile(x, 0, TileType.ground),

    // Section 2: First platform (y=2)
    for (int x = 36; x <= 38; x += 2) LevelTile(x, 0, TileType.ground),
    LevelTile(36, 2, TileType.block),
    LevelTile(38, 2, TileType.block),

    // Double triangle
    LevelTile(41, 1, TileType.triangle),
    LevelTile(46, 1, TileType.triangle),
    for (int x = 40; x <= 50; x += 2) LevelTile(x, 0, TileType.ground),

    // 3 spikes in a row
    LevelTile(53, 1, TileType.triangle),
    LevelTile(54, 1, TileType.triangle),
    LevelTile(55, 1, TileType.triangle),
    for (int x = 52; x <= 56; x += 2) LevelTile(x, 0, TileType.ground),
    // Gap before platforms
    LevelTile(58, 0, TileType.pit),

    // Section 3: Ascending platforms (staircase, +1 each step, 2 wide each)
    for (int x = 60; x <= 62; x += 2) LevelTile(x, 0, TileType.ground),
    // Step 1: y=1
    LevelTile(64, 1, TileType.block),
    LevelTile(66, 1, TileType.block),
    // Step 2: y=2
    LevelTile(70, 2, TileType.block),
    LevelTile(72, 2, TileType.block),
    // Step 3: y=3
    LevelTile(76, 3, TileType.block),
    LevelTile(78, 3, TileType.block),
    // Step 4: y=4
    LevelTile(82, 4, TileType.block),
    LevelTile(84, 4, TileType.block),
    // Spike on top
    LevelTile(86, 5, TileType.triangle),
    LevelTile(86, 4, TileType.block),

    // Section 4: Large drop back to ground
    for (int x = 92; x <= 98; x += 2) LevelTile(x, 0, TileType.ground),
    for (int x = 102; x <= 104; x += 2) LevelTile(x, 0, TileType.ground),

    // Section 5: Final obstacles before gate
    LevelTile(95, 1, TileType.triangle),
    LevelTile(100, 0, TileType.pit),

    // Gate at end (2x2, placed on last ground)
    LevelTile(104, 1, TileType.gate),
  ],
);

final levels = [level1];

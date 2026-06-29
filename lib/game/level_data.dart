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

final level1 = LevelData(
  length: 100,
  tiles: [
    // Section 1: Ground with single obstacles
    for (int x = 0; x <= 9; x++) LevelTile(x, 0, TileType.ground),
    LevelTile(10, 1, TileType.triangle),
    for (int x = 10; x <= 14; x++) LevelTile(x, 0, TileType.ground),
    // Gap at 15-16
    for (int x = 17; x <= 22; x++) LevelTile(x, 0, TileType.ground),
    LevelTile(23, 1, TileType.block),
    for (int x = 23; x <= 28; x++) LevelTile(x, 0, TileType.ground),
    LevelTile(30, 1, TileType.triangle),
    for (int x = 29; x <= 33; x++) LevelTile(x, 0, TileType.ground),

    // Section 2: First platform (y=2)
    for (int x = 34; x <= 38; x++) LevelTile(x, 0, TileType.ground),
    LevelTile(35, 2, TileType.block),
    LevelTile(36, 2, TileType.block),
    LevelTile(37, 2, TileType.block),

    // Double triangle
    LevelTile(40, 1, TileType.triangle),
    LevelTile(45, 1, TileType.triangle),
    for (int x = 39; x <= 49; x++) LevelTile(x, 0, TileType.ground),

    // 3 spikes in a row
    LevelTile(52, 1, TileType.triangle),
    LevelTile(53, 1, TileType.triangle),
    LevelTile(54, 1, TileType.triangle),
    for (int x = 50; x <= 58; x++) LevelTile(x, 0, TileType.ground),

    // Section 3: Ascending platforms (staircase, +1 each step, 4 wide)
    for (int x = 59; x <= 62; x++) LevelTile(x, 0, TileType.ground),
    // Step 1: y=1
    for (int x = 63; x <= 66; x++) LevelTile(x, 1, TileType.block),
    // Step 2: y=2
    for (int x = 68; x <= 71; x++) LevelTile(x, 2, TileType.block),
    // Step 3: y=3
    for (int x = 73; x <= 76; x++) LevelTile(x, 3, TileType.block),
    // Step 4: y=4
    for (int x = 78; x <= 81; x++) LevelTile(x, 4, TileType.block),
    // Step 5: y=5 with spike
    for (int x = 83; x <= 86; x++) LevelTile(x, 5, TileType.block),

    // Section 4: Large drop back to ground (freefall from y=5)
    for (int x = 93; x <= 103; x++) LevelTile(x, 0, TileType.ground),

    // Section 5: Final obstacles before gate
    LevelTile(93, 1, TileType.triangle),
    LevelTile(99, 1, TileType.block),
  ],
);

final levels = [level1];

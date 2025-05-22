# Manual Coordinate Debugging Guide

## Systematic Testing Plan

Based on the debug output we've seen, here's a systematic approach to identify the coordinate transformation issue:

### Phase 1: Identify Visual vs Logical Element Positions

From the debug output, we know:
- **person1 logical bounds**: `306,6 -> 386,126` (at zoom 1.0)
- **system1 logical bounds**: `730,444 -> 827,504` (at zoom 1.0)

### Phase 2: Test Clicks at Calculated Positions

#### Test 1: person1 Element (Zoom 1.0)
- **Expected logical center**: `(346, 66)`
- **Action**: Click at exactly `(346, 66)` at zoom 1.0
- **Expected result**: Should hit person1
- **Actual result**: [Record from debug output]

#### Test 2: system1 Element (Zoom 1.0)
- **Expected logical center**: `(778, 474)`
- **Action**: Click at exactly `(778, 474)` at zoom 1.0
- **Expected result**: Should hit system1
- **Actual result**: [Record from debug output]

#### Test 3: Zoom Out Test (0.7x)
- **Action**: Zoom out to 0.7, then click at person1 visual position
- **person1 visual position should be**: `(346 * 0.7, 66 * 0.7) = (242, 46)`
- **BUT debug shows adjusted coords are calculated as**: `(346 / 0.7, 66 / 0.7) = (494, 94)`
- **Expected result**: Test both positions to see which works

#### Test 4: Pan Offset Test
- **Action**: Pan the diagram, then test clicks
- **When pan = (50, 30)**, test clicking person1
- **Expected logical coords**: Should account for pan offset

### Phase 3: Coordinate Transformation Analysis

The core issue is in this line:
```dart
final adjustedPoint = (details.localPosition / _zoomScale) - _panOffset;
```

But canvas rendering uses:
```dart
canvas.translate(panOffset.dx, panOffset.dy);
canvas.scale(zoomScale);
```

### Phase 4: Test Different Coordinate Formulas

Try these alternatives in the code:

#### Formula A (Current):
```dart
final adjustedPoint = (details.localPosition / _zoomScale) - _panOffset;
```

#### Formula B (Alternative 1):
```dart
final adjustedPoint = (details.localPosition - _panOffset) / _zoomScale;
```

#### Formula C (Alternative 2 - No Transform):
```dart
final adjustedPoint = details.localPosition; // Raw coordinates
```

#### Formula D (Alternative 3 - Only Scale):
```dart
final adjustedPoint = details.localPosition / _zoomScale;
```

### Phase 5: Expected Results Matrix

| Test Case | Zoom | Pan | Click Position | Formula A | Formula B | Formula C | Formula D |
|-----------|------|-----|----------------|-----------|-----------|-----------|-----------|
| person1 | 1.0 | (0,0) | (346,66) | ✓ | ✓ | ✓ | ✓ |
| person1 | 0.7 | (0,0) | (242,46) | ? | ? | ? | ? |
| person1 | 0.7 | (0,0) | (346,66) | ? | ? | ? | ? |
| system1 | 1.0 | (0,0) | (778,474) | ✓ | ✓ | ✓ | ✓ |

### Manual Testing Steps

1. **Run the desktop app**: `flutter run -d linux`
2. **Test each formula** by temporarily changing the coordinate calculation
3. **Record which clicks succeed** for each zoom/pan combination
4. **Identify the correct transformation pattern**

### Debug Output to Watch For

Look for these patterns in debug output:
- `COORD_DEBUG: Using RAW coordinates for hit test` (indicates raw coords work better)
- `COORD_DEBUG: Using ADJUSTED coordinates for hit test` (indicates adjusted coords work)
- `✅ ELEMENT HIT DETECTED` (successful hit)
- `❌ NO ELEMENT HIT` (failed hit)

### Key Insight from Previous Testing

From our earlier runs, we saw:
- **Raw coordinates often work better** when zoomed out
- **Adjusted coordinates work at zoom 1.0**
- This suggests the **coordinate transformation formula is incorrect for non-1.0 zoom levels**

### Root Cause Hypothesis

The issue is likely that:
1. **DiagramPainter.performHitTest()** works in **logical coordinates** (no transformations)
2. **DiagramPainter.paint()** applies **canvas transformations** (translate + scale)
3. **Hit testing coordinate conversion** must **exactly reverse** the paint transformations

The correct order should be:
1. **Visual click** → **Reverse scale** → **Reverse translate** → **Logical coordinates**
2. Which means: `(click / scale) - pan` ✓ (our current formula)
3. NOT: `(click - pan) / scale` ❌

But there might be additional factors like:
- **Canvas coordinate system origin differences**
- **Element positioning calculation differences between hit test and render**
- **Layout calculation inconsistencies**

### Next Action Plan

1. Test Formula A vs Formula B systematically
2. If both fail, investigate DiagramPainter layout consistency
3. Check if element rectangles in hit test match render coordinates exactly
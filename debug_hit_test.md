# Debug Hit Test Instructions

Based on the debug output, the elements are positioned at:
- system: Rect.fromLTRB(722.0, 494.0, 819.2, 554.0)
- user: Rect.fromLTRB(322.0, 47.0, 402.0, 167.0)

## To test:
1. The app should show red rectangles overlaying the elements (debug hit areas)
2. Click on the "User" element around position (322-402, 47-167)
3. Click on the "System" element around position (722-819, 494-554)
4. Check the console for "HIT!" messages

## Expected debug output when clicking:
- DEBUG: ===== HIT TEST DEBUG =====
- DEBUG: Tap at local: ...
- DEBUG: Adjusted point: ...
- DEBUG: HIT! Element ... (User/System)

## Current issues being debugged:
1. Element selection not working
2. Fit to screen should use centroid
3. Zoom buttons should center on canvas (already fixed)
#!/bin/bash

echo "Starting Flutter app with drag debug logging..."
echo "Try to drag an element and watch the output"
echo "Press Ctrl+C to stop"
echo "========================================"

cd /home/jenner/Code/dart-structurizr
flutter run -d linux 2>&1 | grep -E "DEBUG:.*UnifiedScale|DEBUG:.*DRAG|DEBUG:.*ELEMENT|DEBUG:.*HIT!|DEBUG:.*Contains\?|DEBUG:.*isEditable|DEBUG:.*_handlePan|DEBUG:.*temporaryElement|DEBUG:.*Moving element|DEBUG:.*delta:|DEBUG:.*adjustedPoint:|DEBUG:.*cachedElementRects|DEBUG:.*WARNING"
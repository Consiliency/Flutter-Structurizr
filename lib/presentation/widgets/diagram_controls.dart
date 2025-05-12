import 'package:flutter/material.dart';

/// Configuration for the diagram controls
class DiagramControlsConfig {
  /// Whether to show the zoom in button
  final bool showZoomIn;
  
  /// Whether to show the zoom out button
  final bool showZoomOut;
  
  /// Whether to show the reset view button
  final bool showResetView;
  
  /// Whether to show the fit to screen button
  final bool showFitToScreen;
  
  /// Whether to show the button labels
  final bool showLabels;
  
  /// Whether to arrange the controls vertically (true) or horizontally (false)
  final bool isVertical;
  
  /// Color of the control buttons
  final Color? buttonColor;
  
  /// Color of the control button icons
  final Color? iconColor;
  
  /// Size of the buttons
  final double buttonSize;
  
  /// Spacing between buttons
  final double buttonSpacing;
  
  /// Opacity of the buttons
  final double opacity;
  
  /// Background blur effect intensity (0 for no blur)
  final double blurRadius;
  
  /// Creates a new configuration for diagram controls
  const DiagramControlsConfig({
    this.showZoomIn = true,
    this.showZoomOut = true,
    this.showResetView = true,
    this.showFitToScreen = true,
    this.showLabels = false,
    this.isVertical = true,
    this.buttonColor,
    this.iconColor,
    this.buttonSize = 40.0,
    this.buttonSpacing = 8.0,
    this.opacity = 0.8,
    this.blurRadius = 0.0,
  });
  
  /// Creates a copy of this configuration with the given fields replaced with new values
  DiagramControlsConfig copyWith({
    bool? showZoomIn,
    bool? showZoomOut,
    bool? showResetView,
    bool? showFitToScreen,
    bool? showLabels,
    bool? isVertical,
    Color? buttonColor,
    Color? iconColor,
    double? buttonSize,
    double? buttonSpacing,
    double? opacity,
    double? blurRadius,
  }) {
    return DiagramControlsConfig(
      showZoomIn: showZoomIn ?? this.showZoomIn,
      showZoomOut: showZoomOut ?? this.showZoomOut,
      showResetView: showResetView ?? this.showResetView,
      showFitToScreen: showFitToScreen ?? this.showFitToScreen,
      showLabels: showLabels ?? this.showLabels,
      isVertical: isVertical ?? this.isVertical,
      buttonColor: buttonColor ?? this.buttonColor,
      iconColor: iconColor ?? this.iconColor,
      buttonSize: buttonSize ?? this.buttonSize,
      buttonSpacing: buttonSpacing ?? this.buttonSpacing,
      opacity: opacity ?? this.opacity,
      blurRadius: blurRadius ?? this.blurRadius,
    );
  }
}

/// A widget that provides navigation controls for a Structurizr diagram.
/// 
/// This widget typically displays buttons for zooming in/out, resetting the view,
/// and fitting the diagram to the screen.
class DiagramControls extends StatelessWidget {
  /// Called when the user taps the zoom in button
  final VoidCallback onZoomIn;
  
  /// Called when the user taps the zoom out button
  final VoidCallback onZoomOut;
  
  /// Called when the user taps the reset view button
  final VoidCallback onResetView;
  
  /// Called when the user taps the fit to screen button
  final VoidCallback onFitToScreen;
  
  /// Configuration options for the controls
  final DiagramControlsConfig config;
  
  /// Creates a new diagram controls widget
  const DiagramControls({
    Key? key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onResetView,
    required this.onFitToScreen,
    this.config = const DiagramControlsConfig(),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Use theme colors if not specified in config
    final buttonColor = config.buttonColor ?? theme.colorScheme.surface;
    final iconColor = config.iconColor ?? theme.colorScheme.primary;
    
    // Create control buttons
    final controls = <Widget>[];
    
    // Zoom in button
    if (config.showZoomIn) {
      controls.add(_buildButton(
        icon: Icons.add,
        label: 'Zoom In',
        onPressed: onZoomIn,
        buttonColor: buttonColor,
        iconColor: iconColor,
      ));
      
      controls.add(SizedBox(
        height: config.isVertical ? config.buttonSpacing : 0,
        width: config.isVertical ? 0 : config.buttonSpacing,
      ));
    }
    
    // Zoom out button
    if (config.showZoomOut) {
      controls.add(_buildButton(
        icon: Icons.remove,
        label: 'Zoom Out',
        onPressed: onZoomOut,
        buttonColor: buttonColor,
        iconColor: iconColor,
      ));
      
      controls.add(SizedBox(
        height: config.isVertical ? config.buttonSpacing : 0,
        width: config.isVertical ? 0 : config.buttonSpacing,
      ));
    }
    
    // Reset view button
    if (config.showResetView) {
      controls.add(_buildButton(
        icon: Icons.center_focus_strong,
        label: 'Reset View',
        onPressed: onResetView,
        buttonColor: buttonColor,
        iconColor: iconColor,
      ));
      
      controls.add(SizedBox(
        height: config.isVertical ? config.buttonSpacing : 0,
        width: config.isVertical ? 0 : config.buttonSpacing,
      ));
    }
    
    // Fit to screen button
    if (config.showFitToScreen) {
      controls.add(_buildButton(
        icon: Icons.fit_screen,
        label: 'Fit to Screen',
        onPressed: onFitToScreen,
        buttonColor: buttonColor,
        iconColor: iconColor,
      ));
    }
    
    // Create container with controls
    return Container(
      decoration: BoxDecoration(
        color: buttonColor.withOpacity(config.opacity),
        borderRadius: BorderRadius.circular(config.buttonSize / 2),
        boxShadow: [
          if (config.blurRadius > 0)
            BoxShadow(
              blurRadius: config.blurRadius,
              color: Colors.black.withOpacity(0.2),
            ),
        ],
      ),
      child: config.isVertical
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: controls,
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: controls,
            ),
    );
  }
  
  /// Build a control button with optional label
  Widget _buildButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color buttonColor,
    required Color iconColor,
  }) {
    final buttonWidget = SizedBox(
      width: config.buttonSize,
      height: config.buttonSize,
      child: IconButton(
        icon: Icon(icon, color: iconColor),
        onPressed: onPressed,
        tooltip: label,
        padding: EdgeInsets.zero,
      ),
    );
    
    if (!config.showLabels) {
      return buttonWidget;
    }
    
    // If labels should be shown, wrap the button in a column/row with a label
    return config.isVertical
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buttonWidget,
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 10,
                ),
              ),
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              buttonWidget,
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 10,
                ),
              ),
            ],
          );
  }
}
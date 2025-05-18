import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_structurizr/domain/view/view.dart';

/// Callback for when the animation step changes
typedef AnimationStepChangedCallback = void Function(int step);

/// Animation mode for playback
enum AnimationMode {
  /// Play once and stop at the end
  playOnce,

  /// Loop back to the beginning after reaching the end
  loop,

  /// Ping-pong between the start and end
  pingPong,
}

/// Configuration for the animation controls
class AnimationControlsConfig {
  /// Whether to automatically start the animation when widget is loaded
  final bool autoPlay;

  /// Default animation mode
  final AnimationMode defaultMode;

  /// Animation speed in frames per second (default 1)
  final double fps;

  /// Show step labels next to the slider
  final bool showStepLabels;

  /// Show timing controls (speed slider)
  final bool showTimingControls;

  /// Show mode controls (play once, loop, ping-pong)
  final bool showModeControls;

  /// Width of the timeline/slider
  final double timelineWidth;

  /// Height of the controls
  final double height;

  /// Background color for the controls
  final Color? backgroundColor;

  /// Text color for controls and labels
  final Color? textColor;

  /// Icon color for control buttons
  final Color? iconColor;

  /// Color for the active step in the timeline
  final Color? activeColor;

  /// Color for inactive steps in the timeline
  final Color? inactiveColor;

  /// Creates a new configuration for animation controls
  const AnimationControlsConfig({
    this.autoPlay = false,
    this.defaultMode = AnimationMode.playOnce,
    this.fps = 1.0,
    this.showStepLabels = true,
    this.showTimingControls = true,
    this.showModeControls = true,
    this.timelineWidth = 200.0,
    this.height = 80.0,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
    this.activeColor,
    this.inactiveColor,
  });

  /// Creates a copy of this configuration with the given fields replaced with new values
  AnimationControlsConfig copyWith({
    bool? autoPlay,
    AnimationMode? defaultMode,
    double? fps,
    bool? showStepLabels,
    bool? showTimingControls,
    bool? showModeControls,
    double? timelineWidth,
    double? height,
    Color? backgroundColor,
    Color? textColor,
    Color? iconColor,
    Color? activeColor,
    Color? inactiveColor,
  }) {
    return AnimationControlsConfig(
      autoPlay: autoPlay ?? this.autoPlay,
      defaultMode: defaultMode ?? this.defaultMode,
      fps: fps ?? this.fps,
      showStepLabels: showStepLabels ?? this.showStepLabels,
      showTimingControls: showTimingControls ?? this.showTimingControls,
      showModeControls: showModeControls ?? this.showModeControls,
      timelineWidth: timelineWidth ?? this.timelineWidth,
      height: height ?? this.height,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      iconColor: iconColor ?? this.iconColor,
      activeColor: activeColor ?? this.activeColor,
      inactiveColor: inactiveColor ?? this.inactiveColor,
    );
  }
}

/// A widget that provides controls for playing, pausing, and navigating dynamic view animations.
///
/// This widget integrates with the StructurizrDiagram widget by providing an interface
/// to control the animation steps displayed on the diagram.
class AnimationControls extends StatefulWidget {
  /// List of animation steps to control
  final List<AnimationStep> animationSteps;

  /// Current animation step index
  final int initialStep;

  /// Called when the animation step changes
  final AnimationStepChangedCallback onStepChanged;

  /// Configuration options for the animation controls
  final AnimationControlsConfig config;

  /// Creates a new animation controls widget for dynamic views
  const AnimationControls({
    Key? key,
    required this.animationSteps,
    this.initialStep = 0,
    required this.onStepChanged,
    this.config = const AnimationControlsConfig(),
  }) : super(key: key);

  @override
  State<AnimationControls> createState() => _AnimationControlsState();
}

class _AnimationControlsState extends State<AnimationControls>
    with SingleTickerProviderStateMixin {
  /// Current animation step index
  late int _currentStep;

  /// Whether the animation is currently playing
  bool _isPlaying = false;

  /// Timer for automatic playback
  Timer? _playbackTimer;

  /// Current animation playback direction (1 for forward, -1 for backward)
  int _playbackDirection = 1;

  /// Current animation playback mode
  late AnimationMode _mode;

  /// Current frames per second
  late double _fps;

  /// Animation controller for smooth transitions
  late AnimationController _animationController;

  /// Current transition animation
  Animation<double>? _stepTransition;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep.clamp(0, _maxStepIndex);
    _mode = widget.config.defaultMode;
    _fps = widget.config.fps;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    if (widget.config.autoPlay && widget.animationSteps.isNotEmpty) {
      _startPlayback();
    }
  }

  @override
  void didUpdateWidget(AnimationControls oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle changes to animation steps
    if (oldWidget.animationSteps != widget.animationSteps) {
      _currentStep = _currentStep.clamp(0, _maxStepIndex);

      // If the animation was playing, restart with new steps
      final wasPlaying = _isPlaying;
      _stopPlayback();

      if (wasPlaying && widget.animationSteps.isNotEmpty) {
        _startPlayback();
      }
    }

    // Handle changes to initial step
    if (oldWidget.initialStep != widget.initialStep && !_isPlaying) {
      _jumpToStep(widget.initialStep.clamp(0, _maxStepIndex));
    }
  }

  @override
  void dispose() {
    _stopPlayback();
    _animationController.dispose();
    super.dispose();
  }

  /// Get the maximum step index
  int get _maxStepIndex =>
      widget.animationSteps.isEmpty ? 0 : widget.animationSteps.length - 1;

  /// Start the automatic playback
  void _startPlayback() {
    if (_isPlaying || widget.animationSteps.isEmpty) return;

    setState(() {
      _isPlaying = true;
    });

    // Calculate the playback interval based on FPS
    final interval = Duration(milliseconds: (1000 / _fps).round());

    // Create a periodic timer for playback
    _playbackTimer = Timer.periodic(interval, (timer) {
      _advanceToNextStep();
    });
  }

  /// Stop the automatic playback
  void _stopPlayback() {
    if (!_isPlaying) return;

    _playbackTimer?.cancel();
    _playbackTimer = null;

    setState(() {
      _isPlaying = false;
    });
  }

  /// Toggle the playback state
  void _togglePlayback() {
    if (_isPlaying) {
      _stopPlayback();
    } else {
      _startPlayback();
    }
  }

  /// Advance to the next step based on the current animation mode
  void _advanceToNextStep() {
    if (widget.animationSteps.isEmpty) return;

    int nextStep = _currentStep;

    switch (_mode) {
      case AnimationMode.playOnce:
        // In play once mode, just increment until the end
        if (_currentStep < _maxStepIndex) {
          nextStep = _currentStep + 1;
        } else {
          // Stop at the end
          _stopPlayback();
          return;
        }
        break;

      case AnimationMode.loop:
        // In loop mode, wrap around to the beginning
        nextStep = (_currentStep + 1) % widget.animationSteps.length;
        break;

      case AnimationMode.pingPong:
        // In ping-pong mode, change direction at the ends
        nextStep = _currentStep + _playbackDirection;

        // If we've reached an end, reverse direction
        if (nextStep < 0 || nextStep > _maxStepIndex) {
          _playbackDirection *= -1;
          nextStep = _currentStep + _playbackDirection;
        }
        break;
    }

    _animateToStep(nextStep);
  }

  /// Go to the previous step
  void _goToPreviousStep() {
    if (widget.animationSteps.isEmpty) return;

    final prevStep = (_currentStep - 1).clamp(0, _maxStepIndex);
    if (prevStep != _currentStep) {
      _animateToStep(prevStep);
    }
  }

  /// Go to the next step
  void _goToNextStep() {
    if (widget.animationSteps.isEmpty) return;

    final nextStep = (_currentStep + 1).clamp(0, _maxStepIndex);
    if (nextStep != _currentStep) {
      _animateToStep(nextStep);
    }
  }

  /// Jump to a specific step immediately (without animation)
  void _jumpToStep(int step) {
    if (widget.animationSteps.isEmpty) return;

    final clampedStep = step.clamp(0, _maxStepIndex);
    if (clampedStep != _currentStep) {
      setState(() {
        _currentStep = clampedStep;
      });

      widget.onStepChanged(_currentStep);
    }
  }

  /// Animate smoothly to a specific step
  void _animateToStep(int step) {
    if (widget.animationSteps.isEmpty) return;

    final clampedStep = step.clamp(0, _maxStepIndex);
    if (clampedStep == _currentStep) return;

    // Cancel any ongoing animations
    _animationController.stop();

    // Create a new animation for the transition
    _stepTransition = Tween<double>(
      begin: _currentStep.toDouble(),
      end: clampedStep.toDouble(),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Listen to animation updates
    void listener() {
      // Update the current step when the animation finishes
      if (_animationController.status == AnimationStatus.completed) {
        setState(() {
          _currentStep = clampedStep;
        });

        widget.onStepChanged(_currentStep);
        _animationController.removeListener(listener);
      }
    }

    _animationController.addListener(listener);

    // Start the animation
    _animationController.forward(from: 0.0);
  }

  /// Set the animation speed in frames per second
  void _setSpeed(double fps) {
    if (_fps == fps) return;

    setState(() {
      _fps = fps;
    });

    // If the animation is playing, restart with the new speed
    if (_isPlaying) {
      _stopPlayback();
      _startPlayback();
    }
  }

  /// Set the animation mode
  void _setMode(AnimationMode mode) {
    setState(() {
      _mode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Use theme colors if not specified in config
    final backgroundColor =
        widget.config.backgroundColor ?? Colors.black.withValues(alpha: 0.1);
    final textColor = widget.config.textColor ?? colorScheme.onSurface;
    final iconColor = widget.config.iconColor ?? colorScheme.primary;
    final activeColor = widget.config.activeColor ?? colorScheme.primary;
    final inactiveColor = widget.config.inactiveColor ??
        colorScheme.onSurface.withValues(alpha: 0.3);

    // Build a label for the current step
    final stepLabel = widget.animationSteps.isEmpty
        ? 'No steps'
        : 'Step ${_currentStep + 1}/${widget.animationSteps.length}';

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8.0),
      child: SizedBox(
        height: widget.config.height,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Step display and controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Step back button
                    IconButton(
                      icon: Icon(Icons.skip_previous, color: iconColor),
                      onPressed: widget.animationSteps.isEmpty
                          ? null
                          : _goToPreviousStep,
                      tooltip: 'Previous Step',
                    ),

                    // Play/pause button
                    IconButton(
                      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow,
                          color: iconColor),
                      onPressed: widget.animationSteps.isEmpty
                          ? null
                          : _togglePlayback,
                      tooltip: _isPlaying ? 'Pause' : 'Play',
                    ),

                    // Step forward button
                    IconButton(
                      icon: Icon(Icons.skip_next, color: iconColor),
                      onPressed:
                          widget.animationSteps.isEmpty ? null : _goToNextStep,
                      tooltip: 'Next Step',
                    ),

                    // Current step indicator
                    SizedBox(
                      width: 100,
                      child: Text(
                        stepLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                // Timeline slider
                if (widget.animationSteps.isNotEmpty) ...[
                  SizedBox(
                    width: widget.config.timelineWidth,
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: activeColor,
                        inactiveTrackColor: inactiveColor,
                        thumbColor: activeColor,
                        overlayColor: activeColor.withValues(alpha: 0.2),
                        showValueIndicator: ShowValueIndicator.always,
                      ),
                      child: Slider(
                        min: 0,
                        max: _maxStepIndex.toDouble(),
                        divisions: _maxStepIndex,
                        value: _currentStep.toDouble(),
                        label: 'Step ${_currentStep + 1}',
                        onChanged: (value) {
                          _jumpToStep(value.round());
                        },
                      ),
                    ),
                  ),

                  // Additional controls (speed, mode)
                  if (widget.config.showTimingControls ||
                      widget.config.showModeControls)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 16.0,
                        children: [
                          // Speed control
                          if (widget.config.showTimingControls)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Speed:',
                                  style:
                                      TextStyle(color: textColor, fontSize: 12),
                                ),
                                const SizedBox(width: 8),
                                DropdownButton<double>(
                                  value: _fps,
                                  dropdownColor: Theme.of(context)
                                      .dialogTheme
                                      .backgroundColor,
                                  style:
                                      TextStyle(color: textColor, fontSize: 12),
                                  underline: Container(
                                    height: 1,
                                    color: textColor.withValues(alpha: 0.3),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 0.5, child: Text('0.5x')),
                                    DropdownMenuItem(
                                        value: 1.0, child: Text('1x')),
                                    DropdownMenuItem(
                                        value: 2.0, child: Text('2x')),
                                    DropdownMenuItem(
                                        value: 3.0, child: Text('3x')),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      _setSpeed(value);
                                    }
                                  },
                                ),
                              ],
                            ),

                          // Mode control
                          if (widget.config.showModeControls)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Mode:',
                                  style:
                                      TextStyle(color: textColor, fontSize: 12),
                                ),
                                const SizedBox(width: 8),
                                DropdownButton<AnimationMode>(
                                  value: _mode,
                                  dropdownColor: Theme.of(context)
                                      .dialogTheme
                                      .backgroundColor,
                                  style:
                                      TextStyle(color: textColor, fontSize: 12),
                                  underline: Container(
                                    height: 1,
                                    color: textColor.withValues(alpha: 0.3),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: AnimationMode.playOnce,
                                      child: Text('Once'),
                                    ),
                                    DropdownMenuItem(
                                      value: AnimationMode.loop,
                                      child: Text('Loop'),
                                    ),
                                    DropdownMenuItem(
                                      value: AnimationMode.pingPong,
                                      child: Text('Ping-pong'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      _setMode(value);
                                    }
                                  },
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

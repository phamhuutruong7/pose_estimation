import 'package:flutter/material.dart';

enum DrawingTool {
  none,
  line,
  rectangle,
  circle,
  eraser,
}

class DrawingToolbar extends StatefulWidget {
  final DrawingTool selectedTool;
  final Function(DrawingTool) onToolSelected;
  final VoidCallback onClearDrawings;
  final bool hasDrawings;

  const DrawingToolbar({
    super.key,
    required this.selectedTool,
    required this.onToolSelected,
    required this.onClearDrawings,
    this.hasDrawings = false,
  });

  @override
  State<DrawingToolbar> createState() => _DrawingToolbarState();
}

class _DrawingToolbarState extends State<DrawingToolbar> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
        // When collapsing, also deselect any drawing tool
        if (widget.selectedTool != DrawingTool.none) {
          widget.onToolSelected(DrawingTool.none);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        return Container(
          width: _isExpanded ? 60 : 50,
          margin: const EdgeInsets.only(right: 16, top: 80, bottom: 80),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(_isExpanded ? 30 : 25),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              
              // Toggle Button (Pencil/Close)
              _buildToggleButton(),
              
              // Expanded Content
              if (_isExpanded) ...[
                const SizedBox(height: 8),
                
                // Divider
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                
                const SizedBox(height: 8),
                
                // Line Drawing Tool (Blue)
                AnimatedOpacity(
                  opacity: _expandAnimation.value,
                  duration: const Duration(milliseconds: 200),
                  child: _buildToolButton(
                    icon: Icons.trending_up,
                    tool: DrawingTool.line,
                    tooltip: 'Draw Line (Blue)\n(Press & Drag)',
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Rectangle Drawing Tool (Green)
                AnimatedOpacity(
                  opacity: _expandAnimation.value,
                  duration: const Duration(milliseconds: 200),
                  child: _buildToolButton(
                    icon: Icons.crop_square,
                    tool: DrawingTool.rectangle,
                    tooltip: 'Draw Rectangle (Green)\n(Press & Drag)',
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Circle Drawing Tool (Red)
                AnimatedOpacity(
                  opacity: _expandAnimation.value,
                  duration: const Duration(milliseconds: 200),
                  child: _buildToolButton(
                    icon: Icons.radio_button_unchecked,
                    tool: DrawingTool.circle,
                    tooltip: 'Draw Circle (Red)\n(Press & Drag)',
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Divider
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                
                const SizedBox(height: 8),
                
                // Eraser Tool
                AnimatedOpacity(
                  opacity: _expandAnimation.value,
                  duration: const Duration(milliseconds: 200),
                  child: _buildToolButton(
                    icon: Icons.auto_fix_high,
                    tool: DrawingTool.eraser,
                    tooltip: 'Eraser\n(Drag over shapes)',
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Divider
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                
                const SizedBox(height: 8),
                
                // Clear All Button
                AnimatedOpacity(
                  opacity: _expandAnimation.value,
                  duration: const Duration(milliseconds: 200),
                  child: _buildActionButton(
                    icon: Icons.clear_all,
                    onPressed: widget.hasDrawings ? widget.onClearDrawings : null,
                    tooltip: 'Clear All',
                  ),
                ),
              ],
              
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToggleButton() {
    return Tooltip(
      message: _isExpanded ? 'Close Drawing Tools' : 'Open Drawing Tools',
      child: GestureDetector(
        onTap: _toggleExpanded,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _isExpanded ? Colors.red.withValues(alpha: 0.2) : Colors.blue.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _isExpanded ? Colors.red : Colors.blue,
              width: 2,
            ),
          ),
          child: Icon(
            _isExpanded ? Icons.close : Icons.edit,
            color: _isExpanded ? Colors.red : Colors.blue,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required DrawingTool tool,
    required String tooltip,
  }) {
    final isSelected = widget.selectedTool == tool;
    
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () => widget.onToolSelected(tool),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isSelected ? Colors.yellow.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected ? Colors.yellow : Colors.transparent,
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.yellow : Colors.white.withValues(alpha: 0.8),
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    final isEnabled = onPressed != null;
    
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Icon(
            icon,
            color: isEnabled 
                ? Colors.white.withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.3),
            size: 24,
          ),
        ),
      ),
    );
  }
}

class DrawingInstructions extends StatelessWidget {
  final DrawingTool selectedTool;

  const DrawingInstructions({
    super.key,
    required this.selectedTool,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedTool == DrawingTool.none) return const SizedBox.shrink();

    String instruction = '';
    switch (selectedTool) {
      case DrawingTool.line:
        instruction = 'Draw Line (Blue):\nPress and drag to create';
        break;
      case DrawingTool.rectangle:
        instruction = 'Draw Rectangle (Green):\nPress and drag to create';
        break;
      case DrawingTool.circle:
        instruction = 'Draw Circle (Red):\nPress and drag to create';
        break;
      case DrawingTool.eraser:
        instruction = 'Eraser Mode:\nDrag over shapes to remove them';
        break;
      case DrawingTool.none:
        return const SizedBox.shrink();
    }

    return Positioned(
      top: 120,
      left: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.yellow.withValues(alpha: 0.5)),
        ),
        child: Text(
          instruction,
          style: const TextStyle(
            color: Colors.yellow,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum DrawingTool {
  none,
  line,
  eraser,
  // Future tools: circle, rectangle, freehand, etc.
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
          width: 48, // Reduced width to match smaller buttons
          margin: const EdgeInsets.only(right: 16), // Removed top/bottom margins
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20), // Reduced border radius for compactness
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4), // Minimal top padding
              
              // Toggle Button (Pencil/Close)
              _buildToggleButton(),
              
              // Expanded Content
              if (_isExpanded) ...[
                const SizedBox(height: 4), // Minimal spacing
                
                // Divider
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 8), // Reduced margins
                  color: Colors.white.withOpacity(0.3),
                ),
                
                const SizedBox(height: 4), // Minimal spacing
                
                // Line Drawing Tool
                AnimatedOpacity(
                  opacity: _expandAnimation.value,
                  duration: const Duration(milliseconds: 200),
                  child: _buildToolButton(
                    svgAssetPath: 'assets/icons/line_tool.svg',
                    tool: DrawingTool.line,
                    tooltip: 'Draw Line\n(Tap → Tap → Drag)',
                  ),
                ),
                
                const SizedBox(height: 4), // Minimal spacing
                
                // Divider
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 8), // Reduced margins
                  color: Colors.white.withOpacity(0.3),
                ),
                
                const SizedBox(height: 4), // Minimal spacing
                
                // Eraser Tool
                AnimatedOpacity(
                  opacity: _expandAnimation.value,
                  duration: const Duration(milliseconds: 200),
                  child: _buildToolButton(
                    svgAssetPath: 'assets/icons/eraser_tool.svg',
                    tool: DrawingTool.eraser,
                    tooltip: 'Eraser\n(Drag over lines)',
                  ),
                ),
                
                const SizedBox(height: 4), // Minimal spacing
                
                // Clear All Button
                AnimatedOpacity(
                  opacity: _expandAnimation.value,
                  duration: const Duration(milliseconds: 200),
                  child: _buildActionButton(
                    svgAssetPath: 'assets/icons/clear_all.svg',
                    onPressed: widget.hasDrawings ? widget.onClearDrawings : null,
                    tooltip: 'Clear All',
                  ),
                ),
              ],
              
              const SizedBox(height: 4), // Minimal bottom padding
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
          width: 32, // Much more compact
          height: 32, // Much more compact
          decoration: BoxDecoration(
            color: _isExpanded ? Colors.red.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isExpanded ? Colors.red : Colors.blue,
              width: 2,
            ),
          ),
          child: Icon(
            _isExpanded ? Icons.close : Icons.edit,
            color: _isExpanded ? Colors.red : Colors.blue,
            size: 18, // Smaller icon to fit better
          ),
        ),
      ),
    );
  }

  Widget _getSvgIcon(String assetPath, {Color? color, double size = 18}) {
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter: color != null 
          ? ColorFilter.mode(color, BlendMode.srcIn)
          : null,
    );
  }

  Widget _buildToolButton({
    required String svgAssetPath,
    required DrawingTool tool,
    required String tooltip,
  }) {
    final isSelected = widget.selectedTool == tool;
    
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () => widget.onToolSelected(tool),
        child: Container(
          width: 32, // Much more compact
          height: 32, // Much more compact
          decoration: BoxDecoration(
            color: isSelected ? Colors.yellow.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Colors.yellow : Colors.transparent,
              width: 2,
            ),
          ),
          child: _getSvgIcon(
            svgAssetPath,
            color: isSelected ? Colors.yellow : Colors.white.withOpacity(0.8),
            size: 18, // Smaller icon to fit better
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String svgAssetPath,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    final isEnabled = onPressed != null;
    
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 32, // Much more compact
          height: 32, // Much more compact
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: _getSvgIcon(
            svgAssetPath,
            color: isEnabled 
                ? Colors.white.withOpacity(0.8)
                : Colors.white.withOpacity(0.3),
            size: 18, // Smaller icon to fit better
          ),
        ),
      ),
    );
  }
}

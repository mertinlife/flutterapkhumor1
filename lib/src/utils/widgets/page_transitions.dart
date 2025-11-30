import 'package:flutter/material.dart';

class PageTransition {
  // Slide from right
  static Route<T> slideFromRight<T>({
    required WidgetBuilder builder,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = const Offset(1.0, 0.0);
        var end = Offset.zero;
        var curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  // Fade transition
  static Route<T> fadeTransition<T>({
    required WidgetBuilder builder,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  // Scale transition
  static Route<T> scaleTransition<T>({
    required WidgetBuilder builder,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var tween = Tween<double>(begin: 0.8, end: 1.0);
        var scaleAnimation = animation.drive(tween);

        return ScaleTransition(
          scale: scaleAnimation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

class StaggeredListView extends StatelessWidget {
  final List<Widget> children;
  final Axis scrollDirection;
  final bool reverse;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final Duration delayBetweenItems;
  final Duration animationDuration;

  const StaggeredListView({
    Key? key,
    required this.children,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.padding,
    this.delayBetweenItems = const Duration(milliseconds: 50),
    this.animationDuration = const Duration(milliseconds: 500),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      scrollDirection: scrollDirection,
      reverse: reverse,
      padding: padding,
      itemCount: children.length,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _buildAnimation(index),
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                scrollDirection == Axis.vertical ? 0 : _getOffset(index),
                scrollDirection == Axis.vertical ? _getOffset(index) : 0,
              ),
              child: Opacity(
                opacity: _getOpacity(index),
                child: children[index],
              ),
            );
          },
        );
      },
    );
  }

  AnimationController _animationController = AnimationController(
    duration: Duration(milliseconds: 500),
    vsync: null, // We'll set this in the widget where it's used
  );

  Animation<double> _buildAnimation(int index) {
    return _animationController
        .drive(CurveTween(curve: Interval(
      (index * delayBetweenItems.inMilliseconds) / 1000,
      ((index * delayBetweenItems.inMilliseconds) + animationDuration.inMilliseconds) / 1000,
      curve: Curves.easeOut,
    )));
  }

  double _getOffset(int index) {
    // Return offset based on animation value
    return 0; // This would be implemented in a more complex version
  }

  double _getOpacity(int index) {
    // Return opacity based on animation
    return 1; // This would be implemented in a more complex version
  }
}

// A more simplified staggered animation using animated list
class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration startDelay;
  final Duration animationDuration;

  const AnimatedListItem({
    Key? key,
    required this.child,
    required this.index,
    this.startDelay = const Duration(milliseconds: 50),
    this.animationDuration = const Duration(milliseconds: 500),
  }) : super(key: key);

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          (widget.index * widget.startDelay.inMilliseconds) / 1000,
          ((widget.index * widget.startDelay.inMilliseconds) + widget.animationDuration.inMilliseconds) / 1000,
          curve: Curves.easeOut,
        ),
      ),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animation,
        curve: Curves.easeOut,
      ),
    );

    // Delay the start of the animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SlideTransition(
          position: _offsetAnimation,
          child: Opacity(
            opacity: _animation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

library expandable_page_view;

import 'package:expandable_page_view/size_reporting_widget.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class ExpandablePageView extends StatefulWidget {
  final List<Widget>? children;
  final int? itemCount;
  final TabController? controller;
  final ValueChanged<int>? onPageChanged;
  final bool reverse;
  final Duration animationDuration;
  final Curve animationCurve;
  final ScrollPhysics? physics;
  final bool pageSnapping;
  final DragStartBehavior dragStartBehavior;
  final String? restorationId;
  final Clip clipBehavior;

  /// Whether to animate the first page displayed by this widget.
  ///
  /// By default (false) [ExpandablePageView] will resize to the size of it's
  /// initially displayed page without any animation.
  final bool animateFirstPage;

  /// The estimated size of displayed pages.
  ///
  /// This property can be used to indicate how big a page will be more or less.
  /// By default (0.0) all pages will have their initial sizes set to 0.0
  /// until they report that their size changed, which will result in
  /// [ExpandablePageView] size animation. This can lead to a behaviour
  /// when after changing the page, [ExpandablePageView] will first shrink to 0.0
  /// and then animate to the size of the page.
  ///
  /// For example: If there is certainty that most pages displayed by [ExpandablePageView]
  /// will vary from 200 to 600 in size, then [estimatedPageSize] could be set to some
  /// value in that range, to at least partially remove the "shrink and expand" effect.
  ///
  /// Setting it to a value much bigger than most pages' sizes might result in a
  /// reversed - "expand and shrink" - effect.
  final double estimatedPageSize;

  ExpandablePageView({
    this.children,
    this.itemCount,
    this.controller,
    this.onPageChanged,
    this.reverse = false,
    this.animationDuration = const Duration(milliseconds: 100),
    this.animationCurve = Curves.easeInOutCubic,
    this.physics,
    this.pageSnapping = true,
    this.dragStartBehavior = DragStartBehavior.start,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    this.animateFirstPage = false,
    this.estimatedPageSize = 0.0,
    Key? key,
  })  : assert(estimatedPageSize >= 0.0),
        super(key: key);

  @override
  _ExpandablePageViewState createState() => _ExpandablePageViewState();
}

class _ExpandablePageViewState extends State<ExpandablePageView>
    with SingleTickerProviderStateMixin {
  late TabController _pageController;
  late List<double> _heights;
  int _currentPage = 0;
  int _previousPage = 0;
  bool _shouldDisposePageController = false;
  bool _firstPageLoaded = false;

  double get _currentHeight => _heights[_currentPage];

  double get _previousHeight => _heights[_previousPage];

  @override
  void initState() {
    _heights = _prepareHeights();
    super.initState();
    _pageController =
        widget.controller ?? TabController(length: 2, vsync: this);
    _pageController.addListener(_updatePage);
    _shouldDisposePageController = widget.controller == null;
  }

  @override
  void dispose() {
    _pageController.removeListener(_updatePage);
    if (_shouldDisposePageController) {
      _pageController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      curve: widget.animationCurve,
      duration: _getDuration(),
      tween: Tween<double>(begin: _previousHeight, end: _currentHeight),
      builder: (context, value, child) => SizedBox(height: value, child: child),
      child: _buildPageView(),
    );
  }

  Duration _getDuration() {
    if (_firstPageLoaded) {
      return widget.animationDuration;
    }
    return widget.animateFirstPage ? widget.animationDuration : Duration.zero;
  }

  Widget _buildPageView() {
    return TabBarView(
      key: widget.key,
      controller: _pageController,
      children: _sizeReportingChildren(),
      physics: widget.physics,
      dragStartBehavior: widget.dragStartBehavior,
    );
  }

  List<double> _prepareHeights() {
    return widget.children!.map((child) => widget.estimatedPageSize).toList();
  }

  void _updatePage() {
    final newPage = _pageController.index;
    if (_currentPage != newPage) {
      setState(() {
        _firstPageLoaded = true;
        _previousPage = _currentPage;
        _currentPage = newPage;
      });
    }
  }

  List<Widget> _sizeReportingChildren() => widget.children!
      .asMap()
      .map(
        (index, child) => MapEntry(
          index,
          OverflowPage(
            onSizeChange: (size) =>
                setState(() => _heights[index] = size.height),
            child: child,
          ),
        ),
      )
      .values
      .toList();
}

class OverflowPage extends StatelessWidget {
  final ValueChanged<Size> onSizeChange;
  final Widget child;

  const OverflowPage({
    required this.onSizeChange,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return OverflowBox(
      minHeight: 0,
      maxHeight: double.infinity,
      alignment: Alignment.topCenter,
      child: SizeReportingWidget(
        onSizeChange: onSizeChange,
        child: child,
      ),
    );
  }
}

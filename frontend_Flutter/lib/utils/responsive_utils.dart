import 'package:flutter/material.dart';

class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

class ResponsiveUtils {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < Breakpoints.mobile;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= Breakpoints.mobile && width < Breakpoints.desktop;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= Breakpoints.desktop;
  }

  static bool isWide(BuildContext context) {
    return MediaQuery.of(context).size.width >= Breakpoints.tablet;
  }

  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static EdgeInsets responsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < Breakpoints.mobile) {
      return const EdgeInsets.all(12);
    } else if (width < Breakpoints.tablet) {
      return const EdgeInsets.all(16);
    } else {
      return const EdgeInsets.all(24);
    }
  }

  static int getGridCrossAxisCount(BuildContext context, {int minItems = 2, int maxItems = 4}) {
    final width = MediaQuery.of(context).size.width;
    if (width < Breakpoints.mobile) {
      return minItems;
    } else if (width < Breakpoints.tablet) {
      return minItems + 1;
    } else if (width < Breakpoints.desktop) {
      return maxItems - 1;
    } else {
      return maxItems;
    }
  }

  static double getMaxContentWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > Breakpoints.desktop) {
      return 900;
    } else if (width > Breakpoints.tablet) {
      return 700;
    }
    return width;
  }

  static Widget constrainedContent({
    required BuildContext context,
    required Widget child,
    double? maxWidth,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? getMaxContentWidth(context),
        ),
        child: child,
      ),
    );
  }
}

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (ResponsiveUtils.isDesktop(context) && desktop != null) {
      return desktop!;
    }
    if (ResponsiveUtils.isTablet(context) && tablet != null) {
      return tablet!;
    }
    return mobile;
  }
}

class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets? mobilePadding;
  final EdgeInsets? tabletPadding;
  final EdgeInsets? desktopPadding;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.mobilePadding,
    this.tabletPadding,
    this.desktopPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: _getPadding(context),
      child: child,
    );
  }

  EdgeInsets _getPadding(BuildContext context) {
    if (ResponsiveUtils.isDesktop(context) && desktopPadding != null) {
      return desktopPadding!;
    }
    if (ResponsiveUtils.isTablet(context) && tabletPadding != null) {
      return tabletPadding!;
    }
    return mobilePadding ?? ResponsiveUtils.responsivePadding(context);
  }
}

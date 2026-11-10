import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../gestures/app_tap_area.dart';
import '../images/app_image.dart';

///顶级父类容器包含顶部视图
///{navigatorTitle}导航栏标题
///{navigatorTitleWidget}导航栏自定义widget
///{navigatorTiTleStyle}导航栏标题样式
///{navigatorColor}导航栏颜色
///{backgroundColor}容器颜色
///{backIconColor}返回按钮颜色
///{navigatorBackWidget}自定义返回按钮widget
///{navigatorActionWidget}导航栏右侧菜单栏
///{scaffoldBottomNavigationBar}底部tab菜单
///{body}主视图
///{isTitleCenter}标题是否中间显示
///{isAppBar}是否显示导航栏
///{isNavigatorTopPadding}导航栏顶部间距
///{isResizeToAvoidBottomInset}是否自动调整
///{isExtendBodyBehindAppBar}是否将主视图延伸到顶部导航栏
///{navigatorBackWidgetWidth}返回按钮widget宽度
///{navigatorBackPressed}返回按钮事件
///{endDrawer}左边抽屉视图
///{endDrawerKey}左边抽屉视图绑定的标识
///{extendBody}底部导航延伸
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.navigatorTitle,
    this.navigatorTitleWidget,
    this.navigatorTiTleStyle,
    this.navigatorColor,
    this.backgroundColor,
    this.backIconColor,
    this.navigatorBackWidget,
    this.navigatorActionWidget,
    this.scaffoldBottomNavigationBar,
    required this.body,
    this.isTitleCenter,
    this.isAppBar,
    this.isNavigatorTopPadding,
    this.isResizeToAvoidBottomInset,
    this.isExtendBodyBehindAppBar,
    this.navigatorBackWidgetWidth,
    this.navigatorBackIconPath,
    this.navigatorBackPressed,
    this.endDrawer,
    this.endDrawerKey,
    this.extendBody,
    this.isShowBottomBorder,
  });
  final String? navigatorTitle;
  final Widget? navigatorTitleWidget;
  final TextStyle? navigatorTiTleStyle;
  final Color? navigatorColor;
  final Color? backgroundColor;
  final Color? backIconColor;
  final bool? isTitleCenter;
  final bool? isAppBar;
  final bool? isNavigatorTopPadding;
  final bool? isResizeToAvoidBottomInset;
  final bool? isExtendBodyBehindAppBar;
  final Widget? navigatorBackWidget;
  final double? navigatorBackWidgetWidth;
  final String? navigatorBackIconPath;
  final VoidCallback? navigatorBackPressed;
  final List<Widget>? navigatorActionWidget;
  final Widget? scaffoldBottomNavigationBar;
  final Widget? endDrawer;
  final GlobalKey? endDrawerKey;
  final Widget body;
  final bool? extendBody;
  final bool? isShowBottomBorder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: endDrawerKey,
      extendBody: extendBody ?? false,
      endDrawer: endDrawer,
      extendBodyBehindAppBar: isExtendBodyBehindAppBar ?? false,
      resizeToAvoidBottomInset: isResizeToAvoidBottomInset,
      appBar: isAppBar ?? true
          ? AppBar(
              title:
                  navigatorTitleWidget ??
                  Text(
                    navigatorTitle ?? '',
                    style:
                        navigatorTiTleStyle ??
                        TextStyle(fontSize: 16.sp, color: Colors.black87),
                  ),
              backgroundColor: isExtendBodyBehindAppBar ?? false
                  ? Colors.transparent
                  : navigatorColor ?? const Color(0xFFF7F7F7),

              centerTitle: isTitleCenter ?? true,
              shadowColor: Colors.red,
              leadingWidth: navigatorBackWidgetWidth,
              elevation: 0,
              scrolledUnderElevation: 0,
              leading:
                  navigatorBackWidget ??
                  // 未提供自定义资源时使用返回按钮，不能让空图片显示错误占位。
                  (navigatorBackIconPath?.isNotEmpty == true
                      ? Center(
                          child: AppTapArea(
                            behavior: HitTestBehavior.opaque,
                            child: AppImage(
                              src: navigatorBackIconPath,
                              width: 24.r,
                              height: 24.r,
                              iconColor: backIconColor,
                            ),
                            onTap: () {
                              if (navigatorBackPressed != null) {
                                navigatorBackPressed!();
                                return;
                              }
                              Navigator.maybePop(context);
                            },
                          ),
                        )
                      : BackButton(
                          color: backIconColor ?? Colors.black87,
                          onPressed: navigatorBackPressed,
                        )),
              actions: navigatorActionWidget,
              bottom: isShowBottomBorder ?? false
                  ? PreferredSize(
                      preferredSize: const Size.fromHeight(1),
                      child: Container(
                        height: 1,
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFFEEEEEE),
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    )
                  : null,
              // systemOverlayStyle: const SystemUiOverlayStyle(
              //   statusBarColor: Colors.transparent,
              //   statusBarIconBrightness: Brightness.light,
              //   systemNavigationBarColor: Colors.black, //导航栏颜色
              //   systemNavigationBarIconBrightness: Brightness.light, //导航栏图标颜色
              //   systemNavigationBarDividerColor:
              //       Colors.transparent, //系统导航栏分隔线颜色
              //   systemNavigationBarContrastEnforced: true, //系统导航栏对比度强制
              // ),
            )
          : null,
      body: Container(
        width: double.maxFinite,
        height: double.maxFinite,
        color: backgroundColor,
        padding: EdgeInsets.only(
          top: isNavigatorTopPadding ?? false
              ? MediaQueryData.fromView(View.of(context)).padding.top
              : 0,
        ),
        child: body,
      ),
      bottomNavigationBar: scaffoldBottomNavigationBar,
    );
  }
}

///局部刷新widget
notifierWidget<T>({
  required Widget Function(T value)? builder,
  required ValueNotifier<T>? notifier,
}) {
  return ValueListenableBuilder<dynamic>(
    builder: (BuildContext context, dynamic value, Widget? child) {
      if (builder != null) {
        return builder(value);
      }
      return Container();
    },
    valueListenable: notifier ?? ValueNotifier<dynamic>(null),
  );
}

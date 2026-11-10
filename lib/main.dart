import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'app/bootstrap/application_bootstrapper.dart';
import 'app/config/app_globals.dart';
import 'app/config/application_config.dart';
import 'app/navigation/app_navigator.dart';
import 'app/navigation/app_router.dart';
import 'app/theme/app_theme.dart';
import 'shared/widgets/feedback/network_status_banner.dart';

Future<void> main() async {
  await ApplicationBootstrapper.instance.bootstrap();
}

class Application extends ConsumerWidget {
  const Application({
    super.key,
    required this.startPage,
    this.showNetworkStatus = false,
  });

  final Widget startPage;
  final bool showNetworkStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScreenUtilInit(
      designSize: MediaQuery.sizeOf(context).shortestSide > 600
          ? const Size(1112, 710)
          : const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      rebuildFactor: RebuildFactors.size,
      builder: (context, child) {
        return MaterialApp(
          ///这里是路由跳转页面配置，如果不需要路由跳转，则不需要配置
          //initialRoute: RouteNames.example,

          ///这里是路由跳转页面配置，如果不需要路由跳转，则不需要配置
          onGenerateRoute: AppRouter.onGenerateRoute,
          title: ApplicationConfig.appName,
          navigatorKey: globalKeyNavigatorKey,
          navigatorObservers: [RouteObserverService()],
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          debugShowCheckedModeBanner: false,
          builder: EasyLoading.init(
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1)),
                child: Stack(
                  children: [
                    child ?? const SizedBox.shrink(),
                    if (showNetworkStatus)
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: NetworkStatusBanner(),
                      ),
                  ],
                ),
              );
            },
          ),

          ///这里是首页配置，如果不需要首页，则不需要配置，比如登录页，引导页等，路由跳转方式需要注释掉
          home: RefreshConfiguration(
            enableLoadingWhenNoData: false,
            child: startPage,
          ),
        );
      },
    );
  }
}

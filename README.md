# Class Reference

本章节说明项目中主要类、枚举、Provider 的职责，避免后续开发时不知道类的用途。

---

## App Layer Classes

| Class / File | 作用 |

| ------------------------- | ----------------------------------------------------------------------------------------------------------- |

| `Application` | App 根组件，负责挂载 `MaterialApp`、主题、路由等应用级配置。 |

| `ApplicationBootstrapper` | 应用启动引导器，负责统一执行启动前初始化任务。 |

| `ApplicationInitTask` | 启动任务模型，用于描述一个初始化任务。 |

| `ApplicationInitializer` | 初始化任务执行器，负责按顺序执行多个启动任务。 |

| `BootstrapContext` | 启动上下文，用于在初始化阶段传递全局依赖或配置。 |

| `runAppHandle` | App 启动封装函数，用于统一处理异常、初始化和运行 App。 |

| `ApplicationConfig` | 应用配置类，统一管理 App 名称、接口地址、环境配置等。 |

| `AppEnvironment` | 应用环境枚举，区分 `development`、`staging`、`production`。 |

| `globalKeyNavigatorKey` | 全局导航 Key，用于在非 Widget 场景下执行页面跳转。 |

| `PageScope` | 页面级依赖作用域，用于在页面树中传递页面状态或依赖。 |

| `AppNavigator` | 应用导航管理器，统一封装页面跳转、返回、替换等导航操作。 |

| `AppRouter` | 应用导航管理路由 |

| `AppPageRoute` | 自定义页面路由，统一页面切换动画和路由行为。 |

| `RouteObserverService` | 路由监听服务，用于监听页面进入、退出、切换等生命周期。 |

| `RouteNames` | 路由名称常量类，统一管理页面路由字符串。 |

| `AppTheme` | 应用主题类，统一管理亮色主题、暗色主题、颜色和字体样式。 |

| `EnvConfig` | 运行环境参数读取类，统一读取 `dart-define` / `dart-define-from-file` 传入的环境、API 地址、调试开关等配置。 |

---

## Core / Device Classes

| Class | 作用 |

| ------------------- | ---------------------------------------------------------------- |

| `DeviceInfoService` | 设备信息服务，统一获取设备型号、系统版本、App 版本、包名等信息。 |

---

## Core / Network Classes

| Class / File | 作用 |

| ------------------------- | --------------------------------------------------------------- |

| `DioClientHolder` | Dio 实例持有器，负责创建、配置、缓存和复用 Dio 实例。 |

| `HttpClient` | 网络请求客户端，统一封装 GET、POST、PUT、DELETE 等请求。 |

| `NetworkMonitor` | 网络状态监听器，用于监听当前设备是否联网。 |

| `Reachability` | 网络可达状态枚举，包含 `unknown`、`online`、`offline`。 |

| `NetworkState` | 网络状态模型，用于描述当前网络连接状态。 |

| `ResponseErrorHandler` | HTTP 响应错误处理器，统一处理接口错误、状态码异常等问题。 |

| `RequestHeaders` | 请求头管理类，统一生成 Token、语言、版本号、设备信息等 Header。 |

| `RequestMethod` | 请求方法枚举，包含 GET、POST、PUT、DELETE、HEAD、UPLOAD。 |

| `request` | 通用请求方法，用于根据请求参数统一发起网络请求。 |

| `OfflineQueueInterceptor` | 离线请求拦截器，当网络不可用时拦截请求并加入离线队列。 |

| `OfflineQueueManager` | 离线队列管理器，负责请求入队、重试、清理和恢复发送。 |

| `OfflineQueueState` | 离线队列状态模型，用于描述队列数量、处理中状态等信息。 |

| `OfflineQueueStorage` | 离线队列本地存储服务，负责把离线请求保存到本地。 |

| `OfflineRequest` | 离线请求模型，保存请求地址、参数、Header、请求方法等信息。 |

| `QueuePriority` | 离线请求优先级枚举，区分高、中、低优先级。 |

| `QueueCategory` | 离线请求分类枚举，例如用户操作、同步、统计、日志等。 |

| `IdempotencyKeyGenerator` | 幂等 Key 生成器，用于生成唯一请求标识，避免重复提交。 |

---

## Core / Network Providers

| Provider | 作用 |

| ----------------------------- | ----------------------------------------------- |

| `dioProvider` | Riverpod Provider，用于全局提供 Dio 实例。 |

| `dioInterceptorsProvider` | Riverpod Provider，用于注册 Dio 拦截器。 |

| `networkMonitorProvider` | Riverpod Provider，用于提供网络监听服务。 |

| `networkStateProvider` | Riverpod StreamProvider，用于监听网络状态变化。 |

| `offlineQueueManagerProvider` | Riverpod Provider，用于提供离线队列管理器。 |

| `offlineQueueStateProvider` | Riverpod StreamProvider，用于监听离线队列状态。 |

| `offlineQueueStorageProvider` | Riverpod Provider，用于提供离线队列存储服务。 |

---

## Core / Logger Classes

| Class | 作用 |

| ----------- | ------------------------------------------------------------- |

| `AppLogger` | 应用日志工具类，统一输出 Debug、Info、Warning、Error 等日志。 |

> 项目中不要直接使用 `print()` 输出日志，统一使用 `AppLogger`，方便后续控制 Release 环境日志。

---

## Core / State Classes

| Class / Enum | 作用 |

| ------------------------ | ---------------------------------------------------------- |

| `BaseBloc<Event, State>` | Bloc 基础类，用于统一扩展 Bloc 的公共能力。 |

| `BaseEvent` | Bloc 事件基类，所有 Event 可以继承它，方便统一比较和测试。 |

| `BaseState` | Bloc 状态基类，所有 State 可以继承它，方便统一比较和测试。 |

| `AppProviderObserver` | Riverpod 状态监听器，用于调试 Provider 创建、更新、销毁。 |

---

## Core / Storage Classes

| Class | 作用 |

| -------------------- | -------------------------------------------------- |

| `PreferencesService` | SharedPreferences 封装服务，统一处理本地数据读写。 |

| `StorageKeys` | 本地存储 Key 常量类，避免字符串 Key 散落在项目中。 |

---

## Core / Utils Classes

| Class | 作用 |

| ------------------ | -------------------------------------------------------------------------- |

| `InputValidator` | 输入校验工具类，用于校验手机号、邮箱、密码、非空等规则。 |

| `ScreenResponsive` | 响应式尺寸适配工具，根据设计稿宽度自动计算缩放比例，统一适配不同屏幕尺寸。 |

---

# Core / Permission

Permission 模块统一管理应用中的权限申请、权限检测、平台适配以及权限状态记录。

整体设计目标：

- 不直接依赖 `permission_handler`

- 业务层只关心业务权限，不关心 Android / iOS 差异

- Android 不同版本自动适配

- 所有权限申请统一入口

- 支持首次申请记录

- 支持跳转系统设置

目录结构：

```text

core/

└── permission/

├── enum\_permission.dart

├── permission\_request.dart

├── permission\_resolver.dart

├── permission\_handler.dart

└── permission\_request\_record.dart

```

---

## Classes

| Class | 作用 |

| ------------------------- | ---------------------------------------------------- |

| `PermissionRequest` | 权限枚举，业务层统一使用的权限类型。 |

| `PermissionType` | 权限分类枚举，用于描述支持的权限类型。 |

| `PermissionResolver` | 权限解析器，根据平台和系统版本解析真实权限。 |

| `PermissionHandler` | 权限统一管理器，负责申请、检测、跳转系统设置等能力。 |

| `PermissionRequestRecord` | 权限申请记录管理器，用于记录用户是否申请过某项权限。 |

---

## PermissionRequest

业务层不要直接使用 `Permission`。

统一使用：

```dart

PermissionRequest.camera

PermissionRequest.microphone

PermissionRequest.bluetooth

PermissionRequest.wifi

PermissionRequest.photos

```

这样可以避免：

- Android 权限变化

- iOS 权限差异

- Android 13+

- Android 12+

- 后续系统升级导致业务代码修改

---

## PermissionResolver

PermissionResolver 专门负责：

根据不同平台解析真实权限。

例如：

Wi-Fi：

```text

Android

↓

Location

```

蓝牙：

```text

Android 12+

↓

Bluetooth Scan

Bluetooth Connect

```

Android 11 以下：

```text

Bluetooth

```

相册：

```text

Android 13+

↓

Photos

Android 12-

↓

Storage

```

业务层永远不知道这些差异。

---

## PermissionHandler

统一负责：

- 检查权限

- 申请权限

- 多权限申请

- 权限弹窗

- 跳转系统设置

- 判断权限状态

例如：

申请相机权限：

```dart

final granted =

await PermissionHandler.instance.requestPermissionByType(

PermissionRequest.camera,

);

```

申请多个权限：

```dart

await PermissionHandler.instance.requestPermissionsByType([

PermissionRequest.camera,

PermissionRequest.microphone,

]);

```

检查权限：

```dart

final hasPermission =

await PermissionHandler.instance.checkPermissionByType(

PermissionRequest.bluetooth,

);

```

---

## PermissionRequestRecord

用于记录：

> 用户是否已经申请过某个权限。

例如：

```dart

await PermissionRequestRecord.instance.markRequested(

PermissionRequest.camera);

```

判断：

```dart

final requested =

await PermissionRequestRecord.instance.hasRequested(

    PermissionRequest.camera);

```

适用于：

- 首次授权引导

- 不再重复弹说明页

- 权限教育页

- 首次启动流程

---

## Shared / Form Classes

| Class | 作用 |

| -------------------- | ---------------------------------------------------------------- |

| `FormViewState` | 表单整体状态模型，用于描述表单是否加载、是否可提交、错误信息等。 |

| `FormFieldViewState` | 单个表单字段状态模型，用于描述字段值、错误信息、是否必填等。 |

| `AppForm` | 应用统一表单容器，用于统一表单布局和提交逻辑。 |

| `AppTextField` | 应用统一输入框组件，封装输入、校验、错误提示、样式等能力。 |

| `_AppTextFieldState` | `AppTextField` 的内部状态类，负责维护输入框状态。 |

---

## Shared / Feedback Classes

| Class | 作用 |

| --------------------- | --------------------------------------------------------------- |

| `AppToast` | Toast 提示工具类，统一显示成功、失败、警告、普通提示。 |

| `_ToastWidget` | Toast 内部 UI 组件，负责 Toast 的实际展示样式。 |

| `LoadingOverlay` | 全局 Loading 浮层工具，用于接口请求、页面加载、文件上传等场景。 |

| `NetworkStatusBanner` | 网络状态提示条，当网络断开或恢复时显示提示。 |

| `_OfflineBanner` | 离线状态提示条内部组件。 |

---

## Shared / Gesture Classes

| Class | 作用 |

| ------------------ | -------------------------------------------------- |

| `AppTapArea` | 通用点击区域组件，封装点击、防抖、触摸反馈等能力。 |

| `_AppTapAreaState` | `AppTapArea` 的内部状态类，负责处理点击状态。 |

---

## Shared / Image Classes

| Class / Enum | 作用 |

| --------------------------- | ---------------------------------------------------------------- |

| `AppCachedImage` | 网络缓存图片组件，封装图片加载、缓存、占位图、错误图。 |

| `AdvancedImageCacheManager` | 图片缓存管理器，负责管理网络图片缓存策略。 |

| `AppImage` | 应用统一图片组件，支持资源图片、网络图片、Base64、文件图片等。 |

| `_ImageType` | 图片类型枚举，用于区分 asset、network、base64、file 等图片来源。 |

| `_AppImageState` | `AppImage` 的内部状态类，负责判断图片类型并渲染。 |

---

## Shared / Layout Classes

| Class | 作用 |

| ------------- | ----------------------------------------------------------------- |

| `AppScaffold` | 应用统一页面骨架，封装 Scaffold、AppBar、Body、背景色等通用结构。 |

---

## Shared / Page Classes

| Class | 作用 |

| `BaseRiverpodPage<S, VM extends StateNotifier<S>>` | Riverpod 页面基类，负责绑定 Provider 与 ViewModel，统一页面结构、生命周期管理和状态管理入口。 |

| `BaseRiverpodState<T, S, VM extends StateNotifier<S>>` | Riverpod 页面状态基类，负责页面初始化、Provider 状态读取、ViewModel 获取、页面缓存、导航栏配置以及页面容器构建。 |

| `BaseBlocPage<S, B extends BlocBase<S>>` | Bloc 页面基类，负责创建并注入 Bloc/Cubit，统一页面结构、生命周期管理和状态管理入口。 |

| `BaseBlocState<T, S, B extends BlocBase<S>>` | Bloc 页面状态基类，负责页面初始化、Bloc 获取、状态监听（BlocListener）、状态刷新（BlocBuilder）、页面缓存、导航栏配置以及页面容器构建。 |

---

## Shared / Text Classes

| Class | 作用 |

| --------------- | ---------------------------------------------------------------------- |

| `AppText` | 应用统一文本组件，封装字体大小、颜色、行高、对齐方式等常用 Text 配置。 |

| `_AppTextState` | `AppText` 的内部状态类，负责处理文本组件状态。 |

---

## Feature / Example Classes

| Class | 作用 |

| ------------- | ---------------------------------------------------- |

| `ExamplePage` | 示例页面，用于展示框架的基础页面结构和组件使用方式。 |

---

## Feature / Riverpod Example Classes

| Class / Provider | 作用 |

| ----------------- | ----------------------------------------------------------- |

| `counterProvider` | Riverpod 示例 Provider，用于管理计数器状态。 |

| `CounterNotifier` | 计数器状态控制器，负责增加、减少、重置计数。 |

| `CounterPage` | Riverpod 示例页面，用于展示如何通过 Provider 驱动 UI 刷新。 |

---

## Feature / Bloc Example Classes

| Class | 作用 |

| ------------------------ | -------------------------------------------------------- |

| `OrderEvent` | 订单 Bloc 事件基类，用于描述订单流程中发生的行为。 |

| `CreateOrderRequested` | 创建订单事件，表示用户触发创建订单操作。 |

| `PayOrderRequested` | 支付订单事件，表示用户触发支付操作。 |

| `CompleteOrderRequested` | 完成订单事件，表示订单流程完成。 |

| `OrderStatus` | 订单状态枚举，用于描述订单当前所处阶段。 |

| `OrderState` | 订单状态模型，保存当前订单状态、提示信息、错误信息等。 |

| `OrderBloc` | 订单业务流程控制器，接收事件、处理业务逻辑、输出新状态。 |

| `OrderPage` | Bloc 示例页面，用于展示如何通过 Bloc 管理复杂业务流程。 |

---

# Bloc Example Workflow

Bloc 适合复杂业务流程，例如订单流程。

```text

用户点击创建订单

    ↓

CreateOrderRequested

    ↓

OrderBloc

    ↓

OrderState(status: pendingPayment)

    ↓

UI 刷新为待支付状态

```

支付流程：

```text

用户点击支付

    ↓

PayOrderRequested

    ↓

OrderBloc

    ↓

OrderState(status: paid)

    ↓

UI 刷新为支付成功状态

```

完成流程：

```text

订单完成

    ↓

CompleteOrderRequested

    ↓

OrderBloc

    ↓

OrderState(status: completed)

    ↓

UI 刷新为订单完成状态

```

---

# Riverpod Example Workflow

Riverpod 适合轻量状态，例如计数器、主题、用户信息、接口数据。

```text

用户点击按钮

    ↓

CounterNotifier.increment()

    ↓

counterProvider 状态更新

    ↓

ConsumerWidget 自动刷新 UI

```

---

# ScreenResponsive Usage

`ScreenResponsive` 用于统一管理项目中的尺寸适配，根据设计稿宽度自动计算缩放比例。

## 初始化

```dart

@override

Widget build(BuildContext context) {

ScreenResponsive.init(context);

return const Scaffold(

body: ...

);

}

```

默认设计稿宽度为 **375**。

自定义设计稿：

```dart

ScreenResponsive.init(

context,

designWidth: 390,

);

```

限制缩放范围：

```dart

ScreenResponsive.init(

context,

designWidth: 375,

minScale: 0.85,

maxScale: 1.25,

);

```

## 使用

```dart

Container(

width: 120.adapt,

height: 48.adapt,

padding: EdgeInsets.all(16.adapt),

margin: EdgeInsets.symmetric(horizontal: 20.adapt),

decoration: BoxDecoration(

borderRadius: BorderRadius.circular(12.adapt),

),

child: Text(

'Hello',

style: TextStyle(

  fontSize: 16.adapt,

),

),

)

```

```dart

Icon(

Icons.home,

size: 24.adapt,

)

```

## Best Practice

统一使用 `.adapt` 进行尺寸适配：

- width

- height

- padding

- margin

- fontSize

- borderRadius

- iconSize

---

# Class Placement Rules

## 放到 core 的类

满足以下条件时放入 `core`：

- 与 UI 无关

- 与具体业务无关

- 多个模块都需要

- 属于基础设施能力

例如：

```text

HttpClient

PreferencesService

DeviceInfoService

AppLogger

```

---

## 放到 shared 的类

满足以下条件时放入 `shared`：

- 是 UI 组件

- 多个业务页面都会使用

- 不包含具体业务逻辑

例如：

```text

AppText

AppImage

AppTextField

AppToast

LoadingOverlay

```

---

## 放到 features 的类

满足以下条件时放入 `features`：

- 只服务于某个业务模块

- 包含业务状态

- 包含业务页面

- 包含业务流程

例如：

```text

LoginPage

OrderBloc

UserProvider

OrderRepository

```

---

# Important Rule

不要为了“看起来通用”过早把代码放到 `core` 或 `shared`。

推荐原则：

```text

先放 features

真正复用后再抽到 shared 或 core

```

## EnvConfig

`EnvConfig` 用于统一读取通过 Flutter 编译 / 运行命令传入的环境参数。

文件位置：

```text

lib/

└── core/

└── config/

    └── app\_env.dart

```

主要用于管理：

- 当前运行环境

- API 地址

- WebSocket 地址

- 日志开关

- UME 调试工具开关

- MQTT 等第三方服务地址

- 其他需要根据运行环境切换的配置

示例：

```dart

class EnvConfig {

EnvConfig._();

/// 当前环境

static const String env = String.fromEnvironment(

'ENV',

defaultValue: 'dev',

);

/// 是否启用 UME

static const bool enableUme = bool.fromEnvironment(

'ENABLE\_UME',

defaultValue: false,

);

/// 是否启用日志

static const bool enableLog = bool.fromEnvironment(

'ENABLE\_LOG',

defaultValue: false,

);

/// API 地址

static const String apiBaseUrl = String.fromEnvironment(

'API\_BASE\_URL',

defaultValue: '',

);

/// WebSocket 地址

static const String wsUrl = String.fromEnvironment(

'WS\_URL',

defaultValue: '',

);

/// 是否开发环境

static bool get isDev => env == 'dev';

/// 是否测试环境

static bool get isTest => env == 'test';

/// 是否生产环境

static bool get isProd => env == 'prod';

}

```

---

### 环境配置文件

推荐在项目根目录创建：

```text

env/

├── dev.json

├── test.json

└── prod.json

```

开发环境：

```json
{
  "ENV": "dev",

  "ENABLE_UME": true,

  "ENABLE_LOG": true,

  "API_BASE_URL": "https://dev-api.example.com",

  "WS_URL": "wss://dev-ws.example.com"
}
```

生产环境：

```json
{
  "ENV": "prod",

  "ENABLE_UME": false,

  "ENABLE_LOG": false,

  "API_BASE_URL": "https://api.example.com",

  "WS_URL": "wss://ws.example.com"
}
```

---

### 运行方式

开发环境：

```bash

flutter run --dart-define-from-file=env/dev.json

```

测试环境：

```bash

flutter run --dart-define-from-file=env/test.json

```

生产环境：

```bash

flutter run --dart-define-from-file=env/prod.json

```

也可以单独传入参数：

```bash

flutter run --dart-define=ENABLE_UME=true

```

或者在环境文件基础上临时覆盖某个配置：

```bash

flutter run \

--dart-define-from-file=env/dev.json \

--dart-define=ENABLE_UME=false

```

---

### UME 使用

`runAppHandle` 根据 `EnvConfig.enableUme` 决定是否注册并挂载 `UMEWidget`。

```dart

if (EnvConfig.enableUme) {

PluginManager.instance

..register(const ShowCode())

..register(const DeviceInfoPanel())

..register(const MemoryInfoPage())

..register(CpuInfoPage())

..register(Console())

..register(Performance())

..register(

  DioInspector(

    dio: DioClientHolder.instance.dio,

  ),

);

app = UMEWidget(

icon: const FlutterLogo(),

enable: true,

child: app,

);

}

```

这样：

```text

dev

↓

ENABLE_UME = true

↓

启用 UME

```

生产环境：

```text

prod

↓

ENABLE_UME = false

↓

不创建 UMEWidget

```

---

### EnvConfig 与 ApplicationConfig 的区别

两者职责不要混在一起。

```text

EnvConfig

↓

读取编译 / 运行时传入的环境变量

ApplicationConfig

↓

组织应用最终实际使用的配置

```

例如：

```text

--dart-define

    ↓

 EnvConfig

    ↓

ApplicationConfig

    ↓

Network / WebSocket / Logger / App

```

`EnvConfig` 更接近底层环境变量读取器。

`ApplicationConfig` 则用于把这些配置进一步整理成应用可以直接使用的配置对象。

---

### Best Practice

业务代码不要大量直接使用：

```dart

String.fromEnvironment(...)

```

统一通过：

```dart

EnvConfig.xxx

```

读取。

例如：

```dart

EnvConfig.apiBaseUrl

EnvConfig.wsUrl

EnvConfig.enableLog

EnvConfig.enableUme

```

这样后续增加、修改环境参数时，只需要维护 `EnvConfig`。

同时不要在环境配置文件中保存真正的安全密钥。

例如以下内容不能因为使用了 `dart-define` 就认为是安全的：

```text

数据库密码

服务器私钥

支付平台 Secret Key

后端永久 Token

```

Flutter 客户端最终仍然会把相关配置编译进应用，因此客户端只应该保存允许暴露给客户端的配置。

Framework 版本与下游项目同步规则

flutter_app_framework 作为通用 Flutter 基础架构，负责维护可复用的基础能力，并允许后续基于该框架创建的项目按需同步 Framework 升级。

推荐关系：

flutter_app_framework
↓
下游项目

其中：

flutter_app_framework：基础架构仓库，只维护通用能力。

下游项目：基于 Framework 创建的具体应用项目。

下游项目通过 Git upstream 方式同步 Framework 后续升级。

Framework 升级不会自动修改下游项目，由下游项目主动选择同步时机和目标版本。

Git Remote 约定

在基于 Framework 创建的项目中，建议配置：

origin
↓
当前项目自己的 Git 仓库

upstream
↓
flutter_app_framework 基础架构仓库

首次配置：

git remote add upstream <flutter_app_framework 仓库地址>

查看：

git remote -v

正常情况下应同时存在：

origin
upstream

Framework 版本管理

flutter_app_framework 每次完成一批稳定升级后，应提交代码并创建 Git Tag。

例如：

v1.0.0
↓
v1.1.0
↓
v1.2.0

示例：

git add .
git commit -m "feat: improve framework"

git tag v1.2.0

git push origin main
git push origin v1.2.0

下游项目同步时，优先同步指定 Tag，而不是长期直接追踪 upstream/main。

推荐：

git fetch upstream --tags
git merge v1.2.0

这样可以明确知道当前项目使用的是哪个 Framework 版本。

FRAMEWORK_VERSION

建议每个基于 Framework 创建的项目，在项目根目录增加：

FRAMEWORK_VERSION

内容只记录当前同步的 Framework 版本：

v1.2.0

例如：

project/
├── FRAMEWORK_VERSION
├── lib/
├── android/
├── ios/
└── pubspec.yaml

当项目从：

v1.2.0

升级到：

v1.3.0

同步完成并测试通过后，同时更新：

FRAMEWORK_VERSION

避免后续无法确认当前项目基于哪个 Framework 版本。

Framework 同步分支

不要直接在下游项目的 main 分支执行 Framework 合并。

每次 Framework 升级都创建独立同步分支。

例如同步：

v1.2.0

先进入当前项目：

git checkout main
git pull origin main

创建同步分支：

git checkout -b sync/framework-v1.2.0

获取 Framework：

git fetch upstream --tags

合并指定版本：

git merge v1.2.0

此时所有：

Framework 文件变化

Git 冲突

兼容性修改

项目适配

都只发生在：

sync/framework-v1.2.0

不会直接影响当前项目正式 main 分支。

同步后的验证流程

Framework 合并完成后必须执行：

flutter pub get
flutter analyze
flutter test
flutter run

确认：

依赖安装正常

无静态分析错误

自动化测试通过

App 可以正常启动

关键功能正常

Framework 新能力工作正常

全部确认后，再合并到当前项目 main：

git checkout main

git merge sync/framework-v1.2.0

git push origin main

同步完成后可删除本地同步分支：

git branch -d sync/framework-v1.2.0

Framework 与项目代码边界

为了减少后续同步冲突，需要严格区分 Framework 代码和项目自身代码。

Framework 负责

以下类型代码原则上由 flutter_app_framework 维护：

core/
├── config/
├── device/
├── logger/
├── network/
├── permission/
├── storage/
└── utils/

shared/
├── feedback/
├── form/
├── gesture/
├── image/
├── layout/
├── page/
└── text/

例如：

EnvConfig
AppLogger
HttpClient
NetworkMonitor
PreferencesService
PermissionHandler
AppText
AppImage
AppToast
AppScaffold
BaseRiverpodPage
BaseBlocPage

如果下游项目发现这些通用能力需要修改，原则上应优先回到：

flutter_app_framework

修改。

流程：

发现 Framework 通用能力需要修改
↓
修改 flutter_app_framework
↓
测试
↓
提交并发布新版本 Tag
↓
下游项目按需同步

不要只在某个下游项目中长期维护 Framework 的不同版本。

下游项目负责

只和具体项目相关的功能，应只存在于当前项目中。

例如：

features/
├── auth/
├── home/
├── profile/
├── order/
└── ...

包括：

业务页面

业务状态

业务流程

项目特有协议

项目特有设备能力

项目特有服务接入

这些代码不应该反向加入 flutter_app_framework，除非后续确认具备真正的通用复用价值。

目录修改原则

不同目录的维护优先级：

lib/

app/
↑ Framework 与下游项目都可能修改
↑ 同步时重点检查冲突

core/
↑ Framework 优先维护

shared/
↑ Framework 优先维护

features/
↑ 下游项目自行维护

其中 app/ 最容易发生冲突，例如：

app.dart
bootstrap/
config/
di/
navigation/
theme/

下游项目修改这些文件时，应尽量避免破坏 Framework 原有通用结构。

Framework CHANGELOG

建议 flutter_app_framework 维护：

CHANGELOG.md

每个 Framework 版本记录：

Added

Changed

Fixed

Removed

Breaking Changes

例如：

# v1.2.0

## Added

- EnvConfig 环境参数配置
- dart-define-from-file 支持

## Changed

- AppLogger 根据环境控制日志等级
- runAppHandle 支持 ENABLE_UME

## Removed

- 已废弃的环境配置代码

下游项目同步前先查看对应版本的 CHANGELOG，确认：

修改了哪些模块

是否存在破坏性变更

是否需要额外适配

哪些文件可能产生冲突

标准同步流程

Framework 每次升级统一按照以下流程执行：

1. 修改 flutter_app_framework

2. Framework 测试通过

3. 提交 Framework

4. 创建版本 Tag
   ↓
   v1.2.0

5. 下游项目更新 main

6. 创建同步分支
   ↓
   sync/framework-v1.2.0

7. fetch upstream Tags

8. merge Framework 指定版本

9. 处理 Git 冲突

10. flutter pub get

11. flutter analyze

12. flutter test

13. flutter run

14. 验证项目功能

15. 更新 FRAMEWORK_VERSION

16. 合并同步分支到 main

17. push origin main

Important Rule

Framework 与下游项目之间遵循：

通用能力
↓
回 flutter_app_framework 修改

项目专属能力
↓
在当前项目修改

不要形成：

flutter_app_framework
AppLogger A

项目 A
AppLogger B

项目 B
AppLogger C

否则 Framework 后续升级会产生越来越多冲突。

目标应保持为：

                flutter_app_framework
                        ↓
             统一维护通用基础能力
                 ↙              ↘
              项目 A            项目 B
                ↓                 ↓
          维护自身业务        维护自身业务

推荐同步原则

最终遵循以下四条：

Framework 升级必须有版本
下游项目升级必须走同步分支
通用修改优先回 Framework
同步完成必须测试后才能进入 main

这样可以继续保持“通用基础框架 + 多项目复用”的开发方式，同时最大限度减少 Framework 后续升级造成的代码混乱。

## 微撩 Tab 与 Mock 数据

2026-11-10：初始化样本改用「应用数据-11:9」中的工作簿与配套172张图片，包含20位用户、24条活动、20条动态和60个兴趣/标签。用户相册、活动多图及字段映射见[初始化数据导入](docs/data/initial-data.md)。已有手机账号快照不自动覆盖，首次创建的快照使用新样本。

底栏由 `MainTabShell` 管理。广场、消息和我的分别位于
`lib/features/square`、`lib/features/messages`、`lib/features/user`。
各模块通过 Riverpod 注入 Mock 仓库，个人中心由 `UserBloc` 管理资料和账号状态。业务样本位于 `assets/mock/`，仓库通过异步接口解析 JSON 并返回项目 Model。首页、活动目录与兴趣标签从打包 JSON 读取。个人资料、反馈、动态和互动、消息和黑名单、邀约及示例状态会写入应用支持目录下的 `mock/`，重启时从该目录恢复。

样本来自《搭子App模拟数据》的用户、活动、动态与兴趣标签工作表，图片引用指向 `assets/mock/media/`。演示账号选用 U001，首页搭子列表排除当前账号。表格中的活动时间是发布时间，已按原字段语义显示。表格没有聊天、报名与履约记录，聊天与信誉沿用设计样例，参加列表由明确的报名记录决定。

| 页面 | Figma 节点 | Flutter 入口与复用 |
| --- | --- | --- |
| 广场 | `3048:18424`、`3163:24193`、`3168:8861` | `SquarePage`、`SquarePublishPage`。动态卡片也用于我的动态，视频使用本地封面演示。 |
| 消息 | `3157:21069`、`3178:2029` | `MessagesPage`、`ChatPage`。顶部为消息标题和三个消息分类入口。聊天支持分组消息、示例图片预览与发送及活动邀约卡片，拉黑状态同步到设置。 |
| 我的 | `3122:20484`、`3160:21545`、`3163:29611`、`3162:6037` 等 | `ProfilePage`、`ProfileEditPage`、`ProfileSettingsPage`。个人中心首页包含账号概览、我的组队和功能列表。 |

新增页面复用 `CompanionPageSurface` 的氛围背景、`AppScaffold` 的子页导航和 `CompanionCardSurfaceWidget` 的卡片容器。

活动详情由首页活动、个人组队、有活动关联的广场动态和聊天邀约统一进入。入口传递活动 ID，详情从 `assets/mock/home/catalog.json` 查询。模拟报名与关注写入应用支持目录的 `mock/activity/participation.json`，报名后可在「我参加的」查看。目录中的时间字段显示为发布时间，活动配图仅在目录提供对应图片时展示。

用户详情可从首页和找搭子列表、活动发布人及关联用户 ID 的动态头像进入。资料读取本地用户目录，活动与动态复用原模块的数据和交互。用户详情与活动详情共用本地关注记录。


业务分层及跨模块入口见 [页面结构与模块职责](docs/ui-structure/index.md)。页面通过 Provider 使用 Repository 或 Server 契约，磁盘 Mock 实现、业务模型、枚举及请求参数分别归入对应的数据层子目录。活动邀约由活动模块维护，个人中心的动态和黑名单入口分别打开广场和消息模块的页面。


## 本地认证演示

启动先恢复持久化会话。全新安装显示手机号验证码登录，点击获取后使用演示验证码 `8888`（不会发送真实短信）。新手机号自动建号，须设置头像、性别、昵称和生日；同账号再登录无需重复填写，注册性别不可修改。已有磁盘 U001 快照迁移到演示手机号 `13800138000`，打包样本不会自动登录。

账号注册表/会话位于应用支持目录 `mock/auth/`，私有资料、消息、动态互动、关注报名、邀约和举报位于 `mock/accounts/<账号ID>/`。退出保留记录，注销清理私有记录及关联本地发布，并禁止旧身份恢复；同手机号再次注册产生新ID。完整状态与设计来源见 `docs/ui-structure/auth.md`。


启动页按新版Figma3262:33636实现，并行恢复会话后分流。新注册ID采用8位数字，旧local内部ID兼容保留且界面显示短businessId。预置账号手机号17000000888：点击获取验证码后输入8888，资料已完成且私有业务初始为空；既有安装也会幂等补齐。

用户协议/隐私政策通过应用内WebView打开；当前按要求均指向百度占位。后续分别修改lib/app/config/legal_links.dart的userAgreementUrl/privacyPolicyUrl即可。

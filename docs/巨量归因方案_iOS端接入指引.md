# 巨量归因方案接入指引（iOS端）

> 本文档为巨量引擎转化SDK（巨量归因方案）的**iOS端**完整接入指引。
> 
> ⚠️ 请注意以下流程为【**巨量引擎归因方案**】，非【融合归因方案】。

---

## 一、客户端接入

广告主接入SDK后，需要在APP隐私政策中加上SDK的隐私协议进行披露。

> ⚠️ **iOS**：SDK会采集IDFA、IDFV和其他的设备特征字段，请遵循相关合规要求在隐私弹窗后采集。
> 
> 由于SDK可能需要采集IDFA（由宿主APP通过SDK的开关控制），请广告主 App Store 上架申请时表明需要获取IDFA权限，以免影响审核。

---

### 1.1 SDK集成

巨量引擎转化SDK支持 **Pod 方式**接入，只需配置 Pod 环境，在 `Podfile` 文件中加入以下代码即可接入成功：

```ruby
pod 'BDASignalSDK'
pod 'Protobuf'
```

除此以外，SDK也支持通过**静态库**方式接入，以下是静态库代码包：
- `libBDASignalSDK.zip`（719.80KB）
- iOS隐私合规 manifest 文件：`PrivacyInfo.xcprivacy`（941B）

---

### 1.2 SDK使用方式（必要）

#### 启动事件上报

需要在以下方法添加转化SDK相关代码，当本app启动时，将相关启动参数传递给巨量引擎转化SDK，用于上报启动事件。并在此时机，注入转化SDK所需要的可选参数。

**如使用 AppDelegate：**

```objc
#import "BDASignalManager.h"
#import "BDASignalDefinitions.h"

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // 注册可选参数
    [BDASignalManager registerWithOptionalData:@{
        kBDADSignalSDKUserUniqueId : @"3y48693232" // 业务用户id，非必传
    }];
    // 上报冷启动事件
    [BDASignalManager didFinishLaunchingWithOptions:launchOptions connectOptions:nil];
    return YES;
}
```

**如使用 SceneDelegate：**

```objc
#import "BDASignalManager.h"
#import "BDASignalDefinitions.h"

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    // 注册可选参数
    [BDASignalManager registerWithOptionalData:@{
        kBDADSignalSDKUserUniqueId : @"3y48693232" // 业务用户id，非必传
    }];
    // 上报冷启事件
    [BDASignalManager didFinishLaunchingWithOptions:nil connectOptions:connectionOptions];
}
```

> 需要注意的是，以上两种方式根据接入工程时机情况选择对应方案即可。两种方案透传给SDK的数据结构不同：AppDelegate 方案需要传 `launchOptions`，SceneDelegate 方案需要传 `connectionOptions`。

---

#### 其他事件上报

当前SDK内置了转化目标类事件定义，同时也支持自定义事件（APP内用户行为事件）上报。如果线上预期使用巨量归因结果（转化SDK），务必保证投放目标的事件有上报。

**标准事件定义：**

| 事件 | 含义 |
|---|---|
| `stay_time` | 停留时长 |
| `register` | 注册 |
| `purchase` | 付费 |
| `game_addiction` | 关键行为 |
| 自定义事件（事件名自定义） | 自定义事件 |

```objc
FOUNDATION_EXTERN NSString *_Nonnull const kBDADSignalSDKEventStayTime;
FOUNDATION_EXTERN NSString *_Nonnull const kBDADSignalSDKEventRegister;
FOUNDATION_EXTERN NSString *_Nonnull const kBDADSignalSDKEventPurchase;
FOUNDATION_EXTERN NSString *_Nonnull const kBDADSignalSDKEventGameAddiction;
```

**上报方式：**

```objc
#import "BDASignalManager.h"
#import "BDASignalDefinitions.h"

// 上报注册事件
[BDASignalManager trackEssentialEventWithName:kBDADSignalSDKEventRegister params:@{
}];

// 上报付费事件
[BDASignalManager trackEssentialEventWithName:kBDADSignalSDKEventPurchase params:@{
    @"pay_amount": 2334, // 用户支付金额，单位：分
}];
```

`params` 中覆盖转化相关的属性字段，如付费的金额。字段定义和 API 转化上报一致。

**其他自定义事件上报方式：**

```objc
#import "BDASignalManager.h"
#import "BDASignalDefinitions.h"

// 上报自定义事件
[BDASignalManager trackEssentialEventWithName:@"customLabel" params:@{
    @"param1": @"xxx"
}];
```

---

#### 上报成功验证

日志示例：

```objc
NSURLSession *session = [NSURLSession sharedSession];
__weak typeof(self) weakSelf = self;
NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
    if (error) {
        if ([pbEvent.eventName isEqualToString:@"launch_app"]) {
            // 冷启请求失败需要重试
            [weakSelf requestSignalwithParams:params];
        }
    }
    NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    NSLog(@"采集SDK上报结果，response:%@ message:%@ error:%@", result ?: @"", [result objectForKey:@"message"] ?: @"", error.userInfo ?: @"nil");
}];
[task resume];
```

---

#### 获取 IDFA

SDK内部，IDFA的获取使用了开关来控制。**默认不获取IDFA**，如果需要获取IDFA，可以通过以下方式进行设置。如果开启IDFA获取，请确保对应权限声明。

```objc
[BDASignalManager enableIdfa:YES];
```

---

#### Deeplink clickid 采集

下载完成后，媒体APP会尝试自动吊起安装的APP（用户同意自动吊起后），缩短转化路径。需要在以下方法添加转化SDK相关代码，当通过 deeplink 方式打开本app时，将相关参数传递给巨量引擎转化SDK，转化SDK内部将会进行 clickid 提取以及处理相关归因事件。

**如使用 AppDelegate：**

```objc
#import "BDASignalManager.h"

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    // 将url参数转换成string类型之后，传递给SDK
    NSString *openUrl = url.absoluteString;
    [BDASignalManager anylyseDeeplinkClickidWithOpenUrl:openUrl];
    return YES;
}
```

**如使用 SceneDelegate：**

```objc
#import "BDASignalManager.h"

- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts {
    // 需要从原始参数中，取相关字段传递给SDK
    UIOpenURLContext *context = [URLContexts allObjects].firstObject;
    NSString *openUrl = context.URL.absoluteString;
    [BDASignalManager anylyseDeeplinkClickidWithOpenUrl:openUrl];
}
```

---

#### URL Scheme 注册

URL Scheme 是为方便app之间互相调用而设计的，APP可以注册自己的URL Scheme。为保障后续能通过 deeplink 直接从巨量APP吊起广告主推广的APP，请按照推荐规范配置URL Scheme：

**配置规则**

在 Xcode 中，选择你的工程设置项，选中 "TARGETS" 一栏，在 "Info" 标签栏的 "URL type" 添加 "URL scheme"，输入应用对应的**包名**作为 scheme 头（默认规则）。

配置流程可参考官方文档：https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app#Register-your-URL-scheme

**验证是否配置成功**

在测试设备中安装好推广APP，在备忘录中输入以应用包名为scheme头的直达链接，点击该链接，若成功吊起对应的APP，则URL Scheme配置成功！

例如：假设一个包的包名为 `com.test.example`；
- 配置对应的URL scheme：`com.test.example`
- Deeplink调起的链接：`com.test.example://oceanengine/ads?clickid=__CLICKID__&track_id=__TRACK_ID__`（CLICKID 和 TRACK_ID 宏参数会根据调用场景替换对应的值）

将上述 deeplink 链接复制到备忘录中，点击链接，成功跳转对应的应用。

---

#### 隐私数据获取说明

以下用户数据由巨量引擎数据采集iOS SDK收集：

| 字段 | 字段含义 | 数据示例 |
|---|---|---|
| `idfv` | 供应商标识符 / identifierForVendor | `080006E2-5666-49C1-8786-3FD9FC77DC0A`。是开发者为应用指定的代码，设备上属于该开发者的所有应用都拥有同一个 IDFV。同一台设备上不同开发者的应用 IDFV 值不同 |
| `idfa` | 广告主标识符（Identifier for advertisers） | `41E94323-9AB3-4004-857E-D7690572D699`。每台 iOS 设备独有的字母和数字组合。<br>- iOS 10 及以上，用户如果开启了「限制广告跟踪」，获取的 IDFA 将是一串 0。<br>- iOS 14.5 及以上，默认无法获取 IDFA，必须通过 ATT 才能获取。 |
| `sys_file_time` | 系统更新时间 | `1595214620.383940` |
| `device_name` | 设备名称 | MD5(iPhone)，iOS16以后建议传固定值：`867e57bd062c7169995dc03cc0541c19` |
| `machine` | 设备 machine（device_model） | `iPhone10,3` |
| `model` | Hardware model | `D22AP` |
| `boot_time_in_sec` | 系统启动时间（秒） | `1595643553` |
| `system_version` | 系统版本 | `14.0` |
| `memory` | 物理内存大小 | `3955589120` |
| `disk` | 硬盘大小 | `63900340224` |
| `mnt_id` | 挂载id | `80825948939346695D0D7DD52CB405D11A80344027A07803D5F8410346398776C879BF6BD67627@/dev/disk1s1` |
| `device_init_time` | 设备初始化时间 | `1632467920.301150749` |
| `client_tun` | tun | `fe80::d93e:a3d7:6f3d:965c,fe80::df78:367d:c4dc:23c4,...` |
| `client_anpi` | anpi | `fe80::8c3c:53ff:fe8a:489a` |
| `IPV4` | 公网ipv4 | `1.2.3.4` |
| `IPV6` | 公网ipv6 | `240e:478:5618:b87a:100b:6ecc:bb9a:707a` |
| `UA` | 系统webview user agent | `Mozilla/5.0 (iPhone; CPU iPhone OS 16_4_1 like Mac OS X) AppleWebKit/605.1.15...` |
| `package_name` | 应用包名 | |
| `app_version` | 应用版本 | |
| `local_time` | 本地时间 | |

**可选参数：**

| 其他参数 | 说明 |
|---|---|
| `params` | 自定义参数 |
| `user_unique_id` | 用户唯一id |

---

### 1.5 SDK其他能力（可选）

#### 延时上报

为了兼容不同应用隐私协议初始化逻辑的不同，SDK支持了延时上报的能力。用户可以调用以下方法进行开启，开启后，需调用开始方法，SDK才会进行采集数据上报。

```objc
// 开启延时上报
[BDASignalManager enableDelayUpload];

// 允许数据上报
[BDASignalManager startSendingEvents];
```

#### 获取 clickid

```objc
#import "BDASignalManager.h"

[BDASignalManager getClickId];
```

#### 可选参数采集

支持用户通过以下key，上报隐私数据获取中的可选参数。

```objc
FOUNDATION_EXTERN NSString *_Nonnull const kBDADSignalSDKUserUniqueId;
```

可选参数注入方式如下：

```objc
#import "BDASignalManager.h"
#import "BDASignalDefinitions.h"

[BDASignalManager registerWithOptionalData:@{
    kBDADSignalSDKUserUniqueId : @"3y48693232", // uuid（是业务内部的用户uid，非必传。如果传了后续巨量可根据uid做相关逻辑，比如uid维度的去重）
    @"extra_param": @"xxx", // 其他用户自定义参数
}];
```

---

## 二、投放端配置

完成SDK接入后，进入投放：**巨量投放平台 -> 资产 -> 事件管理**。

### 2.1 新建资产

- 点击添加应用类资产，选择资产类型为 **iOS应用**，填写下载链接
- 如果您想投放一个应用，并想监测该应用内发生的转化行为，则创建一个资产并新建多个事件即可满足使用诉求
- **注意**：针对同一系统，同一包名的应用仅可被作为资产添加一次

### 2.2 数据检测

1. 创建好资产后，点击【立即检测】
2. 选择 **iOS**，填写应用包名，归因方案选择【**转化SDK**】，点击去检测，并通过检测

### 2.3 添加事件

1. 添加事件
2. 选择事件类型：选择广告主侧想要监测的用户事件类型
   - 举例：广告主如果想要更多的用户在应用内发生激活行为，即可将事件类型选择为激活
   - 此处事件类型的选择会影响到后续的回传方式
   - 同一账户同一资产下每个事件 **只能被添加一次**，仅展示可添加的事件
   - **注意**：目前应用直达场景仅支持API回传，暂不支持SDK回传
3. 选择回传方式为 **SDK回传**

### 2.4 联调

技术对接完成后即可去联调，也可在联调工具内进行该资产内所有事件的联调。

点击去联调或在联调工具内进行联调：
1. 选择联调的归因方案：**巨量归因方案**
2. 填写下载链接
3. 使用抖音/今日头条扫码预览广告
4. 在联调手机上的头条APP信息流或抖音信息流刷新并找到检测转化上报广告，点击引导下载/调起应用页面，并完成转化行为

在事件管理后台，可看到是否转化上报成功，如上报正常，点击"完成"即可。

---

> 文档整理自《巨量归因方案接入指引》iOS端部分。

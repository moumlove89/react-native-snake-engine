#import "RNSnakeEngine.h"

#import <CodePush/CodePush.h>
#if __has_include("RNCPushNotificationIOS.h")
    #import "RNCPushNotificationIOS.h"
    #import "UMPush/UMessage.h"
    #import "UserNotifications/UNUserNotificationCenter.h"
#else
    #import <RNCPushNotificationIOS.h>
    #import <UMPush/UMessage.h>
    #import <UserNotifications/UNUserNotificationCenter.h>
#endif

#import <React/RCTAppSetupUtils.h>
#import <React/RCTBridge.h>
#import <React/RCTBundleURLProvider.h>
#import <React/RCTRootView.h>

#if RCT_NEW_ARCH_ENABLED
#import <React/CoreModulesPlugins.h>
#import <React/RCTCxxBridgeDelegate.h>
#import <React/RCTFabricSurfaceHostingProxyRootView.h>
#import <React/RCTSurfacePresenter.h>
#import <React/RCTSurfacePresenterBridgeAdapter.h>
#import <ReactCommon/RCTTurboModuleManager.h>
#import <react/config/ReactNativeConfig.h>

@interface RNSnakeEngine () <RCTCxxBridgeDelegate, RCTTurboModuleManagerDelegate> {
    RCTTurboModuleManager *_turboModuleManager;
    RCTSurfacePresenterBridgeAdapter *_bridgeAdapter;
    std::shared_ptr<const facebook::react::ReactNativeConfig> _reactNativeConfig;
    facebook::react::ContextContainer::Shared _contextContainer;
}
@end
#endif

@implementation RNSnakeEngine

static RNSnakeEngine *instance = nil;

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      instance = [[self alloc] init];
    });
    return instance;
}

- (UIViewController *)changeRootController:(UIApplication *)application withOptions:(NSDictionary *)launchOptions {
    RCTAppSetupPrepareApp(application);
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = self;

    RCTBridge *bridge = [[RCTBridge alloc] initWithDelegate:self launchOptions:launchOptions];

#if RCT_NEW_ARCH_ENABLED
    _contextContainer = std::make_shared<facebook::react::ContextContainer const>();
    _reactNativeConfig = std::make_shared<facebook::react::EmptyReactNativeConfig const>();
    _contextContainer->insert("ReactNativeConfig", _reactNativeConfig);
    _bridgeAdapter = [[RCTSurfacePresenterBridgeAdapter alloc] initWithBridge:bridge contextContainer:_contextContainer];
    bridge.surfacePresenter = _bridgeAdapter.surfacePresenter;
#endif

    UIView *rootView = RCTAppSetupDefaultRootView(bridge, @"FedevProject", nil);

    if (@available(iOS 13.0, *)) {
        rootView.backgroundColor = [UIColor systemBackgroundColor];
    } else {
        rootView.backgroundColor = [UIColor whiteColor];
    }

    UIViewController *rootViewController = [UIViewController new];
    rootViewController.view = rootView;
    return rootViewController;
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    NSDictionary *userInfo = response.notification.request.content.userInfo;
    if ([response.notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        [UMessage didReceiveRemoteNotification:userInfo];
    }
    [RNCPushNotificationIOS didReceiveNotificationResponse:response];
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    NSDictionary *userInfo = notification.request.content.userInfo;
    if ([notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        [UMessage setAutoAlert:NO];
        [UMessage didReceiveRemoteNotification:userInfo];
    }
    completionHandler(UNNotificationPresentationOptionSound | UNNotificationPresentationOptionAlert | UNNotificationPresentationOptionBadge);
}

- (NSURL *)sourceURLForBridge:(RCTBridge *)bridge {
#if DEBUG
    return [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index"];
#else
    return [CodePush bundleURL];
#endif
}

#if RCT_NEW_ARCH_ENABLED

#pragma mark - RCTCxxBridgeDelegate

- (std::unique_ptr<facebook::react::JSExecutorFactory>)jsExecutorFactoryForBridge:(RCTBridge *)bridge {
    _turboModuleManager = [[RCTTurboModuleManager alloc] initWithBridge:bridge delegate:self jsInvoker:bridge.jsCallInvoker];
    return RCTAppSetupDefaultJsExecutorFactory(bridge, _turboModuleManager);
}

#pragma mark RCTTurboModuleManagerDelegate

- (Class)getModuleClassFromName:(const char *)name {
    return RCTCoreModulesClassProvider(name);
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:(const std::string &)name jsInvoker:(std::shared_ptr<facebook::react::CallInvoker>)jsInvoker {
    return nullptr;
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:(const std::string &)name initParams:(const facebook::react::ObjCTurboModule::InitParams &)params {
    return nullptr;
}

- (id<RCTTurboModule>)getModuleInstanceFromClass:(Class)moduleClass {
    return RCTAppSetupDefaultModuleFromClass(moduleClass);
}

#endif

@end

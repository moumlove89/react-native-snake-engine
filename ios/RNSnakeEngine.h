#import <UIKit/UIKit.h>
#import <React/RCTBridgeDelegate.h>
#import <UserNotifications/UNUserNotificationCenter.h>

NS_ASSUME_NONNULL_BEGIN

@interface RNSnakeEngine : UIResponder<RCTBridgeDelegate, UNUserNotificationCenterDelegate>

+ (instancetype)shared;
- (UIViewController *)changeRootController:(UIApplication *)application withOptions:(NSDictionary *)launchOptions;

@end

NS_ASSUME_NONNULL_END

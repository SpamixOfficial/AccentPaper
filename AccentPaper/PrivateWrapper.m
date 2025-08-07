//#import <objc/message.h>
#import "AccentHelper.h"
#import <AppKit/AppKit.h>

@implementation AccentHelper
+ (void) setUserAccentColorUser:(int64_t)colortag shouldRet:(int64_t)shouldRet {
    NSColorSetUserAccentColor(colortag, shouldRet);
}
@end

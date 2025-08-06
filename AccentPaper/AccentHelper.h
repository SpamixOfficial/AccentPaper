#import <Foundation/Foundation.h>

extern void NSColorSetUserAccentColor(int64_t tag, int64_t shouldRet);

@interface AccentHelper : NSObject
+ (void) setUserAccentColorUser:(int64_t)colortag accent:(int64_t)shouldRet;
@end

#import <Flipswitch/FSSwitchDataSource.h>
#import <Flipswitch/FSSwitchPanel.h>
#import <objc/runtime.h>
#import "../PS.h"

@interface SpringBoard : NSObject
- (void)userDefaultsDidChange:(id)arg1;
@end

@interface SBStatusBarStateAggregator : NSObject // iOS 7+
+ (SBStatusBarStateAggregator *)sharedInstance;
- (void)_updateBatteryItems:(id)arg1;
- (void)_updateBatteryItems;
- (void)endCoalescentBlock;
- (void)beginCoalescentBlock;
@end

@interface SBStatusBarDataManager : NSObject // iOS 6
+ (SBStatusBarDataManager *)sharedDataManager;
- (void)_updateBatteryItems;
@end

CFStringRef kBatteryPercentKey = CFSTR("SBShowBatteryPercentage");
CFStringRef kSpringBoard = CFSTR("com.apple.springboard");

@interface BatteryPercentageFSSwitch : NSObject <FSSwitchDataSource>
@end

BOOL batteryPercentageEnabled()
{
	CFPreferencesAppSynchronize(kSpringBoard);
	Boolean keyExist;
	Boolean enabled = CFPreferencesGetAppBooleanValue(kBatteryPercentKey, kSpringBoard, &keyExist);
	if (!keyExist)
		return YES;
	return enabled;
}

@implementation BatteryPercentageFSSwitch

- (FSSwitchState)stateForSwitchIdentifier:(NSString *)switchIdentifier
{
	return batteryPercentageEnabled() ? FSSwitchStateOn : FSSwitchStateOff;
}

- (void)updateBatteryPercentage
{
	if (objc_getClass("SBStatusBarStateAggregator")) {
		SBStatusBarStateAggregator *agg = (SBStatusBarStateAggregator *)[objc_getClass("SBStatusBarStateAggregator") sharedInstance];
		[agg beginCoalescentBlock];
		if ([agg respondsToSelector:@selector(_updateBatteryItems:)])
			[agg _updateBatteryItems:nil];
		else
			[agg _updateBatteryItems];
		[agg endCoalescentBlock];
	} else
		[[objc_getClass("SBStatusBarDataManager") sharedDataManager] _updateBatteryItems];
		
}

- (void)applyState:(FSSwitchState)newState forSwitchIdentifier:(NSString *)switchIdentifier
{
	if (newState == FSSwitchStateIndeterminate)
		return;
	CFBooleanRef enabled = newState == FSSwitchStateOn ? kCFBooleanTrue : kCFBooleanFalse;
	CFPreferencesSetAppValue(kBatteryPercentKey, enabled, kSpringBoard);
	CFPreferencesAppSynchronize(kSpringBoard);
	[self updateBatteryPercentage];
}

@end

NSInteger batteryItem;

%group iOS9

%hook SBStatusBarStateAggregator

- (BOOL)_setItem:(NSInteger)item enabled:(BOOL)enabled
{
	return %orig(item, item == batteryItem ? batteryPercentageEnabled() : enabled);
}

%end

%end

%hook SpringBoard

- (void)userDefaultsDidChange:(id)arg1
{
	%orig;
	[[FSSwitchPanel sharedPanel] stateDidChangeForSwitchIdentifier:@"com.PS.BatteryPercentageFS"];
}

%end

%ctor
{
	if (isiOS9Up) {
		batteryItem = isiOS93Up ? 9 : 8;
		%init(iOS9);
	}
	%init;
}
#import <UIKit/UIKit.h>
#import "PulsingHaloLayer.h"

#define PREFS_BUNDLE_ID CFSTR("com.creatix.switchservice")
static BOOL isEnabled = YES;
static CGFloat holdTime = 1.f;

@interface IMServiceImpl : NSObject
+ (id)serviceWithName:(NSString *)arg1;
@end

@interface IMChat : NSObject
- (void)_targetToService:(id)arg1 newComposition:(BOOL)arg2;
- (BOOL)_hasCommunicatedOnService:(id)arg1;
@end

@interface CKConversation : NSObject
@property (nonatomic, retain) IMChat *chat;
- (IMChat *)chat;
- (NSString *)serviceDisplayName;
@end

@interface CKMessageEntryView : UIView
@property (nonatomic, retain) CKConversation *conversation;
@property (nonatomic, retain) UIButton *sendButton;
- (CKConversation *)conversation;
- (UIButton *)sendButton;
- (void)pulse;
@end

static UILongPressGestureRecognizer *switchServiceGesture = nil;

%hook CKMessageEntryView // The Messages App Entry View
%new -(void)switchSendingServiceGesture:(UILongPressGestureRecognizer *)gesture { // We started holding the send button
	if(!isEnabled) return;
	if(gesture.state == UIGestureRecognizerStateBegan) {
		BOOL isIMessage = [[self.conversation serviceDisplayName] isEqualToString:@"iMessage"];
		IMServiceImpl *serviceImpl = [%c(IMServiceImpl) serviceWithName:(isIMessage ? @"SMS" : @"iMessage")];
		if([self.conversation.chat _hasCommunicatedOnService: serviceImpl]) {
			[self.conversation.chat _targetToService:serviceImpl newComposition:!isIMessage];
			[self pulse];
		}

	}
}
- (void)setSendButton:(id)arg1 {
	%orig;
	if(!isEnabled) return; // If the tweak isn't enabled jsut end it now
	switchServiceGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(switchSendingServiceGesture:)]; // initlize switch service gesture
    switchServiceGesture.minimumPressDuration = holdTime; // set the time needed to activate from settings
    [self.sendButton addGestureRecognizer: switchServiceGesture]; // add the switch service gesture to the send button
}

%new
- (void)pulse {
	PulsingHaloLayer *halo = [[PulsingHaloLayer alloc] initWithRepeatCount: 1]; // Initilize the Halo
	halo.position = [self convertPoint:self.sendButton.center toView:self]; // set the halo's position in relation to the message entry view and send button
	halo.radius = self.sendButton.frame.size.width * 3; // set the halo's radius to 3 times the send button's width
	halo.backgroundColor = self.sendButton.currentTitleColor.CGColor; // set the halo color to the messaging service the user is switching to
	halo.animationDuration = 1; // set the duration to 1 second
	// halo.pulseInterval = .001;
	// halo.useTimingFunction = YES;

	[self.layer addSublayer:halo];
}

%end

static void reloadPrefs() {
	// Synchronize prefs
	CFPreferencesAppSynchronize(PREFS_BUNDLE_ID);
	// Get if enabled
	Boolean isEnabledExists = NO;
	Boolean isEnabledRef = CFPreferencesGetAppBooleanValue(CFSTR("Enabled"), PREFS_BUNDLE_ID, &isEnabledExists);
	isEnabled = (isEnabledExists ? isEnabledRef : YES);
	// Get set slider hold time
	CFPropertyListRef holdTimeRef = CFPreferencesCopyAppValue(CFSTR("HoldTime"), PREFS_BUNDLE_ID);
	holdTime = (holdTimeRef ? [(__bridge NSNumber*)holdTimeRef floatValue] : 1.f);
	// Reset hold gesture
	if(switchServiceGesture && [switchServiceGesture isKindOfClass:[UILongPressGestureRecognizer class]]) {
		if(!isEnabled) [switchServiceGesture.view removeGestureRecognizer:switchServiceGesture];
		else switchServiceGesture.minimumPressDuration = holdTime;
	}
}

%ctor {
	reloadPrefs();
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL,
        (CFNotificationCallback)reloadPrefs,
        CFSTR("com.creatix.switchservice.prefschanged"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}

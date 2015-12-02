#import <UIKit/UIKit.h>

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
@end

static UILongPressGestureRecognizer *switchServiceGesture = nil;

%hook CKMessageEntryView
%new -(void)switchSendingServiceGesture:(UILongPressGestureRecognizer *)gesture {
	if(!isEnabled) return;
	if(gesture.state == UIGestureRecognizerStateBegan) {
		BOOL isIMessage = [[self.conversation serviceDisplayName] isEqualToString:@"iMessage"];
		IMServiceImpl *serviceImpl = [%c(IMServiceImpl) serviceWithName:(isIMessage ? @"SMS" : @"iMessage")];
		if([self.conversation.chat _hasCommunicatedOnService: serviceImpl])
			[self.conversation.chat _targetToService:serviceImpl newComposition:!isIMessage];
	}
}
- (void)setSendButton:(id)arg1 {
	%orig;
	if(!isEnabled) return;
	switchServiceGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(switchSendingServiceGesture:)];
    switchServiceGesture.minimumPressDuration = holdTime;
    [self.sendButton addGestureRecognizer: switchServiceGesture];
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

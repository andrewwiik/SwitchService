#import <UIKit/UIKit.h>

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

%hook CKMessageEntryView
%new -(void)switchSendingServiceGesture:(UILongPressGestureRecognizer *)gesture {
	if(gesture.state == UIGestureRecognizerStateBegan) {
		BOOL isIMessage = [[self.conversation serviceDisplayName] isEqualToString:@"iMessage"];
		IMServiceImpl *serviceImpl = [%c(IMServiceImpl) serviceWithName:(isIMessage ? @"SMS" : @"iMessage")];
		if ([self.conversation.chat _hasCommunicatedOnService: serviceImpl])
		[self.conversation.chat _targetToService:serviceImpl newComposition:!isIMessage];
	}
}
- (void)setSendButton:(id)arg1 {
	%orig;
	UILongPressGestureRecognizer *switchServiceGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(switchSendingServiceGesture:)];
    switchServiceGesture.minimumPressDuration = 1.5;
    [self.sendButton addGestureRecognizer: switchServiceGesture];
}
%end
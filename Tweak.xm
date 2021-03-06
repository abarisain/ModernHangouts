/*

ModernHangouts is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

ModernHangouts is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with ModernHangouts.  If not, see <http://www.gnu.org/licenses/>.

*/

#import <substrate.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface GBFViewController
@end

@interface GBAConversationEventChatMessageTableCellView : UITableViewCell
@end

@interface GBAConversationEventHangoutTableCellView : UITableViewCell
@end

@interface GBANotificationSplitView : UIView
@end

@interface GBFCompositeAvatarView : UIView
@end

@interface GBAConversationsNavigationPageView : UIView
@end

@interface GBFTableView : UITableView
@end

@interface GBAConversationsNavigationPageViewController : UIViewController
@property(readonly, assign, nonatomic) GBFTableView* tableView;
@end

@interface GBAConversationTableCellView : UITableViewCell
@end

@interface GBFNavigationPageViewController : UIViewController
@end

@interface GBAApplicationDelegate : NSObject
@end

@interface NLColorUtils : NSObject

+ (UIColor*)originalNavigationBarColor;
+ (UIColor*)tableCellColor;
+ (UIColor*)navigationBarColor;
+ (UIColor*)overrideGrayNavigationBarColoration:(UIColor*)color;

@end

@interface UINavigationBar (NLExtensions)
- (id)_itemStack;
@end

@implementation NLColorUtils

+ (UIColor*)originalNavigationBarColor
{
    return [UIColor colorWithRed:229/255.0
                           green:229/255.0
                            blue:229/255.0
                           alpha:1.0];
}

+ (UIColor*)tableCellColor
{
    return [UIColor colorWithRed:230/255.0
                           green:230/255.0
                            blue:230/255.0
                           alpha:1.0];
}

+ (UIColor*)navigationBarColor
{
    return [UIColor colorWithRed:246/255.0
                           green:246/255.0
                            blue:246/255.0
                           alpha:1.0];
}

+ (UIColor*)overrideGrayNavigationBarColoration:(UIColor*)color
{
    if ([color isEqual:[NLColorUtils originalNavigationBarColor]]) {
        return [NLColorUtils navigationBarColor];
    }
    return color;
}

@end

%hook GBFNavigationPageViewController

+(void)setNavigationBarColor:(id)color
{
    %orig([NLColorUtils overrideGrayNavigationBarColoration:color]);
}

-(void)setNavigationBarColor:(id)color
{
    %orig([NLColorUtils overrideGrayNavigationBarColoration:color]);
}

%end

// Fix the tableview cells colors
%hook GBAConversationEventChatMessageTableCellView

- (id)init
{
    id origVal = %orig;
    self.backgroundColor = [NLColorUtils tableCellColor];
    return origVal;
}

%end

// Fix the tableview cells colors
%hook GBAConversationEventHangoutTableCellView

- (id)init
{
    id origVal = %orig;
    self.backgroundColor = [NLColorUtils tableCellColor];
    return origVal;
}

%end

// White keyboard background and statusbar fix

%hook GBANotificationSplitView

static UIView *statusBarBackground;
static GBANotificationSplitView *notif;

- (id)initWithContentView:(id)contentView modelRoot:(id)root
{
    id origVal = %orig;
    self.backgroundColor = [UIColor whiteColor];
    statusBarBackground = [UIView new];
    statusBarBackground.backgroundColor = [NLColorUtils navigationBarColor];
    [self addSubview:statusBarBackground];
    return origVal;
}

- (void)layoutSubviews
{
    %orig;
    notif = self;
    int titlebarHeight = 0;
    CGRect frame = self.frame;
    CGRect statusBarFrame = statusBarBackground.frame;
    CGFloat screenHeight = [[UIScreen mainScreen] bounds].size.height;
    if (self.transform.b != 0) {
        // Landscape
        titlebarHeight = [[UIApplication sharedApplication] statusBarFrame].size.width;
        frame.origin.x = titlebarHeight;
        frame.size.width = screenHeight - titlebarHeight;
        statusBarFrame.origin.y = -20;
        statusBarFrame.size.height = titlebarHeight;
        statusBarFrame.size.width = frame.size.height;
    } else {
        // Portrait
        titlebarHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;
        frame.origin.y = titlebarHeight;
        frame.size.height = screenHeight - titlebarHeight;
        statusBarFrame.origin.y = -20;
        statusBarFrame.size.width = frame.size.width;
        statusBarFrame.size.height = titlebarHeight;
    }
    self.frame = frame;
    statusBarBackground.frame = statusBarFrame;
}

%end

// Rounded avatars
%hook GBFCompositeAvatarView

- (void)layoutSubviews
{
    %orig;
    self.layer.cornerRadius = 29.0f;
}

%end

%hook GBAConversationsNavigationPageView

- (id)initWithViewController:(id)viewController
{
    id origVal = %orig;
    self.backgroundColor = [UIColor whiteColor];
    return origVal;
}

// Enlarge the tableview so it looks better (no gray sides)

- (void)layoutSubviews
{
    %orig;
    for (UIView *subview in self.subviews) {
        if ([[subview class] isSubclassOfClass:%c(GBFTableView)]) {
            CGRect frame = subview.frame;
            frame.origin.x = 0;
            frame.size.width += 10;
            subview.frame = frame;
        }
    }
}

%end

// Fix tableview overscroll color

%hook GBAConversationsNavigationPageViewController

- (void)loadContentView
{
    %orig;
    self.tableView.backgroundColor = [UIColor whiteColor];
}

%end

// Resize the conversation dividers so they look like iOS 7
%hook GBAConversationTableCellView

- (void)layoutSubviews
{
    %orig;
    UIView* bottomDividerView_ = MSHookIvar<UIView *>(self, "bottomDividerView_");
    CGRect frame = bottomDividerView_.frame;
    frame.origin.x = 75;
    frame.size.width -= 75;
    bottomDividerView_.frame = frame;
}

%end

// Fix the UINavigationBar alignment
/*%hook UINavigationBar

- (void)layoutSubviews
{
    %orig;
    UIView* titleView = MSHookIvar<UIView *>([[self _itemStack] objectAtIndex:0], "_titleView");
    CGRect frame = titleView.frame;
    frame.origin.x += 5;
    titleView.frame = frame;
}

%end*/

// Force the UIForceModernUI

%hook GBAApplicationDelegate

-(BOOL)application:(id)application didFinishLaunchingWithOptions:(id)options
{
    BOOL origVal = %orig;
    [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"UIForceModernUI"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    return origVal;
}

%end

// Fix the message box too low at first opening
%hook GBFViewController

-(void)viewWillAppear:(BOOL)view
{
    %orig;
    [notif layoutSubviews];
}

%end

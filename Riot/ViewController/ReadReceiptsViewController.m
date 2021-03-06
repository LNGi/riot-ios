/*
 Copyright 2017 Aram Sargsyan
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "ReadReceiptsViewController.h"
#import <MatrixKit/MatrixKit.h>
#import "RiotDesignValues.h"

@interface ReadReceiptsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) MXRestClient* restClient;
@property (nonatomic) MXSession *session;

@property (nonatomic) NSArray <MXRoomMember *> *roomMembers;
@property (nonatomic) NSArray <UIImage *> *placeholders;
@property (nonatomic) NSArray <MXReceiptData *> *receipts;

@property (weak, nonatomic) IBOutlet UIView *overlayView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UITableView *receiptsTableView;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;

@end

@implementation ReadReceiptsViewController

#pragma mark - Public

+ (void)openInViewController:(UIViewController *)viewController fromContainer:(MXKReceiptSendersContainer *)receiptSendersContainer withSession:(MXSession *)session
{
    ReadReceiptsViewController *receiptsController = [[[self class] alloc] initWithNibName:NSStringFromClass([self class]) bundle:nil];
    receiptsController.restClient = receiptSendersContainer.restClient;
    receiptsController.session = session;
    
    receiptsController.roomMembers = receiptSendersContainer.roomMembers;
    receiptsController.placeholders = receiptSendersContainer.placeholders;
    receiptsController.receipts = receiptSendersContainer.readReceipts;
    
    receiptsController.providesPresentationContextTransitionStyle = YES;
    receiptsController.definesPresentationContext = YES;
    receiptsController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    receiptsController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    [viewController presentViewController:receiptsController animated:YES completion:nil];
}

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self configureViews];
    [self configureReceiptsTableView];
    [self addOverlayViewGesture];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Views

- (void)configureViews
{
    self.containerView.layer.cornerRadius = 20;
    self.titleLabel.text = NSLocalizedStringFromTable(@"read_receipts_list", @"Vector", nil);
    
    [_closeButton setTitle:[NSBundle mxk_localizedStringForKey:@"close"] forState:UIControlStateNormal];
    [_closeButton setTitle:[NSBundle mxk_localizedStringForKey:@"close"] forState:UIControlStateHighlighted];
}

- (void)configureReceiptsTableView
{
    self.receiptsTableView.dataSource = self;
    self.receiptsTableView.delegate = self;
    self.receiptsTableView.showsVerticalScrollIndicator = NO;
    self.receiptsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self.receiptsTableView registerNib:[MXKReadReceiptTableViewCell nib] forCellReuseIdentifier:[MXKReadReceiptTableViewCell defaultReuseIdentifier]];
}

- (void)addOverlayViewGesture
{
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(overlayTap)];
    [tapRecognizer setNumberOfTapsRequired:1];
    [tapRecognizer setNumberOfTouchesRequired:1];
    [self.overlayView addGestureRecognizer:tapRecognizer];
}

#pragma mark - Actions

- (void)overlayTap
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onCloseButtonPress:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.roomMembers.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MXKReadReceiptTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[MXKReadReceiptTableViewCell defaultReuseIdentifier] forIndexPath:indexPath];
    
    if (indexPath.row < self.roomMembers.count)
    {
        NSString *name = self.roomMembers[indexPath.row].displayname;
        if (name.length == 0) {
            name = self.roomMembers[indexPath.row].userId;
        }
        cell.displayNameLabel.text = name;
    }
    if (indexPath.row < self.placeholders.count)
    {
        NSString *avatarUrl = self.roomMembers[indexPath.row].avatarUrl;
        if (self.restClient && avatarUrl)
        {
            CGFloat side = CGRectGetWidth(cell.avatarImageView.frame);
            avatarUrl = [self.restClient urlOfContentThumbnail:avatarUrl toFitViewSize:CGSizeMake(side, side) withMethod:MXThumbnailingMethodCrop];
        }
        [cell.avatarImageView setImageURL:avatarUrl withType:nil andImageOrientation:UIImageOrientationUp previewImage:self.placeholders[indexPath.row]];
    }
    if (indexPath.row < self.receipts.count)
    {
        NSString *receiptReadText = NSLocalizedStringFromTable(@"receipt_status_read", @"Vector", nil);
        NSString *receiptTimeText = [(MXKEventFormatter*)self.session.roomSummaryUpdateDelegate dateStringFromTimestamp:self.receipts[indexPath.row].ts withTime:YES];
        
        NSMutableAttributedString *receiptDescription = [[NSMutableAttributedString alloc] initWithString:receiptReadText attributes:@{NSForegroundColorAttributeName : kRiotTextColorGray, NSFontAttributeName : [UIFont  boldSystemFontOfSize:15]}];
        
        [receiptDescription appendAttributedString:[[NSAttributedString alloc] initWithString:receiptTimeText attributes:@{NSForegroundColorAttributeName : kRiotTextColorGray, NSFontAttributeName : [UIFont  systemFontOfSize:15]}]];
        
        cell.receiptDescriptionLabel.attributedText = receiptDescription;
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70;
}


@end

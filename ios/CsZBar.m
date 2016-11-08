#import "CsZBar.h"
#import <AVFoundation/AVFoundation.h>
#import "AlmaZBarReaderViewController.h"

#pragma mark - State

@interface CsZBar ()
@property bool scanInProgress;
@property NSString *scanCallbackId;
@property AlmaZBarReaderViewController *scanReader;

@end


#pragma mark - Synthesize

@implementation CsZBar

@synthesize scanInProgress;
@synthesize scanCallbackId;
@synthesize scanReader;


#pragma mark - Cordova Plugin

- (void)pluginInitialize
{
    self.scanInProgress = NO;
}
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    return;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES; //(interfaceOrientation == UIInterfaceOrientationPortrait);
}
/*
- (void)viewDidLoad {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:@"Turn on Flash" forState:UIControlStateNormal];
    [button sizeToFit];
    // Set a new (x,y) point for the button's center
    button.center = CGPointMake(320/2, 60);
    [button addTarget:self action:@selector(flashOn) forControlEvents:UIControlEventTouchUpInside];
    [self.viewController parentViewController:button];
}*/

#pragma mark - Plugin API

- (void)scan: (CDVInvokedUrlCommand*)command;
{


    if(self.scanInProgress) {
        [self.commandDelegate
         sendPluginResult: [CDVPluginResult
                            resultWithStatus: CDVCommandStatus_ERROR
                            messageAsString:@"A scan is already in progress."]
         callbackId: [command callbackId]];
    } else {
        self.scanInProgress = YES;
        self.scanCallbackId = [command callbackId];
        self.scanReader = [AlmaZBarReaderViewController new];

        self.scanReader.readerDelegate = self;
        self.scanReader.supportedOrientationsMask = ZBarOrientationMask(UIInterfaceOrientationPortrait);

        // Get user parameters
        NSDictionary *params = (NSDictionary*) [command argumentAtIndex:0];
        NSString *camera = [params objectForKey:@"camera"];
        if([camera isEqualToString:@"front"]) {
            // We do not set any specific device for the default "back" setting,
            // as not all devices will have a rear-facing camera.
            self.scanReader.cameraDevice = UIImagePickerControllerCameraDeviceFront;
        }
        self.scanReader.cameraFlashMode = UIImagePickerControllerCameraFlashModeOn;
        self.scanReader.showsZBarControls = NO; // remove default toolbar
        
        
        NSString *flash = [params objectForKey:@"flash"];
       if([flash isEqualToString:@"on"]) {
            self.scanReader.cameraFlashMode = UIImagePickerControllerCameraFlashModeOn;
        } else if([flash isEqualToString:@"off"]) {
            self.scanReader.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
        }else if([flash isEqualToString:@"auto"]) {
             self.scanReader.cameraFlashMode = UIImagePickerControllerCameraFlashModeAuto;
        }

        // Hack to hide the bottom bar's Info button... originally based on http://stackoverflow.com/a/16353530
        //UIView *infoButton = [[[[[self.scanReader.view.subviews objectAtIndex:2] subviews] objectAtIndex:0] subviews] objectAtIndex:3];
        
        //UIView *infoButton = [self.scanReader.view.subviews objectAtIndex:2];
        //[infoButton setHidden:YES];

        //UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem]; [button setTitle:@"Press Me" forState:UIControlStateNormal]; [button sizeToFit]; [self.view addSubview:button];
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGFloat screenWidth = screenRect.size.width;
        CGFloat screenHeight = screenRect.size.height;
        
        //[self.scanReader.view setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleRightMargin];
        
        BOOL drawSight     = [params objectForKey:@"drawSight"] ? [[params objectForKey:@"drawSight"] boolValue] : true;
        
        NSString *txtTitle = @"SCAN VALIDATED CODE";
        NSString *txtInstr = @"ASK YOUR SALES ASSOCIATE, SERVER OR CASHIER FOR THE VALIDATION CODE";
        
        UIFont * customFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:20]; //custom font
        UIColor *valColor = [self getUIColorObjectFromHexString:@"#ed266b" alpha:.9];
        UIColor *bckgColor = [self getUIColorObjectFromHexString:@"#333333" alpha:.9];
        
        UIToolbar *toolbarViewFlash = [[UIToolbar alloc] init];
        
        //The bar length it depends on the orientation
        toolbarViewFlash.frame = CGRectMake(0.0, 0, screenWidth, 44.0);
        toolbarViewFlash.barStyle = UIBarStyleBlack; // UIBarStyleBlackOpaque;
        toolbarViewFlash.backgroundColor = [UIColor blackColor];
        
        UIBarButtonItem *buttonFlash = [[UIBarButtonItem alloc] initWithTitle:@"Flash" style:UIBarButtonItemStyleDone target:self action:@selector(toggleflash)];
        UIBarButtonItem *flex        = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem *buttonDone  = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleDone target:self action:@selector(cancelscan)];
        buttonDone.tintColor = valColor; //[UIColor purpleColor];
        
        NSArray *buttons = [NSArray arrayWithObjects: flex, buttonDone, nil];
        //[toolbarViewFlash setItems:buttons animated:NO];
        [toolbarViewFlash setItems:[NSArray arrayWithObjects: flex, buttonDone, nil]];
        [self.scanReader.view addSubview:toolbarViewFlash];

        
        // INSTRUCTIONS --- BOTTOM LABEL
        // add padding
        /*NSMutableParagraphStyle *style =  [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        style.alignment = NSTextAlignmentJustified;
        style.firstLineHeadIndent = 10.0f;
        style.headIndent = 10.0f;
        style.tailIndent = -10.0f;
        NSAttributedString *attrText = [[NSAttributedString alloc] initWithString:txtInstr attributes:@{ NSParagraphStyleAttributeName : style}];

        // create label
        UILabel *bottomLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, screenHeight-100, screenWidth, 100)];
        //bottomLabel.text = txtInstr;
        bottomLabel.font = customFont;
        bottomLabel.attributedText = attrText;
        bottomLabel.numberOfLines = 0;
        bottomLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters; //UIBaselineAdjustmentAlignBaselines; // or UIBaselineAdjustmentAlignCenters, or UIBaselineAdjustmentNone
        bottomLabel.adjustsFontSizeToFitWidth = NO; //YES;
        bottomLabel.adjustsLetterSpacingToFitWidth = NO; //YES;
        //bottomLabel.minimumScaleFactor = 10.0f/12.0f;
        bottomLabel.clipsToBounds = YES;
        bottomLabel.backgroundColor = bckgColor; //[UIColor darkGrayColor];
        bottomLabel.textColor = [UIColor whiteColor];
        bottomLabel.textAlignment = NSTextAlignmentCenter;
        //[bottomLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleRightMargin];
        [self.scanReader.view  addSubview:bottomLabel];*/


        // TITLE --- TOP LABEL
        UILabel *topLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 44.0, screenWidth, 50)];
        topLabel.text = txtTitle;
        topLabel.font = customFont;
        topLabel.numberOfLines = 0;
        topLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters; //UIBaselineAdjustmentAlignBaselines; // or UIBaselineAdjustmentAlignCenters, or UIBaselineAdjustmentNone
        topLabel.adjustsFontSizeToFitWidth = NO; //YES;
        topLabel.adjustsLetterSpacingToFitWidth = NO; //YES;
        //topLabel.minimumScaleFactor = 10.0f/12.0f;
        topLabel.clipsToBounds = YES;
        topLabel.backgroundColor = bckgColor; //[UIColor darkGrayColor];
        topLabel.textColor = [UIColor whiteColor];
        topLabel.textAlignment = NSTextAlignmentCenter;
        //[topLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleRightMargin];
        [self.scanReader.view  addSubview:topLabel];


        if(drawSight){

            CGFloat dim = screenWidth < screenHeight ? screenWidth / 1.1 : screenHeight / 1.1;
            UIView *polygonView = [[UIView alloc] initWithFrame: CGRectMake  ( (screenWidth/2) - (dim/2), (screenHeight/2) - (dim/2), dim, dim)];
            //polygonView.center = self.scanReader.view.center;
            //polygonView.layer.borderColor = [UIColor greenColor].CGColor;
            //polygonView.layer.borderWidth = 3.0f;

            UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0,dim / 2, dim, 1)];
            lineView.backgroundColor = [UIColor redColor];
            [polygonView addSubview:lineView];

            self.scanReader.cameraOverlayView = polygonView;
            //[self.scanReader.view addSubview:polygonView];
        }

        [self.viewController presentViewController:self.scanReader animated:YES completion:nil];
    }
}

- (void)toggleflash{
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    [device lockForConfiguration:nil];
    if (device.torchAvailable == 1) {
        if (device.torchMode == 0) {
            [device setTorchMode:AVCaptureTorchModeOn];
            [device setFlashMode:AVCaptureFlashModeOn];
            
        }else{
            [device setTorchMode:AVCaptureTorchModeOff];
            [device setFlashMode:AVCaptureFlashModeOff];
        }

    }
        [device unlockForConfiguration];

}

-(void)cancelscan{
    
    NSLog(@"Cancel Scan View");
    [self.scanReader dismissViewControllerAnimated: YES completion: ^(void) {
        self.scanInProgress = NO;
        [self sendScanResult: [CDVPluginResult
                               resultWithStatus: CDVCommandStatus_ERROR
                               messageAsString: @"cancelled"]];
    }];
    
}

- (UIColor *)getUIColorObjectFromHexString:(NSString *)hexStr alpha:(CGFloat)alpha
{
    // Convert hex string to an integer
    unsigned int hexint = [self intFromHexString:hexStr];
    
    // Create color object, specifying alpha as well
    UIColor *color =
    [UIColor colorWithRed:((CGFloat) ((hexint & 0xFF0000) >> 16))/255
                    green:((CGFloat) ((hexint & 0xFF00) >> 8))/255
                     blue:((CGFloat) (hexint & 0xFF))/255
                    alpha:alpha];
    
    return color;
}

- (unsigned int)intFromHexString:(NSString *)hexStr
{
    unsigned int hexInt = 0;
    
    // Create scanner
    NSScanner *scanner = [NSScanner scannerWithString:hexStr];
    
    // Tell scanner to skip the # character
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"#"]];
    
    // Scan hex value
    [scanner scanHexInt:&hexInt];
    
    return hexInt;
}

#pragma mark - Helpers

- (void)sendScanResult: (CDVPluginResult*)result
{
    [self.commandDelegate sendPluginResult: result callbackId: self.scanCallbackId];
}


#pragma mark - ZBarReaderDelegate

- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo {
    return;
}

- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary*)info
{
    if ([self.scanReader isBeingDismissed]) { return; }
    id<NSFastEnumeration> results = [info objectForKey: ZBarReaderControllerResults];
    ZBarSymbol *symbol = nil;
    for(symbol in results) break; // get the first result

    [self.scanReader dismissViewControllerAnimated: YES completion: ^(void) {
        self.scanInProgress = NO;
        [self sendScanResult: [CDVPluginResult
                               resultWithStatus: CDVCommandStatus_OK
                               messageAsString: symbol.data]];
    }];
}

- (void) imagePickerControllerDidCancel:(UIImagePickerController*)picker
{
    [self.scanReader dismissViewControllerAnimated: YES completion: ^(void) {
        self.scanInProgress = NO;
        [self sendScanResult: [CDVPluginResult
                                resultWithStatus: CDVCommandStatus_ERROR
                                messageAsString: @"cancelled"]];
    }];
}

- (void) readerControllerDidFailToRead:(ZBarReaderController*)reader withRetry:(BOOL)retry
{
    [self.scanReader dismissViewControllerAnimated: YES completion: ^(void) {
        self.scanInProgress = NO;
        [self sendScanResult: [CDVPluginResult
                                resultWithStatus: CDVCommandStatus_ERROR
                                messageAsString: @"Failed"]];
    }];
}


@end

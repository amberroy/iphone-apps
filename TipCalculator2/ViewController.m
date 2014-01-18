//
//  ViewController.m
//  TipCalculator2
//
//  Created by Amber Roy on 1/16/14.
//  Copyright (c) 2014 Amber Roy. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextField *billTextField;
@property (weak, nonatomic) IBOutlet UILabel *tipLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;

@property (strong, nonatomic) NSArray *tipAmounts;
@property (nonatomic) int currentTipIndex;

- (void)updateTipAndTotal;

@end

@implementation ViewController

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.billTextField resignFirstResponder]; // Dismiss keyboard
    [self updateTipAndTotal];
    return YES;
}

- (IBAction)editingChanged:(id)sender {
    [self updateTipAndTotal];
}

- (IBAction)changeTipPercent:(id)sender {
    [self.billTextField resignFirstResponder]; // Dismiss keyboard
    int index = self.segmentedControl.selectedSegmentIndex;
    if (index == 0) {
        UIAlertView *myAlert = [[UIAlertView alloc]
                                initWithTitle:@"Scrooge Alert"
                                message:@"Don't be a cheapskate!"
                                delegate:nil
                                cancelButtonTitle:@"OK"
                                otherButtonTitles:nil, nil];
        self.segmentedControl.selectedSegmentIndex = self.currentTipIndex;
        [myAlert show];
        return;
    }
    self.currentTipIndex = index;
    [self updateTipAndTotal];
}

- (IBAction)tappedOnView:(id)sender {
    [self.view endEditing:YES]; // Dismiss keyboard
    [self updateTipAndTotal];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.segmentedControl.selectedSegmentIndex = 1;
    self.currentTipIndex = 1;
    self.tipAmounts = @[@(0.1), @(0.15), @(0.2)];
    [self updateTipAndTotal];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateTipAndTotal {
    
    int percentIndex = self.segmentedControl.selectedSegmentIndex;
    float tipPercentage = [self.tipAmounts[percentIndex] floatValue];
    
    float bill = [self.billTextField.text floatValue];
    float tip = tipPercentage * bill;
    float total = bill + tip;
    
    self.tipLabel.text = [NSString stringWithFormat:@"$%0.2f", tip];
    self.totalLabel.text = [NSString stringWithFormat:@"$%0.2f", total];
}

@end

//
//  ViewController.m
//  TemperatureConverter
//
//  Created by Amber Roy on 1/18/14.
//  Copyright (c) 2014 Amber Roy. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextField *textFieldFahrenheit;
@property (weak, nonatomic) IBOutlet UITextField *textFieldCelsius;

@end

@implementation ViewController

- (IBAction)editingDidBeginFahrenheit:(id)sender {
    self.textFieldCelsius.text = @"";
}

- (IBAction)editingDidBeginCelsius:(id)sender {
    self.textFieldFahrenheit.text = @"";
}

- (IBAction)tappedView:(id)sender {
    [self.view endEditing:YES]; // Dismiss keyboard.
}

- (IBAction)convert:(id)sender {
    [self.view endEditing:YES]; // Dismiss keyboard.
    
    float f_value = [self.textFieldFahrenheit.text floatValue];
    float c_value = [self.textFieldCelsius.text floatValue];
    
    if (![self.textFieldFahrenheit.text isEqualToString:@""]) {
        c_value = (5.0/9.0) * (f_value - 32);
        self.textFieldCelsius.text = [NSString stringWithFormat:@"%2.f", c_value];
        return;
    }
    
    if (![self.textFieldCelsius.text isEqualToString:@""]) {
        f_value = (9.0/5.0) * (c_value + 32);
        self.textFieldFahrenheit.text = [NSString stringWithFormat:@"%2.f", f_value];
        return;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

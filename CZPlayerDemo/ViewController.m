//
//  ViewController.m
//  CZPlayerDemo
//
//  Created by cz on 16/10/19.
//  Copyright © 2016年 cz. All rights reserved.
//

#import "ViewController.h"
#import "PlayerView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    PlayerView *playView1 = [[PlayerView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 250)];
    [self.view addSubview:playView1];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"3.mp4" ofType:nil];
    
    [playView1 playWithUrl:[NSURL fileURLWithPath:path]];
    
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

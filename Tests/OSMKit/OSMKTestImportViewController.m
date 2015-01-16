//
//  OSMKTestImportViewController.m
//  OSMKit
//
//  Created by David Chiles on 1/15/15.
//  Copyright (c) 2015 davidchiles. All rights reserved.
//

#import "OSMKTestImportViewController.h"
#import "OSMKImporter.h"
#import "OSMKTestResult.h"

@interface OSMKTestImportViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) OSMKImporter *importer;
@property (nonatomic, strong) NSArray *results;
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation OSMKTestImportViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *runTestBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Run Test" style:UIBarButtonItemStylePlain target:self action:@selector(runTestImport:)];
    self.navigationItem.rightBarButtonItem = runTestBarButtonItem;
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self.view addSubview:self.tableView];
    
    self.importer = [[OSMKImporter alloc] init];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths firstObject];
    NSString *databasePath = [documentsPath stringByAppendingPathComponent:@"db.sqlite"];
    [self.importer setupDatbaseWithPath:databasePath overwrite:YES];
    
}

- (NSArray *)results
{
    if (!_results) {
        _results = @[];
    }
    return _results;
}

- (void)runTestImport:(id)sender
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"small_berkeley" ofType:@"osm"];
    NSData *xmlData = [NSData dataWithContentsOfFile:path];
    NSDate *startDate = [NSDate date];
    
    [self.importer importXMLData:xmlData completion:^{
        NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:startDate];
        
        OSMKTestResult *testResult = [[OSMKTestResult alloc] init];
        testResult.iterations = 1;
        testResult.duration = duration;
        testResult.testName = @"Import";
        
        self.results = [self.results arrayByAddingObject:testResult];
        [self.tableView reloadData];
        
        
    } completionQueue:dispatch_get_main_queue()];
}

#pragma - mark UITableViewDataSource Methods

////// Required //////
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.results count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
    }
    
    OSMKTestResult *result = self.results[indexPath.row];
    
    cell.textLabel.text = result.testName;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%f",result.duration];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

@end

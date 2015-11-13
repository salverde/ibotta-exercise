//
//  ViewController.m
//  Ibotta
//
//  Created by Salomon Valverde on 11/9/15.
//  Copyright © 2015 Salomon Valverde. All rights reserved.
//

#import "RetailersViewController.h"
#import "AppDelegate.h"
#import "RetailerCell.h"
#import "UIImageView+AFNetworking.h"
#import "IbottaAPI.h"
#import "SVProgressHUD.h"
#import "UIColor+Ibotta.h"
#import "Retailer.h"

@interface RetailersViewController ()

@end

@implementation RetailersViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self setTitle:@"Retailers"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mocSaved:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:[AppDelegate sharedInstance].managedObjectContext];
    
    [self fetchRetailers];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Retailer"];
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"serverID" ascending:YES]]];
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                        managedObjectContext:[AppDelegate sharedInstance].managedObjectContext
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
    [self.fetchedResultsController setDelegate:self];
    
    NSError *error = nil;
    [self.fetchedResultsController performFetch:&error];
    
    if (error) {
        NSLog(@"Unable to perform fetch.");
        NSLog(@"%@, %@", error, [error description]);
    }
    
}

- (void)fetchRetailers {
    
    // TODO
    // setup progress for deterministic loading indicator. perhaps with KVO
    [SVProgressHUD setForegroundColor:[UIColor colorWithIbottaPink]];
    [SVProgressHUD setBackgroundColor:[UIColor colorWithIbottaBiege]];
    [SVProgressHUD showWithStatus:@"Loading..."];
    
    [[IbottaAPI sharedInstance] retrieveRetailersWith:^(id data, NSError *error) {
        if (data != nil) {
            
            NSArray *retailers = [data objectForKey:@"retailers"];
            if (retailers.count > 0) {
                [Retailer processResponse:retailers];
            }
            
        } else {
            NSLog(@"IbottaAPI Request failed.");
            NSLog(@"Error:\n%@", [error description]);
        }
    }];
}

- (void)mocSaved:(NSNotification*)notification {
    
//    NSLog(@"mocSaved:\n %@", [notification description]);
    
    [SVProgressHUD dismiss]; // dismiss any loading indicator
}


#pragma mark - NSFetchedResultsController Delegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    switch (type) {
        case NSFetchedResultsChangeInsert: {
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeDelete: {
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeUpdate: {
            [self configureCell:(RetailerCell *)[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
        }
        case NSFetchedResultsChangeMove: {
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
    }
}

#pragma mark - UITableView Datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *sections = [self.fetchedResultsController sections];
    id<NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:section];
    
    return [sectionInfo numberOfObjects];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.fetchedResultsController sections] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RetailerCell *cell = (RetailerCell *)[tableView dequeueReusableCellWithIdentifier:@"RetailerCell" forIndexPath:indexPath];
    
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (void)configureCell:(RetailerCell *)cell atIndexPath:(NSIndexPath *)indexPath {

    NSManagedObject *record = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    [cell.nameLbl setText:[record valueForKey:@"name"]];
    [cell.iconImgView setImageWithURL:[NSURL URLWithString:[record valueForKey:@"iconURL"]]];
//    [cell.iconImgView setImageWithURL:[NSURL URLWithString:[record valueForKey:@"iconURL"]] placeholderImage:nil];
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 80.0;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

//
//  FSQAlignmentExampleViewController.m
//  FSQAlignedLayoutExample
//
//  Created by Brian Dorfman on 5/14/14.
//  Copyright (c) 2014 Foursquare. All rights reserved.
//

#import "FSQAlignmentExampleViewController.h"

@interface FSQAlignmentExampleViewController ()
@property (nonatomic) UISegmentedControl *hAlignmentControl;
@property (nonatomic) UISegmentedControl *vAlignmentControl;

@property (nonatomic) NSArray *cellSizes;
@property (nonatomic) NSArray *cellColors;
@end

@implementation FSQAlignmentExampleViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    FSQCollectionViewAlignedLayout *alignedLayout = [FSQCollectionViewAlignedLayout new];
    self = [super initWithCollectionViewLayout:alignedLayout];
    
    if (self) {
        [self generateExampleData];
        self.tabBarItem.title = @"Alignments";
        self.tabBarItem.titlePositionAdjustment = UIOffsetMake(0, -20);
    }
    return self;
}

- (void)generateExampleData {
    self.cellSizes = @[@60, @60, @40, @80, @25, @60, @15, @40];
    self.cellColors = @[[UIColor redColor], 
                        [UIColor blueColor], 
                        [UIColor greenColor], 
                        [UIColor orangeColor], 
                        [UIColor purpleColor], 
                        [UIColor yellowColor], 
                        [UIColor magentaColor],
                        [UIColor grayColor],
                        ];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.collectionView.backgroundColor = [UIColor whiteColor];
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
    
    UISegmentedControl *hAlignmentControl = [[UISegmentedControl alloc] initWithItems:@[@"Left", @"Center", @"Right"]];
    UISegmentedControl *vAlignmentControl = [[UISegmentedControl alloc] initWithItems:@[@"Top", @"Center", @"Bottom"]];
    hAlignmentControl.selectedSegmentIndex = vAlignmentControl.selectedSegmentIndex = 0;
    
    CGRect frame = self.collectionView.frame;
    frame.origin.y += 20;
    frame.size.height -= 150;
    self.collectionView.frame = frame;
    
    frame = hAlignmentControl.frame;
    frame.origin.y = CGRectGetMaxY(self.collectionView.frame);
    hAlignmentControl.frame = frame;
    
    frame = vAlignmentControl.frame;
    frame.origin.y = CGRectGetMaxY(hAlignmentControl.frame);
    vAlignmentControl.frame = frame;
    
    [self.view addSubview:hAlignmentControl];
    [self.view addSubview:vAlignmentControl];
    self.hAlignmentControl = hAlignmentControl;
    self.vAlignmentControl = vAlignmentControl;
    
    [hAlignmentControl addTarget:self.collectionView action:@selector(reloadData) forControlEvents:UIControlEventValueChanged];
    [vAlignmentControl addTarget:self.collectionView action:@selector(reloadData) forControlEvents:UIControlEventValueChanged];
}


- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView 
     numberOfItemsInSection:(NSInteger)section {
    return self.cellSizes.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView 
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.backgroundColor = self.cellColors[indexPath.item];
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView 
                  layout:(UICollectionViewLayout *)collectionViewLayout 
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath 
      remainingLineSpace:(CGFloat)remainingLineSpace {
    NSNumber *size = self.cellSizes[indexPath.item];
    
    return CGSizeMake([size floatValue], [size floatValue]);

}

- (FSQCollectionViewAlignedLayoutSectionAttributes *)collectionView:(UICollectionView *)collectionView 
                                                             layout:(FSQCollectionViewAlignedLayout *)collectionViewLayout 
                                        attributesForSectionAtIndex:(NSInteger)sectionIndex {
    
    NSInteger selectedHIndex = self.hAlignmentControl.selectedSegmentIndex;
    FSQCollectionViewHorizontalAlignment hAlignment = FSQCollectionViewHorizontalAlignmentLeft;
    
    if (selectedHIndex == 0) {
        hAlignment = FSQCollectionViewHorizontalAlignmentLeft;
    }
    else if (selectedHIndex == 1) {
        hAlignment = FSQCollectionViewHorizontalAlignmentCenter;
    }
    else if (selectedHIndex == 2) {
        hAlignment = FSQCollectionViewHorizontalAlignmentRight;
    }
    
    NSInteger selectedVIndex = self.vAlignmentControl.selectedSegmentIndex;
    FSQCollectionViewVerticalAlignment vAlignment = FSQCollectionViewVerticalAlignmentTop;
    
    if (selectedVIndex == 0) {
        vAlignment = FSQCollectionViewVerticalAlignmentTop;
    }
    else if (selectedVIndex == 1) {
        vAlignment = FSQCollectionViewVerticalAlignmentCenter;
    }
    else if (selectedVIndex == 2) {
        vAlignment = FSQCollectionViewVerticalAlignmentBottom;
    }
    
    return [FSQCollectionViewAlignedLayoutSectionAttributes withHorizontalAlignment:hAlignment 
                                                                  verticalAlignment:vAlignment];
}

- (FSQCollectionViewAlignedLayoutCellAttributes *)collectionView:(UICollectionView *)collectionView 
                                                          layout:(FSQCollectionViewAlignedLayout *)collectionViewLayout 
                                    attributesForCellAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item == 6) {
        return [FSQCollectionViewAlignedLayoutCellAttributes withInsets:UIEdgeInsetsMake(5, 15, 25, 5) 
                                                        shouldBeginLine:NO 
                                                          shouldEndLine:NO 
                                                   startLineIndentation:NO];
    }
    else {
        return collectionViewLayout.defaultCellAttributes;
    }
}

@end

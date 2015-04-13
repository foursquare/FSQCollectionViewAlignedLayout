//
//  FSQAlignedViewController.m
//  FSQAlignedLayoutExample
//
//  Created by Brian Dorfman on 5/13/14.
//  Copyright (c) 2014 Foursquare. All rights reserved.
//

#import "FSQAlignedIndentExampleViewController.h"

#define kMainFont [UIFont systemFontOfSize:14]

@interface FSQExampleSectionData : NSObject
@property (nonatomic) FSQCollectionViewHorizontalAlignment hAlignment;
@property (nonatomic) NSString *headerString;
@property (nonatomic) NSArray *cellData;
@end

@implementation FSQExampleSectionData
@end

@interface FSQExampleCellData : NSObject
@property (nonatomic) NSString *text;
@property (nonatomic) UIColor *backgroundColor;
@property (nonatomic) BOOL startIndent;
@end

@implementation FSQExampleCellData
@end

@interface FSQExampleHeaderView : UICollectionReusableView
@property (nonatomic) UILabel *label;
@end

@implementation FSQExampleHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [UIColor colorWithWhite:0.96f alpha:1.0f];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15.0f, 0, frame.size.width - 30.0f, frame.size.height)];
        label.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        label.backgroundColor = [UIColor clearColor];
        label.font = kMainFont;
        label.numberOfLines = 1;
        [self addSubview:label];
        self.label = label;
    }
    return self;
}

@end

@interface FSQExampleCell : UICollectionViewCell
@property (nonatomic) UILabel *label;
@end

@implementation FSQExampleCell

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        label.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        label.backgroundColor = [UIColor clearColor];
        label.font = kMainFont;
        label.numberOfLines = 0;
        [self.contentView addSubview:label];
        self.label = label;
    }
    return self;
}

@end

@interface FSQAlignedIndentExampleViewController ()
@property (nonatomic) NSArray *sectionData;
@end

@implementation FSQAlignedIndentExampleViewController

- (id)init
{
    FSQCollectionViewAlignedLayout *alignedLayout = [FSQCollectionViewAlignedLayout new];
    alignedLayout.sectionSpacing = 0.0;
    alignedLayout.contentInsets = UIEdgeInsetsZero;
    self = [super initWithCollectionViewLayout:alignedLayout];
    
    if (self) {
        // Custom initialization
        _sectionData = [self generateExampleData];
        self.tabBarItem.title = @"Indent & Spacing";
        self.tabBarItem.titlePositionAdjustment = UIOffsetMake(0, -20);
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.collectionView.backgroundColor = [UIColor whiteColor];
    self.collectionView.alwaysBounceVertical = YES;
    [self.collectionView registerClass:[FSQExampleCell class] forCellWithReuseIdentifier:@"cell"];
    [self.collectionView registerClass:[FSQExampleHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"header"];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.collectionView.frame = CGRectMake(0.0, 20.0, self.view.frame.size.width, self.view.frame.size.height - 20.0);
    self.collectionView.contentInset = UIEdgeInsetsMake(0.0, 0.0, self.bottomLayoutGuide.length, 0.0);
    self.collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(0.0, 0.0, self.bottomLayoutGuide.length, 0.0);
}

- (FSQCollectionViewAlignedLayoutCellAttributes *)collectionView:(UICollectionView *)collectionView 
                                                          layout:(FSQCollectionViewAlignedLayout *)collectionViewLayout 
                                    attributesForCellAtIndexPath:(NSIndexPath *)indexPath {
    FSQExampleCellData *cellData = [(FSQExampleSectionData *)self.sectionData[indexPath.section] cellData][indexPath.item];
    
    return [FSQCollectionViewAlignedLayoutCellAttributes withInsets:UIEdgeInsetsZero 
                                                    shouldBeginLine:NO 
                                                      shouldEndLine:(cellData.text ? YES: NO) 
                                               startLineIndentation:cellData.startIndent];
}

- (FSQCollectionViewAlignedLayoutSectionAttributes *)collectionView:(UICollectionView *)collectionView 
                                                             layout:(FSQCollectionViewAlignedLayout *)collectionViewLayout 
                                        attributesForSectionAtIndex:(NSInteger)sectionIndex {
    FSQExampleSectionData *sectionData = self.sectionData[sectionIndex];
    
    return [FSQCollectionViewAlignedLayoutSectionAttributes withHorizontalAlignment:sectionData.hAlignment 
                                                                  verticalAlignment:FSQCollectionViewVerticalAlignmentTop
                                                                        itemSpacing:5.0
                                                                        lineSpacing:5.0
                                                                             insets:UIEdgeInsetsMake(5.0, 5.0, 5.0, 5.0)];
}

- (CGSize)collectionView:(UICollectionView *)collectionView 
                  layout:(FSQCollectionViewAlignedLayout *)collectionViewLayout 
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath 
      remainingLineSpace:(CGFloat)remainingLineSpace {
    FSQExampleCellData *cellData = [(FSQExampleSectionData *)self.sectionData[indexPath.section] cellData][indexPath.item];
    if (cellData.text) {
        CGSize size = CGRectIntegral([cellData.text boundingRectWithSize:CGSizeMake(remainingLineSpace, CGFLOAT_MAX)
                                                                 options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingTruncatesLastVisibleLine)
                                                              attributes:@{ NSFontAttributeName: kMainFont } 
                                                                 context:nil]).size;
        size.width = MIN(remainingLineSpace, size.width);
        return size;
    }
    else {
        return CGSizeMake(25, 25);
    }
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return self.sectionData.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView 
     numberOfItemsInSection:(NSInteger)section {
    return [(FSQExampleSectionData *)self.sectionData[section] cellData].count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView 
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    FSQExampleCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    FSQExampleCellData *cellData = [(FSQExampleSectionData *)self.sectionData[indexPath.section] cellData][indexPath.item];
    cell.label.text = cellData.text;
    cell.backgroundColor = cellData.backgroundColor;
    
    return cell;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceHeightForHeaderInSection:(NSInteger)section {
    FSQExampleSectionData *sectionData = self.sectionData[section];
    return (sectionData.headerString.length > 0) ? 30.0f : 0.0f;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *view = nil;
    if (kind == UICollectionElementKindSectionHeader) {
        FSQExampleSectionData *sectionData = self.sectionData[indexPath.section];
        FSQExampleHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"header" forIndexPath:indexPath];
        headerView.label.text = sectionData.headerString;
        view = headerView;
    }
    return view;
}

- (NSArray *)generateExampleData {
    // First section
    FSQExampleSectionData *sectionOne = [FSQExampleSectionData new];
    sectionOne.hAlignment = FSQCollectionViewHorizontalAlignmentCenter;
    
    FSQExampleCellData *sectionOneCellOne = [FSQExampleCellData new];
    sectionOneCellOne.text = @"Tuesday, June 2nd";
    sectionOne.cellData = @[sectionOneCellOne];
    
    // Second section
    FSQExampleSectionData *sectionTwo = [FSQExampleSectionData new];
    sectionTwo.hAlignment = FSQCollectionViewHorizontalAlignmentLeft;
    sectionTwo.headerString = @"Paul";
    
    FSQExampleCellData *sectionTwoAvatarCell = [FSQExampleCellData new];
    sectionTwoAvatarCell.backgroundColor = [UIColor redColor];
    
    NSMutableArray *sectionTwoCells = [NSMutableArray arrayWithObject:sectionTwoAvatarCell];
    
    for (NSString *string in @[@"I must not fear.",
                               @"Fear is the mind-killer.",
                               @"Fear is the little-death that brings total obliteration."]) {
        FSQExampleCellData *cell = [FSQExampleCellData new];
        cell.text = string;
        cell.backgroundColor = [UIColor cyanColor];
        [sectionTwoCells addObject:cell];
    }
    
    [(FSQExampleCellData *)[sectionTwoCells objectAtIndex:1] setStartIndent:YES];
    sectionTwo.cellData = sectionTwoCells;
    
    
    // Third Section
    FSQExampleSectionData *sectionThree = [FSQExampleSectionData new];
    sectionThree.hAlignment = FSQCollectionViewHorizontalAlignmentLeft;
    sectionThree.headerString = @"Jessica";
    
    FSQExampleCellData *sectionThreeAvatarCell = [FSQExampleCellData new];
    sectionThreeAvatarCell.backgroundColor = [UIColor blueColor];
    
    FSQExampleCellData *sectionThreeTextCell = [FSQExampleCellData new];
    sectionThreeTextCell.text = @"I will face my fear."
    @"I will permit it to pass over me and through me."
    @"And when it has gone past I will turn the inner eye to see its path."
    @"Where the fear has gone there will be nothing....only I will remain";
    sectionThreeTextCell.backgroundColor = [UIColor greenColor];
    
    sectionThree.cellData = @[sectionThreeAvatarCell, sectionThreeTextCell];
    
    
    return @[sectionOne, sectionTwo, sectionThree];
}
@end

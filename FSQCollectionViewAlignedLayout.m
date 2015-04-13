//
//  FSQCollectionViewAlignedLayout.m
//
//  Copyright (c) 2014 foursquare. All rights reserved.
//

#import "FSQCollectionViewAlignedLayout.h"

// Helper functions for common inset operations

CGFloat UIEdgeInsetsHorizontalInset_fsq(UIEdgeInsets insets) {
    return insets.left + insets.right;
}

CGFloat UIEdgeInsetsVerticalInset_fsq(UIEdgeInsets insets) {
    return insets.top + insets.bottom;
}

/**
 The layout has an array of these section data objects which it generates in prepareLayout using the section and cell attributes objects/delegate methods
 
 These store the the bounding box of each section and the layout attributes of each cell in that section.
 These are used in layoutAttributesForElementsInRect and layoutAttributesForItemAtIndexPath to provide the location of each cell.
 
 Note that all the cell frames are stored relative to the origin of the entire collection view frame, and not relative to the section's frame.
 */
@interface FSQCollectionViewAlignedLayoutSectionData : NSObject <NSFastEnumeration>

/// Bounding box for the section. Used in layoutAttributesForElementsInRect calculation
@property (nonatomic) CGRect sectionRect;

@property (nonatomic) UICollectionViewLayoutAttributes *headerAttributes;

/// Array of FSQCollectionViewAlignedLayoutCellData for each cell (including frame). Passed to collection view in delegate methods.
@property (nonatomic) NSMutableArray *cellsData;

/// For easy/typed access to the cellAttributes
- (UICollectionViewLayoutAttributes *)objectAtIndexedSubscript:(NSUInteger)index;
- (void)setObject:(UICollectionViewLayoutAttributes *)attributes atIndexedSubscript:(NSUInteger)index;
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])buffer count:(NSUInteger)len;
@end

@implementation FSQCollectionViewAlignedLayoutSectionData

- (id)initWithCapacity:(NSUInteger)capacity {
    if ((self = [super init])) {
        self.cellsData = [[NSMutableArray alloc] initWithCapacity:capacity];
        self.sectionRect = CGRectNull;
    }
    return self;
}

- (UICollectionViewLayoutAttributes *)objectAtIndexedSubscript:(NSUInteger)index {
    if (index < self.cellsData.count) {
        return [self.cellsData objectAtIndex:index];
    }
    else {
        return nil;
    }
}

- (void)setObject:(UICollectionViewLayoutAttributes *)attributes atIndexedSubscript:(NSUInteger)index {
    self.cellsData[index] = attributes;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len {
    return [self.cellsData countByEnumeratingWithState:state objects:buffer count:len];
}

@end

@implementation FSQCollectionViewAlignedLayoutInvalidationContext

- (instancetype)init {
    if ((self = [super init])) {
        self.invalidateAlignedLayoutAttributes = YES;
    }
    return self;
}

@end

@interface FSQCollectionViewAlignedLayout()

/// Just casts collectionview.delegate to the correct type for simplicity
@property (readonly) id<FSQCollectionViewDelegateAlignedLayout> delegate;

/// array of LayoutSectionData objects (see above)
@property (nonatomic) NSMutableArray *sectionsData;

/// Total content size of all sections. Calculated in prepareLayout
@property (nonatomic) CGSize totalContentSize;

/// For easy/typed access to the section data objects
- (FSQCollectionViewAlignedLayoutSectionData *)objectAtIndexedSubscript:(NSUInteger)index;
- (void)setObject:(FSQCollectionViewAlignedLayoutSectionData *)sectionData atIndexedSubscript:(NSUInteger)index;
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])buffer count:(NSUInteger)len;
@end

@implementation FSQCollectionViewAlignedLayout

#pragma mark - Initialization -

- (id)init {
    if ((self = [super init])) {
        [self setupDefaults];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        [self setupDefaults];
    }
    return self;
}

- (void)setupDefaults {
    self.defaultSectionAttributes = [FSQCollectionViewAlignedLayoutSectionAttributes topLeftAlignment];
    self.defaultCellAttributes = [FSQCollectionViewAlignedLayoutCellAttributes defaultCellAttributes];
    self.totalContentSize = CGSizeZero;
    self.sectionSpacing = 10.f;
    self.contentInsets = UIEdgeInsetsMake(5., 5., 5., 5.);
    self.shouldPinSectionHeadersToTop = YES;
}

#pragma mark - Layout calculation -

- (void)prepareLayout {
    [super prepareLayout];
    
    CGSize totalSizeOfContent = CGSizeMake(CGRectGetWidth(self.collectionView.frame), self.contentInsets.top);
    
    if (self.sectionsData == nil || self.totalContentSize.width != totalSizeOfContent.width) {
        const CGFloat maxCollectionViewWidth = totalSizeOfContent.width - UIEdgeInsetsHorizontalInset_fsq(self.contentInsets);
        NSUInteger numberOfSections = self.collectionView.numberOfSections;
        
        self.sectionsData = (numberOfSections > 0) ? [NSMutableArray arrayWithCapacity:numberOfSections] : nil;
        
        for (NSUInteger sectionIndex = 0; sectionIndex < numberOfSections; sectionIndex++) {
            if (sectionIndex > 0) {
                totalSizeOfContent.height += self.sectionSpacing;
            }
            
            NSUInteger numberOfCellsInSection = [self.collectionView numberOfItemsInSection:sectionIndex];
            
            FSQCollectionViewAlignedLayoutSectionData *sectionData = [[FSQCollectionViewAlignedLayoutSectionData alloc] initWithCapacity:numberOfCellsInSection];
            
            FSQCollectionViewAlignedLayoutSectionAttributes *sectionAttributes = [self attributesForSectionAtIndex:sectionIndex];
            
            /*
             First we check if we need to finish the line we're currently working on by checking various states and the size of what we're adding
             Then if we have more things to add we add them (possibly on a new line depending on previous step)
             
             As we add things we store their rects relative to the origin point of the current line.
             When we finish the line we calculate its total size and align/position it properly relative to collection view origin,
             then we go back and move all the cell origins on that line to be relative to the collection view origin.
             
             We do the for loop one more time than the actual number of cells.
             On the last loop we simply finish off the current line if necessary and do not actually add anything.
             */
            CGFloat maxLineWidth = maxCollectionViewWidth - UIEdgeInsetsHorizontalInset_fsq(sectionAttributes.insets);
            CGFloat remainingLineWidth = maxLineWidth;
            NSUInteger startOfLineIndex = 0;
            CGSize totalSizeOfLine = CGSizeMake(0, 0);
            CGSize totalSizeOfSection = CGSizeMake(0, 0);
            CGFloat leftEdgeOfSection = remainingLineWidth;
            NSNumber *lineIndentationIndex = nil;
            CGFloat lineIndentation = 0;
            
            CGFloat headerHeight = [self heightForHeaderInSection:sectionIndex];
            if (headerHeight > 0.0f) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:sectionIndex];
                UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader withIndexPath:indexPath];
                attributes.frame = CGRectMake(0.0f, totalSizeOfContent.height, totalSizeOfContent.width, headerHeight);
                sectionData.headerAttributes = attributes;
                totalSizeOfSection.width = totalSizeOfContent.width;
                totalSizeOfSection.height += headerHeight;
            }
            
            BOOL hasContent = (numberOfCellsInSection != 0);
            if (hasContent) {
                totalSizeOfSection.height += sectionAttributes.insets.top;
            }
            
            BOOL insertLineBreak = NO;
            for (NSUInteger cellIndex = 0; cellIndex < numberOfCellsInSection + 1; cellIndex++) {
                NSIndexPath *indexPath = nil;
                FSQCollectionViewAlignedLayoutCellAttributes *cellAttributes = nil;
                CGSize cellSize = CGSizeZero;
                CGFloat widthToBeAdded = 0;
                BOOL validHorizontalCellToCellAlignment = NO;
                
                BOOL finishCurrentLine = NO;
                BOOL gotCellSize = NO;
                if (cellIndex >= numberOfCellsInSection) {
                    finishCurrentLine = YES;
                    gotCellSize = YES;
                }
                else {
                    indexPath = [NSIndexPath indexPathForItem:cellIndex inSection:sectionIndex];
                    cellAttributes = [self attributesForCellAtIndexPath:indexPath];
                    CGFloat cellHorizontalInsets = UIEdgeInsetsHorizontalInset_fsq(cellAttributes.insets);
                    
                    if (cellIndex != startOfLineIndex
                        && (insertLineBreak
                            || cellAttributes.shouldBeginLine
                            || cellHorizontalInsets > remainingLineWidth)) {
                            // this needs to go on a new line
                            // finish off the current line first
                            finishCurrentLine = YES;
                        }
                }
                
                
                
                // May need to end the current line both before and after asking for size
                // Loop it until both scenarios are accounted for
                
                while (!gotCellSize || finishCurrentLine) {
                    if (finishCurrentLine) {
                        totalSizeOfLine.width = maxLineWidth - remainingLineWidth;
                        if (startOfLineIndex > 0) {
                            totalSizeOfSection.height += sectionAttributes.lineSpacing;
                        }
                        
                        // Need to get the frame before we adjust everything, but dont actually change things until we reset for the next line
                        if (lineIndentationIndex != nil) {
                            // Temporarily reuse this NSNumber to mean a different thing because we can't actually change lineIndentation yet
                            if (sectionAttributes.horizontalAlignment == FSQCollectionViewHorizontalAlignmentLeft) {
                                lineIndentationIndex = @(CGRectGetMinX(sectionData[[lineIndentationIndex unsignedIntegerValue]].frame));
                            }
                            else if (sectionAttributes.horizontalAlignment == FSQCollectionViewHorizontalAlignmentRight) {
                                lineIndentationIndex = @(totalSizeOfLine.width - CGRectGetMaxX(sectionData[[lineIndentationIndex unsignedIntegerValue]].frame));
                            }
                        }
                        
                        CGRect lineFrame = CGRectMake(self.contentInsets.left + sectionAttributes.insets.left,
                                                      totalSizeOfSection.height + totalSizeOfContent.height,
                                                      totalSizeOfLine.width,
                                                      totalSizeOfLine.height);
                        switch (sectionAttributes.horizontalAlignment) {
                            case FSQCollectionViewHorizontalAlignmentRight:
                                lineFrame.origin.x += remainingLineWidth;
                                break;
                            case FSQCollectionViewHorizontalAlignmentCenter:
                                lineFrame.origin.x += floorf(remainingLineWidth / 2.);
                                break;
                            case FSQCollectionViewHorizontalAlignmentLeft:
                                lineFrame.origin.x += lineIndentation;
                                break;
                            default:
                                NSAssert(0, @"FSQCollectionViewAlignedLayout: Unexpected value (%ld) for section (%lu) horizontal alignment", (long)sectionAttributes.horizontalAlignment, (unsigned long)sectionIndex);
                                break;
                        }
                        
                        // Ok we figured out where the line is in our view. Now go back and update the line's cell attributes so their frames are correct
                        for (NSUInteger cellOnThisLineIndex = startOfLineIndex; cellOnThisLineIndex < cellIndex; cellOnThisLineIndex++) {
                            CGRect cellFrame = sectionData[cellOnThisLineIndex].frame;
                            cellFrame.origin.x += CGRectGetMinX(lineFrame);
                            cellFrame.origin.y += CGRectGetMinY(lineFrame);
                            switch (sectionAttributes.verticalAlignment) {
                                case FSQCollectionViewVerticalAlignmentBottom:
                                    cellFrame.origin.y += (totalSizeOfLine.height - CGRectGetHeight(cellFrame));
                                    break;
                                case FSQCollectionViewVerticalAlignmentCenter:
                                    cellFrame.origin.y += (totalSizeOfLine.height - CGRectGetHeight(cellFrame)) / 2.;
                                    break;
                                case FSQCollectionViewVerticalAlignmentTop:
                                    // It's already aligned top. Do nothing
                                    break;
                                default:
                                    NSAssert(0, @"FSQCollectionViewAlignedLayout: Unexpected value (%ld) for section (%lu) vertical alignment", (long)sectionAttributes.verticalAlignment, (unsigned long)sectionIndex);
                                    break;
                            }
                            sectionData[cellOnThisLineIndex].frame = cellFrame;
                        }
                        
                        if (CGRectGetWidth(lineFrame) > totalSizeOfSection.width) {
                            totalSizeOfSection.width = CGRectGetWidth(lineFrame);
                        }
                        
                        if (CGRectGetMinX(lineFrame) < leftEdgeOfSection) {
                            leftEdgeOfSection = CGRectGetMinX(lineFrame);
                        }
                        
                        // Start a new line
                        if (lineIndentationIndex != nil) {
                            lineIndentation = [lineIndentationIndex doubleValue];
                            maxLineWidth -= lineIndentation;
                            lineIndentationIndex = nil;
                        }
                        
                        startOfLineIndex = cellIndex;
                        remainingLineWidth = maxLineWidth;
                        totalSizeOfSection.height += totalSizeOfLine.height;
                        totalSizeOfLine = CGSizeMake(0, 0);
                        finishCurrentLine = NO;
                    }
                    
                    if (!gotCellSize) {
                        // If previous line needed to be ended, that is done now
                        // We can now safely ask for cell size and remainingLineSpace will be correct
                        
                        CGFloat lineWidthToReport = (cellIndex > startOfLineIndex) ? (remainingLineWidth - sectionAttributes.itemSpacing) : remainingLineWidth;
                        CGFloat cellHorizontalInsets = UIEdgeInsetsHorizontalInset_fsq(cellAttributes.insets);
                        lineWidthToReport -= cellHorizontalInsets;
                        cellSize = [self sizeForCellAtIndexPath:indexPath remainingLineSpace:lineWidthToReport];
                        gotCellSize = YES;
                        widthToBeAdded = (cellSize.width + cellHorizontalInsets);
                        
                        if (cellIndex > startOfLineIndex) {
                            widthToBeAdded += sectionAttributes.itemSpacing;
                        }
                        
                        if (cellIndex != startOfLineIndex
                            && (widthToBeAdded > remainingLineWidth)) {
                            // this needs to go on a new line
                            // finish off the current line first
                            finishCurrentLine = YES;
                        }
                    }
                    
                }
                
                if (cellAttributes) {
                    // Add to this line!
                    UIEdgeInsets cellInsets = cellAttributes.insets;
                    
                    CGRect layoutRectRelativeToLineOrigin = CGRectMake((maxLineWidth - remainingLineWidth),
                                                                       0,
                                                                       cellSize.width  + UIEdgeInsetsHorizontalInset_fsq(cellAttributes.insets),
                                                                       cellSize.height + UIEdgeInsetsVerticalInset_fsq(cellAttributes.insets));
                    
                    if (startOfLineIndex != cellIndex) {
                        layoutRectRelativeToLineOrigin.origin.x += sectionAttributes.itemSpacing;
                    }
                    
                    
                    UICollectionViewLayoutAttributes *itemAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
                    itemAttributes.frame =  UIEdgeInsetsInsetRect(layoutRectRelativeToLineOrigin, cellAttributes.insets);
                    
                    
                    if (cellAttributes.startLineIndentation
                        && (sectionAttributes.horizontalAlignment == FSQCollectionViewHorizontalAlignmentLeft
                            || sectionAttributes.horizontalAlignment == FSQCollectionViewHorizontalAlignmentRight)) {
                            lineIndentationIndex = @(cellIndex);
                        }
                    
                    [sectionData.cellsData addObject:itemAttributes];
                    if (CGRectGetHeight(layoutRectRelativeToLineOrigin) > totalSizeOfLine.height) {
                        totalSizeOfLine.height = cellSize.height + UIEdgeInsetsVerticalInset_fsq(cellInsets);
                    }
                    
                    remainingLineWidth = maxLineWidth - CGRectGetMaxX(layoutRectRelativeToLineOrigin);
                    insertLineBreak = cellAttributes.shouldEndLine || (validHorizontalCellToCellAlignment && sectionAttributes.horizontalAlignment == FSQCollectionViewHorizontalAlignmentRight);
                }
            }
            
            if (hasContent) {
                totalSizeOfSection.height += sectionAttributes.insets.bottom;
            }
            
            sectionData.sectionRect = CGRectMake(0.0,
                                                 totalSizeOfContent.height,
                                                 totalSizeOfContent.width,
                                                 totalSizeOfSection.height);
            [self.sectionsData addObject:sectionData];
            totalSizeOfContent.height += totalSizeOfSection.height;
        }
        
        if (totalSizeOfContent.height == self.contentInsets.top) {
            totalSizeOfContent.height = 0;
        }
        else {
            totalSizeOfContent.height += self.contentInsets.bottom;
        }
        
        self.totalContentSize = totalSizeOfContent;
    }
}

#pragma mark - Cells in Rect Calculations -

/**
 We often are asked to provide cells that are in a specified rect. To do this, we do a double binary search over all our sections
 to figure out which intersect the specified rect. We want to find both the lowest section that is in the rect and the highest.
 
 First in sectionRangeForRect we start with the midpoint of our sections and kick off two concurrent binary searches with GCD.
 One of them searches down for the lowest intersecting section and one which searches up for the highest intersecting section.
 We wait synchronously for both to complete.
 
 Once we have the range of rects to search through, we then iterate over every cell in those sections and do a CGRectIntersectsRect()
 test to build our array of cell attributes which are in the rect.
 
 Note that there are a few optimizations in layoutAttributesForElementsInRect: that sometimes allow us to intelligently short circuit
 this search and not do it for a few cases where we know one of the bounds.
 */

NSComparisonResult compareCGRectMinYIntersection(CGRect targetRect, CGRect comparisonRect) {
    // Target rect minY is either above, inside, or below us.
    if (CGRectGetMinY(targetRect) < CGRectGetMinY(comparisonRect)) {
        // Lower bound is above our rect
        return NSOrderedAscending;
    }
    else if (CGRectGetMinY(targetRect) > CGRectGetMaxY(comparisonRect)) {
        // Lower bound is below our rect
        return NSOrderedDescending;
    }
    else {
        // Lower bound is inside our rect
        return NSOrderedSame;
    }
}

NSComparisonResult compareCGRectMaxYIntersection(CGRect targetRect, CGRect comparisonRect) {
    // Target rect maxY is either above, inside, or below us.
    if (CGRectGetMaxY(targetRect) < CGRectGetMinY(comparisonRect)) {
        // Upper bound is above our rect
        return NSOrderedAscending;
    }
    else if (CGRectGetMaxY(targetRect) > CGRectGetMaxY(comparisonRect)) {
        // Upper bound is below our rect
        return NSOrderedDescending;
    }
    else {
        // Upper bound is inside our rect
        return NSOrderedSame;
    }
}

typedef NSComparisonResult (^SearchComparisonBlock)(NSUInteger currentSearchIndex);

NSUInteger boundIndexWithComparisonBlock(SearchComparisonBlock comparisonBlock, NSUInteger minSearchIndex, NSUInteger maxSearchIndex) {
    if (minSearchIndex == maxSearchIndex) {
        return minSearchIndex;
    }
    NSUInteger currentSearchSectionIndex = minSearchIndex + ((maxSearchIndex - minSearchIndex) / 2);
    NSComparisonResult comparisonResult = comparisonBlock(currentSearchSectionIndex);
    switch (comparisonResult) {
        case NSOrderedAscending:
            if (currentSearchSectionIndex == minSearchIndex) {
                return currentSearchSectionIndex;
            }
            else {
                return boundIndexWithComparisonBlock(comparisonBlock, minSearchIndex, (currentSearchSectionIndex - 1));
            }
        case NSOrderedDescending:
            if (currentSearchSectionIndex == maxSearchIndex) {
                return currentSearchSectionIndex;
            }
            else {
                return boundIndexWithComparisonBlock(comparisonBlock, (currentSearchSectionIndex + 1), maxSearchIndex);
            }
        case NSOrderedSame:
            // Inside this section
            return currentSearchSectionIndex;
        default:
            NSCAssert(0, @"FSQCollectionViewAlignedLayout: Unexpected value (%ld) in boundIndexWithComparisonBlock comparison result", (long)comparisonResult);
            return 0;
    }
}

- (NSRange)sectionRangeForRect:(CGRect)targetRect minSearchIndex:(NSUInteger)minSearchIndex maxSearchIndex:(NSUInteger)maxSearchIndex {
    if (minSearchIndex == maxSearchIndex) {
        return NSMakeRange(minSearchIndex, 1);
    }
    
    // Concurrently seach for upper and lower bound!
    __block NSUInteger lowerBoundIndex = 0;
    __block NSUInteger upperBoundIndex = 0;
    
    dispatch_group_t searchGroup = dispatch_group_create();
    dispatch_queue_t searchQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_CONCURRENT);
    dispatch_group_async(searchGroup, searchQueue, ^{
        lowerBoundIndex = boundIndexWithComparisonBlock(^NSComparisonResult(NSUInteger currentSearchIndex) {
            return compareCGRectMinYIntersection(targetRect, self[currentSearchIndex].sectionRect);
        }, minSearchIndex, maxSearchIndex);
    });
    dispatch_group_async(searchGroup, searchQueue, ^{
        upperBoundIndex = boundIndexWithComparisonBlock(^NSComparisonResult(NSUInteger currentSearchIndex) {
            return compareCGRectMaxYIntersection(targetRect, self[currentSearchIndex].sectionRect);
        }, minSearchIndex, maxSearchIndex);
    });
    dispatch_group_wait(searchGroup, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 1));
    
    lowerBoundIndex = MAX(minSearchIndex, lowerBoundIndex);
    upperBoundIndex = MIN(maxSearchIndex, upperBoundIndex);
    
    return NSMakeRange(lowerBoundIndex, (upperBoundIndex - lowerBoundIndex) + 1);
    
}

#pragma mark - UICollectionViewLayout Overrides -

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)targetRect {
    NSMutableArray *matchingLayoutAttributes = [NSMutableArray new];
    
    CGRect contentRect = CGRectMake(0, 0, _totalContentSize.width, _totalContentSize.height);
    
    void (^addSectionDataLayoutAttributes)(FSQCollectionViewAlignedLayoutSectionData *, NSInteger) = ^(FSQCollectionViewAlignedLayoutSectionData *sectionData, NSInteger index) {
        UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader atIndexPath:[NSIndexPath indexPathForItem:0 inSection:index]];
        if (attributes) {
            [matchingLayoutAttributes addObject:attributes];
        }
        
        for (UICollectionViewLayoutAttributes *cellAttributes in sectionData) {
            if (CGRectIntersectsRect(targetRect, cellAttributes.frame)) {
                [matchingLayoutAttributes addObject:[cellAttributes copy]];
            }
        }
    };
    
    void (^addLayoutAttributes)(BOOL, BOOL (^)(FSQCollectionViewAlignedLayoutSectionData *)) = ^(BOOL reverse, BOOL (^breakCondition)(FSQCollectionViewAlignedLayoutSectionData *)) {
        NSEnumerationOptions options = (reverse) ? NSEnumerationReverse : 0;
        [self.sectionsData enumerateObjectsWithOptions:options usingBlock:^(FSQCollectionViewAlignedLayoutSectionData *sectionData, NSUInteger idx, BOOL *stop) {
            if (breakCondition && breakCondition(sectionData)) {
                *stop = YES;
                return;
            }
            
            addSectionDataLayoutAttributes(sectionData, idx);
        }];
    };
    
    if (!CGRectIntersectsRect(targetRect, contentRect)) {
        // Outside our bounds, so return nil!
        return nil;
    }
    else if (CGRectContainsRect(targetRect, contentRect)) {
        // Just return everything!
        addLayoutAttributes(NO, nil);
    }
    else if (CGRectGetMinY(targetRect) <= 0.) {
        // Just start at the beginning and go up until it doesn't intersect
        addLayoutAttributes(NO, ^BOOL (FSQCollectionViewAlignedLayoutSectionData *sectionData) {
            return !CGRectIntersectsRect(targetRect, sectionData.sectionRect);
        });
    }
    else if (CGRectGetMaxY(targetRect) >= _totalContentSize.height) {
        // Just start at the end and go down until it doenst intersect
        addLayoutAttributes(YES, ^BOOL (FSQCollectionViewAlignedLayoutSectionData *sectionData) {
            return !CGRectIntersectsRect(targetRect, sectionData.sectionRect);
        });
    }
    else {
        // Do a double binary search to figure out the range of sections that intersect the rect
        NSRange sectionRange = [self sectionRangeForRect:targetRect minSearchIndex:0 maxSearchIndex:(self.sectionsData.count - 1)];
        
        if ([self.sectionsData count] > 0) {
            [self.sectionsData enumerateObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:sectionRange] options:0 usingBlock:^(FSQCollectionViewAlignedLayoutSectionData *sectionData, NSUInteger idx, BOOL *stop) {
                addSectionDataLayoutAttributes(sectionData, idx);
            }];
        }
    }
    
    return matchingLayoutAttributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self[indexPath.section][indexPath.item] copy];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attributes = nil;
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        FSQCollectionViewAlignedLayoutSectionData *sectionData = self.sectionsData[indexPath.section];
        if (sectionData.headerAttributes) {
            attributes = [sectionData.headerAttributes copy];
            
            if (self.shouldPinSectionHeadersToTop) {
                NSInteger section = indexPath.section;
                NSInteger numberOfItemsInSection = [self.collectionView numberOfItemsInSection:section];
                
                NSIndexPath *firstCellIndexPath = [NSIndexPath indexPathForItem:0 inSection:section];
                NSIndexPath *lastCellIndexPath = [NSIndexPath indexPathForItem:MAX(0, (numberOfItemsInSection - 1)) inSection:section];
                
                UICollectionViewLayoutAttributes *firstCellAttributes = [self layoutAttributesForItemAtIndexPath:firstCellIndexPath];
                UICollectionViewLayoutAttributes *lastCellAttributes = [self layoutAttributesForItemAtIndexPath:lastCellIndexPath];
                
                if (firstCellAttributes && lastCellAttributes) {
                    CGFloat headerHeight = attributes.frame.size.height;
                    CGFloat minY = CGRectGetMinY(sectionData.sectionRect);
                    CGFloat maxY = CGRectGetMaxY(sectionData.sectionRect) - headerHeight;
                    CGFloat yOffset = MIN(MAX(self.collectionView.contentOffset.y + self.collectionView.contentInset.top, minY), maxY);
                    attributes.frame = CGRectMake(0.0f, yOffset, self.collectionViewContentSize.width, headerHeight);
                    attributes.zIndex = NSIntegerMax;
                }
            }
        }
    }
    return attributes;
}

- (CGSize)collectionViewContentSize {
    return self.totalContentSize;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return YES;
}

- (FSQCollectionViewAlignedLayoutInvalidationContext *)invalidationContextForBoundsChange:(CGRect)newBounds {
    FSQCollectionViewAlignedLayoutInvalidationContext *context = (FSQCollectionViewAlignedLayoutInvalidationContext *)[super invalidationContextForBoundsChange:newBounds];
    if (newBounds.size.width == self.collectionViewContentSize.width) {
        context.invalidateAlignedLayoutAttributes = NO;
    }
    return context;
}

+ (Class)invalidationContextClass {
    return [FSQCollectionViewAlignedLayoutInvalidationContext class];
}

- (void)invalidateLayoutWithContext:(FSQCollectionViewAlignedLayoutInvalidationContext *)context {
    [super invalidateLayoutWithContext:context];
    if (context.invalidateAlignedLayoutAttributes) {
        self.sectionsData = nil;
    }
}

#pragma mark - Delegate Helpers -

- (CGSize)sizeForCellAtIndexPath:(NSIndexPath *)indexPath remainingLineSpace:(CGFloat)remainingLineSpace {
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:sizeForItemAtIndexPath:remainingLineSpace:)]) {
        return [self.delegate collectionView:self.collectionView layout:self sizeForItemAtIndexPath:indexPath remainingLineSpace:remainingLineSpace];
    }
    else {
        return self.defaultCellSize;
    }
}

- (CGFloat)heightForHeaderInSection:(CGFloat)section {
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:referenceHeightForHeaderInSection:)]) {
        return [self.delegate collectionView:self.collectionView layout:self referenceHeightForHeaderInSection:section];
    }
    else {
        return 0.0f;
    }
}

- (FSQCollectionViewAlignedLayoutSectionAttributes *)attributesForSectionAtIndex:(NSInteger)sectionIndex {
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:attributesForSectionAtIndex:)]) {
        return [self.delegate collectionView:self.collectionView layout:self attributesForSectionAtIndex:sectionIndex];
    }
    else {
        return self.defaultSectionAttributes;
    }
}

- (FSQCollectionViewAlignedLayoutCellAttributes *)attributesForCellAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:attributesForCellAtIndexPath:)]) {
        return [self.delegate collectionView:self.collectionView layout:self attributesForCellAtIndexPath:indexPath];
    }
    else {
        return self.defaultCellAttributes;
    }
}

- (id<FSQCollectionViewDelegateAlignedLayout>)delegate {
    return (id<FSQCollectionViewDelegateAlignedLayout>) self.collectionView.delegate;
}

#pragma mark - Enumeration helpers -

- (FSQCollectionViewAlignedLayoutSectionData *)objectAtIndexedSubscript:(NSUInteger)index {
    return [self.sectionsData objectAtIndexedSubscript:index];
}

- (void)setObject:(FSQCollectionViewAlignedLayoutSectionData *)sectionData atIndexedSubscript:(NSUInteger)index {
    self.sectionsData[index] = sectionData;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len {
    return [self.sectionsData countByEnumeratingWithState:state objects:buffer count:len];
}

#pragma mark - Layout information helpers - 

- (CGRect)contentFrameForSection:(NSInteger)section {
    return (section < self.sectionsData.count) ? [self.sectionsData[section] sectionRect] : CGRectZero;
}

@end

@implementation FSQCollectionViewAlignedLayoutSectionAttributes

#define DEC_SHARED_ALIGNMENT(_name, _hAlign, _vAlign) \
+ (FSQCollectionViewAlignedLayoutSectionAttributes *)_name { \
static FSQCollectionViewAlignedLayoutSectionAttributes *shared##_name = nil; \
static dispatch_once_t onceToken; \
dispatch_once(&onceToken, ^{ shared##_name = [FSQCollectionViewAlignedLayoutSectionAttributes withHorizontalAlignment:_hAlign verticalAlignment:_vAlign]; }); \
return shared##_name; \
}

DEC_SHARED_ALIGNMENT(topLeftAlignment, FSQCollectionViewHorizontalAlignmentLeft, FSQCollectionViewVerticalAlignmentTop);
DEC_SHARED_ALIGNMENT(topRightAlignment, FSQCollectionViewHorizontalAlignmentRight, FSQCollectionViewVerticalAlignmentTop);
DEC_SHARED_ALIGNMENT(topCenterAlignment, FSQCollectionViewHorizontalAlignmentCenter, FSQCollectionViewVerticalAlignmentTop);
DEC_SHARED_ALIGNMENT(centerCenterAlignment, FSQCollectionViewHorizontalAlignmentCenter, FSQCollectionViewVerticalAlignmentCenter);

+ (instancetype)withHorizontalAlignment:(FSQCollectionViewHorizontalAlignment)horizontalAlignment verticalAlignment:(FSQCollectionViewVerticalAlignment)verticalAlignment {
    return [self withHorizontalAlignment:horizontalAlignment verticalAlignment:verticalAlignment itemSpacing:5. lineSpacing:5. insets:UIEdgeInsetsZero];
}

+ (instancetype)withHorizontalAlignment:(FSQCollectionViewHorizontalAlignment)horizontalAlignment verticalAlignment:(FSQCollectionViewVerticalAlignment)verticalAlignment itemSpacing:(CGFloat)itemSpacing lineSpacing:(CGFloat)lineSpacing insets:(UIEdgeInsets)insets{
    return [[self alloc] initWithHorizontalAlignment:horizontalAlignment verticalAlignment:verticalAlignment itemSpacing:itemSpacing lineSpacing:lineSpacing insets:insets];
}

- (instancetype)initWithHorizontalAlignment:(FSQCollectionViewHorizontalAlignment)horizontalAlignment verticalAlignment:(FSQCollectionViewVerticalAlignment)verticalAlignment itemSpacing:(CGFloat)itemSpacing lineSpacing:(CGFloat)lineSpacing insets:(UIEdgeInsets)insets{
    if ((self = [super init])) {
        _horizontalAlignment = horizontalAlignment;
        _verticalAlignment = verticalAlignment;
        _itemSpacing = itemSpacing;
        _lineSpacing = lineSpacing;
        _insets = insets;
    }
    return self;
}

@end


@implementation FSQCollectionViewAlignedLayoutCellAttributes

+ (FSQCollectionViewAlignedLayoutCellAttributes *)defaultCellAttributes {
    static FSQCollectionViewAlignedLayoutCellAttributes *sharedDefaultCellAttributes = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ sharedDefaultCellAttributes = [FSQCollectionViewAlignedLayoutCellAttributes withInsets:UIEdgeInsetsZero
                                                                                                        shouldBeginLine:NO
                                                                                                          shouldEndLine:NO
                                                                                                   startLineIndentation:NO];});
    return sharedDefaultCellAttributes;
}

+ (instancetype)withInsets:(UIEdgeInsets)insets shouldBeginLine:(BOOL)shouldBeginLine shouldEndLine:(BOOL)shouldEndLine startLineIndentation:(BOOL)startLineIndentation {
    return [[self alloc] initWithInsets:insets shouldBeginLine:shouldBeginLine shouldEndLine:shouldEndLine startLineIndentation:startLineIndentation];
}

- (instancetype)initWithInsets:(UIEdgeInsets)insets shouldBeginLine:(BOOL)shouldBeginLine shouldEndLine:(BOOL)shouldEndLine startLineIndentation:(BOOL)startLineIndentation {
    if ((self = [super init])) {
        _insets = insets;
        _shouldBeginLine = shouldBeginLine;
        _shouldEndLine = shouldEndLine;
        _startLineIndentation = startLineIndentation;
    }
    return self;
}

@end

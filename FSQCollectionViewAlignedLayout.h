//
//  FSQCollectionViewAlignedLayout.h
//
//  Copyright (c) 2014 foursquare. All rights reserved.
//

/**
 Overview:
 
 FSQCollectionViewAlignedLayout lays out collection view cells sort of like how a type setter would draw out a string,
 but with collection cells instead of font glyphs. Each section can have both a vertical and horizontal alignment
 (horizontal aligns each line relative to the whole section, vertical aligns the items within each line if they are
 different heights). It also allows you to specify distance between items in each section and between lines.
 
 Each cell can have not only a size, but insets. You can also tell it to insert "line breaks" before or
 after each cell to get things to wrap how you want.
 
 You can set defaults for section and cell styles just like you can in Flow Layout. Or you can implement delegate methods:
 
 - (FSQCollectionViewAlignedLayoutSectionAttributes*)collectionView:layout:attributesForSectionAtIndex:
 
 To return section layout information for the specified index.
 
 - (FSQCollectionViewAlignedLayoutCellAttributes*)collectionView:layout:attributesForCellAtIndexPath:
 
 To return cell layout information for the specified indexPath.
 
 - (CGSize)collectionView:layout:sizeForItemAtIndexPath:remainingLineSpace:
 
 To return the size of each cell. It passes in the remaining space on the current line, the returned size must be
 no larger than remainingLineSpace if you want it to stay on the current line (you can use this to "fill" the
 rest of the line up, which is often useful for string and image sizing purposes).
 
 Note: This layout currently only supports laying out views vertically (with a fixed collection view width).
 
 */

#import <UIKit/UIKit.h>

@class FSQCollectionViewAlignedLayoutSectionAttributes, FSQCollectionViewAlignedLayoutCellAttributes;

@interface FSQCollectionViewAlignedLayoutInvalidationContext : UICollectionViewLayoutInvalidationContext

@property (nonatomic) BOOL invalidateAlignedLayoutAttributes; // if set to NO, aligned layout will keep all layout information, effectively not invalidating - useful for a subclass which invalidates only a piece of itself

@end

@interface FSQCollectionViewAlignedLayout : UICollectionViewLayout <NSFastEnumeration>

/**
 Used if sizeForItemAtIndexPath delegate method is not implemented.
 
 Defaults to 100x100 cells if not set.
 */
@property (nonatomic) IBInspectable CGSize defaultCellSize;

/**
 Used if attributesForSectionAtIndex delegate method is not implemented
 
 Defaults to [FSQCollectionViewAlignedLayoutSectionAttributes topLeftAlignment] if not set.
 */
@property (nonatomic) FSQCollectionViewAlignedLayoutSectionAttributes *defaultSectionAttributes;

/**
 Used if attributesForCellAtIndexPaths delegate method is not implemented
 
 Defaults to [FSQCollectionViewAlignedLayoutCellAttributes defaultCellAttributes] if not set.
 */
@property (nonatomic) FSQCollectionViewAlignedLayoutCellAttributes *defaultCellAttributes;

/**
 Space in points between the bottom most part of a section and the top most part of the next one.
 
 Defaults to 10 if not set.
 */
@property (nonatomic) IBInspectable CGFloat sectionSpacing;

/**
 Insets in points around the entire contents of the collection. Defaults to (5, 5, 5, 5) if not set
 */
@property (nonatomic) UIEdgeInsets contentInsets;

/**
 Determines if the current section's header is pinned to the top of the collection view.
 
 Defaults to YES.
 
 @note This is similar to the behavior observed in UITableView's with the style UITableViewStylePlain.
 */
@property (nonatomic) BOOL shouldPinSectionHeadersToTop;

/**
 @param section The section of the collection view.
 
 @return The frame for the section, or CGRectZero if the section is out of range.
 */
- (CGRect)contentFrameForSection:(NSInteger)section;

@end


@protocol FSQCollectionViewDelegateAlignedLayout <UICollectionViewDelegate>

@optional
/**
 Used instead of defaultSize if implemented.
 
 @param collectionView       The collection view object displaying the layout.
 @param collectionViewLayout The layout object requesting the information.
 @param indexPath            The index path of the item.
 @param remainingLineSpace   The amount of space in pts remaining on the line the layout is currently laying out.
 
 @return The size the cell should be. If you return a size whose width is less than or equal to @c remainingLineSpace
 it will be laid out on the same lane.
 
 @note remainingLineSpace takes into account any insets that may exist for the current cell, subtracting the
 horizontal cell insets from the actual available space.
 */
- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(FSQCollectionViewAlignedLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
      remainingLineSpace:(CGFloat)remainingLineSpace;

/**
 Asks the delegate for the height of the header view in the specified section.
 If you do not implement this method, or the height returned is 0, no header is added.
 
 @param collectionView       The collection view object displaying the layout.
 @param collectionViewLayout The layout object requesting the information.
 @param section              The index of the section whose header size is being requested.
 
 @return The height of the header. If you return a value of 0, no header is added.
 */
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceHeightForHeaderInSection:(NSInteger)section;

/**
 Used instead of defaultSectionAttributes if implemented.
 
 @param collectionView       The collection view object displaying the layout.
 @param collectionViewLayout The layout object requesting the information.
 @param sectionIndex         The index number of the section whose attributes are needed.
 
 @return An aligned layout section attributes object configured with the attributes to use for this section.
 */
- (FSQCollectionViewAlignedLayoutSectionAttributes *)collectionView:(UICollectionView *)collectionView
                                                             layout:(FSQCollectionViewAlignedLayout *)collectionViewLayout
                                        attributesForSectionAtIndex:(NSInteger)sectionIndex;

/**
 Used instead of defaultCellAttributes if implemented.
 
 @param collectionView       The collection view object displaying the layout.
 @param collectionViewLayout The layout object requesting the information.
 @param indexPath            The index path of the cell whose attributes are needed.
 
 @return An aligned layout cell attributes object configured with the attributes to use for this cell.
 */
- (FSQCollectionViewAlignedLayoutCellAttributes *)collectionView:(UICollectionView *)collectionView
                                                          layout:(FSQCollectionViewAlignedLayout *)collectionViewLayout
                                    attributesForCellAtIndexPath:(NSIndexPath *)indexPath;
@end


typedef NS_ENUM(NSInteger, FSQCollectionViewHorizontalAlignment) {
    FSQCollectionViewHorizontalAlignmentLeft,
    FSQCollectionViewHorizontalAlignmentRight,
    FSQCollectionViewHorizontalAlignmentCenter,
    
};


typedef NS_ENUM(NSInteger, FSQCollectionViewVerticalAlignment) {
    FSQCollectionViewVerticalAlignmentTop,
    FSQCollectionViewVerticalAlignmentBottom,
    FSQCollectionViewVerticalAlignmentCenter,
};

/**
 This class defines the configurable attributes for a section in the layout.
 
 You can either set a default instance used for the entire collection view, or manually return instances
 via the delegate method.
 */
@interface FSQCollectionViewAlignedLayoutSectionAttributes : NSObject

/**
 Defines how each line of the section is aligned relative to the entire section
 */
@property (nonatomic, readonly) FSQCollectionViewHorizontalAlignment horizontalAlignment;

/**
 Defines how each line of the section is aligned relative to the other cells on its own line
 */
@property (nonatomic, readonly) FSQCollectionViewVerticalAlignment verticalAlignment;

/**
 Defines the space space in points between cells on the same line
 */
@property (nonatomic, readonly) CGFloat itemSpacing;

/**
 Defines the space in points between lines
 */
@property (nonatomic, readonly) CGFloat lineSpacing;

/**
 Defines the insets in points around this section.
 */
@property (nonatomic, readonly) UIEdgeInsets insets;

// Some shared pointers for common alignments

/** Reusable shared pointer to a simple top-left alignment section attribute object */
+ (FSQCollectionViewAlignedLayoutSectionAttributes *)topLeftAlignment;
/** Reusable shared pointer to a simple top-center alignment section attribute object */
+ (FSQCollectionViewAlignedLayoutSectionAttributes *)topCenterAlignment;
/** Reusable shared pointer to a simple top-right alignment section attribute object */
+ (FSQCollectionViewAlignedLayoutSectionAttributes *)topRightAlignment;
/** Reusable shared pointer to a simple center-center alignment section attribute object */
+ (FSQCollectionViewAlignedLayoutSectionAttributes *)centerCenterAlignment;

/**
 Creates a new section attributes instance with the specified alignments.
 
 @param horizontalAlignment Horizontal alignment for the section
 @param verticalAlignment   Vertical alignment for the section
 
 @return New section attributes object with the specified alignments, spacings of 5 points, and zero insets.
 */
+ (instancetype)withHorizontalAlignment:(FSQCollectionViewHorizontalAlignment)horizontalAlignment
                      verticalAlignment:(FSQCollectionViewVerticalAlignment)verticalAlignment;

/**
 Creates a new section attributes instance with the specified attributes.
 
 @param horizontalAlignment Horizontal alignment for the section
 @param verticalAlignment   Vertical alignment for the section
 @param itemSpacing         Space between cells on the same line
 @param lineSpacing         Space between lines
 @param insets              Insets around the section
 
 @return New section attributes object with the specified attributes.
 */
+ (instancetype)withHorizontalAlignment:(FSQCollectionViewHorizontalAlignment)horizontalAlignment
                      verticalAlignment:(FSQCollectionViewVerticalAlignment)verticalAlignment
                            itemSpacing:(CGFloat)itemSpacing
                            lineSpacing:(CGFloat)lineSpacing
                                 insets:(UIEdgeInsets)insets;
@end


/**
 This class defines the configurable attributes for a cell in the layout.
 
 You can either set a default instance used for the entire collection view, or manually return instances
 via the delegate method.
 */
@interface FSQCollectionViewAlignedLayoutCellAttributes : NSObject

/**
 Insets will be added to size for layout purposes, but the collection cell will end up actually being the size reported
 in either the sizeForItemAtIndexPath or the layout's defaultCellSize property.
 
 You can add more padding around cells with positive insets,
 or effectively shrink cell/line spacing or make cells overlap by using negative insets.
 */
@property (nonatomic, readonly) UIEdgeInsets insets;

/**
 If YES, ensures this cell is the first thing on the line by inserting a line break before if necessary
 
 If there was going to be a line break before anyway, this has no effect (does not insert an EXTRA newline)
 */
@property (nonatomic, readonly) BOOL shouldBeginLine;

/**
 If YES, ensures this cell is the last thing on the line by inserting a line break after if necessary
 
 If there was going to be a line break after anyway, this has no effect (does not insert an EXTRA newline)
 */
@property (nonatomic, readonly) BOOL shouldEndLine;

/**
 If YES and section alignment is Left or Right, future lines will start from this cell's left or right edge respectively.
 
 The available width of all future lines will be lowered and padding will be added to the appropriate side to inset
 future lines
 
 @note There is no way to stop indenting once you start it without creating a new section, although you can start a new
 indentation from a different cell.
 
 @note The alignment is from the actual position of the cell, not including its insets. Therefore you can fake an
 "unindentation" by using negative insets and then starting a new indentation.
 */
@property (nonatomic, readonly) BOOL startLineIndentation;

/**
 Reusable shared pointer to a simple cell attribute object.
 Zero insets, no line breaks, no indentation.
 */
+ (FSQCollectionViewAlignedLayoutCellAttributes *)defaultCellAttributes;

/**
 Creates a new cell attributes instance with the specified attributes.
 
 @param insets               Insets around the cell
 @param shouldBeginLine      Whether this cell should be the first thing on its line
 @param shouldEndLine        Whether this cell should be the last thing on its line
 @param startLineIndentation Whether this cell should start a new indentation for future lines
 
 @return New cell attributes object with the specified attributes.
 */
+ (instancetype)withInsets:(UIEdgeInsets)insets
           shouldBeginLine:(BOOL)shouldBeginLine
             shouldEndLine:(BOOL)shouldEndLine
      startLineIndentation:(BOOL)startLineIndentation;

@end

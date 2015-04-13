FSQCollectionViewAlignedLayout
==============================

A simple, generic collection view layout with multiple customization options.

Overview
========

FSQCollectionViewAlignedLayout is a generic collection view layout designed to be very flexible and configurable. It's goal is to save its users from having to write their own custom layout classes every time UICollectionViewFlowLayout is not appropriate for their view.

The layout acts like a very simple typesetter, with each cell being like a "word" or font glyph, and each section being a "paragraph" with multiple lines of cells.


The class is thoroughly documented in its header (which should be automatically parsed and available through Xcode's documentation popovers), but this file includes an overview of its features.

Setup
=====
Aligned Layout is only two files with no external dependencies, so it should be quick and easy to add to your project. Simply add the files to your project, and then you can start using aligned layout with your collection views.

We recommend using git submodules to link your repo against this one for easy updating when future versions are released.

Section Attributes
==================
The `FSQCollectionViewAlignedLayoutSectionAttributes` class defines the properties for customizing the layout of your collection view sections. 

If all your sections have the same attributes, you can set the `defaultSectionAttributes` property on the layout. Alternatively you can implement the following method in your delegate to return different attributes for each section:
```objc
- (FSQCollectionViewAlignedLayoutSectionAttributes *)collectionView:(UICollectionView *)collectionView
                                                             layout:(FSQCollectionViewAlignedLayout *)collectionViewLayout
                                        attributesForSectionAtIndex:(NSInteger)sectionIndex;
```

The follow section attributes are available:

**FSQCollectionViewHorizontalAlignment horizontalAlignment** — This property aligns each line of the collection view horizontally, relative to the entire section. The options are *Left*, *Right*, and *Center*

**FSQCollectionViewVerticalAlignment verticalAlignment** — If cells on the same line are different heights, this property aligns them vertically relative to each other. The options are *Top*, *Bottom*, and *Center*

**CGFloat itemSpacing** — This is the horizontal space in points between cells on the same line.

**CGFloat lineSpacing** — This is the vertical space in points between the bottom of one line in the paragraph and the top of the next. The bounding box of each line is considered to be a rectangle that exactly encompasses every cell on the line. Because of this, if cells on the same line are not of uniform height, some of them may have more vertical space between them and the next or previous line (depending on many other factors, such as vertical alignment and cell insets).

**UIEdgeInsets insets** — This is the spacing in points around all four edges of the section. The bounding box of the section is considered to be a rectangle that exactly encompasses every line in the section.


Instances of this class are immutable, so you must define all properties on creation. There are two class methods for creating new attributes objects

```objc
+ (instancetype)withHorizontalAlignment:(FSQCollectionViewHorizontalAlignment)horizontalAlignment
                      verticalAlignment:(FSQCollectionViewVerticalAlignment)verticalAlignment;
```

This method creates a new section attributes object with the specified alignments. It defaults to item and line spacings of 5 points and has no insets (UIEdgeInsetsZero).

```objc
+ (instancetype)withHorizontalAlignment:(FSQCollectionViewHorizontalAlignment)horizontalAlignment
                      verticalAlignment:(FSQCollectionViewVerticalAlignment)verticalAlignment
                            itemSpacing:(CGFloat)itemSpacing
                            lineSpacing:(CGFloat)lineSpacing
                                 insets:(UIEdgeInsets)insets;
```

This method is the same as above but lets you specify your own spacings and insets.


Additionally the class defines four shared pointers to commonly used alignments for convenience.
```objc
+ (FSQCollectionViewAlignedLayoutSectionAttributes *)topLeftAlignment;
+ (FSQCollectionViewAlignedLayoutSectionAttributes *)topCenterAlignment;
+ (FSQCollectionViewAlignedLayoutSectionAttributes *)topRightAlignment;
+ (FSQCollectionViewAlignedLayoutSectionAttributes *)centerCenterAlignment;
```

Cell Attributes
===============
The FSQCollectionViewAlignedLayoutCellAttributes class defines the properties for customizing the layout of your collection view cells. 

If all your cells have the same attributes, you can set the `defaultCellAttributes` property on the layout. Alternatively you can implement the following method in your delegate to return different attributes for each cell:
```objc
- (FSQCollectionViewAlignedLayoutCellAttributes *)collectionView:(UICollectionView *)collectionView
                                                          layout:(FSQCollectionViewAlignedLayout *)collectionViewLayout
                                    attributesForCellAtIndexPath:(NSIndexPath *)indexPath;
```

The following cell attributes are available


**UIEdgeInsets insets** — This is the spacing in points around all four edges of the cell. For layout positioning purposes, these insets are added to the cell's size. For example, a 50x50 point cell with 5 point insets on all four sides will be laid out as if it was a 60x60 point cell. However, the actual UICollectionViewCell class will end up being the correct size you reported it as being.

**BOOL shouldBeginLine** — If *YES*, this will force the cell to be the first cell on the line if it would not otherwise have been laid out that way.

**BOOL shouldEndLine** — If *YES*, this will force the cell to be the last cell on the line if it would not otherwise have been laid out that way.

**BOOL startLineIndentation** — If *YES* and the section's alignment is *Left* or *Right*, this will force all future lines to line up with the left or right edge of this cell respectively. The available width of all future lines will be lowered and padding will be added to the appropriate side to inset them. The indentation starts at the actual edge of the cell, not including insets. There can be only one indentation at a time per section; a future cell in the same section with indentation will override a previous one.

Instances of this class are immutable, so you must define all properties on creation. There is one class method for creating new attributes objects:

```objc
+ (instancetype)withInsets:(UIEdgeInsets)insets
           shouldBeginLine:(BOOL)shouldBeginLine
             shouldEndLine:(BOOL)shouldEndLine
      startLineIndentation:(BOOL)startLineIndentation;
```

This method creates a new cell attributes object with the specified values.

Additionally the class defines a shared pointer to a default attributes object with no insets, no line breaks, and no indentation.

```objc
+ (FSQCollectionViewAlignedLayoutCellAttributes *)defaultCellAttributes;
```

Cell Sizing
===========

If all your cells are the same size, you can set the `defaultCellSize` property on the layout. Alternatively, you can implement the following method in your delegate to return different sizes for each cell:
```objc
- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(FSQCollectionViewAlignedLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
      remainingLineSpace:(CGFloat)remainingLineSpace;
```

This mirrors the sizing delegate method used by UICollectionViewDelegateFlowLayout, but with the addition of the `remainingLineSpace` parameter. This parameter contains the amount of horizontal space in points remaining on the current line that is being laid out. If you return a size whose width is less than or equal to remainingLineSpace it will therefore be laid out on the same line (barring any other cell attributes that might change this, such as line breaks). This can be useful when you want to calculate a height based on width to fill up space on the rest of the line (e.g. for text or image sizing purposes).

Top Level Properties
====================

The layout has the following top level properties for customizing the entire collection view.

**CGSize defaultCellSize** — This size is used for all cells if the corresponding delegate method is not implemented. It defaults to 100x100 points.

**FSQCollectionViewAlignedLayoutSectionAttributes \*defaultSectionAttributes** — This attributes object is used for all sections if the corresponding delegate method is not implemented. If not set, the default value is FSQCollectionViewAlignedLayoutSectionAttributes topLeftAlignment].

**FSQCollectionViewAlignedLayoutCellAttributes \*defaultCellAttributes** — This attributes object is used for all cells if the corresponding delegate method is not implemented. If not set, the default value is [FSQCollectionViewAlignedLayoutCellAttributes defaultCellAttributes].

**CGFloat sectionSpacing** — This is the vertical spacing in points between the bottom of one section and the top of the next. The bounding box of the section is considered to be a rectangle that exactly encompasses every line in the section. If not set, the default value is 10 points.

**UIEdgeInsets contentInsets** — This is the spacing in points around all four edges of the collection view content. The bounding box is a rectangle that exactly encompasses every section in the collection. If not set, the default value is 5 point spacing for all edges.

**BOOL shouldPinSectionHeadersToTop** — This controls whether the current top-most section's header gets pinned to the top of the view, similar to how UITableView works when using UITableViewStylePlain. The default value is YES.


Contributors
============
FSQCollectionViewAlignedLayout was initially developed by Foursquare Labs for internal use. It was originally written by Brian Dorfman ([@bdorfman](https://twitter.com/bdorfman)) and is currently maintained by Brian Dorfman and [Cameron Mulhern](http://www.cameronmulhern.com).

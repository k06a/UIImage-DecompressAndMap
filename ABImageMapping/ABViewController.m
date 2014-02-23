//
//  ABViewController.m
//  ABImageMapping
//
//  Created by Антон Буков on 23.02.14.
//  Copyright (c) 2014 Codeless Solutions. All rights reserved.
//

#import "ABViewController.h"
#import "ABFastImageCell.h"
#import "UIImage+DecompressAndMap.h"

@interface ABViewController ()
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentControl;

@property (strong, nonatomic) NSArray *imageNames;
@property (strong, nonatomic) NSMutableArray *images;
@end

@implementation ABViewController

- (NSArray *)imageNames
{
    if (_imageNames == nil)
    {
        _imageNames = @[];
        for (NSString *ext in @[@"jpg",@"png"])
            _imageNames = [_imageNames arrayByAddingObjectsFromArray:[[NSBundle mainBundle] URLsForResourcesWithExtension:ext subdirectory:@"Demo Images"]];
    }
    return _imageNames;
}

- (NSMutableArray *)images
{
    if (_images == nil || _images.count != self.imageNames.count)
    {
        _images = [NSMutableArray arrayWithCapacity:self.imageNames.count];
        for (id a in self.imageNames)
            [_images addObject:[NSNull null]];
    }
    return _images;
}

#pragma mark - Collection View

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
        return CGSizeMake(85,85);
    return CGSizeMake(32,32);
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.imageNames.count * 1000;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ABFastImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell_1" forIndexPath:indexPath];
    //cell.layer.rasterizationScale = [UIScreen mainScreen].scale;
    //cell.layer.shouldRasterize = YES;
    
    NSInteger imageIndex = indexPath.row % self.imageNames.count;
    NSURL *photoUrl = self.imageNames[imageIndex];
    
    cell.image = nil;
    
    if (self.segmentControl.selectedSegmentIndex == 0)
    {
        cell.image = [UIImage imageWithContentsOfFile:photoUrl.path];
        return cell;
    }
    
    if (self.images[imageIndex] != [NSNull null])
        cell.image = self.images[imageIndex];
    
    if (cell.image == nil)
    {
        static NSString *documentDir = nil;
        if (documentDir == nil)
            documentDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        
        NSString *photoPath = photoUrl.path;
        NSString *path = [documentDir stringByAppendingFormat:@"/%i-%i-%i",
                          (int)photoPath.hash,
                          (int)cell.bounds.size.width,
                          (int)cell.bounds.size.height];
        
        cell.image = [UIImage imageMapFromPath:path];
        if (cell.image == nil)
        {
            cell.image = [UIImage imageWithContentsOfFile:photoPath];
            cell.image = [cell.image decompressAndMapToPath:path withResize:CGSizeMake((int)cell.bounds.size.width*9/10, (int)cell.bounds.size.height*9/10)];
        }
        if (cell.image)
            self.images[imageIndex] = cell.image;
    }
    
    return cell;
}

#pragma mark - View

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.collectionView registerClass:[ABFastImageCell class] forCellWithReuseIdentifier:@"cell_1"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

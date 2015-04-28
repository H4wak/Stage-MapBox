#import "MGLUserLocation_Private.h"

#import "MGLMapView.h"

@interface MGLUserLocation ()

@property (nonatomic, weak) MGLMapView *mapView;

@end

@implementation MGLUserLocation

- (instancetype)init
{
    if (self = [super init])
    {
        _location = [[CLLocation alloc] initWithLatitude:MAXFLOAT longitude:MAXFLOAT];
    }

    return self;
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key
{
    return ! [key isEqualToString:@"location"] && ! [key isEqualToString:@"heading"];
}

+ (NSSet *)keyPathsForValuesAffectingCoordinate
{
    return [NSSet setWithObject:@"location"];
}

- (void)setLocation:(CLLocation *)newLocation
{
    if ([newLocation distanceFromLocation:_location] && newLocation.coordinate.latitude != 0 &&
            newLocation.coordinate.longitude != 0)
    {
        [self willChangeValueForKey:@"location"];
        _location = newLocation;
        [self didChangeValueForKey:@"location"];
    }
}

- (BOOL)isUpdating
{
    return self.mapView.userTrackingMode != MGLUserTrackingModeNone;
}

- (void)setHeading:(CLHeading *)newHeading
{
    if (newHeading.trueHeading != _heading.trueHeading)
    {
        [self willChangeValueForKey:@"heading"];
        _heading = newHeading;
        [self didChangeValueForKey:@"heading"];
    }
}

- (CLLocationCoordinate2D)coordinate
{
    return self.location.coordinate;
}

- (NSString *)title
{
    return (_title ? _title : @"Current Location");
}

@end

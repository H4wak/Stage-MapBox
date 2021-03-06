#import "MGLMapboxEvents.h"
#import "MGLMetricsLocationManager.h"

#import <CoreLocation/CoreLocation.h>

@interface MGLMetricsLocationManager() <CLLocationManagerDelegate>

@property (nonatomic) CLLocationManager *locationManager;
@property (atomic) NSDateFormatter *rfc3339DateFormatter;

@end

@implementation MGLMetricsLocationManager

- (instancetype) init {
    if (self = [super init]) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.distanceFilter = 10;
        [_locationManager setDelegate:self];

        _rfc3339DateFormatter = [[NSDateFormatter alloc] init];
        NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];

        [_rfc3339DateFormatter setLocale:enUSPOSIXLocale];
        [_rfc3339DateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ssZ"];
        // Clear Any System TimeZone Cache
        [NSTimeZone resetSystemTimeZone];
        [_rfc3339DateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    }
    return self;
}

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    static MGLMetricsLocationManager *sharedManager;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

+ (void) startUpdatingLocation {
    [[MGLMetricsLocationManager sharedManager].locationManager startUpdatingLocation];
}

+ (void) stopUpdatingLocation {
    [[MGLMetricsLocationManager sharedManager].locationManager stopUpdatingLocation];
}

+ (void) startMonitoringVisits {
    if ([[MGLMetricsLocationManager sharedManager].locationManager respondsToSelector:@selector(startMonitoringVisits)]) {
        [[MGLMetricsLocationManager sharedManager].locationManager startMonitoringVisits];
    }
}

+ (void) stopMonitoringVisits {
    if ([[MGLMetricsLocationManager sharedManager].locationManager respondsToSelector:@selector(stopMonitoringVisits)]) {
        [[MGLMetricsLocationManager sharedManager].locationManager stopMonitoringVisits];
    }
}

#pragma mark CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    //  Iterate through locations to pass all data
    for (CLLocation *loc in locations) {
        [MGLMapboxEvents pushEvent:MGLEventTypeLocation withAttributes:@{
            MGLEventKeyLatitude: @(loc.coordinate.latitude),
            MGLEventKeyLongitude: @(loc.coordinate.longitude),
            MGLEventKeySpeed: @(loc.speed),
            MGLEventKeyCourse: @(loc.course),
            MGLEventKeyAltitude: @(loc.altitude),
            MGLEventKeyHorizontalAccuracy: @(loc.horizontalAccuracy),
            MGLEventKeyVerticalAccuracy: @(loc.verticalAccuracy)
        }];
    }
}

- (void)locationManager:(CLLocationManager *)manager didVisit:(CLVisit *)visit {
    [MGLMapboxEvents pushEvent:MGLEventTypeVisit withAttributes:@{
        MGLEventKeyLatitude: @(visit.coordinate.latitude),
        MGLEventKeyLongitude: @(visit.coordinate.longitude),
        MGLEventKeyHorizontalAccuracy: @(visit.horizontalAccuracy),
        MGLEventKeyArrivalDate: [[NSDate distantPast] isEqualToDate:visit.arrivalDate] ? [NSNull null] : [_rfc3339DateFormatter stringFromDate:visit.arrivalDate],
        MGLEventKeyDepartureDate: [[NSDate distantFuture] isEqualToDate:visit.departureDate] ? [NSNull null] : [_rfc3339DateFormatter stringFromDate:visit.departureDate]
    }];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    NSString *newStatus = nil;
    switch (status) {
        case kCLAuthorizationStatusNotDetermined:
            newStatus = @"User Hasn't Determined Yet";
            break;
        case kCLAuthorizationStatusRestricted:
            newStatus = @"Restricted and Can't Be Changed By User";
            break;
        case kCLAuthorizationStatusDenied:
            newStatus = @"User Explcitly Denied";
            [MGLMetricsLocationManager stopUpdatingLocation];
            [MGLMetricsLocationManager stopMonitoringVisits];
            break;
        case kCLAuthorizationStatusAuthorized:
            newStatus = @"User Has Authorized / Authorized Always";
            [MGLMetricsLocationManager startUpdatingLocation];
            [MGLMetricsLocationManager startMonitoringVisits];
            break;
            //        case kCLAuthorizationStatusAuthorizedAlways:
            //            newStatus = @"Not Determined";
            //            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            newStatus = @"User Has Authorized When In Use Only";
            [MGLMetricsLocationManager startUpdatingLocation];
            [MGLMetricsLocationManager startMonitoringVisits];
            break;
        default:
            newStatus = @"Unknown";
            break;
    }
}

@end

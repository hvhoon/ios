
#define kGoogleAPIKey @"AIzaSyC2cGYoi-OZ7Rb2ItQrO1bNsBoCOvGDge0"
#define kGoogleAPINSErrorCode 42

@class CLPlacemark;

typedef enum {
    PlaceTypeGeocode = 0,
    PlaceTypeEstablishment
} GooglePlacesAutocompletePlaceType;

typedef void (^GooglePlacesPlacemarkResultBlock)(CLPlacemark *placemark, NSString *addressString, NSError *error);
typedef void (^GooglePlacesAutocompleteResultBlock)(NSArray *places, NSError *error);
typedef void (^GooglePlacesPlaceDetailResultBlock)(NSDictionary *placeDictionary, NSError *error);

extern GooglePlacesAutocompletePlaceType PlaceTypeFromDictionary(NSDictionary *placeDictionary);
extern NSString *BooleanStringForBool(BOOL boolean);
extern NSString *PlaceTypeStringForPlaceType(GooglePlacesAutocompletePlaceType type);
extern BOOL EnsureGoogleAPIKey();
extern void PresentAlertViewWithErrorAndTitle(NSError *error, NSString *title);
extern BOOL IsEmptyString(NSString *string);

@interface NSArray(FoundationAdditions)
- (id)onlyObject;
@end
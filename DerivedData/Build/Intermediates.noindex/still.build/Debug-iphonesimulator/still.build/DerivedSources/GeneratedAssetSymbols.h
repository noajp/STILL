#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"com.takanorinakano.still";

/// The "Background" asset catalog color resource.
static NSString * const ACColorNameBackground AC_SWIFT_PRIVATE = @"Background";

/// The "appBackground" asset catalog color resource.
static NSString * const ACColorNameAppBackground AC_SWIFT_PRIVATE = @"appBackground";

/// The "buttonText" asset catalog color resource.
static NSString * const ACColorNameButtonText AC_SWIFT_PRIVATE = @"buttonText";

/// The "inputBackground" asset catalog color resource.
static NSString * const ACColorNameInputBackground AC_SWIFT_PRIVATE = @"inputBackground";

/// The "lightGreenButtonBackground" asset catalog color resource.
static NSString * const ACColorNameLightGreenButtonBackground AC_SWIFT_PRIVATE = @"lightGreenButtonBackground";

/// The "textPrimary" asset catalog color resource.
static NSString * const ACColorNameTextPrimary AC_SWIFT_PRIVATE = @"textPrimary";

#undef AC_SWIFT_PRIVATE

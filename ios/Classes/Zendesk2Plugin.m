#import "Zendesk2Plugin.h"
#if __has_include(<zendesk2/zendesk2-Swift.h>)
#import <zendesk2/zendesk2-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "zendesk2-Swift.h"
#endif

@implementation Zendesk2Plugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftZendesk2Plugin registerWithRegistrar:registrar];
}
@end

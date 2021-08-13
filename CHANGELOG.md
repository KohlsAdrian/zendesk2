# 2.0.0+0

* [Features]

* Answer SDK providers

* Plugin wrapped features: Zendesk, ZendeskChat and ZendeskAnswer (see README.md)

* [BREAKING CHANGES]

* Wrapped 3 new streams: Connection Status, Chat Settings and isOnline status (Provider Model optimisation)

* Optimised null-safety on ProviderModel object

* Moved SDK initialization to general Zendesk class (Flutter and Native side)

* [OPTIMISATION]

* Removed unused SDKs and unused code

* Removed deprecated functions:
    
    * Native Chat
    
    * Rating

# 1.6.1+0

* [Not-breaking][Android] fixed setVisitorInfo on MethodChannel where Name, Email and Phone were conflicting with duplicate setup usage.

# 1.6.0+3

* Code cleanup and fixed ./example to nullsafety

## 1.6.0+0 - 1.6.0+1 - 1.6.0+2 

* Support for push notifications

* Pull request from https://github.com/diegogarciar

* Fix README.md

F* ixed FirebaseService Example

## 1.5.0

* [Breaking change] replaced `Timer.periodic` by `invokeMethod`

* Optimisation made by https://github.com/kiplelive-zariman

## 1.4.1

* Fixes bug on iOS opening (deprecated) native chat only once

## 1.4.0+1

* Fixes breaking kotlin file on Android

## 1.4.0

* Migrated to NNBD

* Min Dart 2.10

* Min Flutter version 1.20+

## 1.3.0

* Fixed Android bug, removed `endChat()` on `dispose()`

## 1.2.1

* Fixed Android setVisitorInfo not working, and added iOS logging

## 1.2.0

* Added logs for all events happening on plugin if Logger enabled

## 1.1.1

* Hotfix

* mistype mimeType in ProviderModel

* You must call supported types after providers finished initializing

## 1.1.0+1

* Added plugin docs.

## 1.1.0

* Added providers for custom UI development, see example

## 1.0.2

* Updated readme.me

## 1.0.1

* fixed iOS native code department glitch, was not setting nil on empty field, so SDK didn't work properly

## 1.0.0

* iOS integration finished, Chat SDK v2 for Android and iOS 

## 0.0.2

* Android working

## 0.0.1

* Initial release

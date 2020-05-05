### 2.1.3 (5 May, 2020)
- Improvements to logging.

### 2.1.2 (4 Dec, 2019)
- GitHub issue #51 - Call Places API to collect `CLAuthorizationStatus` from device when it changes.

### 2.1.1 (25 Nov, 2019)
- GitHub issue #44 - Fixed import statements for Cocoapods projects using multiple pod projects option.

### 2.1.0 (9 Oct, 2019)
- Added a new API `setRequestAuthorizationLevel` to set the type of location authorization request for which the user will be prompted.

### 2.0.0 (25 Jul, 2019)
- Changed existing API in ACPPlacesMonitor allowing you to clear all Places data from the device:
  - old API - `+ (void) stop;`
  - new API - `+ (void) stop: (BOOL) clearData;`
- Updated use of ACPPlaces `getNearbyPointsOfInterest` API to handle error scenarios more effectively
- Disabling or uninstalling the Places extension in Adobe Launch will now cause the Places Monitor to unregister all regions and clear all client-side Places data.
- Completed GitHub issues:
  - #21, #28, #29

### 1.0.2 (25 Jun, 2019)
- GitHub issue #25 - update logs to be more helpful
- Update to contributing guidelines and readme, now accepting pull requests!

### 1.0.1 (9 Apr, 2019)
- Added full unit test coverage
- CI integration (CircleCI)
- Code coverage integration (codecov)

### 1.0.0 (25 Mar, 2019)
- Initial release of ACPPlacesMonitor

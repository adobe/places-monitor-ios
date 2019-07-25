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

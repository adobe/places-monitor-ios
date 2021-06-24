# Getting started with ACPPlacesMonitor for iOS

## Notice of deprecation

On **August 31, 2021**, the **Places Monitor** extension for the Adobe Experience Platform Mobile SDKs will be **deprecated**. The Places Monitor extension will not receive further updates or support beyond August 31st.

Customers that currently use the Places Monitor extension can continue usage of this extension with the understanding that no additional updates or support will be available through Adobe.

The deprecation of the Places Monitor extension has no bearing or negative impact on the Places Service extension which will continue to be supported with enhancements and updates.

Customers that are looking to transition away from the Places Monitor extension to their own monitoring solution should review the documentation for: [Use Places Service with your own monitoring solution](https://experienceleague.adobe.com/docs/places/using/using-your-own-monitor.html?lang=en). This document explains how to interact with the Places Service by implementing [Core Location](https://developer.apple.com/documentation/corelocation) services on iOS or [Location Services](https://developers.google.com/android/reference/com/google/android/gms/location/package-summary) from Google Play.

---

Table of Contents

1. [About this project](#about-this-project)
2. [Current version](#current-version)
3. [Contributing to the project](#contributing-to-the-project)
4. [Environment setup](#environment-setup)
    - [Open the Xcode workspace](#open-the-xcode-workspace)
    - [Command line integration](#command-line-integration)    

## About this project

The ACPPlacesMonitor for iOS is used to manage the integration between iOS's CLLocationManager and the [ACPPlaces extension](https://cocoapods.org/pods/ACPPlaces) for the [Adobe Experience Platform SDK](https://github.com/Adobe-Marketing-Cloud/acp-sdks).

## Current version

[![Cocoapods](https://img.shields.io/cocoapods/v/ACPPlacesMonitor.svg?color=orange&label=ACPPlacesMonitor&logo=apple&logoColor=white)](https://cocoapods.org/pods/ACPPlacesMonitor)
[![CircleCI](https://img.shields.io/circleci/project/github/adobe/places-monitor-ios/master.svg?logo=circleci)](https://circleci.com/gh/adobe/workflows/places-monitor-ios)
[![Code Coverage](https://img.shields.io/codecov/c/github/adobe/places-monitor-ios/master.svg?logo=codecov)](https://codecov.io/gh/adobe/places-monitor-ios/branch/master)


## Contributing to the project

Looking to contribute to this project?  Please review our [Contributing guidelines](.github/CONTRIBUTING.md) prior to opening a pull request.  

We look forward to working with you!

## Environment setup

The first time you clone or download the project, you should run the following from the root directory to setup the environment:

~~~~
make setup
~~~~

Subsequently, you can make sure your environment is updated by running the following:

~~~~
make update
~~~~

#### Open the Xcode workspace

Open the workspace in Xcode by running the following command from the root directory of the repository:

~~~
open ACPPlacesMonitor.xcworkspace
~~~

#### Command line integration

From command line you can build the project by running the following command:

~~~~
make build
~~~~

You can also run the unit test suite from command line:

~~~~
make test
~~~~

To create an XCFramework, run the following:

~~~~
make xcframeworks
~~~~

The resulting XCFramework can be found at `bin/iOS/ACPPlacesMonitor.xcframework`

## Licensing
This project is licensed under the Apache V2 License. See [LICENSE](LICENSE) for more information.

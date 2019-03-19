# Getting started with the iOS Places Monitor

Table of Contents

1. [About this project](#about-this-project)
2. [Environment setup](#environment-setup)
    - [Open the Xcode workspace](#open-the-xcode-workspace)
    - [Development setup](#development-setup)
    - [Manual testing setup](#manual-testing-setup)

# About this project

This project contains the iOS specific code and distributions for version 5 of the Marketing Cloud Mobile SDK.

## Environment setup
In order to start contributing on the iOS Places Monitor project you will need to follow these steps:
* Fork this repo for your username and clone it on your local machine
* From the root directory of the repository, setup your environment via the makefile command:
~~~~
make setup
~~~~

#### Open the Xcode workspace
You can open the workspace in Xcode by running the following command:
~~~
make open
~~~

#### Development setup
Prerequisites:
- [Environment Setup](#environment-setup)
- [Open the Xcode workspace](#open-the-xcode-workspace)

You can build the Places Monitor library by selecting the scheme called `ACPPlacesMonitor_iOS`.  All source code for the monitor can be found in the `ACPPlacesMonitor` group of the solution navigator.  The source itself lives in the [code/src/](https://git.corp.adobe.com/dms-mobile/bourbon-platform-ios-places-monitor/tree/dev/code/src) directory.

<img src="https://github.com/adobe/ACPPlacesMonitor/blob/assets/build_library.png" height="400"></img>

#### Running unit tests
With the `ACPPlacesMonitor_iOS` scheme selected, you can run unit tests from the menu via `Product > Test`, or using the keyboard shortcut `⌘U`.

#### Manual testing setup
Prerequisites:
- [Environment Setup](#environment-setup)
- [Open the Xcode workspace](#open-the-xcode-workspace)

With the workspace open, you can run the test app by selecting the appropriate scheme.  

###### Testing on simulator
- Select the `Simulator - MonitorTestApp` scheme and hit run. <br><br>
<img src="https://github.com/sbenedicadb/ACPPlacesMonitor/tree/assets/test_app_sim.png" height="40"></img><br><br>
- In the app, make sure you enter in a name for your device and hit the `Set Name` button.<br><br>
<img src="https://github.com/sbenedicadb/ACPPlacesMonitor/tree/assets/set_name.png" height="100"></img><br><br>
- On the simulator, you will be spoofing the location using our `.gpx` files.  In the menu for the debug area in Xcode, hit the "simulate location" button to toggle between `AdobeSanJose` and `Safeway-SantaClara` locations. <br><br>
<img src="https://github.com/sbenedicadb/ACPPlacesMonitor/tree/assets/spoof_location.png" height="140"></img> <br>
_Hint:_ Sometimes the "simulate location" button does not appear in the debug area on your first launch.  If you notice it missing, try re-launching the app.

###### Testing on device
- Select the `Device - MonitorTestApp` scheme, then your device, and hit run. <br><br>
<img src="https://github.com/sbenedicadb/ACPPlacesMonitor/tree/assets/test_app_device.png" height="40"></img><br><br>
- In the app, make sure you enter in a name for your device and hit the `Set Name` button.<br><br>
<img src="https://github.com/sbenedicadb/ACPPlacesMonitor/tree/assets/set_name_device.png" height="100"></img><br><br>
- Walk around

###### Validating results
If you are using the default configuration provided in the test app, you should see data about your region entries/exits in the #places-postbacks channel in Slack: https://adobemobileservices.slack.com/messages/GEGSF68KF

// ignore_for_file: use_build_context_synchronously

import 'dart:developer';
import 'dart:io';

import 'package:esp_smartconfig/esp_smartconfig.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final NetworkInfo _networkInfo = NetworkInfo();
  String? wifiName,
      wifiBSSID,
      wifiIPv4,
      wifiIPv6,
      wifiGatewayIP,
      wifiBroadcast,
      wifiSubmask;

  TextEditingController txtWifiNameController = TextEditingController();
  TextEditingController txtWifiBSSIDController = TextEditingController();
  TextEditingController txtWifiPasswordController = TextEditingController();

  GlobalKey<FormState> formKey = GlobalKey();

  bool startProvisioning = false;

  late Provisioner provisioner;

  @override
  void initState() {
    super.initState();
    _permissionHandler();
    _initNetworkInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Wifi Smart Config'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: SafeArea(
          minimum: const EdgeInsets.all(8.0),
          child: Form(
              key: formKey,
              child: Column(
                children: [
                  // wifi name
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: TextFormField(
                      controller: txtWifiNameController,
                      decoration: InputDecoration(
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.0),
                        ),
                        hintText: 'Enter Wifi SSID',
                        label: const Text('SSID'),
                      ),
                    ),
                  ),

                  // bssid
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: TextFormField(
                      controller: txtWifiBSSIDController,
                      decoration: InputDecoration(
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.0),
                        ),
                        hintText: 'Enter Wifi BSSID',
                        label: const Text('BSSID'),
                      ),
                    ),
                  ),

                  // password
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: TextFormField(
                      controller: txtWifiPasswordController,
                      decoration: InputDecoration(
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.0),
                        ),
                        hintText: 'Enter Wifi password',
                        label: const Text('Password'),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Enter Wifi password';
                        }
                        return null;
                      },
                    ),
                  ),

                  // button
                  Visibility(
                    visible: !startProvisioning,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48.0,
                        child: FilledButton(
                          onPressed: () async {
                            setState(() {
                              startProvisioning = true;
                            });
                            if (formKey.currentState!.validate()) {
                              // start smart config
                              provisioner = Provisioner.espTouch();
                              provisioner.listen((response) {
                                log("Device ${response.bssidText} connected to WiFi!");
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    provisioner.stop();
                                    return AlertDialog(
                                      title: const Text('Result'),
                                      content: Text(
                                          'Device ${response.bssidText} connected to WiFi!'),
                                      actions: [
                                        FilledButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Ok'),
                                        )
                                      ],
                                    );
                                  },
                                ).then((value) {
                                  setState(() {
                                    startProvisioning = false;
                                  });
                                });
                              });

                              try {
                                await provisioner
                                    .start(ProvisioningRequest.fromStrings(
                                  ssid: txtWifiNameController.text,
                                  bssid: txtWifiBSSIDController.text,
                                  password: txtWifiPasswordController.text,
                                ));

                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return const AlertDialog(
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.all(16.0),
                                            child: CircularProgressIndicator(),
                                          ),
                                          Text(
                                              'Please waiting for Wifi config.'),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              } catch (e, _) {
                                log('e');
                              }
                            }
                          },
                          child: const Text('Start!'),
                        ),
                      ),
                    ),
                  ),

                  Visibility(
                    visible: startProvisioning,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48.0,
                        child: FilledButton(
                          onPressed: () {
                            // stop smart config
                            setState(() {
                              startProvisioning = false;
                            });
                            provisioner.stop();
                          },
                          child: const Text('Stop!'),
                        ),
                      ),
                    ),
                  )
                ],
              )),
        ));
  }

  _permissionHandler() async {
    await Permission.location.status.then((value) async {
      if (!value.isGranted) {
        await Permission.location.request().then((value) {
          _initNetworkInfo();
        });
      }
    });
  }

  Future<void> _initNetworkInfo() async {
    try {
      if (!kIsWeb && Platform.isIOS) {
        // ignore: deprecated_member_use
        var status = await _networkInfo.getLocationServiceAuthorization();
        if (status == LocationAuthorizationStatus.notDetermined) {
          // ignore: deprecated_member_use
          status = await _networkInfo.requestLocationServiceAuthorization();
        }
        if (status == LocationAuthorizationStatus.authorizedAlways ||
            status == LocationAuthorizationStatus.authorizedWhenInUse) {
          wifiName = await _networkInfo.getWifiName();
        } else {
          wifiName = await _networkInfo.getWifiName();
        }
      } else {
        wifiName = await _networkInfo.getWifiName();
      }
    } on PlatformException catch (e) {
      log('Failed to get Wifi Name', error: e);
      wifiName = 'Failed to get Wifi Name';
    }

    try {
      if (!kIsWeb && Platform.isIOS) {
        // ignore: deprecated_member_use
        var status = await _networkInfo.getLocationServiceAuthorization();
        if (status == LocationAuthorizationStatus.notDetermined) {
          // ignore: deprecated_member_use
          status = await _networkInfo.requestLocationServiceAuthorization();
        }
        if (status == LocationAuthorizationStatus.authorizedAlways ||
            status == LocationAuthorizationStatus.authorizedWhenInUse) {
          wifiBSSID = await _networkInfo.getWifiBSSID();
        } else {
          wifiBSSID = await _networkInfo.getWifiBSSID();
        }
      } else {
        wifiBSSID = await _networkInfo.getWifiBSSID();
      }
    } on PlatformException catch (e) {
      log('Failed to get Wifi BSSID', error: e);
      wifiBSSID = 'Failed to get Wifi BSSID';
    }

    try {
      wifiIPv4 = await _networkInfo.getWifiIP();
    } on PlatformException catch (e) {
      log('Failed to get Wifi IPv4', error: e);
      wifiIPv4 = 'Failed to get Wifi IPv4';
    }

    try {
      if (!Platform.isWindows) {
        wifiIPv6 = await _networkInfo.getWifiIPv6();
      }
    } on PlatformException catch (e) {
      log('Failed to get Wifi IPv6', error: e);
      wifiIPv6 = 'Failed to get Wifi IPv6';
    }

    try {
      if (!Platform.isWindows) {
        wifiSubmask = await _networkInfo.getWifiSubmask();
      }
    } on PlatformException catch (e) {
      log('Failed to get Wifi submask address', error: e);
      wifiSubmask = 'Failed to get Wifi submask address';
    }

    try {
      if (!Platform.isWindows) {
        wifiBroadcast = await _networkInfo.getWifiBroadcast();
      }
    } on PlatformException catch (e) {
      log('Failed to get Wifi broadcast', error: e);
      wifiBroadcast = 'Failed to get Wifi broadcast';
    }

    try {
      if (!Platform.isWindows) {
        wifiGatewayIP = await _networkInfo.getWifiGatewayIP();
      }
    } on PlatformException catch (e) {
      log('Failed to get Wifi gateway address', error: e);
      wifiGatewayIP = 'Failed to get Wifi gateway address';
    }

    setState(() {
      String tmpWifiName = '$wifiName';
      int len = tmpWifiName.length;
      tmpWifiName = tmpWifiName.substring(1, len - 1);

      txtWifiNameController.text = tmpWifiName;
      txtWifiBSSIDController.text = '$wifiBSSID';
    });
  }
}

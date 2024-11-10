import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:ui';
import 'package:arpa/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:nsd/nsd.dart';
import 'package:swipe_to/swipe_to.dart';

//class LoadingDialog extends StatelessWidget {
//	final String text;
//	const LoadingDialog({super.key, required this.text});
//
//	@override
//	Widget build(BuildContext context) {
//		return AlertDialog(
//			content: Row(
//				
//				children: [
//					const CircularProgressIndicator(),
//					const SizedBox(width: 20),
//					Text(text),
//				]
//			)
//		);
//	}
//}

enum OS { 
  Windowslike(desc: "Windows-like", icon: Icon(Icons.desktop_windows)), 
  Unixlike(desc: "Unix-like", icon: Icon(Icons.devices)), 
  Linux(desc: "Linux", icon: Icon(Icons.laptop_chromebook)), 
  Other(desc: "Other", icon: Icon(Icons.devices_other)),
  Android(desc: "Android", icon: Icon(Icons.android)),
  Unknown(desc: "Unknown", icon: Icon(Icons.device_unknown));

  final String desc;
  final Icon icon;

  const OS({required this.desc,	required this.icon});

  static OS fromTTL(String? ttl) {
    if (ttl == null) {
    	return OS.Unknown;
    }
    switch (ttl) {
      case "63":
	return OS.Linux;
      case "64":
	return OS.Unixlike;
      case "128":
	return OS.Windowslike;
      default:
	return OS.Other;
    }
  }
}


class ScannedDeviceCard extends StatelessWidget{
  late String ipv4;
  String? hostname;
  String? mac;
  double? delay;
  OS? os;

  ScannedDeviceCard({
    required this.ipv4, 
    this.hostname,
    this.mac,
    this.os,
    this.delay,
  });

  @override
    Widget build(BuildContext context) {
    return ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          leading: Icon(
            os?.icon.icon ?? Icons.device_unknown,
            size: 32,
            color: Colors.blueAccent,
          ),
          title: Text(
            hostname ?? ipv4,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ipv4,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              Text(
                mac ?? "MAC: Not Available",
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                os?.desc ?? "OS: Unknown",
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
               // isConnected ? Icons.wifi,
               // color: isConnected ? Colors.green : Colors.red,
                delay == null
		? Icons.question_mark
		: delay! < 300.0
		  ? Icons.signal_wifi_4_bar
		  : delay! < 500.0
		    ? Icons.network_wifi_3_bar
		    : delay! < 1000.0
		      ? Icons.network_wifi_2_bar
		      : delay! < 2000.0
			? Icons.network_wifi_1_bar
			: Icons.signal_wifi_0_bar,
		size: 32,
                color: delay == null
		? Colors.grey
		: delay! < 300.0
		  ? Colors.green
		  : delay! < 500.0
		    ? Colors.yellow
		    : delay! < 1000.0
		      ? Colors.orange
		      : delay! < 2000.0
			? Colors.red
			: Colors.grey,
              ),
	      Text(
		delay != null ? "${delay}ms" : "N/A ",
		style: TextStyle(fontSize: 12, color: Colors.grey[500]),
	      ),
            ],
          ),
        );
    }
}

class ScanList extends StatefulWidget {
  GlobalKey<AnimatedListState> listController = GlobalKey<AnimatedListState>();
  List<ScannedDeviceCard> ss = [];
  
  ScanList({super.key});

  @override
  State<ScanList> createState() => _scanListState();

  bool get isEmpty => ss.isEmpty;

  void insertAtBeginning(ScannedDeviceCard card, int index) {
    listController.currentState!.insertItem(index);
    ss.insert(index, card);
  }
}

class _scanListState extends State<ScanList> {
  @override
  Widget build(BuildContext context) {
      return AnimatedList(
        key: widget.listController,
        physics: const AlwaysScrollableScrollPhysics(),
        initialItemCount: widget.ss.length,
        itemBuilder: (context, index, animation) {
          return SlideTransition(
            position: animation.drive(
              Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero
              ).chain(CurveTween(curve: Curves.ease))
            ),
            child: widget.ss[index],
          );
        }
      );
  }
}

// Warp Network Interface
class WNInterface extends StatefulWidget {
  late String name;
  late String ipv4;
  ScanList scanList = ScanList();

  WNInterface({super.key, required this.name, required this.ipv4});

  @override
  State<WNInterface> createState() => _WNInterfaceState();
}


class _WNInterfaceState extends State<WNInterface> {


  // NATIVE ZONE

  MethodChannel _channel = MethodChannel("warp.native");

 //final int WORKER_COUNT = 4;

  Future<String> scan(String ipv4) async {
      
      return await _channel.invokeMethod(
	"scan",
	{
	  "ipv4": ipv4,
	}
      );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print("building...");
    
    return
      RefreshIndicator(
	child: 
      	  ScrollConfiguration(
      	    behavior: ScrollConfiguration.of(context).copyWith(
      	      dragDevices: {
      	        PointerDeviceKind.touch,
      	        PointerDeviceKind.mouse,
      	      },
      	    ),
      	    child: 
	      widget.scanList.isEmpty
	      // stack a listview to trick the refresh indicator
	      ? Stack(children: [widget.scanList, centralNotice("Swipe down to scan!")])
      	      : widget.scanList
      	  ),
      	onRefresh: () async {

	  final discovery = await startDiscovery('_http._tcp');
	  discovery.addListener(() {
	    discovery.services.forEach((s){
	      print(s);
	    });
	  });

	  await stopDiscovery(discovery);

	  final netaddr = widget.ipv4.split('.').sublist(0, 3).join('.');;
	  final int hostaddr = int.parse(widget.ipv4.split('.').last);
	  setState(() {
	    widget.scanList.insertAtBeginning(
	       ScannedDeviceCard(
	        ipv4: "${netaddr}.${hostaddr}",
		// We only support Android and Linux for now which linux isnt really supported yet.
		os: Platform.isAndroid ? OS.Android : OS.Linux,
		hostname: Platform.localHostname,
	      ),0
	    );
	  });

	  for (var i = 255; i >= 0; i--) {
	    if (i == hostaddr) continue;
	    await Future.delayed(const Duration(milliseconds: 80));
	    scan("${netaddr}.${i}").then((value) {
	      print("scanned ${value}");
	      Map<String, dynamic> json = jsonDecode(value);
	      print("scanned ${value}");

	      if (json["exist"] == "true")
		setState(() {
		  widget.scanList.insertAtBeginning(
	      ScannedDeviceCard(
		      ipv4: "${netaddr}.${i}",
		      os: OS.fromTTL(json["ttl"]),
		      delay: double.parse(json["delay"]),
		    ), 1
		  );
		});
	    });
	  }
      	}
      );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'wARP Discovery'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  List<WNInterface> interfaces = [];
  bool _isLoading = true;
  WNInterface? selectedInterface;

  @override
  void initState() {
  	super.initState();
	_loadInterfaces();
  }

  void _loadInterfaces() async {

    var ni = await NetworkInterface.list();
    ni.forEach((i) {
      print("interface ${i.name} ${i.addresses[0].address}");
      interfaces.add(WNInterface(name: i.name, ipv4: i.addresses[0].address));
    });

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    
    return _isLoading 
    ? const Scaffold(
      	body: Center(
      	  child: CircularProgressIndicator()
      	)
      ) 
    : interfaces.isEmpty 
      ? centralNotice("No network interface found!") 
      : Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
              actions: [
                DropdownButton(
                  value: selectedInterface,
                  onChanged: (value) {
                    setState(() {
		      selectedInterface = value;
		      print("selected ${selectedInterface!.scanList.ss}");
                    });
                  },
                  items: interfaces.map((i){
                	  return DropdownMenuItem(
                	    value: i,
                      child: Text("${i.name} (${i.ipv4})"),
                	  );
                	}).toList(),
                ),
              ],
            ),
            body: 
              selectedInterface ?? 
              centralNotice("Please select an interface")
          );
  }
}

void main() {
  runApp(const MyApp());
}

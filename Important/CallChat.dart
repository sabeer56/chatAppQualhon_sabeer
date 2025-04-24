import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:myflproject/Important/ChatApp.dart';

class MyCallPage extends StatefulWidget {
  @override
  State<MyCallPage> createState() => _MyCallPagePageState();
}

class _MyCallPagePageState extends State<MyCallPage> {
  final List<Call> calls = [
    Call(
      name: 'Hakiem',
      timeAgo: '37 Minutes Ago',
      isOutgoing: true,
    ),
    Call(
      name: 'Prakash',
      timeAgo: '2 Days Ago',
      isOutgoing: false,
    ),
    Call(
      name: 'Sai',
      timeAgo: '1 Week Ago',
      isOutgoing: false,
    ),
  ];

  OverlayEntry? _overlayEntry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call History',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        elevation: 5,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.grid_view),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Container(
        color: Colors.teal[50],
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          itemCount: calls.length,
          itemBuilder: (context, index) {
            final call = calls[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.teal[300],
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                title: Text(
                  call.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                trailing: IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.call, color: Colors.teal[800]),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Transform.rotate(
                          angle: call.isOutgoing ? 3.14 / 4 : 5 * 3.14 / 4,
                          child: FaIcon(
                            FontAwesomeIcons.arrowDown,
                            color: call.isOutgoing ? Colors.green : Colors.red,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          call.isOutgoing ? "Outgoing" : "Incoming",
                          style: TextStyle(
                            color: call.isOutgoing ? Colors.green : Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      call.timeAgo,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_overlayEntry != null) {
            _overlayEntry!.remove();
            _overlayEntry = null;
          } else {
            _showOverlayDialog(context);
          }
        },
        backgroundColor: Colors.teal.shade600,
        child: const Icon(Icons.settings, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.message),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatApp(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.phone),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MyCallPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showOverlayDialog(BuildContext context) {
    final overlay = Overlay.of(context);

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: () {
          // Close the overlay when tapped outside
          _overlayEntry?.remove();
          _overlayEntry = null;
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: Colors.black54,
              ),
            ),
            Positioned(
              bottom: MediaQuery.of(context).viewInsets.bottom +
                  95, // Adjust for the FloatingActionButton
              left: MediaQuery.of(context).size.width * 0.5 - 150,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 300,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: () {
                      // Prevent tap from closing the dialog
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Settings',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const FaIcon(FontAwesomeIcons.user),
                          title: const Text('Profile Settings'),
                          onTap: () {
                            Navigator.pop(context);
                            // Handle navigation to Profile Settings
                          },
                        ),
                        ListTile(
                          leading: const FaIcon(FontAwesomeIcons.cogs),
                          title: const Text('App Settings'),
                          onTap: () {
                            Navigator.pop(context);
                            // Handle navigation to App Settings
                          },
                        ),
                        ListTile(
                          leading: const FaIcon(FontAwesomeIcons.signOutAlt),
                          title: const Text('Logout'),
                          onTap: () {
                            Navigator.pop(context);
                            // Handle logout functionality
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }
}

class Call {
  final String name;
  final String timeAgo;
  final bool isOutgoing;

  Call({
    required this.name,
    required this.timeAgo,
    required this.isOutgoing,
  });
}

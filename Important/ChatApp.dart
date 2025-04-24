import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:myflproject/Important/CallChat.dart';
import 'package:myflproject/Important/PerChat.dart';

class ChatApp extends StatefulWidget {
  @override
  ChatAppPage createState() => ChatAppPage();
}

class ChatAppPage extends State<ChatApp> {
  OverlayEntry? _overlayEntry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.teal,
        appBarTheme: AppBarTheme(
          color: Colors.teal,
          titleTextStyle: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Contacts'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {},
          ),
        ),
        body: const ChatList(),
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
                onPressed: () {},
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

class ChatList extends StatelessWidget {
  const ChatList({Key? key}) : super(key: key);

  final List<Map<String, String>> messages = const [
    {"name": "Syed Sabeer", "message": "Hi!", "time": "1.00 pm"},
    {"name": "Surya", "message": "Morning!", "time": "1.00 pm"},
    {"name": "Prakash", "message": "What's up?", "time": "1.30 pm"},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return ChatTile(
          name: messages[index]['name']!,
          message: messages[index]['message']!,
          time: messages[index]['time']!,
        );
      },
    );
  }
}

class ChatTile extends StatelessWidget {
  final String name;
  final String message;
  final String time;

  const ChatTile({
    Key? key,
    required this.name,
    required this.message,
    required this.time,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PersonalChat(), // Navigate to personal chat
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(message,
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade700)),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 16.0,
                          color: Colors.teal,
                        ),
                        const SizedBox(width: 4.0),
                        Text('status',
                            style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(time,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // BottomSheet for settings
}

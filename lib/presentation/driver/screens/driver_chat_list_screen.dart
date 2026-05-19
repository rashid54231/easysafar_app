import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../passenger/screens/chat_screen.dart';

class DriverChatListScreen extends StatelessWidget {
  const DriverChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final driverId = Supabase.instance.client.auth.currentUser!.id;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Text("Passenger Messages"),
        backgroundColor: Colors.blue[900],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('messages')
            .stream(primaryKey: ['id'])
            .eq('receiver_id', driverId)
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final messages = snapshot.data!;
          final uniqueChats = <String, Map<String, dynamic>>{};

          // Unique passengers filter kar rahe hain
          for (var msg in messages) {
            if (!uniqueChats.containsKey(msg['sender_id'])) {
              uniqueChats[msg['sender_id']] = msg;
            }
          }

          final chatList = uniqueChats.values.toList();

          if (chatList.isEmpty) {
            return const Center(child: Text("No messages yet", style: TextStyle(color: Colors.white60)));
          }

          return ListView.builder(
            itemCount: chatList.length,
            itemBuilder: (context, index) {
              final chat = chatList[index];
              final senderId = chat['sender_id'];

              // --- NAYA LOGIC: FutureBuilder use kar rahe hain profile se naam lane ke liye ---
              return FutureBuilder<Map<String, dynamic>?>(
                future: Supabase.instance.client
                    .from('profiles')
                    .select('full_name')
                    .eq('id', senderId)
                    .maybeSingle(),
                builder: (context, profileSnapshot) {
                  // Jab tak naam load ho raha ho, "Loading..." dikhayen
                  String displayName = "Loading...";
                  if (profileSnapshot.hasData && profileSnapshot.data != null) {
                    displayName = profileSnapshot.data!['full_name'] ?? "User";
                  } else if (profileSnapshot.connectionState == ConnectionState.done) {
                    displayName = "User"; // Agar naam na mile
                  }

                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(
                      displayName, // Ab yahan asli naam aayega
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      chat['content'] ?? "",
                      style: const TextStyle(color: Colors.white70),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            tripId: chat['trip_id'].toString(),
                            receiverId: senderId,
                            receiverName: displayName, // Chat screen mein bhi asli naam jayega
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
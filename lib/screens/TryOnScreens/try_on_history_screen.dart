import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'try_on_detail_screen.dart';

class TryOnHistoryScreen extends StatelessWidget {
  const TryOnHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Try-On History"),
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        elevation: 4,
      ),
      body: userId == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(30.0),
                child: Text(
                  "Please log in to Firebase Authentication to save and view your history.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Users')
                  .doc(userId)
                  .collection('virtual_try_on')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text("Error fetching data: ${snapshot.error}"),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("You have no saved try-on results yet."),
                  );
                }

                // Display the history as a list
                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final imageUrl = data['imageUrl'] as String;
                    final timestamp = data['timestamp'] as Timestamp?;
                    final garmentsCount = data['garmentsCount'] as int? ?? 0;

                    final date = timestamp?.toDate();
                    final formattedDate = date != null
                        ? "${date.month}/${date.day}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}"
                        : "Unknown date";

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 5,
                      ),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            // Display the image from the Cloudinary URL
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(child: Icon(Icons.broken_image)),
                            ),
                          ),
                        ),
                        title: Text(
                          "Try-On Result ($garmentsCount Garments)",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text("Saved: $formattedDate"),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // Navigate to the detail screen, passing the data
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => TryOnDetailScreen(
                                imageUrl: imageUrl,
                                formattedDate: formattedDate,
                                garmentsCount: garmentsCount,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

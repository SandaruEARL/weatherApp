import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.blue[400],
        title: const Text('Weather History',style: TextStyle(color: Colors.white)),

      ),

      body: StreamBuilder<QuerySnapshot>(

        stream: FirebaseFirestore.instance
            .collection('weatherData')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading data'));
          }

          final documents = snapshot.data?.docs;

          return ListView.builder(
            itemCount: documents?.length ?? 0,
            itemBuilder: (context, index) {
              final data = documents![index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['city']),
                subtitle: Text('Temperature: ${data['temperature']}°C'),
                trailing: Text(data['timestamp'].toDate().toString()),
              );
            },
          );
        },
      ),
    );
  }
}

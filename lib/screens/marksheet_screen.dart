import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class MarksheetScreen extends StatelessWidget {
  const MarksheetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final savedMarksheets = context.watch<AppProvider>().savedMarksheets;

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Marksheets')),
      body: savedMarksheets.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_edu, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text("No saved marksheets yet.", style: TextStyle(color: Colors.grey, fontSize: 18)),
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text("Complete a quiz with Premium to see your progress here!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: savedMarksheets.length,
              itemBuilder: (context, index) {
                final item = savedMarksheets[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      child: Text(item['percentage'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(item['topic'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Score: ${item['score']} | ${item['date'].toString().substring(0, 10)}"),
                    trailing: const Icon(Icons.download, color: Colors.blue),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Downloading marksheet..."))
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

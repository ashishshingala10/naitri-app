import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../api.dart';
import '../theme.dart';

class DocumentsScreen extends StatefulWidget {
  final int loanId;
  final String loanCode;
  const DocumentsScreen({super.key, required this.loanId, required this.loanCode});
  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  Future<List>? _future;

  @override
  void initState() {
    super.initState();
    _future = Api.i.documents(widget.loanId);
  }

  Future<void> _download(String key, String title) async {
    try {
      final bytes = await Api.i.statementCsv(widget.loanId); // statement + schedule both come as CSV
      final dir = await getTemporaryDirectory();
      final f = File('${dir.path}/${widget.loanCode}-$key.csv');
      await f.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(f.path)], text: '$title — ${widget.loanCode}');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Brand.red, content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Documents & statements')),
      body: FutureBuilder<List>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text(snap.error.toString(), style: const TextStyle(color: Brand.inkSoft)));
          }
          final docs = (snap.data!).cast<Map>();
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final d = docs[i];
              final can = d['downloadable'] == true;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.insert_drive_file_outlined, color: Brand.red),
                  title: Text(d['title'] ?? ''),
                  subtitle: can ? null : Text(d['note'] ?? '', style: const TextStyle(fontSize: 12)),
                  trailing: can
                      ? const Icon(Icons.download_rounded, color: Brand.red)
                      : const Icon(Icons.lock_outline, color: Brand.inkSoft, size: 18),
                  onTap: can ? () => _download(d['key'], d['title']) : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

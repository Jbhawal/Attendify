import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ExportsPage extends StatefulWidget {
  const ExportsPage({super.key});

  @override
  State<ExportsPage> createState() => _ExportsPageState();
}

class _ExportsPageState extends State<ExportsPage> {
  List<File> _files = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<Directory> _getExportDir() async {
    try {
      if (Platform.isAndroid) {
        final dirs = await getExternalStorageDirectories(type: StorageDirectory.downloads);
        if (dirs != null && dirs.isNotEmpty) return dirs.first;
      }
    } catch (_) {}
    return getApplicationDocumentsDirectory();
  }

  Future<void> _loadFiles() async {
    setState(() {
      _loading = true;
    });

    try {
      // On Android some directories may require permissions; we try to read and
      // fallback silently if not allowed.
    } catch (_) {}

    final dir = await _getExportDir();
    final files = dir.existsSync() ? dir.listSync().whereType<File>().toList() : <File>[];
    files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

    setState(() {
      _files = files;
      _loading = false;
    });
  }

  Future<void> _openFile(File f) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      if (Platform.isWindows) {
        await Process.start('explorer', [f.path]);
      } else if (Platform.isMacOS) {
        await Process.start('open', [f.path]);
      } else if (Platform.isLinux) {
        await Process.start('xdg-open', [f.path]);
      } else {
        // Mobile: copy path and inform user to open externally
        await Clipboard.setData(ClipboardData(text: f.path));
        messenger?.showSnackBar(const SnackBar(content: Text('File path copied to clipboard (open externally)')));
        return;
      }
    } catch (_) {
      messenger?.showSnackBar(const SnackBar(content: Text('Cannot open file')));
    }
  }

  Future<void> _copyPath(File f) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    await Clipboard.setData(ClipboardData(text: f.path));
    messenger?.showSnackBar(const SnackBar(content: Text('Path copied to clipboard')));
  }

  Future<void> _deleteFile(File f) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final ok = await showDialog<bool?>(context: context, builder: (ctx) => AlertDialog(
          title: const Text('Delete file?'),
          content: Text('Delete ${p.basename(f.path)}? This action cannot be undone.'),
          actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete'))],
        ));
    if (ok == true) {
      try {
        await f.delete();
        messenger?.showSnackBar(const SnackBar(content: Text('File deleted')));
      } catch (_) {
        messenger?.showSnackBar(const SnackBar(content: Text('Could not delete file')));
      }
      await _loadFiles();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exports')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('No exports found'), const SizedBox(height: 8), FilledButton(onPressed: _loadFiles, child: const Text('Refresh'))]))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _files.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final f = _files[i];
                    final name = p.basename(f.path);
                    final m = f.statSync().modified;
                    return ListTile(
                      title: Text(name),
                      subtitle: Text('${m.toLocal()}'),
                      trailing: PopupMenuButton<String>(onSelected: (v) async {
                        if (v == 'open') await _openFile(f);
                        if (v == 'copy') await _copyPath(f);
                        if (v == 'delete') await _deleteFile(f);
                      }, itemBuilder: (_) => [const PopupMenuItem(value: 'open', child: Text('Open')), const PopupMenuItem(value: 'copy', child: Text('Copy path')), const PopupMenuItem(value: 'delete', child: Text('Delete'))]),
                      onTap: () => _openFile(f),
                    );
                  },
                ),
    );
  }
}

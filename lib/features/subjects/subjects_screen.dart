import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/subject.dart';
import '../../providers.dart';
import '../../constants/app_colors.dart';
import '../../widgets/responsive_page.dart';

class SubjectsScreen extends ConsumerWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = ref.watch(subjectsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Subjects')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSubjectSheet(context, ref),
        label: const Text('Add Subject'),
        icon: const Icon(Icons.add_rounded),
      ),
      body: ResponsivePage(
        // Let the list span the full width of the screen
        padding: EdgeInsets.zero,
        child: subjects.isEmpty
            ? Center(child: Text('No subjects yet', style: Theme.of(context).textTheme.bodyLarge))
            : ListView.separated(
                padding: const EdgeInsets.only(bottom: 120, top: 12),
                itemCount: subjects.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _SubjectCard(subject: subjects[index]),
              ),
      ),
    );
  }

  Future<void> _showSubjectSheet(BuildContext context, WidgetRef ref, {Subject? subject}) async {
    final nameController = TextEditingController(text: subject?.name ?? '');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final bottom = MediaQuery.of(context).viewInsets.bottom;
        return ResponsivePage(
          padding: EdgeInsets.fromLTRB(20, 24, 20, bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 12),
              Row(children: [Expanded(child: FilledButton(onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                if (subject == null) {
                  await ref.read(subjectsProvider.notifier).addSubject(name: name, code: '', professor: '', credits: 3, color: '#00897B');
                } else {
                  await ref.read(subjectsProvider.notifier).updateSubject(subject.copyWith(name: name));
                }
                if (context.mounted) Navigator.of(context).pop();
              }, child: const Text('Save')))]),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

class _SubjectCard extends ConsumerStatefulWidget {
  const _SubjectCard({Key? key, required this.subject}) : super(key: key);
  final Subject subject;

  @override
  ConsumerState<_SubjectCard> createState() => _SubjectCardState();
}

class _SubjectCardState extends ConsumerState<_SubjectCard> {
  bool _expanded = false;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final s = widget.subject;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          ListTile(
            onTap: _toggle,
            leading: CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Text(s.name.isNotEmpty ? s.name[0].toUpperCase() : '?'),
            ),
            title: Text(s.name, style: Theme.of(context).textTheme.titleMedium),
            subtitle: s.code.isNotEmpty ? Text(s.code) : null,
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              // Add past attendance moved into header
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                onPressed: () => _showAddPastAttendance(context, ref, s),
                tooltip: 'Add past attendance',
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () => _showSubjectSheet(context, ref, subject: s),
                tooltip: 'Edit',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Delete?'),
                      content: Text('Delete ${s.name}?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('No')),
                        FilledButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Yes')),
                      ],
                    ),
                  );
                  if (ok ?? false) await ref.read(subjectsProvider.notifier).deleteSubject(s.id);
                },
                tooltip: 'Delete',
              ),
            ]),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (s.professor.isNotEmpty) Text('Professor: ${s.professor}'),
                  const SizedBox(height: 6),
                  Text('Credits: ${s.credits}'),
                  const SizedBox(height: 6),
                  // Placeholder area for attendance summary; keep UI light and avoid heavy computations here
                  Text('More details and quick actions available when expanded.'),
                ],
              ),
            ),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 240),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddPastAttendance(BuildContext context, WidgetRef ref, Subject subject) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final dateController = TextEditingController(text: DateTime.now().toIso8601String());
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add past attendance for ${subject.name}', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(controller: dateController, decoration: const InputDecoration(labelText: 'Date (ISO)'), keyboardType: TextInputType.datetime),
              const SizedBox(height: 12),
              Row(children: [Expanded(child: FilledButton(onPressed: () async {
                // Placeholder: real implementation should create an AttendanceRecord
                Navigator.of(context).pop();
              }, child: const Text('Save')))]),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showSubjectSheet(BuildContext context, WidgetRef ref, {Subject? subject}) async {
    // delegate to parent helper on SubjectsScreen
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final nameController = TextEditingController(text: subject?.name ?? '');
        final bottom = MediaQuery.of(context).viewInsets.bottom;
        return ResponsivePage(
          padding: EdgeInsets.fromLTRB(20, 24, 20, bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            Row(children: [Expanded(child: FilledButton(onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              if (subject == null) {
                await ref.read(subjectsProvider.notifier).addSubject(name: name, code: '', professor: '', credits: 3, color: '#00897B');
              } else {
                await ref.read(subjectsProvider.notifier).updateSubject(subject.copyWith(name: name));
              }
              if (context.mounted) Navigator.of(context).pop();
            }, child: const Text('Save')))]),
            const SizedBox(height: 12),
          ]),
        );
      },
    );
  }
}

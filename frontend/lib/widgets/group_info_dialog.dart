import 'package:flutter/material.dart';
import '../config/config.dart';

class GroupInfoDialog extends StatelessWidget {
  final String groupName;
  final List<dynamic> participants;

  const GroupInfoDialog({
    super.key,
    required this.groupName,
    required this.participants,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Group: $groupName'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: participants.length,
                itemBuilder: (context, index) {
                  final user = participants[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: user['profilePicture'] != null
                          ? NetworkImage('${Config.baseUrl}/${user['profilePicture']}')
                          : const AssetImage('assets/images/defaultProfile.jpg') as ImageProvider,
                    ),
                    title: Text(user['username'] ?? 'Unknown User'),
                    subtitle: Text(index == 0 ? 'Admin' : 'Member'), // Simplified role for now
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String _selectedFilter = 'All';
  int _unreadCount = 2;

  final List<Map<String, dynamic>> _notifications = [
    {
      'id': 1,
      'type': 'claim_approved',
      'title': 'Claim Approved!',
      'message': 'Your claim "Blue Umbrella" has been approved. You can pick it up from St. Raymund.',
      'time': '6:58 AM',
      'isRead': false,
      'icon': Icons.check_circle,
      'iconColor': Color(0xFF4318FF),
      'bgColor': Color(0xFFE8E4FF),
      'hasAction': true,
      'actionText': 'View Pickup Info',
    },
    {
      'id': 2,
      'type': 'new_claim',
      'title': 'New Claim Received',
      'message': 'J. Smith wants to claim your posted item "Student ID - Jane Smith"',
      'time': '6:58 AM',
      'isRead': false,
      'icon': Icons.notifications,
      'iconColor': Color(0xFF4318FF),
      'bgColor': Color(0xFFE8E4FF),
      'hasAction': true,
      'actionText': 'Review Claim',
    },
    {
      'id': 3,
      'type': 'challenge',
      'title': 'Challenge Progress',
      'message': 'You\'re halfway to earning the "Rainy Day Hero" badge! Return 1 more umbrella this month.',
      'time': '6:54 AM',
      'isRead': true,
      'icon': Icons.emoji_events,
      'iconColor': Color(0xFF9333EA),
      'bgColor': Color(0xFFF3E8FF),
      'hasAction': false,
    },
  ];

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification['isRead'] = true;
      }
      _unreadCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredNotifications = _selectedFilter == 'All'
        ? _notifications
        : _notifications.where((n) => !n['isRead']).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$_unreadCount unread',
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 8),
                _buildFilterChip('Unread ($_unreadCount)'),
                const Spacer(),
                TextButton(
                  onPressed: _markAllAsRead,
                  child: const Text(
                    'Mark all read',
                    style: TextStyle(
                      color: Color(0xFF4318FF),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Notifications List
          Expanded(
            child: filteredNotifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredNotifications.length,
                    itemBuilder: (context, index) {
                      final notification = filteredNotifications[index];
                      return _buildNotificationCard(notification);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = label.startsWith(_selectedFilter);
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = label.split(' ')[0];
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black87 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black54,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: notification['bgColor'],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: notification['iconColor'],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  notification['icon'],
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          notification['title'],
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              notification['time'],
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(width: 4),
                            if (!notification['isRead'])
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4318FF),
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification['message'],
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    if (notification['hasAction']) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4ECDC4),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            notification['actionText'],
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

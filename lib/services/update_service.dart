import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  /// Check for updates and prompt user if available
  /// Call this when app starts or when user opens the app
  Future<void> checkForUpdate(BuildContext context) async {
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        // Update is available
        debugPrint('Update available: ${updateInfo.availableVersionCode}');
        
        // Check if immediate update is allowed (for critical updates)
        if (updateInfo.immediateUpdateAllowed) {
          // Show dialog before forcing update
          if (context.mounted) {
            _showUpdateDialog(
              context,
              title: 'Update Required',
              message: 'A critical update is available. The app needs to update now to continue.',
              isForced: true,
              updateInfo: updateInfo,
            );
          }
        } 
        // Check if flexible update is allowed (for optional updates)
        else if (updateInfo.flexibleUpdateAllowed) {
          if (context.mounted) {
            _showUpdateDialog(
              context,
              title: 'Update Available',
              message: 'A new version of iBalik is available. Update now to get the latest features and improvements!',
              isForced: false,
              updateInfo: updateInfo,
            );
          }
        }
      } else {
        debugPrint('No update available');
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      // Silently fail - don't interrupt user experience
    }
  }

  /// Show update dialog to user
  void _showUpdateDialog(
    BuildContext context, {
    required String title,
    required String message,
    required bool isForced,
    required AppUpdateInfo updateInfo,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !isForced, // Can't dismiss if forced update
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              isForced ? Icons.warning : Icons.system_update,
              color: isForced ? Colors.orange : const Color(0xFF2196F3),
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            if (updateInfo.availableVersionCode != null)
              Text(
                'Version: ${updateInfo.availableVersionCode}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
        actions: [
          if (!isForced)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Later'),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performUpdate(context, isForced: isForced);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Update Now',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// Perform the actual update
  Future<void> _performUpdate(BuildContext context, {required bool isForced}) async {
    try {
      if (isForced) {
        // Immediate update - app will restart automatically
        await InAppUpdate.performImmediateUpdate();
      } else {
        // Flexible update - download in background
        await InAppUpdate.startFlexibleUpdate();
        
        // Listen for download completion
        InAppUpdate.completeFlexibleUpdate().then((_) {
          if (context.mounted) {
            _showUpdateCompletedSnackBar(context);
          }
        }).catchError((e) {
          debugPrint('Error completing flexible update: $e');
        });
      }
    } catch (e) {
      debugPrint('Error performing update: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show snackbar when flexible update is downloaded
  void _showUpdateCompletedSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.download_done, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text('Update downloaded! Tap to install.'),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        duration: const Duration(seconds: 10),
        action: SnackBarAction(
          label: 'Install',
          textColor: Colors.white,
          onPressed: () async {
            try {
              await InAppUpdate.completeFlexibleUpdate();
            } catch (e) {
              debugPrint('Error completing update: $e');
            }
          },
        ),
      ),
    );
  }

  /// Manual check for updates (when user taps "Check for Updates" in settings)
  Future<void> manualUpdateCheck(BuildContext context) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Checking for updates...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
      }

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        if (context.mounted) {
          _showUpdateDialog(
            context,
            title: 'Update Available',
            message: 'A new version of iBalik is available!',
            isForced: updateInfo.immediateUpdateAllowed,
            updateInfo: updateInfo,
          );
        }
      } else {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 28),
                  SizedBox(width: 12),
                  Text('You\'re Up to Date'),
                ],
              ),
              content: const Text(
                'You\'re using the latest version of iBalik!',
                style: TextStyle(fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.orange, size: 28),
                SizedBox(width: 12),
                Text('Check Failed'),
              ],
            ),
            content: const Text(
              'Could not check for updates. Please try again later.',
              style: TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}

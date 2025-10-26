import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsManager {
  Future<bool> requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isDenied) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }
    
    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        final shouldOpen = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Camera Permission Required'),
            content: const Text(
              'Camera access is required to scan documents. Please enable it in settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
        
        if (shouldOpen == true) {
          await openAppSettings();
        }
      }
      return false;
    }
    
    return false;
  }
}
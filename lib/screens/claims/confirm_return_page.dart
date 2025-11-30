import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import 'return_success_page.dart';
import '../../utils/page_transitions.dart';
import '../../utils/app_theme.dart';
import '../../utils/claims_theme.dart';
import '../../services/game_service.dart';
import '../../services/supabase_storage_service.dart';

class ConfirmReturnPage extends StatefulWidget {
  final Map<String, dynamic> itemData;
  final String claimId;

  const ConfirmReturnPage({
    super.key, 
    required this.itemData,
    required this.claimId,
  });

  @override
  State<ConfirmReturnPage> createState() => _ConfirmReturnPageState();
}

class _ConfirmReturnPageState extends State<ConfirmReturnPage> {
  bool _verifiedIdentity = false;
  final TextEditingController _meetingLocationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final List<Uint8List> _returnImagesBytes = [];
  final List<String> _returnImageNames = [];
  final int maxImages = 5;
  bool _isProcessing = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();
  final SupabaseStorageService _storageService = SupabaseStorageService();
  
  Map<String, dynamic> _itemData = {};
  bool _loadingItemData = true;

  @override
  void initState() {
    super.initState();
    _loadItemData();
  }
  
  Future<void> _loadItemData() async {
    try {
      // Get claim to find itemId
      final claimDoc = await _firestore.collection('claims').doc(widget.claimId).get();
      if (!claimDoc.exists) {
        setState(() {
          _itemData = widget.itemData;
          _loadingItemData = false;
        });
        return;
      }
      
      final claimData = claimDoc.data() as Map<String, dynamic>;
      final itemId = claimData['itemId'];
      
      if (itemId != null) {
        // Fetch the lost_item document
        final itemDoc = await _firestore.collection('lost_items').doc(itemId.toString()).get();
        
        if (itemDoc.exists) {
          final lostItemData = itemDoc.data() as Map<String, dynamic>;
          
          // Merge claim data with lost item data
          setState(() {
            _itemData = {
              ...widget.itemData,
              'title': lostItemData['title'] ?? lostItemData['name'] ?? widget.itemData['title'],
              'description': lostItemData['description'] ?? lostItemData['details'] ?? widget.itemData['description'],
              'location': lostItemData['location'] ?? lostItemData['pickupLocation'] ?? lostItemData['foundAt'],
              'images': lostItemData['images'],
              'imageUrl': (lostItemData['images'] is List && (lostItemData['images'] as List).isNotEmpty) 
                  ? (lostItemData['images'] as List).first 
                  : null,
              'itemId': itemId,
              'claimerId': claimData['claimerId'],
              'founderId': claimData['founderId'],
              'claimerName': claimData['claimerName'] ?? claimData['seekerName'],
            };
            _loadingItemData = false;
          });
          return;
        }
      }
      
      // Fallback to widget data
      setState(() {
        _itemData = widget.itemData;
        _loadingItemData = false;
      });
    } catch (e) {
      debugPrint('Error loading item data: $e');
      setState(() {
        _itemData = widget.itemData;
        _loadingItemData = false;
      });
    }
  }

  @override
  void dispose() {
    _meetingLocationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickReturnImages() async {
    if (_returnImagesBytes.length >= maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum $maxImages images allowed'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 85,
      );
      
      if (pickedFiles.isEmpty) return;

      final int remainingSlots = maxImages - _returnImagesBytes.length;
      final List<XFile> filesToAdd = pickedFiles.take(remainingSlots).toList();

      for (var file in filesToAdd) {
        final bytes = await file.readAsBytes();
        setState(() {
          _returnImagesBytes.add(bytes);
          _returnImageNames.add(file.name);
        });
      }

      if (pickedFiles.length > remainingSlots) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Only added $remainingSlots images (limit: $maxImages)'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${filesToAdd.length} image(s) added'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _returnImagesBytes.removeAt(index);
      _returnImageNames.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image removed'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _viewImage(int index) {
    showDialog(
      context: context,
      builder: (context) => _ImageViewerDialog(
        imagesBytes: _returnImagesBytes,
        initialIndex: index,
      ),
    );
  }

  Future<void> _confirmReturn() async {
    if (!_verifiedIdentity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify the owner\'s identity first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_meetingLocationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the return location'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isProcessing = true);

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get the claim data first to ensure we have all necessary information
      final claimDoc = await _firestore.collection('claims').doc(widget.claimId).get();
      if (!claimDoc.exists) {
        throw Exception('Claim not found');
      }

      final claimData = claimDoc.data() as Map<String, dynamic>;
      final claimerId = claimData['claimerId'];
      final founderId = claimData['founderId'];
      final itemId = widget.itemData['itemId'];
      
      // Validate that current user is the founder
      if (currentUser.uid != founderId) {
        throw Exception('Only the item founder can confirm returns. Current user: ${currentUser.uid}, Required founder: $founderId');
      }
      
      print('Founder validation passed - User ${currentUser.uid} is confirming return for claim ${widget.claimId}');

      // Create a batch write for all operations
      final batch = _firestore.batch();

      // Upload return images if any
      List<String> returnImageUrls = [];
      if (_returnImagesBytes.isNotEmpty) {
        try {
          final itemId = widget.itemData['itemId']?.toString() ?? widget.claimId;
          
          returnImageUrls = await _storageService.uploadMultipleImagesBytes(
            imagesBytes: _returnImagesBytes,
            fileNames: _returnImageNames,
            itemId: itemId,
            type: 'returns',
          );
          
          print('Uploaded ${returnImageUrls.length} return images');
        } catch (e) {
          print('Error uploading return images: $e');
          // Continue with the return process even if image upload fails
        }
      }

      // 1. Update claim status to 'completed' (matches Firestore rules)
      final claimRef = _firestore.collection('claims').doc(widget.claimId);
      final Map<String, dynamic> claimUpdate = {
        'status': 'completed',
        'returnedAt': FieldValue.serverTimestamp(),
        'returnLocation': _meetingLocationController.text.trim(),
        'returnNotes': _notesController.text.trim(),
        'returnedBy': currentUser.uid,
      };
      
      // Add image data if available
      if (returnImageUrls.isNotEmpty) {
        claimUpdate['returnImages'] = returnImageUrls;
        claimUpdate['returnImage'] = returnImageUrls.first; // Backward compatibility
        claimUpdate['hasReturnPhoto'] = true;
      } else {
        claimUpdate['hasReturnPhoto'] = false;
      }
      
      batch.update(claimRef, claimUpdate);

      // 2. Update lost item status to 'returned'
      if (itemId != null) {
        final itemRef = _firestore.collection('lost_items').doc(itemId.toString());
        batch.update(itemRef, {
          'status': 'returned',
          'returnedAt': FieldValue.serverTimestamp(),
          'returnedTo': claimerId,
        });
      }

      // 3. Create notification for the claimer (item owner)
      if (claimerId != null) {
        final notificationRef = _firestore.collection('notifications').doc();
        final itemTitle = _itemData['title'] ?? widget.itemData['title'] ?? 'item';
        batch.set(notificationRef, {
          'userId': claimerId,
          'type': 'item_returned',
          'title': 'Item Successfully Returned! 🎉',
          'message': 'Your $itemTitle has been successfully returned by the founder.',
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
          'meta': {
            'itemId': itemId,
            'claimId': widget.claimId,
            'itemTitle': itemTitle,
            'founderId': founderId,
          },
        });
      }

      // 4. Create notification for the founder (current user)
      final itemTitle2 = _itemData['title'] ?? widget.itemData['title'] ?? 'the item';
      final founderNotificationRef = _firestore.collection('notifications').doc();
      batch.set(founderNotificationRef, {
        'userId': currentUser.uid,
        'type': 'return_confirmed',
        'title': 'Return Confirmed!',
        'message': 'You successfully returned $itemTitle2 to its owner.',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'meta': {
          'itemId': itemId,
          'claimId': widget.claimId,
          'itemTitle': itemTitle2,
          'claimerId': claimerId,
        },
      });

      // 5. Add activity for the claimer
      if (claimerId != null) {
        final itemTitle3 = _itemData['title'] ?? widget.itemData['title'] ?? 'item';
        final claimerActivityRef = _firestore.collection('users').doc(claimerId).collection('activities').doc();
        batch.set(claimerActivityRef, {
          'type': 'item_received',
          'title': 'Item Received',
          'message': 'You received your $itemTitle3 from the founder.',
          'createdAt': FieldValue.serverTimestamp(),
          'meta': {
            'itemId': itemId,
            'claimId': widget.claimId,
            'itemTitle': itemTitle3,
            'founderId': founderId,
          },
        });
      }

      // Commit all Firestore operations first
      await batch.commit();
      print('✅ Batch commit successful for claim ${widget.claimId}');
      
      // 6. Use GameService for consistent rewards (points, karma, activity, notifications)
      // This should be called AFTER commit to ensure the claim is marked completed
      final gameService = GameService();
      final itemTitle = _itemData['title'] ?? widget.itemData['title'] ?? widget.itemData['itemName'] ?? 'Item';
      print('🎁 Rewarding successful return for: "$itemTitle" to user: ${currentUser.uid}');
      print('📊 Rewards: +20 Points, +15 Karma, +25 XP');
      
      try {
        await gameService.rewardSuccessfulReturn(itemTitle);
        print('✅ Rewards successfully applied!');
      } catch (rewardError) {
        print('❌ Error applying rewards: $rewardError');
        // Don't fail the entire operation if rewards fail
      }

      // Show success dialog
      if (mounted) {
        _showSuccessDialog();
      }

    } catch (e) {
      print('Return confirmation error: $e');
      print('Current user: ${_auth.currentUser?.uid}');
      print('Claim ID: ${widget.claimId}');
      print('Item ID: ${widget.itemData['itemId']}');
      
      if (mounted) {
        setState(() => _isProcessing = false);
        String errorMessage = 'Failed to confirm return';
        if (e.toString().contains('Only the item founder')) {
          errorMessage = 'You are not the founder of this item. Only the person who posted the lost item can confirm its return.';
        } else if (e.toString().contains('permission')) {
          errorMessage = 'Permission denied. Please check if you are the item founder.';
        } else if (e.toString().contains('not-found')) {
          errorMessage = 'Claim or item not found.';
        }
        _showError('$errorMessage');
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 32),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Return Confirmed!',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
        content: const Text(
          'The item has been successfully marked as returned. Rewards have been added to your account.',
          style: TextStyle(fontSize: 14),
        ),
      ),
    );

    // Navigate to success page after a short delay
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        Navigator.pop(context); // Close dialog
        Navigator.pushReplacement(
          context,
          SmoothPageRoute(
            page: const ReturnSuccessPage(
              pointsEarned: 20,  // From GameService.rewardSuccessfulReturn
              karmaEarned: 15,
              xpEarned: 25,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirm Return',
              style: AppTextStyles.h1,
            ),
            Text(
              'Mark this item as successfully returned',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        toolbarHeight: 70,
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Processing return...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.all(ClaimsSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item Details Card
                  Container(
                    padding: EdgeInsets.all(ClaimsSpacing.md),
                    decoration: ClaimsCardStyles.card(),
                    child: _loadingItemData
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : Row(
                            children: [
                              // Item Image
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: (_itemData['imageUrl'] != null && _itemData['imageUrl'].toString().isNotEmpty)
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          _itemData['imageUrl'],
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Icon(
                                              Icons.image,
                                              color: Colors.grey[400],
                                              size: 35,
                                            );
                                          },
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                value: loadingProgress.expectedTotalBytes != null
                                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                    : null,
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                    : Icon(
                                        Icons.image,
                                        color: Colors.grey[400],
                                        size: 35,
                                      ),
                              ),
                              SizedBox(width: ClaimsSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _itemData['title'] ?? 'Unknown Item',
                                      style: ClaimsTypography.subtitle,
                                    ),
                                    SizedBox(height: ClaimsSpacing.xxs),
                                    Text(
                                      _itemData['description'] ?? 'No description available',
                                      style: ClaimsTypography.body,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: ClaimsSpacing.xs),
                                    ClaimsWidgets.infoRow(
                                      icon: Icons.location_on,
                                      text: _itemData['location'] ?? 'Unknown location',
                                    ),
                                    SizedBox(height: ClaimsSpacing.xs),
                                    ClaimsWidgets.infoRow(
                                      icon: Icons.person,
                                      text: 'Returning to: ${_itemData['claimerName'] ?? 'Unknown user'}',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Verify Owner Identity Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.standard),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Verify Owner Identity',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        CheckboxListTile(
                          value: _verifiedIdentity,
                          onChanged: (value) {
                            setState(() {
                              _verifiedIdentity = value ?? false;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'I have verified the owner\'s identity',
                            style: ClaimsTypography.bodyBold,
                          ),
                          subtitle: Padding(
                            padding: EdgeInsets.only(top: ClaimsSpacing.xs),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildCheckItem('They provided the proof of ownership as described'),
                                _buildCheckItem('Their identity matches their claim details'),
                                _buildCheckItem('I am confident this is the rightful owner'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: ClaimsSpacing.lg),
                  
                  // Return Details Card
                  Container(
                    padding: EdgeInsets.all(ClaimsSpacing.lg),
                    decoration: ClaimsCardStyles.card(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Return Details',
                          style: ClaimsTypography.title,
                        ),
                        SizedBox(height: ClaimsSpacing.md),
                        Text(
                          'Where did the return take place?',
                          style: ClaimsTypography.bodyBold,
                        ),
                        SizedBox(height: ClaimsSpacing.xs),
                        TextField(
                          controller: _meetingLocationController,
                          decoration: InputDecoration(
                            hintText: 'e.g., Library Information Desk, Security Office',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              borderSide: BorderSide(color: AppColors.lightGray, width: 1.5),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Additional Notes (Optional)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _notesController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Any additional details about the return process...',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Return Photos Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.camera_alt, size: 20),
                            SizedBox(width: ClaimsSpacing.xs),
                            Text(
                              'Return Photos (Optional)',
                              style: ClaimsTypography.title,
                            ),
                            const Spacer(),
                            if (_returnImagesBytes.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2196F3).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${_returnImagesBytes.length}/$maxImages',
                                  style: const TextStyle(
                                    color: Color(0xFF2196F3),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: ClaimsSpacing.md),
                        
                        // Image Grid
                        if (_returnImagesBytes.isNotEmpty)
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 1.0,
                            ),
                            itemCount: _returnImagesBytes.length,
                            itemBuilder: (context, index) {
                              return Stack(
                                children: [
                                  InkWell(
                                    onTap: () => _viewImage(index),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFF2196F3).withOpacity(0.5),
                                          width: 2,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.memory(
                                          _returnImagesBytes[index],
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: InkWell(
                                      onTap: () => _removeImage(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        
                        if (_returnImagesBytes.isNotEmpty)
                          SizedBox(height: ClaimsSpacing.md),
                        
                        // Add Images Button
                        InkWell(
                          onTap: _pickReturnImages,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 2,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _returnImagesBytes.isEmpty ? Icons.camera_alt : Icons.add_photo_alternate,
                                    size: 40,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _returnImagesBytes.isEmpty
                                        ? 'Add photos of the successful return'
                                        : 'Add more photos (${_returnImagesBytes.length}/$maxImages)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Optional: Helps build trust in the community',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Your Rewards Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF4CAF50),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.stars,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Your Rewards',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                  Text(
                                    'Earned for successful return',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF388E3C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildRewardItem('+20', 'Points', const Color(0xFF2196F3)),
                            _buildRewardItem('+15', 'Karma', const Color(0xFF9C27B0)),
                            _buildRewardItem('🏆', 'Helper Badge', const Color(0xFFFFA726)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Need Help Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.help_outline,
                          color: Color(0xFF2196F3),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF1976D2),
                              ),
                              children: [
                                TextSpan(
                                  text: 'Need Help?\n',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                TextSpan(
                                  text: 'If you encounter any issues with the return process, contact our support team through the profile page.',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Confirm Button using ClaimsButton
                  ClaimsButton(
                    label: 'Confirm Successful Return',
                    icon: Icons.check_circle,
                    onPressed: _confirmReturn,
                    type: ClaimsButtonType.approve,
                    isLoading: _isProcessing,
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: ClaimsSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// Image Viewer Dialog for local images
class _ImageViewerDialog extends StatefulWidget {
  final List<Uint8List> imagesBytes;
  final int initialIndex;

  const _ImageViewerDialog({
    required this.imagesBytes,
    this.initialIndex = 0,
  });

  @override
  State<_ImageViewerDialog> createState() => _ImageViewerDialogState();
}

class _ImageViewerDialogState extends State<_ImageViewerDialog> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          // Image PageView
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imagesBytes.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.memory(
                    widget.imagesBytes[index],
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
          
          // Close button
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          
          // Image counter
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${widget.imagesBytes.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          
          // Navigation arrows (if more than 1 image)
          if (widget.imagesBytes.length > 1) ...[
            // Previous button
            if (_currentIndex > 0)
              Positioned(
                left: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_left,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
            // Next button
            if (_currentIndex < widget.imagesBytes.length - 1)
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
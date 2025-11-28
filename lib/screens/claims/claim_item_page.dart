import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/notification_service.dart';
import '../../services/activity_service.dart';
import '../../services/supabase_storage_service.dart';
// no external date package required; we'll format DateTime manually

class ClaimItemPage extends StatefulWidget {
  final Map<String, dynamic> item;

  const ClaimItemPage({super.key, required this.item});

  @override
  State<ClaimItemPage> createState() => _ClaimItemPageState();
}

class _ClaimItemPageState extends State<ClaimItemPage> {
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _additionalInfoController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _messengerController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  String _selectedContactMethod = '';
  
  // Multiple images upload state
  List<Uint8List> _proofImagesBytes = [];
  List<String> _proofImageNames = [];
  final ImagePicker _imagePicker = ImagePicker();
  static const int maxImages = 5;

  @override
  void dispose() {
    _detailsController.dispose();
    _additionalInfoController.dispose();
    _phoneController.dispose();
    _messengerController.dispose();
    _emailController.dispose();
    super.dispose();
  }
  
  Future<void> _pickProofImages() async {
    try {
      if (_proofImagesBytes.length >= maxImages) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Maximum $maxImages images allowed'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFiles.isNotEmpty) {
        final remainingSlots = maxImages - _proofImagesBytes.length;
        final filesToAdd = pickedFiles.take(remainingSlots).toList();
        
        for (var file in filesToAdd) {
          final bytes = await file.readAsBytes();
          _proofImagesBytes.add(bytes);
          _proofImageNames.add(file.name);
        }
        
        setState(() {});
        
        if (pickedFiles.length > remainingSlots) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Only $remainingSlots more images could be added (max $maxImages)'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _removeImage(int index) {
    setState(() {
      _proofImagesBytes.removeAt(index);
      _proofImageNames.removeAt(index);
    });
  }
  
  void _viewImage(int index) {
    showDialog(
      context: context,
      builder: (context) => _ImageViewerDialog(
        images: _proofImagesBytes,
        initialIndex: index,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Claim Item',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  
                  // Item Summary Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        // Item Image
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Builder(
                              builder: (context) {
                                // Prefer first image URL from `images` list if present
                                final images = widget.item['images'];
                                if (images is List && images.isNotEmpty && images[0] is String) {
                                  return Image.network(
                                    images[0],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stack) => Icon(
                                      Icons.image_not_supported,
                                      size: 32,
                                      color: Colors.grey[600],
                                    ),
                                  );
                                }
                                // Fallback to any provided icon or default umbrella icon
                                final iconData = widget.item['image'];
                                if (iconData is IconData) {
                                  return Icon(
                                    iconData,
                                    size: 32,
                                    color: Colors.grey[600],
                                  );
                                }
                                return Icon(
                                  Icons.umbrella,
                                  size: 32,
                                  color: Colors.grey[600],
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Item Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (widget.item['itemName'] ?? widget.item['name'] ?? widget.item['title'] ?? 'Untitled').toString(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                (widget.item['description'] ?? widget.item['details'] ?? '').toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    (widget.item['location'] ?? widget.item['place'] ?? 'Unknown location').toString(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                        // Prefer `dateFound` (ISO string) or `datePosted` (Timestamp)
                                        (() {
                                          final df = widget.item['dateFound'] ?? widget.item['datePosted'];
                                          if (df == null) return 'Found: Date unknown';
                                          if (df is String) {
                                          try {
                                            final dt = DateTime.parse(df);
                                            return 'Found: ${dt.month}/${dt.day}/${dt.year}';
                                          } catch (_) {
                                            return 'Found: ${df.toString()}';
                                          }
                                        }
                                        if (df is Timestamp) {
                                          final dt = df.toDate();
                                          return 'Found: ${dt.month}/${dt.day}/${dt.year}';
                                        }
                                        if (df is DateTime) {
                                          return 'Found: ${df.month}/${df.day}/${df.year}';
                                        }
                                          return 'Found: ${df.toString()}';
                                        })(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Prove Your Ownership Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF2196F3),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.verified_user,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Prove Your Ownership',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Provide details only the owner would know',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Details text field
                        const Text(
                          'Describe specific details about this item *',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _detailsController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: 'Example: "My phone has a purple case, cracked screen protector, wallpaper is my mom and dad. I have a banking app with notifications enabled. The last text was from my mom about dinner."',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF5F5F5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '• Include details like: contents, unique marks, personal settings, recent usage, or anything distinctive',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Additional Information
                        const Text(
                          'Additional Information (Optional)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _additionalInfoController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Any other details that might help verify your ownership...',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF5F5F5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Upload Proof Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF9C27B0),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Upload Proof (Optional)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Photos that support your claim',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Upload area - Multiple images support
                        Column(
                          children: [
                            if (_proofImagesBytes.isNotEmpty) ...[
                              // Image grid
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                                itemCount: _proofImagesBytes.length,
                                itemBuilder: (context, index) {
                                  return Stack(
                                    children: [
                                      InkWell(
                                        onTap: () => _viewImage(index),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: const Color(0xFF9C27B0),
                                              width: 2,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(6),
                                            child: Image.memory(
                                              _proofImagesBytes[index],
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
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 4,
                                        right: 4,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.zoom_in,
                                                color: Colors.white,
                                                size: 12,
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                'View',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                            ],
                            // Add more button
                            if (_proofImagesBytes.length < maxImages)
                              InkWell(
                                onTap: _pickProofImages,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 32),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _proofImagesBytes.isNotEmpty 
                                          ? const Color(0xFF9C27B0) 
                                          : Colors.grey[300]!,
                                      width: _proofImagesBytes.isNotEmpty ? 2 : 1,
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          _proofImagesBytes.isEmpty 
                                              ? Icons.add_a_photo_outlined 
                                              : Icons.add_photo_alternate_outlined,
                                          size: 48,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          _proofImagesBytes.isEmpty 
                                              ? 'Add supporting photos' 
                                              : 'Add more photos',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${_proofImagesBytes.length}/$maxImages photos selected',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF4CAF50),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF4CAF50),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Maximum $maxImages photos added',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.green[800],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Contact Method Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                Icons.contact_phone,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'How Can the Finder Reach You?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choose your preferred contact methods',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Phone Call option
                        _buildContactOption(
                          'Phone Call',
                          'Direct phone communication',
                          Icons.phone,
                        ),
                        const SizedBox(height: 12),
                        
                        // Facebook Messenger option
                        _buildContactOption(
                          'Facebook Messenger',
                          'Contact via Facebook Messenger',
                          Icons.messenger,
                        ),
                        const SizedBox(height: 12),
                        
                        // Email option
                        _buildContactOption(
                          'Email',
                          'Contact via WVSU email',
                          Icons.email,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Important Information Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9C4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber,
                          color: Color(0xFFF57C00),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Important Information',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFF57C00),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '• Your claim will be reviewed by the finder\n• Only provide contact info you\'re comfortable sharing\n• Meet in public places for safety (Library, CSC Office)\n• Bring valid ID when picking up your item',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[800],
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          
          // Submit Button at bottom
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitClaim,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Submit Claim Request',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption(String title, String subtitle, IconData icon) {
    bool isSelected = _selectedContactMethod == title;
    TextEditingController? controller;
    String? hintText;
    TextInputType? keyboardType;
    
    // Determine which controller and settings to use
    if (title == 'Phone Call') {
      controller = _phoneController;
      hintText = 'Enter your phone number';
      keyboardType = TextInputType.phone;
    } else if (title == 'Facebook Messenger') {
      controller = _messengerController;
      hintText = 'Enter your Facebook Messenger profile link';
      keyboardType = TextInputType.url;
    } else if (title == 'Email') {
      controller = _emailController;
      hintText = 'Enter your email address';
      keyboardType = TextInputType.emailAddress;
    }
    
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF4CAF50) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _selectedContactMethod = title;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[400],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? const Color(0xFF4CAF50) : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Show text field inside the same container when selected
          if (isSelected && controller != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: TextField(
                controller: controller,
                keyboardType: keyboardType,
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(icon, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _submitClaim() async {
    // Validate required fields
    if (_detailsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe specific details about the item'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_selectedContactMethod.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a contact method'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Validate contact information based on selected method
    if (_selectedContactMethod == 'Phone Call' && _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_selectedContactMethod == 'Facebook Messenger' && _messengerController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your Facebook Messenger profile link'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_selectedContactMethod == 'Email' && _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Show processing dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _ProcessingDialog(),
    );
    
    // Prepare contact value - only store selected method
    String contactValue = '';
    
    if (_selectedContactMethod == 'Phone Call') contactValue = _phoneController.text.trim();
    if (_selectedContactMethod == 'Facebook Messenger') contactValue = _messengerController.text.trim();
    if (_selectedContactMethod == 'Email') contactValue = _emailController.text.trim();

    try {
      final user = FirebaseAuth.instance.currentUser;
      
      // Extract item image URL from images array
      String? itemImageUrl;
      final images = widget.item['images'];
      if (images is List && images.isNotEmpty && images[0] is String) {
        itemImageUrl = images[0] as String;
      }
      
      // Upload proof images if provided
      List<String> proofImageUrls = [];
      if (_proofImagesBytes.isNotEmpty) {
        try {
          final storage = SupabaseStorageService();
          final itemId = widget.item['itemId'] ?? widget.item['id'] ?? widget.item['docId'] ?? DateTime.now().millisecondsSinceEpoch.toString();
          
          for (int i = 0; i < _proofImagesBytes.length; i++) {
            try {
              final url = await storage.uploadImageBytes(
                imageBytes: _proofImagesBytes[i],
                fileName: _proofImageNames[i],
                itemId: itemId.toString(),
                type: 'claims',
              );
              proofImageUrls.add(url);
              debugPrint('Proof image ${i + 1} uploaded: $url');
            } catch (e) {
              debugPrint('Failed to upload proof image ${i + 1}: $e');
              // Continue with other images
            }
          }
        } catch (e) {
          debugPrint('Failed to upload proof images: $e');
          // Continue without proof images if upload fails
        }
      }
      
      // Normalize item fields and copy founder contact info into the claim
      final claimData = <String, dynamic>{
        'itemId': widget.item['itemId'] ?? widget.item['id'] ?? widget.item['docId'],
        'itemTitle': widget.item['itemName'] ?? widget.item['title'] ?? widget.item['name'] ?? widget.item['itemTitle'],
        'itemDescription': widget.item['description'] ?? widget.item['details'] ?? widget.item['itemDescription'],
        'imageUrl': itemImageUrl, // Store item's image URL for display in claims list
        'claimerId': user?.uid,
        'claimerName': user?.displayName,
        'claimerEmail': user?.email,
        'claimerContactMethod': _selectedContactMethod,
        'claimerContactValue': contactValue,
        'claimDescription': _detailsController.text.trim(),
        'additionalInfo': _additionalInfoController.text.trim(),
        'proofImages': proofImageUrls,
        'proofImage': proofImageUrls.isNotEmpty ? proofImageUrls[0] : null, // Backward compatibility
        'submittedDate': FieldValue.serverTimestamp(),
        'status': 'pending',
        // founder contact copied from the lost item where possible so claim details don't need extra lookups
        'founderId': widget.item['userId'] ?? widget.item['foundById'] ?? widget.item['posterId'],
        'founderName': widget.item['userName'] ?? widget.item['foundBy'] ?? widget.item['posterName'] ?? widget.item['founderName'],
        'founderContactMethod': widget.item['founderContactMethod'],
        'founderContactValue': widget.item['founderContactValue'],
      };

      final firestore = FirebaseFirestore.instance;

      // Extra safety: if founderId or founderName are missing, resolve them directly from lost_items
      try {
        final dynamic rawItemId = claimData['itemId'];
        if (rawItemId != null &&
            (claimData['founderId'] == null ||
                (claimData['founderName'] ?? '').toString().isEmpty)) {
          final itemIdStr = rawItemId.toString();
          final fs = FirebaseFirestore.instance;

          DocumentSnapshot<Map<String, dynamic>>? itemDoc;

          // Try by document id
          try {
            final doc = await fs.collection('lost_items').doc(itemIdStr).get();
            if (doc.exists) itemDoc = doc;
          } catch (_) {}

          // Fallback: query by itemId field
          if (itemDoc == null) {
            try {
              final q = await fs
                  .collection('lost_items')
                  .where('itemId', isEqualTo: rawItemId)
                  .limit(1)
                  .get();
              if (q.docs.isNotEmpty) {
                itemDoc = q.docs.first;
              }
            } catch (_) {}
          }

          if (itemDoc != null && itemDoc.exists) {
            final d = itemDoc.data() ?? {};
            claimData['founderId'] ??= d['userId'] ?? d['founderId'] ?? d['posterId'];
            claimData['founderName'] ??= d['userName'] ?? d['posterName'] ?? d['foundBy'];
            claimData['founderContactMethod'] ??= d['founderContactMethod'];
            claimData['founderContactValue'] ??= d['founderContactValue'];
          }
        }
      } catch (_) {
        // If lookup fails, we still proceed with whatever founder data we have
      }

      // Create claim document
      final claimRef = await firestore.collection('claims').add(claimData);

      // We do NOT update `lost_items` here. The founder should review the
      // claim and approve it before the item's status is changed. Keeping the
      // lost_items update on claim creation caused items to become 'claimed'
      // prematurely.
      final itemId = claimData['itemId'];
      final founderId = claimData['founderId'];
      final itemTitle = claimData['itemTitle'] ?? '';

      // Notify the founder about the new claim using NotificationService
      if (founderId != null) {
        try {
          final notificationService = NotificationService();
          await notificationService.notifyUserClaimReceived(
            userId: founderId,
            itemName: itemTitle,
            claimerName: user?.displayName ?? 'Someone',
            claimId: claimRef.id,
            itemId: itemId?.toString(),
          );
        } catch (_) {
          // ignore notification errors
        }
      }

      // Record activity for the claimer (current user)
      try {
        final activityService = ActivityService();
        await activityService.recordClaimSubmitted(
          itemName: itemTitle,
          claimId: claimRef.id,
        );
      } catch (_) {
        // ignore activity errors
      }

      // Close processing dialog
      if (mounted) Navigator.pop(context);

      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const _SuccessDialog(),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit claim: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

// Processing Dialog Widget
class _ProcessingDialog extends StatelessWidget {
  const _ProcessingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Shield icon with blue background
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFF2196F3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Submitting the Claim',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Please wait while we process your request...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
            ),
          ],
        ),
      ),
    );
  }
}

// Success Dialog Widget
class _SuccessDialog extends StatelessWidget {
  const _SuccessDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Checkmark icon with green background
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Claim Submitted!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'The finder will review your claim and\nget back to you soon.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close success dialog
                  // Navigate to Home Page (clear stack back to home)
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Image Viewer Dialog Widget
class _ImageViewerDialog extends StatefulWidget {
  final List<Uint8List> images;
  final int initialIndex;

  const _ImageViewerDialog({
    required this.images,
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
            itemCount: widget.images.length,
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
                    widget.images[index],
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
                decoration: BoxDecoration(
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
                  '${_currentIndex + 1} / ${widget.images.length}',
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
          if (widget.images.length > 1) ...[
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
                      decoration: BoxDecoration(
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
            if (_currentIndex < widget.images.length - 1)
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
                      decoration: BoxDecoration(
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

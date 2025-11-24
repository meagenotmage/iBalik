import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  String _selectedContactMethod = '';

  @override
  void dispose() {
    _detailsController.dispose();
    _additionalInfoController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    super.dispose();
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
                        
                        // Upload area
                        InkWell(
                          onTap: () {
                            // TODO: Implement photo picker
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.add_a_photo_outlined,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Add supporting photo',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Screenshots, receipts, or related photos',
                                    style: TextStyle(
                                      fontSize: 12,
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
                        
                        // WhatsApp option
                        _buildContactOption(
                          'WhatsApp',
                          'Message via WhatsApp',
                          Icons.chat,
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
    } else if (title == 'WhatsApp') {
      controller = _whatsappController;
      hintText = 'Enter your WhatsApp number';
      keyboardType = TextInputType.phone;
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
    
    if (_selectedContactMethod == 'WhatsApp' && _whatsappController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your WhatsApp number'),
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
    
    // Prepare contact value
    String contactValue = '';
    if (_selectedContactMethod == 'Phone Call') contactValue = _phoneController.text.trim();
    if (_selectedContactMethod == 'WhatsApp') contactValue = _whatsappController.text.trim();
    if (_selectedContactMethod == 'Email') contactValue = _emailController.text.trim();

    try {
      final user = FirebaseAuth.instance.currentUser;
      final claimData = {
        'itemId': widget.item['itemId'] ?? widget.item['id'] ?? widget.item['docId'] ?? null,
        'itemTitle': widget.item['itemName'] ?? widget.item['title'] ?? null,
        'claimerId': user?.uid,
        'claimerName': user?.displayName ?? null,
        'claimerEmail': user?.email ?? null,
        'claimerProvidedContactMethod': _selectedContactMethod,
        'claimerProvidedContactValue': contactValue,
        'claimDescription': _detailsController.text.trim(),
        'additionalInfo': _additionalInfoController.text.trim(),
        'proofImage': null,
        'submittedDate': FieldValue.serverTimestamp(),
        'status': 'pending',
        'founderId': widget.item['userId'] ?? widget.item['foundById'] ?? null,
      };

      final firestore = FirebaseFirestore.instance;

      // Create claim document
      final claimRef = await firestore.collection('claims').add(claimData);

      // If the lost item doc id is available, update the lost_items doc so the
      // founder sees this in their "Found Claims" (ClaimsPage queries lost_items
      // where userId == founder and status == 'claimed').
      final itemId = claimData['itemId'];
      final founderId = claimData['founderId'];
      if (itemId != null) {
        try {
          final itemRef = firestore.collection('lost_items').doc(itemId.toString());
          await itemRef.update({
            'status': 'claimed',
            'claimedBy': user?.uid,
            'claimedAt': FieldValue.serverTimestamp(),
            'claimerProvidedContactMethod': _selectedContactMethod,
            'claimerProvidedContactValue': contactValue,
            'claimId': claimRef.id,
          });
        } catch (e) {
          // If update fails (maybe item doc id is not the doc id), try to find by itemId field
          try {
            final query = await firestore.collection('lost_items').where('itemId', isEqualTo: itemId).limit(1).get();
            if (query.docs.isNotEmpty) {
              final docRef = query.docs.first.reference;
              await docRef.update({
                'status': 'claimed',
                'claimedBy': user?.uid,
                'claimedAt': FieldValue.serverTimestamp(),
                'claimerProvidedContactMethod': _selectedContactMethod,
                'claimerProvidedContactValue': contactValue,
                'claimId': claimRef.id,
              });
            }
          } catch (_) {
            // ignore; claim document still exists and founder can be notified separately
          }
        }
      }

      // Create a notification for the founder so they see the new claim in notifications
      if (founderId != null) {
        try {
          await firestore.collection('notifications').add({
            'userId': founderId,
            'type': 'new_claim',
            'title': 'New Claim Received',
            'message': '${user?.displayName ?? 'Someone'} submitted a claim for your item "${claimData['itemTitle'] ?? ''}"',
            'createdAt': FieldValue.serverTimestamp(),
            'isRead': false,
            'meta': {
              'claimId': claimRef.id,
              'itemId': itemId,
            }
          });
        } catch (_) {
          // ignore notification errors
        }
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
                  Navigator.pop(context); // Go back to item details
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

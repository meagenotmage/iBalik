import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/page_transitions.dart';
import '../claims/claim_item_page.dart';

class ItemDetailsPage extends StatefulWidget {
  final Map<String, dynamic> item;

  const ItemDetailsPage({super.key, required this.item});

  @override
  State<ItemDetailsPage> createState() => _ItemDetailsPageState();
}

class _ItemDetailsPageState extends State<ItemDetailsPage> {
  bool _isCheckingClaim = true;
  bool _hasExistingClaim = false;
  String? _existingClaimStatus;

  // Check if current user is the founder of the item
  bool get _isCurrentUserFounder {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final itemUserId = widget.item['userId'] ?? '';
    
    return currentUserId == itemUserId;
  }

  @override
  void initState() {
    super.initState();
    _checkExistingClaim();
  }

  // Check if user already has a claim for this item
  Future<void> _checkExistingClaim() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      final itemId = widget.item['itemId'] ?? widget.item['docId'];
      
      if (currentUserId == null || itemId == null) {
        setState(() {
          _isCheckingClaim = false;
        });
        return;
      }

      final querySnapshot = await FirebaseFirestore.instance
          .collection('claims')
          .where('claimerId', isEqualTo: currentUserId)
          .where('itemId', isEqualTo: itemId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final claimData = querySnapshot.docs.first.data();
        setState(() {
          _hasExistingClaim = true;
          _existingClaimStatus = claimData['status'] ?? 'pending';
          _isCheckingClaim = false;
        });
      } else {
        setState(() {
          _hasExistingClaim = false;
          _isCheckingClaim = false;
        });
      }
    } catch (e) {
      print('Error checking existing claim: $e');
      setState(() {
        _isCheckingClaim = false;
      });
    }
  }

  // Check if item is already claimed by someone else
  bool get _isItemAlreadyClaimed {
    final status = widget.item['status']?.toString().toLowerCase();
    return status == 'claimed' || status == 'approved';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Item Details',
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
                  // Item Image (use Cloudinary/URL if available, otherwise fallback to icon)
                  Container(
                    height: 250,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: () {
                        // images field is a list of URLs in Firestore
                        final images = (widget.item['images'] is List) ? List.from(widget.item['images']) : null;
                        final firstImage = (images != null && images.isNotEmpty) ? images.first as String? : null;
                        if (firstImage != null && firstImage.isNotEmpty) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              firstImage,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 250,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.broken_image,
                                size: 80,
                                color: Colors.white54,
                              ),
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(child: CircularProgressIndicator());
                              },
                            ),
                          );
                        }

                        // If an icon code was passed (legacy), show it
                        if (widget.item['image'] != null && widget.item['image'] is IconData) {
                          return Icon(
                            widget.item['image'],
                            size: 100,
                            color: Colors.white.withOpacity(0.4),
                          );
                        }

                        return Icon(
                          Icons.image,
                          size: 100,
                          color: Colors.white.withOpacity(0.4),
                        );
                      }(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Item Status Banner (if claimed or user has existing claim)
                  if (_isItemAlreadyClaimed || _hasExistingClaim) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _getStatusBannerColor(),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(_getStatusIcon(), color: _getStatusIconColor(), size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getStatusTitle(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _getStatusTextColor(),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getStatusMessage(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _getStatusTextColor(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Item Details Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Item Name
                        Text(
                          widget.item['itemName'] ?? widget.item['name'] ?? widget.item['title'] ?? 'Untitled',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Location and Date
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 6),
                            Text(
                              // Try to format datePosted (Timestamp) or dateFound string
                              () {
                                final dp = widget.item['datePosted'] ?? widget.item['dateFound'];
                                if (dp == null) return 'Date unknown';
                                if (dp is Timestamp) {
                                  final dt = dp.toDate();
                                  return '${dt.month}/${dt.day}/${dt.year}';
                                }
                                return dp.toString();
                              }(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.location_on, size: 18, color: Colors.grey[600]),
                            const SizedBox(width: 6),
                            Text(
                              widget.item['location'] ?? widget.item['place'] ?? 'Library',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Description
                        Text(
                          widget.item['description'] ?? widget.item['details'] ?? 'No description provided.',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[800],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Category Badge (use Firestore value if available)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4318FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            (widget.item['category'] ?? 'Uncategorized').toString(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Found By Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 50,
                          height: 50,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4318FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Name and Label
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Found by',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.item['userName'] ?? widget.item['foundBy'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Verified Student',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Trusted Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Color(0xFF4CAF50),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Trusted',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Pickup Information Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F7E8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.location_on,
                              color: Colors.black87,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Pickup Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Pickup info depends on availability
                        () {
                          final availability = (widget.item['availability'] ?? '').toString();
                          final dropOff = (widget.item['dropOffLocation'] ?? widget.item['location'] ?? 'Library').toString();

                          if (availability.isNotEmpty && availability == 'Keep with me') {
                            // Show contact-founder UI
                            final contactName = widget.item['userName'] ?? widget.item['foundBy'] ?? 'Founder';
                            final contactEmail = widget.item['userEmail'] ?? '';
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Available at:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    Text(
                                      'Contact founder',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'This item is being kept by the finder. Contact $contactName ${contactEmail.isNotEmpty ? '($contactEmail)' : ''} to arrange return or pickup. Use the in-app chat or call feature to reach out.',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[800],
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }

                          // Default: show drop-off location info
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Available at:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  Text(
                                    dropOff,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Visit the $dropOff information desk during its hours with a valid ID to claim this item. Items are kept in the secure Lost & Found area.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[800],
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Claim Button at bottom - Updated with multiple validations
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
              child: _buildClaimButton(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimButton() {
    // Show loading while checking claim status
    if (_isCheckingClaim) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text(
                "Checking claim status...",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // User is the founder - can't claim own item
    if (_isCurrentUserFounder) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            "You can't claim your own item",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    // Item is already claimed by someone else
    if (_isItemAlreadyClaimed) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.orange[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            "Item Already Claimed",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.orange,
            ),
          ),
        ),
      );
    }

    // User already has a claim for this item
    if (_hasExistingClaim) {
      String buttonText = "Claim Pending";
      Color buttonColor = Colors.blue[100]!;
      Color textColor = Colors.blue[800]!;

      if (_existingClaimStatus == 'approved') {
        buttonText = "Claim Approved ✓";
        buttonColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
      } else if (_existingClaimStatus == 'rejected') {
        buttonText = "Claim Rejected";
        buttonColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            buttonText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      );
    }

    // User can claim the item
    return ElevatedButton(
      onPressed: () {
        _showClaimDialog(context);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4318FF),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: const Text(
        'Claim This Item',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Helper methods for status banner
  Color _getStatusBannerColor() {
    if (_isItemAlreadyClaimed) return Colors.orange[50]!;
    if (_hasExistingClaim) {
      switch (_existingClaimStatus) {
        case 'approved':
          return Colors.green[50]!;
        case 'rejected':
          return Colors.red[50]!;
        default:
          return Colors.blue[50]!;
      }
    }
    return Colors.transparent;
  }

  Color _getStatusIconColor() {
    if (_isItemAlreadyClaimed) return Colors.orange;
    if (_hasExistingClaim) {
      switch (_existingClaimStatus) {
        case 'approved':
          return Colors.green;
        case 'rejected':
          return Colors.red;
        default:
          return Colors.blue;
      }
    }
    return Colors.grey;
  }

  Color _getStatusTextColor() {
    if (_isItemAlreadyClaimed) return Colors.orange[800]!;
    if (_hasExistingClaim) {
      switch (_existingClaimStatus) {
        case 'approved':
          return Colors.green[800]!;
        case 'rejected':
          return Colors.red[800]!;
        default:
          return Colors.blue[800]!;
      }
    }
    return Colors.grey;
  }

  IconData _getStatusIcon() {
    if (_isItemAlreadyClaimed) return Icons.warning;
    if (_hasExistingClaim) {
      switch (_existingClaimStatus) {
        case 'approved':
          return Icons.check_circle;
        case 'rejected':
          return Icons.cancel;
        default:
          return Icons.access_time;
      }
    }
    return Icons.info;
  }

  String _getStatusTitle() {
    if (_isItemAlreadyClaimed) return 'Item Already Claimed';
    if (_hasExistingClaim) {
      switch (_existingClaimStatus) {
        case 'approved':
          return 'Claim Approved!';
        case 'rejected':
          return 'Claim Rejected';
        default:
          return 'Claim Pending';
      }
    }
    return '';
  }

  String _getStatusMessage() {
    if (_isItemAlreadyClaimed) return 'This item has already been claimed by another user.';
    if (_hasExistingClaim) {
      switch (_existingClaimStatus) {
        case 'approved':
          return 'Your claim has been approved! Contact the founder to arrange pickup.';
        case 'rejected':
          return 'Your claim was rejected. You can view the reason in your claims history.';
        default:
          return 'Your claim is under review by the founder. You\'ll be notified when there\'s an update.';
      }
    }
    return '';
  }

  void _showClaimDialog(BuildContext context) async {
    // Navigate to claim page and wait for result
    final result = await Navigator.push(
      context,
      SmoothPageRoute(page: ClaimItemPage(item: widget.item)),
    );

    // Refresh claim status when returning from claim page
    if (result == true && mounted) {
      setState(() {
        _isCheckingClaim = true;
      });
      await _checkExistingClaim();

      // Redirect to home after claim submission
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }
}
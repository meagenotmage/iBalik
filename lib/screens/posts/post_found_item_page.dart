import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../../utils/page_transitions.dart';
import '../claims/drop_off_page.dart';
import 'post_success_page.dart';
import '../../services/lost_item_service.dart';

class PostFoundItemPage extends StatefulWidget {
  const PostFoundItemPage({super.key});

  @override
  State<PostFoundItemPage> createState() => _PostFoundItemPageState();
}

class _PostFoundItemPageState extends State<PostFoundItemPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final LostItemService _lostItemService = LostItemService();
  final ImagePicker _imagePicker = ImagePicker();
  
  List<File> _selectedImages = [];
  bool _isUploading = false;
  
  String _selectedCategory = 'Select category';
  String _selectedLocation = 'Select location';
  String _selectedAvailability = 'Keep with me';
  String _selectedDropOffLocation = 'Library';
  DateTime _selectedDate = DateTime.now();

  final List<String> _categories = [
    'Select category',
    'Electronics',
    'Personal Items',
    'Bags',
    'Documents',
    'Accessories',
    'Clothes',
    'Shoes',
    'Others'
  ];

  final List<String> _locations = [
    'Select location',
    'Library',
    'CO-OP',
    'College of ICT',
    'College of Nursing',
    'College of Law',
    'Research Building',
    'Binhi',
    'Medicine Gym',
    'Rizal Hall',
    'Admin Building',
    'Mini Forest',
    'Jubilee Park',
    'Quezon Hall',
    'Grandstand',
    'College of Communications',
    'Audio Visual Hall',
    'Cultural Center',
    'Foreign Languages Building',
    'College of Education',
    'College of Business and Management',
    'College of PESCAR', 
    'CTE Building',
    'Elementary CO-OP'
  ];

  final List<String> _dropOffLocations = [
    'College of ICT',
    'Library',
    'College of Nursing',
    'College of Medicine',
    'College of Arts and Science',
    'College of Communication',
    'College of Business and Management',
    'College of Education',
    'College of PESCAR',
    'College of Dentistry',
    'Guard House',
  ];

  // No location-based drop-off suggestions needed anymore.

  // (Removed college-specific hub UI; no college list needed)

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
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
          'Post Found Item',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Banner
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.volunteer_activism,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Found Something?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Drop off your found item with a certified staff or Student Council member.\nThey will facilitate the return of the item.\nYou will claim your points and karma once it\'s claimed successfully.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF388E3C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Item Details Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Item Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Item Title
                  const Text(
                    'Item Title',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'e.g., Black iPhone with cracked screen',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Provide more details that could help identify the owner...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Category and Found Date
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Category',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: Builder(builder: (context) {
                                  final categoryOptions = _categories.toSet().toList();
                                  final currentCategory = categoryOptions.contains(_selectedCategory) ? _selectedCategory : null;
                                  return DropdownButton<String>(
                                    value: currentCategory,
                                    isExpanded: true,
                                    icon: const Icon(Icons.keyboard_arrow_down),
                                    items: categoryOptions.map((String category) {
                                      return DropdownMenuItem<String>(
                                        value: category,
                                        child: Text(
                                          category,
                                          style: TextStyle(
                                            color: category == 'Select category'
                                                ? Colors.grey[400]
                                                : Colors.black87,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _selectedCategory = newValue ?? 'Select category';
                                      });
                                    },
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Found Date',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null && picked != _selectedDate) {
                                  setState(() {
                                    _selectedDate = picked;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
                                      style: TextStyle(
                                        color: Colors.grey[800],
                                        fontSize: 14,
                                      ),
                                    ),
                                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                                  ],
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
            
            // Location Details Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
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
                        'Location Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Where was it found
                  const Text(
                    'Where was it found?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                          child: Builder(builder: (context) {
                            final locationOptions = _locations.toSet().toList();
                            final currentLocation = locationOptions.contains(_selectedLocation) ? _selectedLocation : null;
                            return DropdownButton<String>(
                              value: currentLocation,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down),
                              items: locationOptions.map((String location) {
                                return DropdownMenuItem<String>(
                                  value: location,
                                  child: Text(
                                    location,
                                    style: TextStyle(
                                      color: location == 'Select location'
                                          ? Colors.grey[400]
                                          : Colors.black87,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedLocation = newValue ?? 'Select location';
                                  // If the founder chose the 'Drop off location' flow,
                                  // default the drop-off selection to the first available option.
                                });
                              },
                            );
                          }),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Item Availability
                  const Text(
                    'Item Availability',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose where the item will be available for pickup:',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Keep with me option
                  _buildAvailabilityOption(
                    'Keep with me',
                    'I\'ll handle the return directly through the app',
                    '• Immediate posting • Direct communication',
                  ),
                  const SizedBox(height: 12),
                  
                  // Drop off option
                  _buildAvailabilityOption(
                    'Drop off location',
                    'Student council/person in charge will facilitate return',
                    '+15 preliminary points • Professional handling',
                  ),
                  
                  // Show dropdown if "Drop off location" is selected
                  if (_selectedAvailability == 'Drop off location') ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(left: 32),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                          child: DropdownButtonHideUnderline(
                          child: Builder(builder: (context) {
                            final variantOptions = _dropOffLocations.toSet().toList();
                            final currentVariant = variantOptions.contains(_selectedDropOffLocation) ? _selectedDropOffLocation : null;
                            return DropdownButton<String>(
                              value: currentVariant,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down),
                              items: variantOptions.map((String location) {
                                return DropdownMenuItem<String>(
                                  value: location,
                                  child: Text(
                                    location,
                                    style: const TextStyle(color: Colors.black87),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedDropOffLocation = newValue ?? (variantOptions.isNotEmpty ? variantOptions.first : 'Library');
                                });
                              },
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  
                  // (College-specific hub option removed)
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Add Photo Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.add_a_photo,
                        color: Colors.black87,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Add Photos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You can add up to 5 photos',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Photo upload area
                  if (_selectedImages.isEmpty)
                    InkWell(
                      onTap: _pickImages,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
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
                                Icons.add_a_photo_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Tap to add photos',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Clear photos help owners identify their items',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        // Display selected images
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedImages.length + (_selectedImages.length < 5 ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _selectedImages.length && _selectedImages.length < 5) {
                                // Add more button
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: InkWell(
                                    onTap: _pickImages,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      width: 120,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5F5F5),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey[300]!,
                                          width: 2,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_a_photo_outlined,
                                            size: 32,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Add more',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }
                              
                              // Display image
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        _selectedImages[index],
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    // Remove button
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            _selectedImages.removeAt(index);
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${_selectedImages.length} of 5 photos selected',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Post Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4318FF), Color(0xFF4ECDC4)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _postItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _selectedAvailability == 'Keep with me' 
                            ? 'Post Item and Earn Points' 
                            : 'Continue to Drop-off',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityOption(String title, String subtitle, String points) {
    bool isSelected = _selectedAvailability == title;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedAvailability = title;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEDE7F6) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF4318FF) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: isSelected ? const Color(0xFF4318FF) : Colors.grey[400],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFF4318FF) : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    points,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    try {
      // Show dialog to choose between camera and gallery
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      // Request permissions
      bool hasPermission = false;
      if (source == ImageSource.camera) {
        final cameraStatus = await Permission.camera.request();
        hasPermission = cameraStatus.isGranted;
        
        if (cameraStatus.isDenied || cameraStatus.isPermanentlyDenied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Camera permission is required to take photos'),
                action: SnackBarAction(
                  label: 'Settings',
                  onPressed: () => openAppSettings(),
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
      } else {
        // For gallery on Android 13+, use photos permission
        if (Platform.isAndroid) {
          final androidInfo = await Permission.photos.status;
          if (androidInfo.isDenied) {
            final status = await Permission.photos.request();
            hasPermission = status.isGranted;
          } else {
            hasPermission = androidInfo.isGranted;
          }
          
          // Fallback to storage permission for older Android versions
          if (!hasPermission) {
            final storageStatus = await Permission.storage.request();
            hasPermission = storageStatus.isGranted;
          }
        } else {
          // iOS uses photos permission
          final photoStatus = await Permission.photos.request();
          hasPermission = photoStatus.isGranted;
        }
        
        if (!hasPermission) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Photo library permission is required'),
                action: SnackBarAction(
                  label: 'Settings',
                  onPressed: () => openAppSettings(),
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
      }

      int remainingSlots = 5 - _selectedImages.length;
      
      if (remainingSlots <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Maximum 5 photos allowed'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (source == ImageSource.gallery) {
        // Try to pick multiple images from gallery
        try {
          final List<XFile> images = await _imagePicker.pickMultiImage(
            maxWidth: 1024,  // Compress gallery images too
            maxHeight: 1024,
            imageQuality: 70,
          );
          
          if (images.isNotEmpty) {
            setState(() {
              // Add new images but limit to 5 total
              for (int i = 0; i < images.length && i < remainingSlots; i++) {
                _selectedImages.add(File(images[i].path));
              }
            });
            
            if (images.length > remainingSlots && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Only $remainingSlots more photo(s) can be added'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        } catch (e) {
          // Fallback to single image if multi-image fails
          final XFile? image = await _imagePicker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 1024,
            maxHeight: 1024,
            imageQuality: 70,
          );
          if (image != null) {
            setState(() {
              _selectedImages.add(File(image.path));
            });
          }
        }
      } else {
        // Camera - single image only
        final XFile? image = await _imagePicker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1024,  // Reduced from 1920 to save storage
          maxHeight: 1024,  // Reduced from 1080 to save storage
          imageQuality: 70,  // Reduced from 85 to save storage (still good quality)
        );
        if (image != null) {
          setState(() {
            _selectedImages.add(File(image.path));
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _postItem() async {
    // Validate inputs
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an item title'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a description'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_selectedCategory == 'Select category') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_selectedLocation == 'Select location') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // No college-specific hub option anymore; no college validation needed
    
    // Images are now OPTIONAL for testing
    // if (_selectedImages.isEmpty) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //       content: Text('Please add at least one photo of the item'),
    //       backgroundColor: Colors.orange,
    //     ),
    //   );
    //   return;
    // }
    
    // Navigate to drop-off page based on availability selection
    if (_selectedAvailability == 'Keep with me') {
      // Upload to Firebase and post immediately
      setState(() {
        _isUploading = true;
      });
      
        try {
        final String itemId = await _lostItemService.createLostItem(
          itemName: _titleController.text,
          description: _descriptionController.text,
          category: _selectedCategory,
          location: _selectedLocation,
          images: _selectedImages,
          dateFound: _selectedDate.toIso8601String(),
          additionalDetails: {
            'availability': _selectedAvailability,
            'dropOffLocation': null,
          },
        );
        
        setState(() {
          _isUploading = false;
        });
        
        final itemData = {
          'itemId': itemId,
          'title': _titleController.text,
          'description': _descriptionController.text,
          'category': _selectedCategory,
          'location': _selectedLocation,
          'date': _selectedDate,
          'availability': _selectedAvailability,
        };
        
        Navigator.push(
          context,
          SmoothPageRoute(page: PostSuccessPage(itemData: itemData)),
        );
      } catch (e) {
        setState(() {
          _isUploading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error posting item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Navigate to drop-off page (upload will happen after drop-off confirmation)
      String dropOffLocation;
      if (_selectedAvailability == 'Drop off location') {
        dropOffLocation = _selectedDropOffLocation;
      } else {
        // Not a drop-off flow; clear dropOffLocation
        dropOffLocation = '';
      }
      
      final itemData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'category': _selectedCategory,
        'location': _selectedLocation,
        'date': _selectedDate,
        'dropOffLocation': dropOffLocation,
        'availability': _selectedAvailability,
        'images': _selectedImages,
      };
      
      Navigator.push(
        context,
        SmoothPageRoute(page: DropOffPage(itemData: itemData)),
      );
    }
  }
}

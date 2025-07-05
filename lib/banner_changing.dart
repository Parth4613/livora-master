import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/firebase_storage_service.dart';

class BannerManagementPage extends StatefulWidget {
  @override
  State<BannerManagementPage> createState() => _BannerManagementPageState();
}

class _BannerManagementPageState extends State<BannerManagementPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _banners = [];
  bool _loading = true;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _loadBanners();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadBanners() async {
    try {
      final bannersSnap = await FirebaseFirestore.instance
          .collection('promo_banners')
          .orderBy('title')
          .get();
      if (mounted) {
        setState(() {
          _banners = bannersSnap.docs
              .map((d) => {...d.data(), 'id': d.id})
              .toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showErrorSnackBar('Failed to load banners: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _editBanner(int index) async {
    final banner = _banners[index];
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BannerFormPage(
          title: 'Edit Banner',
          banner: banner,
        ),
      ),
    );
    
    if (result == true) {
      _showSuccessSnackBar('Banner updated successfully');
      _loadBanners();
    }
  }

  Future<void> _addNewBanner() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BannerFormPage(
          title: 'Create New Banner',
        ),
      ),
    );
    
    if (result == true) {
      _showSuccessSnackBar('Banner created successfully');
      _loadBanners();
    }
  }

  Future<void> _deleteBanner(int index) async {
    final banner = _banners[index];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.warning_amber_rounded, 
                color: Colors.red.shade600, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Delete Banner',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "${banner['title']}"?',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey.shade700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('promo_banners')
            .doc(banner['id'])
            .delete();
        
        if (banner['image'] != null && banner['image'].toString().isNotEmpty) {
          try {
            await FirebaseStorageService.deleteImage(banner['image']);
          } catch (e) {
            print('Error deleting image: $e');
          }
        }
        
        _showSuccessSnackBar('Banner deleted successfully');
        _loadBanners();
      } catch (e) {
        _showErrorSnackBar('Failed to delete banner: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        title: Text(
          'Banners',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _addNewBanner,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Add Banner'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.blue.shade700 : Colors.blue.shade600,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(_slideAnimation),
        child: FadeTransition(
          opacity: _slideAnimation,
          child: _loading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(
                          isDark ? Colors.blue.shade400 : Colors.blue.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading banners...',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : _banners.isEmpty
                  ? _buildEmptyState(isDark)
                  : _buildBannersList(isDark),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.blue.shade900.withOpacity(0.3)
                    : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.photo_library_outlined,
                size: 60,
                color: isDark ? Colors.blue.shade300 : Colors.blue.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No banners yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first promotional banner to get started.\nBanners help showcase your services and promotions.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.grey.shade600,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _addNewBanner,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create First Banner'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.blue.shade700 : Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannersList(bool isDark) {
    return Column(
      children: [
        // Stats Header
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDark 
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark 
                      ? Colors.blue.shade900.withOpacity(0.3)
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.dashboard_rounded,
                  color: isDark ? Colors.blue.shade300 : Colors.blue.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_banners.length} Active ${_banners.length == 1 ? 'Banner' : 'Banners'}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      'Manage your promotional content',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Banners Grid
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 : 
                               MediaQuery.of(context).size.width > 800 ? 2 : 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: _banners.length,
              itemBuilder: (context, index) {
                final banner = _banners[index];
                return _buildBannerCard(banner, index, isDark);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBannerCard(Map<String, dynamic> banner, int index, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              color: isDark ? Colors.grey[800] : Colors.grey.shade100,
            ),
            child: banner['image'] != null && banner['image'].toString().isNotEmpty
                ? ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    child: Image.network(
                      banner['image'],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 120,
                      errorBuilder: (c, o, e) => Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: isDark ? Colors.white38 : Colors.grey.shade400,
                          size: 48,
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Icon(
                      Icons.image_outlined,
                      color: isDark ? Colors.white38 : Colors.grey.shade400,
                      size: 48,
                    ),
                  ),
          ),
          // Content Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    banner['title'] ?? 'Untitled',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    banner['subtitle'] ?? 'No description',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                      fontSize: 14,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _editBanner(index),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Edit'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.blue.shade300 : Colors.blue.shade600,
                            side: BorderSide(color: isDark ? Colors.blue.shade700 : Colors.blue.shade200),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _deleteBanner(index),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        style: IconButton.styleFrom(
                          backgroundColor: isDark ? Colors.red.shade900.withOpacity(0.3) : Colors.red.shade50,
                          foregroundColor: Colors.red.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Banner Form Page (separate page for adding/editing)
class BannerFormPage extends StatefulWidget {
  final String title;
  final Map<String, dynamic>? banner;

  const BannerFormPage({
    Key? key,
    required this.title,
    this.banner,
  }) : super(key: key);

  @override
  State<BannerFormPage> createState() => _BannerFormPageState();
}

class _BannerFormPageState extends State<BannerFormPage> {
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  String _selectedIcon = 'home_work';
  String _imageUrl = '';
  File? _newImageFile;
  bool _isUploading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.banner != null) {
      _titleController.text = widget.banner!['title'] ?? '';
      _subtitleController.text = widget.banner!['subtitle'] ?? '';
      _selectedIcon = widget.banner!['icon'] ?? 'home_work';
      _imageUrl = widget.banner!['image'] ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _isUploading = true);
      try {
        _newImageFile = File(picked.path);
        final uploadedUrl = await FirebaseStorageService.uploadImage(_newImageFile!.path);
        setState(() {
          _imageUrl = uploadedUrl;
          _isUploading = false;
        });
      } catch (e) {
        setState(() => _isUploading = false);
        _showErrorSnackBar('Failed to upload image: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _saveBanner() async {
    if (_titleController.text.trim().isEmpty ||
        _subtitleController.text.trim().isEmpty ||
        _imageUrl.isEmpty) {
      _showErrorSnackBar('Please fill all fields and select an image');
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (widget.banner != null) {
        // Update existing banner
        await FirebaseFirestore.instance
            .collection('promo_banners')
            .doc(widget.banner!['id'])
            .update({
          'title': _titleController.text.trim(),
          'subtitle': _subtitleController.text.trim(),
          'icon': _selectedIcon,
          'image': _imageUrl,
          'updated_at': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new banner
        await FirebaseFirestore.instance.collection('promo_banners').add({
          'title': _titleController.text.trim(),
          'subtitle': _subtitleController.text.trim(),
          'icon': _selectedIcon,
          'image': _imageUrl,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
      
      Navigator.pop(context, true);
    } catch (e) {
      _showErrorSnackBar('Failed to save banner: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        title: Text(
          widget.title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: ElevatedButton(
              onPressed: _isSaving || _isUploading ? null : _saveBanner,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.blue.shade700 : Colors.blue.shade600,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text(widget.banner != null ? 'Update' : 'Create'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Field
            _buildFormSection(
              title: 'Banner Title',
              child: TextFormField(
                controller: _titleController,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: _buildInputDecoration(
                  hint: 'Enter banner title',
                  icon: Icons.title,
                  isDark: isDark,
                ),
              ),
              isDark: isDark,
            ),
            
            const SizedBox(height: 24),
            
            // Subtitle Field
            _buildFormSection(
              title: 'Banner Subtitle',
              child: TextFormField(
                controller: _subtitleController,
                maxLines: 3,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: _buildInputDecoration(
                  hint: 'Enter banner subtitle or description',
                  icon: Icons.subtitles,
                  isDark: isDark,
                ),
              ),
              isDark: isDark,
            ),
            
            const SizedBox(height: 24),
            
            // Icon Selection
            _buildFormSection(
              title: 'Select Icon',
              child: _buildIconSelector(isDark),
              isDark: isDark,
            ),
            
            const SizedBox(height: 24),
            
            // Image Section
            _buildFormSection(
              title: 'Banner Image',
              child: _buildImageSection(isDark),
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection({
    required String title, 
    required Widget child, 
    required bool isDark
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
    required bool isDark,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark ? Colors.white38 : Colors.grey.shade600,
      ),
      prefixIcon: Icon(
        icon, 
        color: isDark ? Colors.blue.shade300 : Colors.blue.shade600,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.blue.shade400 : Colors.blue.shade600, 
          width: 2,
        ),
      ),
      filled: true,
      fillColor: isDark ? Colors.grey[850] : Colors.grey.shade50,
      contentPadding: const EdgeInsets.all(16),
    );
  }

  Widget _buildIconSelector(bool isDark) {
    final icons = [
      {'name': 'home_work', 'icon': Icons.home_work},
      {'name': 'support_agent', 'icon': Icons.support_agent},
      {'name': 'people', 'icon': Icons.people},
      {'name': 'bed', 'icon': Icons.bed},
      {'name': 'room_service', 'icon': Icons.room_service},
      {'name': 'group', 'icon': Icons.group},
      {'name': 'hotel', 'icon': Icons.hotel},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: icons.map((iconData) {
        final isSelected = _selectedIcon == iconData['name'];
        return GestureDetector(
          onTap: () => setState(() => _selectedIcon = iconData['name'] as String),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected 
                  ? (isDark ? Colors.blue.shade700 : Colors.blue.shade600)
                  : (isDark ? Colors.grey[850] : Colors.grey.shade50),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                    ? (isDark ? Colors.blue.shade500 : Colors.blue.shade600)
                    : (isDark ? Colors.grey.shade600 : Colors.grey.shade300),
                width: 2,
              ),
            ),
            child: Icon(
              iconData['icon'] as IconData,
              color: isSelected 
                  ? Colors.white 
                  : (isDark ? Colors.white54 : Colors.grey.shade600),
              size: 28,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildImageSection(bool isDark) {
    return GestureDetector(
      onTap: _isUploading ? null : _pickImage,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey.shade600 : Colors.grey.shade300, 
            width: 2,
          ),
        ),
        child: _isUploading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(
                        isDark ? Colors.blue.shade400 : Colors.blue.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Uploading image...', 
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
            : _imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      _imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (c, o, e) => Center(
                        child: Icon(
                          Icons.broken_image, 
                          size: 48, 
                          color: isDark ? Colors.white38 : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark 
                              ? Colors.blue.shade900.withOpacity(0.3)
                              : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.cloud_upload_outlined,
                          size: 48,
                          color: isDark ? Colors.blue.shade300 : Colors.blue.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tap to select image',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.grey.shade600,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Recommended size: 800x400px',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

/// Entry point for opening the banner management page from anywhere in the app.
Future<void> showBannerChangingDialog(BuildContext context) async {
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => BannerManagementPage()),
  );
}
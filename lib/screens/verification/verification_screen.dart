// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:madadgar/config/theme.dart';
import 'package:madadgar/services/verification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:madadgar/services/auth_service.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({Key? key}) : super(key: key);

  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final VerificationService _verificationService = VerificationService();
  final _cnicController = TextEditingController();
  final _additionalInfoController = TextEditingController();
  
  File? _idCardFrontImage;
  File? _idCardBackImage;
  
  bool _isLoading = true;
  bool _canSubmit = false;
  Map<String, dynamic>? _verificationStatus;
  
  @override
  void initState() {
    super.initState();
    _checkVerificationStatus();
  }
  
  Future<void> _checkVerificationStatus() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final status = await _verificationService.getCurrentUserVerificationRequest();
      final canSubmit = await _verificationService.canSubmitVerificationRequest();
      
      setState(() {
        _verificationStatus = status;
        _canSubmit = canSubmit;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking verification status: $e')),
      );
      setState(() {
        _isLoading = false;
        _canSubmit = false;
      });
    }
  }
  
  Future<void> _pickImage(bool isFront) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
      );
      
      if (pickedFile != null) {
        setState(() {
          if (isFront) {
            _idCardFrontImage = File(pickedFile.path);
          } else {
            _idCardBackImage = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }
  
  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate()) return;
    if (_idCardFrontImage == null || _idCardBackImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload both sides of your ID card')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser!;
      
      await _verificationService.submitVerificationRequest(
        userId: user.uid,
        idCardFront: _idCardFrontImage!,
        idCardBack: _idCardBackImage!,
        cnic: _cnicController.text.trim(),
        additionalInfo: _additionalInfoController.text.trim(),
      );
      
      await _checkVerificationStatus();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification request submitted successfully!')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting verification request: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final primaryColor = MadadgarTheme.primaryColor;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Account Verification',
        style:TextStyle(
          color: MadadgarTheme.primaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        )),
        backgroundColor :Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryColor),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: primaryColor),
            onPressed: _checkVerificationStatus,
          ),
        ],
      ),
      body: _isLoading 
        ? Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          )
        : _buildContent(),
    );
  }
  
  Widget _buildContent() {
    final bool hasSubmitted = _verificationStatus != null && _verificationStatus!['hasSubmitted'] == true;
    
    if (hasSubmitted) {
      return _buildVerificationStatus();
    } else if (_canSubmit) {
      return _buildVerificationForm();
    } else {
      return const Center(
        child: Text('Verification is not available at this time.'),
      );
    }
  }
  
  Widget _buildVerificationStatus() {
    final primaryColor = MadadgarTheme.primaryColor;
    final fontFamily = MadadgarTheme.fontFamily;
    final status = _verificationStatus!['status'];
    final String statusText;
    final Color statusColor;
    
    switch (status) {
      case VerificationService.STATUS_PENDING:
        statusText = 'Pending Review';
        statusColor = Colors.orange;
        break;
      case VerificationService.STATUS_APPROVED:
        statusText = 'Approved';
        statusColor = Colors.green;
        // Refresh the auth service to update the isVerified flag
        AuthService.refreshAuthServiceUser(context);
        break;
      case VerificationService.STATUS_REJECTED:
        statusText = 'Rejected';
        statusColor = Colors.red;
        break;
      default:
        statusText = 'Unknown';
        statusColor = Colors.grey;
    }
    
    final submittedAt = _verificationStatus!['submittedAt'] as dynamic;
    final reviewedAt = _verificationStatus!['reviewedAt'] as dynamic;
    
    return RefreshIndicator(
      color: primaryColor,
      onRefresh: _checkVerificationStatus,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, 5),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Header
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.verified_user, size: 22, color: primaryColor),
                            const SizedBox(width: 10),
                            Text(
                              'Verification Status',
                              style: TextStyle(
                                fontFamily: fontFamily,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontFamily: fontFamily,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (submittedAt != null) ...[
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Text(
                                'Submitted: ${submittedAt.toDate().toString().substring(0, 16)}',
                                style: TextStyle(
                                  fontFamily: fontFamily,
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (reviewedAt != null) ...[
                          Row(
                            children: [
                              Icon(Icons.update, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Text(
                                'Reviewed: ${reviewedAt.toDate().toString().substring(0, 16)}',
                                style: TextStyle(
                                  fontFamily: fontFamily,
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                  
                  // Review Notes if available
                  if (_verificationStatus!['reviewNotes'] != null &&
                      _verificationStatus!['reviewNotes'].isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Review Notes:',
                            style: TextStyle(
                              fontFamily: fontFamily,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _verificationStatus!['reviewNotes'],
                            style: TextStyle(
                              fontFamily: fontFamily,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Action based on status
            if (status == VerificationService.STATUS_REJECTED && _canSubmit) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, 5),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your request was rejected',
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'You can submit a new verification request with corrected information.',
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _verificationStatus = null;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: primaryColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Submit New Request',
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Next steps for pending status
            if (status == VerificationService.STATUS_PENDING) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, 5),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: primaryColor, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'What happens next?',
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Our team is reviewing your verification request. This process typically takes upto 24 hrs. You can comeback to your profile and a verification approved status.',
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 14,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Benefits for approved status
            if (status == VerificationService.STATUS_APPROVED) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, 5),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'Verification Benefits',
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Congratulations! Your account is now verified. This gives you:',
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildBenefitItem('A verified badge visible to other users', fontFamily),
                    _buildBenefitItem('Increased trust from the community', fontFamily),
                    _buildBenefitItem('Access to additional platform features', fontFamily),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildBenefitItem(String text, String fontFamily) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildVerificationForm() {
    final primaryColor = MadadgarTheme.primaryColor;
    final fontFamily = MadadgarTheme.fontFamily;
    
    return Form(
      key: _formKey,
      child: RefreshIndicator(
        color: primaryColor,
        onRefresh: _checkVerificationStatus,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info card
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, 5),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.verified_user, size: 22, color: primaryColor),
                        const SizedBox(width: 10),
                        Text(
                          'Why Verify Your Account?',
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Verifying your account helps build trust in the Madadgar community. Verified users get a special badge and their requests and offers receive higher visibility.',
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 14,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              
              // CNIC Input
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, 5),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CNIC Information',
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cnicController,
                      decoration: InputDecoration(
                        labelText: 'CNIC Number',
                        helperText: 'Format: 00000-0000000-0',
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
                          borderSide: BorderSide(color: primaryColor),
                        ),
                        floatingLabelStyle: TextStyle(color: primaryColor),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 14,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your CNIC number';
                        }
                        // Basic CNIC validation (Pakistan's National ID)
                        final cnicRegExp = RegExp(r'^\d{5}-\d{7}-\d{1}$');
                        if (!cnicRegExp.hasMatch(value) && !RegExp(r'^\d{13}$').hasMatch(value)) {
                          return 'Please enter a valid CNIC number (e.g., 00000-0000000-0)';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              
              // ID Card Upload
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, 5),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload CNIC Images',
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildImagePickerCard(
                            title: 'Front Side',
                            image: _idCardFrontImage,
                            onTap: () => _pickImage(true),
                            fontFamily: fontFamily,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildImagePickerCard(
                            title: 'Back Side',
                            image: _idCardBackImage,
                            onTap: () => _pickImage(false),
                            fontFamily: fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Additional Info
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, 5),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Additional Information',
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _additionalInfoController,
                      decoration: InputDecoration(
                        labelText: 'Additional Information (Optional)',
                        helperText: 'Any other details you want to share',
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
                          borderSide: BorderSide(color: primaryColor),
                        ),
                        floatingLabelStyle: TextStyle(color: primaryColor),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      maxLines: 3,
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Important Info
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'Important Information',
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoItem('Your documents are stored securely', fontFamily, Colors.blue[800]!),
                    _buildInfoItem('We only use this information to verify your identity', fontFamily, Colors.blue[800]!),
                    _buildInfoItem('Verification process typically takes 1-3 business days', fontFamily, Colors.blue[800]!),
                    _buildInfoItem('You will receive an email notification with the result', fontFamily, Colors.blue[800]!),
                  ],
                ),
              ),
              
              // Submit Button
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 30),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitVerification,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: primaryColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Submit Verification Request',
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoItem(String text, String fontFamily, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, size: 16, color: textColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 13,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildImagePickerCard({
  required String title,
  required File? image,
  required VoidCallback onTap,
  required String fontFamily,
}) {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 150,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (image == null) ...[
              Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                'Tap to upload',
                style: TextStyle(
                  fontFamily: fontFamily,
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ] else ...[
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        image,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(8),
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              if (title == 'Front Side') {
                                _idCardFrontImage = null;
                              } else {
                                _idCardBackImage = null;
                              }
                            });
                          },
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                          iconSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
  
  @override
  void dispose() {
    _cnicController.dispose();
    _additionalInfoController.dispose();
    super.dispose();
  }
}
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:madadgar/config/theme.dart';
import 'package:madadgar/services/verification_service.dart';
import 'package:madadgar/services/email_service.dart'; // Import the EmailService
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
      
      // Using the existing verification service which now handles email sending internally
      await _verificationService.submitVerificationRequest(
        userId: user.uid,
        idCardFront: _idCardFrontImage!,
        idCardBack: _idCardBackImage!,
        cnic: _cnicController.text.trim(),
        additionalInfo: _additionalInfoController.text.trim(),
      );
      
      // Refresh verification status
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Verification'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkVerificationStatus,
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
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
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modified layout to prevent overflow
                  Row(
                    children: [
                      const Icon(Icons.verified_user, size: 28),
                      const SizedBox(width: 8),
                      const Text(
                        'Verification Status:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Status tag moved below the title to prevent overflow
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (submittedAt != null) ...[
                    Text(
                      'Submitted: ${submittedAt.toDate().toString().substring(0, 16)}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (reviewedAt != null) ...[
                    Text(
                      'Reviewed: ${reviewedAt.toDate().toString().substring(0, 16)}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (_verificationStatus!['reviewNotes'] != null &&
                      _verificationStatus!['reviewNotes'].isNotEmpty) ...[
                    const Divider(),
                    const Text(
                      'Review Notes:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(_verificationStatus!['reviewNotes']),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (status == VerificationService.STATUS_REJECTED && _canSubmit) ...[
            const Text(
              'You can submit a new verification request:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _verificationStatus = null;
                });
              },
              child: const Text('Submit New Request'),
            ),
          ],
          if (status == VerificationService.STATUS_PENDING) ...[
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What happens next?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Our team is reviewing your verification request. This process typically takes 1-3 business days. You will receive an email notification once your request has been processed.',
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (status == VerificationService.STATUS_APPROVED) ...[
            const SizedBox(height: 16),
            const Card(
              color: MadadgarTheme.primaryColor,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Verification Benefits',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Congratulations! Your account is now verified. This gives you:',
                    ),
                    SizedBox(height: 8),
                    Text('• A verified badge visible to other users'),
                    Text('• Higher visibility in search results'),
                    Text('• Increased trust from the community'),
                    Text('• Access to additional platform features'),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildVerificationForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Why Verify Your Account?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Verifying your account helps build trust in the Madadgar community. Verified users get a special badge and their requests and offers receive higher visibility.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Please provide the following information:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cnicController,
              decoration: const InputDecoration(
                labelText: 'CNIC Number',
                helperText: 'Format: 00000-0000000-0',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
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
            const SizedBox(height: 24),
            const Text(
              'Upload both sides of your CNIC:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildImagePickerCard(
                    title: 'Front Side',
                    image: _idCardFrontImage,
                    onTap: () => _pickImage(true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildImagePickerCard(
                    title: 'Back Side',
                    image: _idCardBackImage,
                    onTap: () => _pickImage(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _additionalInfoController,
              decoration: const InputDecoration(
                labelText: 'Additional Information (Optional)',
                helperText: 'Any other details you want to share',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Card(
              color: Colors.blue[50],
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Important Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Your documents are stored securely',
                      style: TextStyle(fontSize: 14),
                    ),
                    Text(
                      '• We only use this information to verify your identity',
                      style: TextStyle(fontSize: 14),
                    ),
                    Text(
                      '• Verification process typically takes 1-3 business days',
                      style: TextStyle(fontSize: 14),
                    ),
                    Text(
                      '• You will receive an email notification with the result',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitVerification,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text(
                        'Submit Verification Request',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildImagePickerCard({
    required String title,
    required File? image,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 150,
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (image == null) ...[
                const Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Tap to upload',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ] else ...[
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        image,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          color: Colors.black.withOpacity(0.6),
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
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
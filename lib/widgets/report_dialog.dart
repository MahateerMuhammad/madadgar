// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:madadgar/models/report.dart';
import 'package:madadgar/services/report_service.dart';
import 'package:madadgar/config/theme.dart';

class ReportDialog extends StatefulWidget {
  final String postId;
  final String reportedUserId;
  final VoidCallback? onReportSubmitted;

  const ReportDialog({
    super.key,
    required this.postId,
    required this.reportedUserId,
    this.onReportSubmitted,
  });

  @override
  _ReportDialogState createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final ReportService _reportService = ReportService();
  final TextEditingController _descriptionController = TextEditingController();
  ReportType? _selectedType;
  bool _isSubmitting = false;

  final Map<ReportType, String> _reportTypeLabels = {
    ReportType.spam: 'Spam or Misleading',
    ReportType.inappropriate: 'Inappropriate Content',
    ReportType.harassment: 'Harassment or Bullying',
    ReportType.scam: 'Scam or Fraud',
    ReportType.violence: 'Violence or Harmful Content',
    ReportType.falseInformation: 'False Information',
    ReportType.other: 'Other',
  };

  final Map<ReportType, IconData> _reportTypeIcons = {
    ReportType.spam: Icons.report_gmailerrorred_rounded,
    ReportType.inappropriate: Icons.warning_rounded,
    ReportType.harassment: Icons.person_off_rounded,
    ReportType.scam: Icons.security_rounded,
    ReportType.violence: Icons.dangerous_rounded,
    ReportType.falseInformation: Icons.fact_check_rounded,
    ReportType.other: Icons.more_horiz_rounded,
  };

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedType == null) {
      _showSnackBar('Please select a report type', isError: true);
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      _showSnackBar('Please provide additional details', isError: true);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _reportService.reportPost(
        postId: widget.postId,
        reportedUserId: widget.reportedUserId,
        type: _selectedType!,
        description: _descriptionController.text.trim(),
      );

      Navigator.of(context).pop();
      widget.onReportSubmitted?.call();
      _showSnackBar('Report submitted successfully. Thank you for helping keep our community safe.');
    } catch (e) {
      String errorMessage = 'Failed to submit report';
      if (e.toString().contains('already reported')) {
        errorMessage = 'You have already reported this post';
      }
      _showSnackBar(errorMessage, isError: true);
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.all(0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      title: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: MadadgarTheme.primaryColor.withOpacity(0.1),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.flag_rounded,
              color: MadadgarTheme.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Report Post',
                style: TextStyle(
                  fontFamily: MadadgarTheme.fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
              iconSize: 20,
              color: Colors.grey[600],
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What\'s the problem with this post?',
              style: TextStyle(
                fontFamily: MadadgarTheme.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ...ReportType.values.map((type) => _buildReportTypeOption(type)),
            const SizedBox(height: 20),
            Text(
              'Additional details',
              style: TextStyle(
                fontFamily: MadadgarTheme.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Please provide more details about the issue...',
                hintStyle: TextStyle(
                  fontFamily: MadadgarTheme.fontFamily,
                  color: Colors.grey[500],
                ),
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
                  borderSide:const BorderSide(color: MadadgarTheme.primaryColor),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.all(16),
              ),
              style: TextStyle(
                fontFamily: MadadgarTheme.fontFamily,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  foregroundColor: Colors.grey[700],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: MadadgarTheme.fontFamily,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Submit Report',
                        style: TextStyle(
                          fontFamily: MadadgarTheme.fontFamily,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReportTypeOption(ReportType type) {
    final isSelected = _selectedType == type;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedType = type;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? MadadgarTheme.primaryColor : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isSelected ? MadadgarTheme.primaryColor.withOpacity(0.05) : null,
          ),
          child: Row(
            children: [
              Icon(
                _reportTypeIcons[type],
                color: isSelected ? MadadgarTheme.primaryColor : Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _reportTypeLabels[type]!,
                  style: TextStyle(
                    fontFamily: MadadgarTheme.fontFamily,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? MadadgarTheme.primaryColor : Colors.black87,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: MadadgarTheme.primaryColor,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
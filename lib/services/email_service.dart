// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:madadgar/config/constants.dart';
// import 'package:madadgar/models/user.dart';

// class EmailService {
//   // Template for verification request email to admin
//   static String getAdminVerificationEmailTemplate({
//     required String userName,
//     required String userEmail,
//      required String userPhone,
//     required String userRegion,
//     required String cnic,
//     required String requestId,
//     required String verificationLink,
//   }) {
//     return '''
// <!DOCTYPE html>
// <html>
// <head>
//     <meta charset="UTF-8">
//     <title>New Verification Request</title>
//     <style>
//         body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
//         .container { max-width: 600px; margin: 0 auto; padding: 20px; }
//         .header { background-color: #4CAF50; color: white; padding: 10px; text-align: center; }
//         .content { padding: 20px; background-color: #f9f9f9; }
//         .footer { padding: 10px; text-align: center; font-size: 12px; color: #666; }
//         .button { display: inline-block; background-color: #4CAF50; color: white; padding: 10px 20px; 
//                  text-decoration: none; border-radius: 4px; margin-top: 20px; }
//         .details { margin: 20px 0; }
//         .details table { width: 100%; border-collapse: collapse; }
//         .details td { padding: 8px; border-bottom: 1px solid #ddd; }
//         .details td:first-child { font-weight: bold; width: 30%; }
//     </style>
// </head>
// <body>
//     <div class="container">
//         <div class="header">
//             <h2>New Verification Request</h2>
//         </div>
//         <div class="content">
//             <p>Dear Admin,</p>
//             <p>A new user verification request has been submitted on the Madadgar platform.</p>
            
//             <div class="details">
//                 <h3>User Details:</h3>
//                 <table>
//                     <tr>
//                         <td>Name:</td>
//                         <td>$userName</td>
//                     </tr>
//                     <tr>
//                         <td>Email:</td>
//                         <td>$userEmail</td>
//                     </tr>
//                     <tr>
//                         <td>Phone:</td>
//                         <td>$userPhone</td>
//                     </tr>
//                     <tr>
//                         <td>Region:</td>
//                         <td>$userRegion</td>
//                     </tr>
//                     <tr>
//                         <td>CNIC:</td>
//                         <td>$cnic</td>
//                     </tr>
//                     <tr>
//                         <td>Request ID:</td>
//                         <td>$requestId</td>
//                     </tr>
//                 </table>
//             </div>
            
//             <p>Please review this verification request by clicking the button below:</p>
//             <a href="$verificationLink" class="button">Review Verification Request</a>
            
//             <p>If the button doesn't work, you can copy and paste this link in your browser:</p>
//             <p style="word-break: break-all;">$verificationLink</p>
//         </div>
//         <div class="footer">
//             <p>This is an automated email from the Madadgar platform. Please do not reply to this email.</p>
//         </div>
//     </div>
// </body>
// </html>
// ''';
//   }

//   // Template for verification result email to user
//   static String getUserVerificationResultEmailTemplate({
//     required String userName,
//     required String status,
//     String? reviewNotes,
//   }) {
//     final String statusText = status == 'approved' ? 'Approved' : 'Rejected';
//     final String statusColor = status == 'approved' ? '#4CAF50' : '#F44336';
//     final String statusMessage = status == 'approved' 
//         ? 'Congratulations! Your account has been verified. You now have access to all verified user features on the Madadgar platform.'
//         : 'Unfortunately, your verification request has been rejected.';
        
//     final String notesSection = reviewNotes != null && reviewNotes.isNotEmpty
//         ? '''
//             <div style="margin-top: 20px; padding: 15px; background-color: #f5f5f5; border-left: 4px solid #ccc;">
//                 <h3 style="margin-top: 0;">Review Notes:</h3>
//                 <p>$reviewNotes</p>
//             </div>
//         '''
//         : '';
        
//     final String nextStepsSection = status == 'approved'
//         ? '''
//             <h3>What this means for you:</h3>
//             <ul>
//                 <li>Your profile now displays a verified badge</li>
//                 <li>Your listings will receive higher visibility</li>
//                 <li>You can access exclusive verified user features</li>
//                 <li>Users will trust your services more easily</li>
//             </ul>
//         '''
//         : '''
//             <h3>Next steps:</h3>
//             <p>You can submit a new verification request after 30 days with the correct documentation.</p>
//             <p>If you believe this was an error, please contact our support team for assistance.</p>
//         ''';

//     return '''
// <!DOCTYPE html>
// <html>
// <head>
//     <meta charset="UTF-8">
//     <title>Verification Request $statusText</title>
//     <style>
//         body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
//         .container { max-width: 600px; margin: 0 auto; padding: 20px; }
//         .header { background-color: $statusColor; color: white; padding: 10px; text-align: center; }
//         .content { padding: 20px; background-color: #f9f9f9; }
//         .footer { padding: 10px; text-align: center; font-size: 12px; color: #666; }
//         .status-badge { display: inline-block; padding: 5px 15px; background-color: $statusColor; 
//                         color: white; border-radius: 20px; font-weight: bold; }
//     </style>
// </head>
// <body>
//     <div class="container">
//         <div class="header">
//             <h2>Verification Request $statusText</h2>
//         </div>
//         <div class="content">
//             <p>Dear $userName,</p>
            
//             <p>$statusMessage</p>
            
//             <div style="text-align: center; margin: 20px 0;">
//                 <span class="status-badge">$statusText</span>
//             </div>
            
//             $notesSection
            
//             $nextStepsSection
            
//             <p>Thank you for using Madadgar!</p>
//         </div>
//         <div class="footer">
//             <p>This is an automated email from the Madadgar platform. Please do not reply to this email.</p>
//         </div>
//     </div>
// </body>
// </html>
// ''';
//   }

//   // Function to send verification email
//   static Future<void> sendEmail({
//     required String to,
//     required String subject,
//     required String htmlContent,
//   }) async {
//     // This would be implemented using Firebase Cloud Functions
//     // For now, we'll use a placeholder implementation
    
//     // In a production environment, you should use a proper email service API
//     // For example, using Firebase Cloud Functions with SendGrid, Mailgun, etc.
    
//     // Example implementation with SendGrid would be:
//     // 1. Set up Firebase Cloud Functions
//     // 2. Install SendGrid package
//     // 3. Create a function that calls SendGrid API
    
//     // Placeholder logging
//     debugPrint('Would send email to: $to');
//     debugPrint('Subject: $subject');
//     debugPrint('Email HTML content length: ${htmlContent.length}');
    
//     // For development purposes, you can simulate sending the email
//     // For example, by adding a Firebase document to a "mail_queue" collection
//     // which can be processed by a Cloud Function
    
//     try {
//       await FirebaseFirestore.instance.collection('mail_queue').add({
//         'to': to,
//         'subject': subject,
//         'html': htmlContent,
//         'createdAt': FieldValue.serverTimestamp(),
//         'status': 'pending',
//       });
      
//       debugPrint('Email added to mail queue');
//     } catch (e) {
//       debugPrint('Error adding email to mail queue: $e');
//     }
//   }
// }

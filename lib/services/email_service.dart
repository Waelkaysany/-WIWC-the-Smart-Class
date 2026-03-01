import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter/foundation.dart';

class EmailService {
  // CONFIGURATION
  static const String _adminEmail = 'waelkisannie@gmail.com';
  // WARNING: This is a placeholder. User needs to provide the real 16-char app password.
  static const String _appPassword = 'uyec xgpr ncxv pwnm'; 

  static Future<bool> sendApprovalEmail({
    required String teacherEmail,
    required String uid,
  }) async {
    final smtpServer = gmail(_adminEmail, _appPassword);

    final message = Message()
      ..from = Address(_adminEmail, 'WIWC Security')
      ..recipients.add(_adminEmail)
      ..subject = '🔔 Action Required: Approve $teacherEmail'
      ..html = '''
        <div style="font-family: sans-serif; padding: 20px; color: #333; max-width: 600px; border: 1px solid #eee; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.05);">
          <h2 style="color: #6B5CE7; margin-bottom: 20px;">New Teacher Request</h2>
          <p style="color: #666;">A new teacher has registered and needs your approval to enter the app.</p>
          
          <div style="background: #f8f9fa; padding: 20px; border-radius: 10px; margin: 25px 0; border: 1px solid #eee;">
            <p style="margin: 0 0 5px 0; font-size: 13px; color: #999; text-transform: uppercase;">Email Address</p>
            <p style="margin: 0; font-size: 18px; font-weight: bold; color: #2D3748;">$teacherEmail</p>
          </div>
          
          <div style="text-align: center; margin: 30px 0;">
            <a href="https://wiwc-smartclass.web.app/approve?uid=$uid" 
               style="background: #6B5CE7; color: white; padding: 16px 32px; border-radius: 12px; text-decoration: none; font-weight: bold; font-size: 16px; display: inline-block; box-shadow: 0 4px 15px rgba(107, 92, 231, 0.4);">
              ✅ Approve Teacher Now
            </a>
          </div>
          
          <p style="font-size: 13px; color: #a0aec0; text-align: center; margin-top: 25px;">
            Clicking this button will instantly grant them access to the classroom.
          </p>
        </div>
      ''';

    try {
      final sendReport = await send(message, smtpServer);
      debugPrint('Message sent: ' + sendReport.toString());
      return true;
    } on MailerException catch (e) {
      debugPrint('Message not sent.');
      for (var p in e.problems) {
        debugPrint('Problem: ${p.code}: ${p.msg}');
      }
      return false;
    } catch (e) {
      debugPrint('Unexpected error sending email: $e');
      return false;
    }
  }
}

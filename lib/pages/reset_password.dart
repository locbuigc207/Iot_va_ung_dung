import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ResetPassword extends StatefulWidget {
  const ResetPassword({Key? key}) : super(key: key);

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  final TextEditingController _emailController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Widget _buildEmail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          '       Email',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontFamily: 'SpaceGrotesk',
          ),
        ),
        const SizedBox(height: 2),
        Container(
          margin: const EdgeInsets.all(16),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: const Color(0xFFE5E4D8),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 2),
              )
            ],
          ),
          height: 60,
          child: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.black87),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 14),
              prefixIcon: Icon(Icons.email_outlined, color: Colors.black),
              hintText: 'example@email.com',
              hintStyle: TextStyle(color: Colors.black38),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildResetButton() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      width: 200,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleReset,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFBD7D5A),
          padding: const EdgeInsets.all(13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 5,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Color(0xFFF4F3E9),
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Reset Password',
                style: TextStyle(
                  color: Color(0xFFF4F3E9),
                  fontSize: 18,
                  fontFamily: 'SpaceGrotesk',
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _handleReset() async {
    if (!mounted) return;

    // Validation
    if (_emailController.text.trim().isEmpty) {
      _showDialog('Error', 'Please enter your email', isError: true);
      return;
    }

    // Email format validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      _showDialog('Error', 'Invalid email format', isError: true);
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());

      if (mounted) {
        _showDialog(
          'Success',
          'A password reset email has been sent to ${_emailController.text.trim()}',
          isError: false,
          onOk: () {
            if (mounted) {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to previous page
            }
          },
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message = 'An error occurred';

      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email';
          break;
        case 'invalid-email':
          message = 'Invalid email';
          break;
        case 'user-disabled':
          message = 'This account has been disabled';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please try again later';
          break;
        case 'network-request-failed':
          message = 'Network error. Check your connection';
          break;
        default:
          message = 'Error: ${e.message}';
      }

      _showDialog('Error', message, isError: true);
    } catch (e) {
      if (!mounted) return;
      _showDialog('Error', 'Error: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDialog(String title, String message,
      {bool isError = false, VoidCallback? onOk}) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: isError ? Colors.red : Colors.green,
            ),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontFamily: 'SpaceGrotesk')),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'SpaceGrotesk'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (onOk != null) onOk();
            },
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color(0xFF00C1C4),
                fontFamily: 'SpaceGrotesk',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F3E9),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 180,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('Assets/Vector 1.png'),
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 10, right: 50, left: 50),
              child: const Center(
                child: Text(
                  "Pi-Vert",
                  style: TextStyle(
                    color: Color(0xFF084C61),
                    fontFamily: 'VeronaSerial',
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Reset Password',
              style: TextStyle(
                color: Color(0xFF084C61),
                fontFamily: 'SpaceGrotesk',
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Enter your email to receive a reset link',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 30),
            _buildEmail(),
            const SizedBox(height: 8),
            _buildResetButton(),
            TextButton(
              onPressed: () {
                if (mounted) Navigator.pop(context);
              },
              child: const Text(
                'Back to login',
                style: TextStyle(
                  color: Color(0xFF00C1C4),
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 14,
                ),
              ),
            ),
            Container(
              height: 250,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('Assets/Vector 2.png'),
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

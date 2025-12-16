import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ResetPassword extends StatefulWidget {
  const ResetPassword({Key? key}) : super(key: key);

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  final TextEditingController _emailController = TextEditingController();
  final auth = FirebaseAuth.instance;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Widget buildEmail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '       Email',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontFamily: 'SpaceGrotesk',
          ),
        ),
        SizedBox(height: 2),
        Container(
          margin: EdgeInsets.all(16),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: Color(0xFFE5E4D8),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
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
            style: TextStyle(color: Colors.black87),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 14),
              prefixIcon: Icon(Icons.email_outlined, color: Colors.black),
            ),
          ),
        )
      ],
    );
  }

  Widget ResetButton() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20),
      width: 200,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleReset,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFBD7D5A),
          padding: EdgeInsets.all(13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 5,
        ),
        child: _isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Color(0xFFF4F3E9),
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Réinitialiser',
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
    if (_emailController.text.isEmpty) {
      _showDialog('Erreur', 'Veuillez entrer votre email');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await auth.sendPasswordResetEmail(email: _emailController.text.trim());
      _showDialog(
        'Succès',
        'Un email de réinitialisation a été envoyé à ${_emailController.text}',
        onOk: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Une erreur est survenue';
      if (e.code == 'user-not-found') {
        message = 'Aucun utilisateur trouvé avec cet email';
      } else if (e.code == 'invalid-email') {
        message = 'Email invalide';
      }
      _showDialog('Erreur', message);
    } catch (e) {
      _showDialog('Erreur', 'Erreur: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDialog(String title, String message, {VoidCallback? onOk}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (onOk != null) onOk();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF4F3E9),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('Assets/Vector 1.png'),
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 10, right: 50, left: 50),
              child: Center(
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
            SizedBox(height: 20),
            Text(
              'Réinitialiser le mot de passe',
              style: TextStyle(
                color: Color(0xFF084C61),
                fontFamily: 'SpaceGrotesk',
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 50),
            buildEmail(),
            SizedBox(height: 8),
            ResetButton(),
            Container(
              height: 400,
              decoration: BoxDecoration(
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

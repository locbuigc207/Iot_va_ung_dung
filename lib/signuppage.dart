import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:projet2cp/Homescreen.dart';

class Sign_up_page extends StatefulWidget {
  const Sign_up_page({Key? key}) : super(key: key);

  @override
  State<Sign_up_page> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<Sign_up_page> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final auth = FirebaseAuth.instance;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget buildUser() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '       Nom d\'utilisateur',
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
            controller: _usernameController,
            keyboardType: TextInputType.name,
            style: TextStyle(color: Colors.black87),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 14),
              prefixIcon: Icon(Icons.person, color: Colors.black),
            ),
          ),
        )
      ],
    );
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

  Widget buildPassword() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '       Mot de passe',
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
            controller: _passwordController,
            obscureText: true,
            style: TextStyle(color: Colors.black87),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 14),
              prefixIcon: Icon(Icons.lock_outline, color: Colors.black),
            ),
          ),
        )
      ],
    );
  }

  Widget SignUpButton() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10),
      width: 164,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFBD7D5A),
          padding: EdgeInsets.all(15),
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
                'Inscription',
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

  Future<void> _handleSignUp() async {
    if (_usernameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showErrorDialog('Veuillez remplir tous les champs');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showErrorDialog('Le mot de passe doit contenir au moins 6 caractères');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newUser = await auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (newUser.user != null) {
        // Update display name
        await newUser.user!.updateDisplayName(_usernameController.text);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Une erreur est survenue';
      if (e.code == 'weak-password') {
        message = 'Le mot de passe est trop faible';
      } else if (e.code == 'email-already-in-use') {
        message = 'Cet email est déjà utilisé';
      } else if (e.code == 'invalid-email') {
        message = 'Email invalide';
      }
      _showErrorDialog(message);
    } catch (e) {
      _showErrorDialog('Erreur d\'inscription: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
              margin: EdgeInsets.only(right: 50, left: 50),
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
            SizedBox(height: 21),
            buildUser(),
            SizedBox(height: 6),
            buildEmail(),
            SizedBox(height: 6),
            buildPassword(),
            SignUpButton(),
            Container(
              height: 145,
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

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:projet2cp/ResetPassword.dart';
import 'package:projet2cp/bilanpage.dart';

class Loginpage extends StatefulWidget {
  const Loginpage({Key? key}) : super(key: key);

  @override
  State<Loginpage> createState() => _LoginpageState();
}

class _LoginpageState extends State<Loginpage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final auth = FirebaseAuth.instance;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget buildEmail() {
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
              hintText: 'exemple@email.com',
              hintStyle: TextStyle(color: Colors.black38),
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
        const Text(
          '       Mot de passe',
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
            controller: _passwordController,
            obscureText: true,
            style: const TextStyle(color: Colors.black87),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 14),
              prefixIcon: Icon(Icons.lock_outline, color: Colors.black),
              hintText: '••••••••',
              hintStyle: TextStyle(color: Colors.black38),
            ),
          ),
        )
      ],
    );
  }

  Widget ForgetPassword() {
    return Container(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: () {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ResetPassword()),
            );
          }
        },
        child: const Text(
          '     Mot de passe oublié ? ',
          style: TextStyle(
            color: Color(0xFF00C1C4),
            fontFamily: 'SpaceGrotesk',
          ),
        ),
      ),
    );
  }

  Widget LoginButton() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 25),
      width: 164,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFBD7D5A),
          padding: const EdgeInsets.all(15),
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
                'Connexion',
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

  Future<void> _handleLogin() async {
    if (!mounted) return;

    // Validation des champs
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _showErrorDialog('Veuillez remplir tous les champs');
      return;
    }

    // Validation format email
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      _showErrorDialog('Format d\'email invalide');
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final userCredential = await auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (userCredential.user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Bilanpage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message = 'Une erreur est survenue';

      switch (e.code) {
        case 'user-not-found':
          message = 'Aucun utilisateur trouvé avec cet email';
          break;
        case 'wrong-password':
          message = 'Mot de passe incorrect';
          break;
        case 'invalid-email':
          message = 'Email invalide';
          break;
        case 'user-disabled':
          message = 'Ce compte a été désactivé';
          break;
        case 'too-many-requests':
          message = 'Trop de tentatives. Réessayez plus tard';
          break;
        case 'network-request-failed':
          message = 'Erreur réseau. Vérifiez votre connexion';
          break;
        case 'invalid-credential':
          message = 'Email ou mot de passe incorrect';
          break;
        default:
          message = 'Erreur d\'authentification: ${e.message}';
      }

      _showErrorDialog(message);
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Erreur de connexion: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Erreur', style: TextStyle(fontFamily: 'SpaceGrotesk')),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'SpaceGrotesk'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
            const SizedBox(height: 40),
            buildEmail(),
            const SizedBox(height: 8),
            buildPassword(),
            ForgetPassword(),
            LoginButton(),
            Container(
              height: 155,
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

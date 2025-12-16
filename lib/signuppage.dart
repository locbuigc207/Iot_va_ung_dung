import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:projet2cp/bilanpage.dart';

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
        const Text(
          '       Nom d\'utilisateur',
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
            controller: _usernameController,
            keyboardType: TextInputType.name,
            style: const TextStyle(color: Colors.black87),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 14),
              prefixIcon: Icon(Icons.person, color: Colors.black),
              hintText: 'Votre nom',
              hintStyle: TextStyle(color: Colors.black38),
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
              hintText: 'Min. 6 caractères',
              hintStyle: TextStyle(color: Colors.black38),
            ),
          ),
        )
      ],
    );
  }

  Widget SignUpButton() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      width: 164,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignUp,
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
    if (!mounted) return;

    // Validation des champs
    if (_usernameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _showErrorDialog('Veuillez remplir tous les champs');
      return;
    }

    // Validation nom d'utilisateur
    if (_usernameController.text.trim().length < 2) {
      _showErrorDialog(
          'Le nom d\'utilisateur doit contenir au moins 2 caractères');
      return;
    }

    // Validation format email
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      _showErrorDialog('Format d\'email invalide');
      return;
    }

    // Validation mot de passe
    if (_passwordController.text.length < 6) {
      _showErrorDialog('Le mot de passe doit contenir au moins 6 caractères');
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (userCredential.user != null) {
        // Mettre à jour le nom d'affichage
        await userCredential.user!
            .updateDisplayName(_usernameController.text.trim());

        // Envoyer un email de vérification
        try {
          await userCredential.user!.sendEmailVerification();
        } catch (e) {
          debugPrint('Error sending verification email: $e');
          // Continue même si l'envoi de l'email échoue
        }

        if (mounted) {
          // Afficher un message de succès
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  const Text('Succès',
                      style: TextStyle(fontFamily: 'SpaceGrotesk')),
                ],
              ),
              content: const Text(
                'Compte créé avec succès!\nUn email de vérification a été envoyé.',
                style: TextStyle(fontFamily: 'SpaceGrotesk'),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (mounted) {
                      Navigator.pop(context); // Fermer le dialog
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const Bilanpage()),
                      );
                    }
                  },
                  child: const Text(
                    'Continuer',
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
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message = 'Une erreur est survenue';

      switch (e.code) {
        case 'weak-password':
          message = 'Le mot de passe est trop faible';
          break;
        case 'email-already-in-use':
          message = 'Cet email est déjà utilisé';
          break;
        case 'invalid-email':
          message = 'Email invalide';
          break;
        case 'operation-not-allowed':
          message = 'Opération non autorisée';
          break;
        case 'network-request-failed':
          message = 'Erreur réseau. Vérifiez votre connexion';
          break;
        default:
          message = 'Erreur d\'inscription: ${e.message}';
      }

      _showErrorDialog(message);
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Erreur d\'inscription: ${e.toString()}');
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
              margin: const EdgeInsets.only(right: 50, left: 50),
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
            const SizedBox(height: 21),
            buildUser(),
            const SizedBox(height: 6),
            buildEmail(),
            const SizedBox(height: 6),
            buildPassword(),
            SignUpButton(),
            Container(
              height: 145,
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

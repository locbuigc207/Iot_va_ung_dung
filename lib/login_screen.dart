import 'package:flutter/material.dart';
import 'package:hust_iot/pages/login_page.dart';
import 'package:hust_iot/pages/signup_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _errorLoadingGirl = false;

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        color: const Color(0xFFF4F3E9),
        height: size.height,
        width: double.infinity,
        child: Stack(
          children: <Widget>[
            // Background image
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('Assets/imageback.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Girl image with error handling
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 445,
                child: _errorLoadingGirl
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.account_circle,
                              size: 150,
                              color: const Color(0xFF084C61).withOpacity(0.5),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Pi-Vert',
                              style: TextStyle(
                                color: Color(0xFF084C61),
                                fontFamily: 'VeronaSerial',
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Image.asset(
                        'Assets/Girl.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('Error loading Girl.png: $error');
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() {
                                _errorLoadingGirl = true;
                              });
                            }
                          });
                          return const SizedBox.shrink();
                        },
                      ),
              ),
            ),

            // App name
            const Positioned(
              top: 365,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Pi-Vert',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    decoration: TextDecoration.none,
                    color: Color(0xFF084C61),
                    fontFamily: 'VeronaSerial',
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Tagline
            const Positioned(
              top: 415,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Make Your Plants Proud',
                  style: TextStyle(
                    decoration: TextDecoration.none,
                    color: Color(0xFF084C61),
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 18,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ),

            // Login button
            Positioned(
              top: 470,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () {
                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginPage()),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C1C4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    child: const Text(
                      'Login',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFF4F3E9),
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Sign up button
            Positioned(
              top: 535,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () {
                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SignUpPage()),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBD7D5A),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    child: const Text(
                      'Sign Up',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFF4F3E9),
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

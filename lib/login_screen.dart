import 'package:flutter/material.dart';
import 'package:projet2cp/loginpage.dart';
import 'package:projet2cp/signuppage.dart';

class Login_screen extends StatefulWidget {
  const Login_screen({Key? key}) : super(key: key);

  @override
  State<Login_screen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<Login_screen> {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        color: Color(0xFFF4F3E9),
        height: size.height,
        width: double.infinity,
        child: Stack(
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('Assets/imageback.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Container(
              height: 445,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('Assets/Girl.png'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 365,
              left: 140,
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
            Positioned(
              top: 415,
              left: 100,
              child: Text(
                'Rendez vos plantes fières',
                style: TextStyle(
                  decoration: TextDecoration.none,
                  color: Color(0xFF084C61),
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
            Positioned(
              top: 470,
              left: 130,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Loginpage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF00C1C4),
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Connexion',
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
            Positioned(
              top: 535,
              left: 130,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Sign_up_page()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFBD7D5A),
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Inscription',
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
          ],
        ),
      ),
    );
  }
}

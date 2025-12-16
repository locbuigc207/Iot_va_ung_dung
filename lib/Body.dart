import 'package:flutter/material.dart';

class Body extends StatelessWidget {
  const Body({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      color: const Color(0xFFF4F3E9),
      height: size.height,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // Logo/Image
          Positioned(
            top: 240,
            child: Image.asset(
              'Assets/sos.png',
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.eco,
                  size: 100,
                  color: Color(0xFF084C61),
                );
              },
            ),
          ),

          // App Name
          const Positioned(
            top: 360,
            child: Text(
              'Pi-Vert',
              style: TextStyle(
                color: Color(0xFF084C61),
                fontFamily: 'VeronaSerial',
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Copyright Line 1
          const Positioned(
            top: 600,
            child: Text(
              'Copyright© 2021-2022 ESI Alger',
              style: TextStyle(
                color: Colors.black87,
                fontFamily: 'SpaceGrotesk',
                fontSize: 13,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),

          // Copyright Line 2
          const Positioned(
            top: 620,
            child: Text(
              'Projet 2CP Tout droit réservé',
              style: TextStyle(
                color: Colors.black87,
                fontFamily: 'SpaceGrotesk',
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class Body extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      color: Color(0xFFF4F3E9),
      height: size.height,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            top: 240,
              child: Image.asset('Assets/sos.png'),
          ),
          Positioned(
            top: 360,
              child: Text(
                'Pi-Vert',
                style: TextStyle(
                  color: Color(0xFF084C61),
                  fontFamily: 'VeronaSerial',
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              )
          ),
          Positioned(
              top: 600,
              child: Text(
                'Copyright© 2021-2022 ESI Alger ',
                style: TextStyle(
                  color: Colors.black87,
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ),
          Positioned(
              top: 620,
              child: Text(
                'Projet 2CP Tout droit réservé',
                style: TextStyle(
                  color: Colors.black87,
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              )
          ),
        ],
      ),
    );
  }
  
}
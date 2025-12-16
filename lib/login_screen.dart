import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:projet2cp/loginpage.dart';
import 'package:projet2cp/signuppage.dart';

class Login_screen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => InitState();

}

class InitState extends State<Login_screen> {
  @override
  Widget build(BuildContext context) {
    return initWidget();
  }

  Widget initWidget() {
    Size size = MediaQuery.of(context).size;
    return Container(
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
              ),
            ),
          ),
          /*Positioned(
            top: 130,
            left: 60,
            child: Image.asset('Assets/Girl.png'),
          ),*/
          Positioned(
            //height: 500,
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
            /*child: Text(
                'Pi-Vert',
                style: TextStyle(
                  decoration: TextDecoration.none,
                  color: Color(0xFF084C61),
                  fontFamily: 'VeronaSerial',
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),*/
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
              child: Container(
                height: 45,
                width: 160,
                padding: EdgeInsets.all(7),
                decoration: new BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Color(0xFF00C1C4),
                ),
                child: FlatButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return Loginpage();
                        },
                      ),
                    );
                  },
                  child: Text(
                    'Connexion',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      decoration: TextDecoration.none,
                      color: Color(0xFFF4F3E9),
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
          ),
          Positioned(
            top: 535,
            left: 130,
            child: Container(
              height: 45,
              width: 160,
              padding: EdgeInsets.all(7),
              decoration: new BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Color(0xFFBD7D5A),
              ),
              child: FlatButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return Sign_up_page();
                      },
                    ),
                  );
                },
                child: Text(
                  'Inscription',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    decoration: TextDecoration.none,
                    color: Color(0xFFF4F3E9),
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          /*Container(
          width : MediaQuery.of(context).size.width,
            child: Align(
              alignment: Alignment.bottomCenter,
              child : Image.asset('Assets/Vector 2.png'),
            ),
            /*decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('Assets/Vector 2.png'),
                fit: BoxFit.fitWidth,
              ),*/
            ),*/
        ],
      ),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:projet2cp/Homescreen.dart';
import 'package:projet2cp/bilanpage.dart';

class ResetPassword extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => InitState();

}

class InitState extends State<ResetPassword> {
  late String _email;
  final auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return resetpassword();
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
                  offset: Offset(0,2),
                )
              ]
          ),
          height: 60,
          child: TextField(
            onChanged: (value) {
              _email = value;
            },
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(
              color: Colors.black87,
            ),
            decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.only(top: 14),
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: Colors.black,
                )
            ),
          ),
        )
      ],
    );
  }

  Future<void> sendPasswordResetEmail(String email) async {
    return auth.sendPasswordResetEmail(email: _email);
  }

  Widget ResetButton(){
    return Container(
        padding: EdgeInsets.symmetric(vertical: 20),
        width: 167,
        child: RaisedButton(
          elevation: 5,
          onPressed: () async {
            try {
              auth.sendPasswordResetEmail(email: _email);
            }
            catch (e) {
              print(e);
            }
          },
          padding: EdgeInsets.all(13),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)
          ),
          color: Color(0xFFBD7D5A),
          child: Text(
            'Reset Password',
            style: TextStyle(
              color: Color(0xFFF4F3E9),
              fontSize: 18,
              fontFamily: 'SpaceGrotesk',
              fontWeight: FontWeight.bold,
            ),
          ),
        )
    );
  }

  Widget resetpassword() {
    Size size = MediaQuery.of(context).size;
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
                    fit : BoxFit.fitWidth,
                  )
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 10, right: 50, left: 50),
              child: Center(
                child: Text("Pi-Vert" , style: TextStyle(color: Color(0xFF084C61) , fontFamily: 'VeronaSerial' , fontSize: 40, fontWeight: FontWeight.bold), ),
              ),
            ),
            SizedBox(height : 70),
            buildEmail(),
            SizedBox(height : 8),
            ResetButton(),
            Container(
              height: 400,
              decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('Assets/Vector 2.png'),
                    fit : BoxFit.fitWidth,
                  )
              ),
            ),
          ],
        ),
      ),
    );
  }

}
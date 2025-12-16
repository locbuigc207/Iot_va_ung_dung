import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:projet2cp/Homescreen.dart';
import 'package:projet2cp/ResetPassword.dart';
import 'package:projet2cp/bilanpage.dart';
import 'package:projet2cp/signuppage.dart';

class Loginpage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => InitState();

}

class InitState extends State<Loginpage> {
  late String _email,_password;
  final auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return loginpage();
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

  Widget buildPassword(){
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
                  offset: Offset(0,2),
                )
              ]
          ),
          height: 60,
          child: TextField(
            onChanged: (value){
              _password = value;
            },
            obscureText: true,
            style: TextStyle(
              color: Colors.black87,
            ),
            decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.only(top: 14),
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: Colors.black,
                )
            ),
          ),
        )
      ],
    );
  }

  Widget ForgetPassword(){
    return Container(
      alignment: Alignment.centerLeft,
      child: FlatButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => ResetPassword(),),);
        },
        padding: EdgeInsets.only(left: 0),
        child: Text(
          '     Mot de passe oublié ? ',
          style: TextStyle(
            color : Color(0xFF00C1C4),
            fontFamily: 'SpaceGrotesk',
          ),
        ),
      ),
    );
  }


  Widget LoginButton(){
    return Container(
        padding: EdgeInsets.symmetric(vertical: 25),
        width: 164,
        child: RaisedButton(
          elevation: 5,
          onPressed: () async {
            try {
              final user = await auth.signInWithEmailAndPassword(
                  email: _email, password: _password);
              if (user != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => Bilanpage(),),);
              }
            }
            catch (e) {
              print(e);
            }
          },
          padding: EdgeInsets.all(15),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)
          ),
          color: Color(0xFFBD7D5A),
          child: Text(
            'Connexion',
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

  Widget loginpage() {
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
            SizedBox(height : 40),
            buildEmail(),
            SizedBox(height : 8),
            buildPassword(),
            ForgetPassword(),
            LoginButton(),
            Container(
              height: 155,
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


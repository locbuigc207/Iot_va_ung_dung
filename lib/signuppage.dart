import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:projet2cp/Homescreen.dart';

class Sign_up_page extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => InitState();
}

class InitState extends State<Sign_up_page> {
  late String _email, _password;
  final auth = FirebaseAuth.instance;
  @override
  Widget build(BuildContext context) {
    return Sign_up_page();
  }

  Widget buildUser() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '       Nom d''utilisateur',
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
            keyboardType: TextInputType.name,
            style: TextStyle(
              color: Colors.black87,
            ),
            decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.only(top: 14),
                prefixIcon: Icon(
                  Icons.person,
                  color: Colors.black,
                )
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
            onChanged: (value) {
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

  Widget SignUpButton(){
    return Container(
        padding: EdgeInsets.symmetric(vertical: 10),
        width: 164,
        child: RaisedButton(
          elevation: 5,
          onPressed: () async {
            try {
              final newUser = await auth.createUserWithEmailAndPassword(email: _email, password: _password);
              if(newUser != null ) {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => HomeScreen(),),);
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
            'Inscription',
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

  Widget Sign_up_page() {
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
              margin: EdgeInsets.only(right: 50, left: 50),
              child: Center(
                child: Text("Pi-Vert" , style: TextStyle(color: Color(0xFF084C61) , fontFamily: 'VeronaSerial' , fontSize: 40, fontWeight: FontWeight.bold), ),
              ),
            ),
            SizedBox(height : 21),
            buildUser(),
            SizedBox(height : 6),
            buildEmail(),
            SizedBox(height : 6),
            buildPassword(),
            SignUpButton(),
            Container(
              height: 145,
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

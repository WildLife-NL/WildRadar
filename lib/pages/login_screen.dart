import 'package:flutter/material.dart';
import 'package:wild_radar/pages/mapping_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Formulaire GlobalKey voor validatie
  final _formKey = GlobalKey<FormState>();

  // Controllers voor e-mail en wachtwoord
  final _emailController = TextEditingController();

  // Functie voor het afhandelen van login
  void _login() {
    if (_formKey.currentState!.validate()) {
      // Hier kun je de login verwerken (bijvoorbeeld een API-aanroep)
      final email = _emailController.text;
      print('Email: $email');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MappingPage()),
      );
    } else {
      print('niet ingelogd!');
    }
  }

  // Functie voor e-mail validatie
  String? _validateEmail(String? value) {
    // Controleer of het e-mailadres niet leeg is
    if (value == null || value.isEmpty) {
      return 'Voer een e-mail in';
    }
    // Reguliere expressie voor e-mailvalidatie
    String pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$';
    RegExp regExp = RegExp(pattern);
    if (!regExp.hasMatch(value)) {
      return 'Voer een geldig e-mailadres in';
    }
    return null;
  }

  @override
Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Check if the screen width is below a certain threshold
          if (constraints.maxWidth < 600) {
            // Mobile/narrow view - stack vertically
            return Form(
              key: _formKey,
              child: Column(
              children: [
                Image.asset('lib/assets/images/wildradarlogo.png'),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'E-mailadres',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateEmail, // Valideer het E-mailadres
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(onPressed: _login, child: Text('inloggen')),
                Expanded(
                  child: Image.asset(
                    'lib/assets/images/edelhert.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
            );
          } else {
            // Wide view - side by side

            return Row(
              children: [
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: Padding(
                      padding: const EdgeInsets.all(50.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Image.asset('lib/assets/images/wildradarlogo.png'),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 15.0, 0, 15.0),
                            child: SizedBox(
                              width: double.infinity,
                              child: Text(
                                  'E-mail',
                                  textAlign: TextAlign.left,
                              ),
                          ),

                          ),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'E-mailadres',
                              border: OutlineInputBorder(),
                            ),
                            validator: _validateEmail, // valideer email adres
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 10, 0, 30.0),
                            child: SizedBox(
                              width: double.infinity,
                              child: Text(
                                  'Vul hier je e-mail in om de code te ontvangen',
                                  textAlign: TextAlign.left,
                              ),
                          ),

                          ),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Color.fromRGBO(90, 167, 49, 100),
                                shape: StadiumBorder(),
                              ),
                              onPressed: _login,
                              child: Text('Inloggen')
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Image.asset(
                    'lib/assets/images/edelhert.jpg',
                     fit: BoxFit.cover,
                     height: double.infinity,
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
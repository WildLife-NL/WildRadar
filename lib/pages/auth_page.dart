import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wild_radar/pages/mapping_page.dart';

// Starting class
class AuthPage extends StatefulWidget {
  @override
  _AuthPageState createState() => _AuthPageState();
}

// General code
class _AuthPageState extends State<AuthPage> {

//Formkey for valudation of the 6 number code
final _codeFormKey = GlobalKey<FormState>();

//Make a list of text controllers for the 6 digit code
final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());

//Make a list of focues nodes to manage the imput focus between boxes (highlighting)
final List<FocusNode> _focusNodes=
  List.generate(6, (_) => FocusNode());

//Function for login (later 6 digit code)
void _login() {
  // if the _codeformkey his current state is set to validate then...
  if (_codeFormKey.currentState!.validate()) {
    //(room for api)
    final code = _controllers.map((controller) => controller.text).join();
    print('Code: $code');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MappingPage()),
    );
    //IF validation is wrong...
  } else {
    print('Fout bij inloggen!');
  }
}

// Clean up controllers
@override
void dispose() {
  for (var controller in _controllers) {
    controller.dispose();
  }
  for (var focusNode in _focusNodes) {
    focusNode.dispose();
  }
  super.dispose();
}




// Make a field of numbers you can put in
@override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Check if the screen is below the treshold
          if(constraints.maxWidth < 600) {
            //mobile version/narrow view
            return Form(
              key: _codeFormKey,
              child: Column(
                children: [
                  Image.asset('lib/assets/images/wildradarlogo.png'),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (index) =>
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: SizedBox(
                            width: 50,
                            child: TextFormField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(1),
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                counterText: '',
                              ),
                              maxLength: 1,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                if (value.isNotEmpty && index < 5) {
                                  FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
                                }
                              },
                            ),
                          ),
                        )
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(onPressed: _login, child: Text('Inloggen')),
                  Expanded(
                    child: Image.asset(
                      	'lib/assets/images/edelhert.jpg',
                        fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            );
            //If screen > 600 (desktop)
          } else {
            return Row(
            children: [
              Expanded(
                child: Form(
                  key: _codeFormKey,
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
                              '6-Cijferige Code',
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(6, (index) => 
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: SizedBox(
                                width: 50,
                                child: TextFormField(
                                  controller: _controllers[index],
                                  focusNode: _focusNodes[index],
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(1),
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    counterText: '',
                                  ),
                                  maxLength: 1,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return '';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) {
                                    if (value.isNotEmpty && index < 5) {
                                      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
                                    }
                                  },
                                ),
                              ),
                            )
                          ),
                        ),
                        Padding(
                           padding: const EdgeInsets.fromLTRB(0, 10, 0, 30.0),
                           child: SizedBox(
                            width: double.infinity,
                            child: Text(
                              'Vul hier je 6-Cijferige code in',
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child:ElevatedButton(
                            style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Color.fromRGBO(90, 167, 49, 100),
                            shape: StadiumBorder(),
                          ),
                          onPressed: _login,
                          child: Text('inloggen')
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
              )
            ],
            );
          }
        },
      ),
    );
  }
}
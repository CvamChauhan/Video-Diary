import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_blackcoffer/auth_via_phone_screen/feed_screen.dart';

enum MobileVerificationState {
  showMobileFormState,
  showOtpFormState,
}

class LogInViaPhone extends StatefulWidget {
  const LogInViaPhone({Key? key}) : super(key: key);

  @override
  State<LogInViaPhone> createState() => _LogInViaPhoneState();
}

class _LogInViaPhoneState extends State<LogInViaPhone> {
  MobileVerificationState currState =
      MobileVerificationState.showMobileFormState;

  late String verificationId;
  bool showLoading = false;
  int? _forceResendingToken;
  TextStyle myTextStyle = const TextStyle(color: Colors.white);
  TextEditingController mobileController = TextEditingController();
  TextEditingController otpController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  void verifyPhoneNumber() async {
    setState(() {
      showLoading = true;
    });
    await _auth.verifyPhoneNumber(
        forceResendingToken: _forceResendingToken,
        phoneNumber: extention + mobileController.text,
        verificationCompleted: (PhoneAuthCredential phoneAuthCredential) async {
          setState(() {
            showLoading = false;
          });
        },
        verificationFailed: (FirebaseAuthException error) async {
          setState(() {
            showLoading = false;
          });
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(error.message.toString())));
        },
        codeSent: (String verificationId, int? forceResendingToken) async {
          setState(() {
            showLoading = false;
            _forceResendingToken = forceResendingToken;
            currState = MobileVerificationState.showOtpFormState;
            this.verificationId = verificationId;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) async {});
  }

  String extention = '+91';
  getMobileFormWidget(context) {
    final mobileField = TextFormField(
        cursorColor: Colors.black,
        autofocus: false,
        controller: mobileController,
        keyboardType: const TextInputType.numberWithOptions(),
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 5.0,
              ),
              DropdownButton(
                value: extention,
                items: const [
                  DropdownMenuItem(
                    child: Text(
                      '+91',
                    ),
                    value: '+91',
                  ),
                  DropdownMenuItem(
                    child: Text('+57'),
                    value: '+57',
                  ),
                  DropdownMenuItem(
                    child: Text('1'),
                    value: '1',
                  ),
                  DropdownMenuItem(
                    child: Text('+49'),
                    value: '+49',
                  ),
                  DropdownMenuItem(
                    child: Text('+93'),
                    value: '+93',
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    extention = value.toString();
                  });
                },
              ),
            ],
          ),
          contentPadding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
          hintText: "Mobile",
          focusColor: Colors.black,
          focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(
            color: Colors.black,
          )),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ));
    return Column(
      // crossAxisAlignment: CrossAxisAlignment.,
      children: [
        const Spacer(
          flex: 1,
        ),
        const Icon(
          Icons.phone,
          size: 100,
          color: Colors.white,
        ),
        const Spacer(
          flex: 2,
        ),
        mobileField,
        const SizedBox(
          height: 10,
        ),
        MaterialButton(
          color: Colors.blue,
          minWidth: 10,
          child: const Text(
            "NEXT",
            style: TextStyle(fontSize: 20, color: Colors.white),
          ),
          onPressed: verifyPhoneNumber,
        ),
        const Spacer(
          flex: 2,
        )
      ],
    );
  }

  getOtpFormWidget(context) {
    final optFormField = TextFormField(
        cursorColor: Colors.black,
        autofocus: false,
        controller: otpController,
        keyboardType: const TextInputType.numberWithOptions(),
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(Icons.mail_outline),
          contentPadding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
          hintText: "Mobile",
          focusColor: Colors.black,
          focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(
            color: Colors.black,
          )),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ));
    return Column(
      children: [
        const Spacer(
          flex: 1,
        ),
        const Icon(
          Icons.phone,
          size: 80,
          color: Colors.white,
        ),
        const Spacer(
          flex: 2,
        ),
        Row(
          children: [
            const SizedBox(
              width: 10,
            ),
            Flexible(child: optFormField),
            const SizedBox(
              width: 10,
            ),
            MaterialButton(
              color: Colors.blue,
              minWidth: 10,
              child: const Text(
                "Verify",
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),

              onPressed: () async {
                PhoneAuthCredential phoneAuthCredential =
                    PhoneAuthProvider.credential(
                        verificationId: verificationId,
                        smsCode: otpController.text);
                signInWithPhoneAuthCredential(phoneAuthCredential);
              },
              // color: Colors.,
            ),
          ],
        ),
        const SizedBox(
          height: 20,
        ),
        MaterialButton(
          color: Colors.blue,
          minWidth: 10,
          child: const Text(
            "Re-Send",
            style: TextStyle(fontSize: 20, color: Colors.white),
          ),

          onPressed: verifyPhoneNumber,
          // color: Colors.,
        ),
        const Spacer(
          flex: 2,
        )
      ],
    );
  }

  void signInWithPhoneAuthCredential(
      PhoneAuthCredential phoneAuthCredential) async {
    setState(() {
      showLoading = true;
    });

    try {
      final authCredential =
          await _auth.signInWithCredential(phoneAuthCredential);
      setState(() {
        showLoading = false;
      });
      if (authCredential.user != null) {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const FeedScreen()));
        setState(() {
          MobileVerificationState.showMobileFormState;
        });
      }
    } catch (e) {
      setState(() {
        showLoading = false;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        body: Container(
            margin: const EdgeInsets.symmetric(vertical: 50, horizontal: 30),
            child: showLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : currState == MobileVerificationState.showMobileFormState
                    ? getMobileFormWidget(context)
                    : getOtpFormWidget(context)));
  }
}

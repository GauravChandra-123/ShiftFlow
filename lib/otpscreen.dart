import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shopmanagementapp/adminpage.dart';

class Otpscreen extends StatefulWidget {
  String verificationId;

  Otpscreen({super.key, required this.verificationId});

  @override
  State<Otpscreen> createState() => _OtpscreenState();
}

class _OtpscreenState extends State<Otpscreen> {
  TextEditingController otpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('OTP Screen'), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: TextField(
              controller: otpController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Enter OTP',
                suffixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: () async {
              try {
                PhoneAuthCredential credential = PhoneAuthProvider.credential(
                  verificationId: widget.verificationId,
                  smsCode: otpController.text.trim(),
                );

                await FirebaseAuth.instance
                    .signInWithCredential(credential)
                    .then((value) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AdminPage(
                          title: 'Admin Page',
                          adminDocID: '',
                          adminName: 'Admin',
                          adminPhone: '',
                          adminPhotoBase64: '',
                        ),
                    ),
                  );
                });
              } catch (ex) {
                print("Error: $ex");
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("Invalid OTP")));
              }
            },
            child: Text("Verify OTP"),
          ),
        ],
      ),
    );
  }
}

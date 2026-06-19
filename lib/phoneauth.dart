import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shopmanagementapp/otpscreen.dart';

import 'adminpage.dart';
import 'employee_page.dart';
import 'firestore.dart';

/*
class PhoneAuth extends StatefulWidget {
  const PhoneAuth({super.key});

  @override
  State<PhoneAuth> createState() => _PhoneAuthState();
}

class _PhoneAuthState extends State<PhoneAuth> {
  TextEditingController phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Phone Auth'), centerTitle: true),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone, // <-- change here
              decoration: InputDecoration(
                hintText: ('Enter Phone Number'),
                suffixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: () async {
              String phone = phoneController.text.trim();

              if (!phone.startsWith("+")) {
                phone =
                "+91$phone"; // default to India (change as per your need)
              }

              await FirebaseAuth.instance.verifyPhoneNumber(
                phoneNumber: phone,
                verificationCompleted:
                    (PhoneAuthCredential credential) async {},
                verificationFailed: (FirebaseAuthException ex) {
                  print("Verification Failed: ${ex.message}");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ex.message ?? "Verification failed"),
                    ),
                  );
                },
                codeSent: (String verificationId, int? resendToken) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          Otpscreen(verificationId: verificationId),
                    ),
                  );
                },
                codeAutoRetrievalTimeout: (String verificationId) {},
              );
            },
            child: Text('Verify Phone Number'),
          ),
        ],
      ),
    );
  }
}
*/

class PhoneAuth extends StatefulWidget {
  const PhoneAuth({super.key});

  @override
  State<PhoneAuth> createState() => _PhoneAuthState();
}

class _PhoneAuthState extends State<PhoneAuth> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FirestoreService firestoreService = FirestoreService();

  Future<void> login() async {
    final String phone = phoneController.text.trim();
    final String password = passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter phone number and password")),
      );
      return;
    }

    if (password.length != 6 || int.tryParse(password) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password must be exactly 6 digits")),
      );
      return;
    }

    try {
      final userData = await firestoreService.loginUser(phone, password);

      if (userData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid phone or password")),
        );
        return;
      }

      final role = userData['role']?.toString() ?? '';

      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => AdminPage(
                title: 'Admin Page',
                adminDocID: userData['docID'] ?? '',
                adminName: userData['name'] ?? 'Admin',
                adminPhone: userData['phone'] ?? '',
                adminPhotoBase64: userData['photoBase64'] ?? '',
              ),
          ),
        );
      } else if (role == 'employee') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            //builder: (context) => const EmployeePage(),
              builder: (context) => EmployeePage(
                docID: userData['docID'] ?? '',
                name: userData['name'] ?? '',
                phone: userData['phone'] ?? '',
                photoBase64: userData['photoBase64'] ?? '',
              ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User role not found")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login error: $e")),
      );
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Enter Phone Number',
                suffixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: InputDecoration(
                hintText: 'Enter 6 Digit Password',
                suffixIcon: const Icon(Icons.lock),
                counterText: "",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: login,
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
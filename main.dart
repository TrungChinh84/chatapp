import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart'; // để dùng kIsWeb
import 'firebase_options.dart';
import 'realtime_demo.dart';

// Hàm login Google
Future<UserCredential?> signInWithGoogle() async {
  if (kIsWeb) {
    // Web login
    GoogleAuthProvider authProvider = GoogleAuthProvider();
    return await FirebaseAuth.instance.signInWithPopup(authProvider);
  } else {
    // Mobile login
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null; // user hủy login
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Login Google trước khi chạy app
  await signInWithGoogle();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RealtimeDemo(),
    );
  }
}

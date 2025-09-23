import 'package:flutter/material.dart';
import 'package:tiktok_clone_app/utils.dart';

import '../../../constants.dart';
import '../../widgets/text_input_field.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _usernameController = TextEditingController();

  String profilePhoto = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Tiktok Clone',
              style: TextStyle(
                fontSize: 35,
                color: buttonColor,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Text(
              'Register',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(
              height: 25,
            ),
            Stack(
              children: [
                CircleAvatar(
                  radius: 64,
                  backgroundImage: NetworkImage(profilePhoto),
                  backgroundColor: Colors.black,
                ),
                Positioned(
                  bottom: -10,
                  left: 75,
                  child: IconButton(
                    onPressed: () async {
                      final pickedImage = await pickImage();
                      if(pickedImage != null) {
                        final imageUrl = await uploadImageToImgBB(pickedImage);
                        if(imageUrl != null) {
                          setState(() {
                            profilePhoto = imageUrl;
                          });
                        }
                      } else {
                        setState(() {
                          profilePhoto = defaultProfilePhoto;
                        });
                      }
                    },
                    icon: Icon(
                      Icons.add_a_photo,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 15,
            ),
            Container(
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: TextInputField(
                controller: _usernameController,
                labelText: 'Username',
                prefixIcon: Icons.person,
              ),
            ),
            const SizedBox(
              height: 15,
            ),
            Container(
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: TextInputField(
                controller: _emailController,
                labelText: 'Email',
                prefixIcon: Icons.email,
              ),
            ),
            const SizedBox(
              height: 15,
            ),
            Container(
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: TextInputField(
                controller: _passwordController,
                labelText: 'Password',
                prefixIcon: Icons.lock,
                isObscure: true,
              ),
            ),
            const SizedBox(
              height: 30,
            ),
            Container(
              width: MediaQuery.of(context).size.width - 40,
              height: 50,
              decoration: BoxDecoration(
                color: buttonColor,
                borderRadius: const BorderRadius.all(
                  Radius.circular(5),
                ),
              ),
              child: InkWell(
                onTap: () => authController.registerUser(
                  _usernameController.text,
                  _emailController.text,
                  _passwordController.text,
                  profilePhoto,
                ),
                child: const Center(
                  child: Text(
                    'Register',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 15,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Already have an account? ',
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => LoginScreen(),
                    ),
                  ),
                  child: Text(
                    'Login',
                    style: TextStyle(fontSize: 20, color: buttonColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:ai1/home.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class MySplash extends StatefulWidget {
  const MySplash({super.key});

  @override
  State<MySplash> createState() => _MySplashState();
}

class _MySplashState extends State<MySplash> {
  var duration=Duration();
  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      splash: Center(
        child: Lottie.asset(
          "assets/splash1.json",
          onLoaded: (composition){
            setState(() {
              duration=composition.duration;
            });
          }
        ),
      ), 
      splashIconSize: 700,
      backgroundColor: Colors.white,
      duration: duration.inMilliseconds ,
      nextScreen: Home()
      );
  }
}
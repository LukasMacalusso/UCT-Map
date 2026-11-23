import 'package:flutter/material.dart';

class UctLogo extends StatelessWidget {
  final double height;
  final double width;

  const UctLogo({super.key, this.height = 36, this.width = 36});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo_uct.png',
      height: height,
      width: width,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback visual estilizado institucional en caso de no tener el archivo PNG aún
        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: const Color(0xFF003865), // Azul UCT
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFEAA221),
              width: 1.5,
            ), // Dorado UCT
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'UCT',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      },
    );
  }
}

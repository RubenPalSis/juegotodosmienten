import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class PlayerAvatar extends StatelessWidget {
  final Map<String, dynamic> playerData;

  const PlayerAvatar({super.key, required this.playerData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final cardColor = isDarkMode ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.3);

    final alias = playerData['alias'] as String? ?? 'Desconocido';
    final isReady = playerData['isReady'] as bool? ?? false;
    final characterFile = playerData['selectedCharacter'] as String? ?? 'robot.glb';
    final playerColorValue = playerData['color'] as int?;

    // Lógica del color del borde: solo se muestra si el jugador está listo.
    final Color borderColor;
    if (isReady) {
      borderColor = playerColorValue != null ? Color(playerColorValue) : Colors.green.shade300;
    } else {
      borderColor = Colors.white.withOpacity(0.2);
    }

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: 2),
      ),
      elevation: isReady ? 8.0 : 2.0,
      shadowColor: isReady ? borderColor.withOpacity(0.8) : Colors.transparent,
      child: Stack(
        children: [
          ModelViewer(
            src: 'assets/models/$characterFile',
            alt: "Avatar de $alias",
            autoRotate: true,
            cameraControls: false,
            disableZoom: true,
            backgroundColor: Colors.transparent,
          ),
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              color: Colors.black.withOpacity(0.5),
              child: Text(
                alias,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (isReady)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade800,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: const Text(
                  'LISTO',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

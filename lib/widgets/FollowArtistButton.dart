import 'package:flutter/material.dart';
import 'package:projecte_pm/services/PlayerService.dart';
import 'package:projecte_pm/services/UserService.dart';

class FollowArtistButton extends StatefulWidget {
  final String artistId;
  final PlayerService playerService;
  final bool showText;
  final double? iconSize;
  final double? fontSize;

  const FollowArtistButton({
    super.key,
    required this.artistId,
    required this.playerService,
    this.showText = true,
    this.iconSize = 18,
    this.fontSize = 14,
  });

  @override
  State<FollowArtistButton> createState() => _FollowArtistButtonState();
}

class _FollowArtistButtonState extends State<FollowArtistButton> {
  bool _isFollowing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkIfFollowing();
  }

  Future<void> _checkIfFollowing() async {
    // Comprova si l'usuari ja segueix l'artista
    if (widget.playerService.userService.currentUserId == null)
      return; // Usuari no autenticat

    try {
      final isFollowing = await widget.playerService.userService.isFollowingArtist(
        widget.artistId,
      );
      if (mounted) {
        // Assegura que el widget encara està muntat abans d'actualitzar l'estat
        setState(() => _isFollowing = isFollowing); // Actualitza l'estat
      }
    } catch (e) {
      // Catch d'errors
      print("Error validant si l'artista ja esta seguit: $e");
    }
  }

  Future<void> _toggleFollow() async {
    // Seguir/Deixar de seguir artista
    if (_isLoading || widget.playerService.userService.currentUserId == null)
      return; // Evita múltiples clics ràpids o usuari no autenticat

    setState(() => _isLoading = true); // Indica que s'està processant l'acció

    try {
      // Intentar seguir/deixar de seguir
      if (_isFollowing) {
        // Ja segueix, així que deixa de seguir
        await widget.playerService.userService.unfollowArtist(
          widget.artistId,
        ); // Deixar de seguir
      } else {
        // No segueix, així que segueix
        await widget.playerService.userService.followArtist(widget.artistId); // Seguir
      }

      final actualStatus = await widget.playerService.userService.isFollowingArtist(
        // Verifica l'estat actual
        widget.artistId, // ID de l'artista
      );

      if (mounted) {
        // Assegura que el widget encara està muntat abans d'actualitzar l'estat
        setState(
          () => _isFollowing = actualStatus,
        ); // Actualitza l'estat de seguiment
      }
      // Feedback visual
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            actualStatus // Mostra missatge segons l'estat
                ? "Ara segueixes a aquest artista"
                : "Has deixat de seguir",
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print("Error al seguir/deixar de seguir artista: $e"); // Log d'error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Error al procesar l'acció"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) // Assegura que el widget encara està muntat abans d'actualitzar l'estat
        setState(() => _isLoading = false); // Finalitza l'estat de càrrega
    }
  }

  @override
  Widget build(BuildContext context) {
    // Construcció del botó
    if (_isLoading) {
      return SizedBox(
        // Mostra indicador de càrrega
        width: widget.showText
            ? null
            : 24, // Si no mostra text, ajusta l'amplada
        height: 24, // Altura fixa
        child: const CircularProgressIndicator(
          // Indicador de càrrega
          strokeWidth: 2, // Gruix de la línia
          valueColor: AlwaysStoppedAnimation<Color>(
            Colors.white,
          ), // Color blanc
        ),
      );
    }

    return GestureDetector(
      onTap: _toggleFollow, // Acció al prémer el botó
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: widget.showText ? 16 : 8,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: _isFollowing ? Colors.transparent : Colors.white,
          border: Border.all(
            color: _isFollowing ? Colors.grey : Colors.transparent,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isFollowing ? Icons.check : Icons.add,
              color: _isFollowing ? Colors.white : Colors.black,
              size: widget.iconSize,
            ),
            if (widget.showText) const SizedBox(width: 6),
            if (widget.showText)
              Text(
                _isFollowing
                    ? "Seguint"
                    : "Seguir", // Text del botó en funció de l'estat
                style: TextStyle(
                  color: _isFollowing
                      ? Colors.white
                      : Colors.black, // Color del text en funció de l'estat
                  fontWeight: FontWeight.bold,
                  fontSize: widget.fontSize,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

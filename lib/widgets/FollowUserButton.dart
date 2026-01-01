import 'package:flutter/material.dart';
import 'package:projecte_pm/services/UserService.dart';

class FollowUserButton extends StatefulWidget {
  final String targetUserId;
  final UserService userService;
  final bool showText;
  final double? iconSize;
  final double? fontSize;

  const FollowUserButton({
    super.key,
    required this.targetUserId,
    required this.userService,
    this.showText = true,
    this.iconSize = 18,
    this.fontSize = 14,
  });

  @override
  State<FollowUserButton> createState() => _FollowUserButtonState();
}

class _FollowUserButtonState extends State<FollowUserButton> {
  bool _isFollowing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkIfFollowing();
  }

  Future<void> _checkIfFollowing() async {
    if (widget.userService.currentUserId == null) return;

    try {
      final isFollowing = await widget.userService.isFollowingUser(
        widget.targetUserId,
      );
      if (mounted) {
        setState(() => _isFollowing = isFollowing);
      }
    } catch (e) {
      print("Error comprovant si l'usuari ja està seguit: $e");
    }
  }

  Future<void> _toggleFollow() async {
    if (_isLoading || widget.userService.currentUserId == null) return;

    setState(() => _isLoading = true);

    try {
      if (_isFollowing) {
        await widget.userService.unfollowUser(widget.targetUserId);
      } else {
        await widget.userService.followUser(widget.targetUserId);
      }

      final actualStatus = await widget.userService.isFollowingUser(
        widget.targetUserId,
      );

      if (mounted) {
        setState(() => _isFollowing = actualStatus);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            actualStatus
                ? "Ara segueixes a aquest usuari"
                : "Has deixat de seguir",
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print("Error al seguir/deixar de seguir usuari: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Error al procesar l'acció"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: widget.showText ? null : 24,
        height: 24,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    return GestureDetector(
      onTap: _toggleFollow,
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
                _isFollowing ? "Seguint" : "Seguir",
                style: TextStyle(
                  color: _isFollowing ? Colors.white : Colors.black,
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

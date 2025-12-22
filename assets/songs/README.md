Opció: GitHub (La millor alternativa gratuïta per a proves)
Si tens el projecte a GitHub, pots pujar els MP3 allà (si no pesen més de 25MB cadascun) i fer servir els enllaços "Raw". GitHub té els permisos CORS oberts, així que funciona perfecte a Flutter Web.

Crea una carpeta assets/music al teu repositori.

Puja la cançó.

Ves a la web de GitHub, obre l'arxiu de la cançó.

Fes clic al botó "Raw" o "Download".

Copia la URL del navegador. Serà algo així: https://raw.githubusercontent.com/ElTeuUsuari/ElTeuRepo/main/assets/music/song.mp3

Posa aquesta URL a la teva base de dades Firestore al camp fileURL i funcionarà a la primera.

IMportantissim!! que sigui una url on posa RAW com: Correcta (la bona): https://raw.githubusercontent.com/rubiolbernat/projecte_pm/main/assets/songs/Johanna.mp3

Dins de playNow
Al PlayerService, detecta si és una URL web o un fitxer local. Si vols fer-ho fàcil, pots dir que si la URL comença per "http" és web, i si no, és local:
```dart
if (song.fileURL.startsWith('http')) {
await \_audioPlayer.play(UrlSource(song.fileURL));
} else {
// Si a la BD has guardat "assets/songs/Johanna.mp3"
await \_audioPlayer.play(AssetSource(song.fileURL.replaceFirst('assets/', '')));
}
```
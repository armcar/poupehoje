import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  const size = 512;
  final image = img.Image(width: size, height: size);

  // fundo azul
  img.fill(image, color: img.ColorRgb8(0, 102, 204));

  // escrever "PH"
  img.drawString(
    image,
    'PH',
    x: size ~/ 3,
    y: size ~/ 3,
    font: img.arial48,
    color: img.ColorRgb8(255, 255, 255),
  );

  final out = File('assets/temp_icon.png')
    ..createSync(recursive: true)
    ..writeAsBytesSync(img.encodePng(image));

  print('✅ Gerado em ${out.path}');
}

# ROFLO Cheesy Nach - App móvil Flutter

Proyecto final de aplicación móvil inspirado en las pantallas de referencia entregadas.

## Qué incluye

- Pantalla splash con identidad ROFLO.
- Login y registro.
- Inicio con banner, categorías y productos destacados.
- Menú de productos con diseño claro como las referencias.
- Detalle de producto con tamaños, extras y cantidad.
- Carrito y confirmación de pedido.
- Seguimiento de pedidos.
- Perfil de usuario.
- Panel de administración.
- CRUD de clientes: crear, consultar, actualizar y eliminar.
- CRUD básico de productos.
- Assets incluidos en `assets/images` y `assets/products`.

## Cómo abrirlo en Flutter

1. Instala Flutter y Android Studio.
2. Descomprime este ZIP.
3. Abre la carpeta `ROFLO_flutter_final` en VS Code o Android Studio.
4. Ejecuta:

```bash
flutter pub get
flutter run
```

## Si Flutter no reconoce Android/iOS

Si necesitas generar carpetas nativas, ejecuta dentro de la carpeta del proyecto:

```bash
flutter create .
flutter pub get
flutter run
```

## Generar APK

```bash
flutter build apk --release
```

El APK se genera normalmente en:

```bash
build/app/outputs/flutter-apk/app-release.apk
```

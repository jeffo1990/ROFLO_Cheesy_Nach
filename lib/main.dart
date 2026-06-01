import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RofloStore.loadData();
  runApp(const RofloApp());
}

class AppColors {
  static const black = Color(0xFF080706);
  static const dark = Color(0xFF101010);
  static const card = Color(0xFF171717);
  static const orange = Color(0xFFFF7A00);
  static const orangeDark = Color(0xFFC95100);
  static const gold = Color(0xFFFFB22E);
  static const cheese = Color(0xFFFFD55A);
  static const white = Color(0xFFFFFFFF);
  static const soft = Color(0xFFFFF8EA);
  static const grey = Color(0xFF777777);
  static const green = Color(0xFF21C26A);
  static const red = Color(0xFFFF5555);
}


int rofloToInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double rofloToDouble(dynamic value, {double fallback = 0}) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

bool rofloToBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  final text = value?.toString().toLowerCase().trim();
  if (text == 'true' || text == '1' || text == 'si' || text == 'sí') return true;
  if (text == 'false' || text == '0' || text == 'no') return false;
  return fallback;
}

String rofloToString(dynamic value, {String fallback = ''}) {
  final text = value?.toString();
  if (text == null) return fallback;
  return text;
}

DateTime rofloToDate(dynamic value, {DateTime? fallback}) {
  return DateTime.tryParse(value?.toString() ?? '') ?? fallback ?? DateTime.now();
}

class Product {
  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.image,
    required this.smallPrice,
    required this.mediumPrice,
    required this.largePrice,
    this.available = true,
  });

  final int id;
  String name;
  String description;
  String category;
  String image;
  double smallPrice;
  double mediumPrice;
  double largePrice;
  bool available;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category,
        'image': image,
        'smallPrice': smallPrice,
        'mediumPrice': mediumPrice,
        'largePrice': largePrice,
        'available': available,
      };

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: rofloToInt(json['id']),
      name: rofloToString(json['name'], fallback: 'Producto'),
      description: rofloToString(json['description'], fallback: 'Sin descripción'),
      category: rofloToString(json['category'], fallback: 'Nachos'),
      image: rofloToString(json['image'], fallback: 'assets/products/classic.jpg'),
      smallPrice: rofloToDouble(json['smallPrice']),
      mediumPrice: rofloToDouble(json['mediumPrice']),
      largePrice: rofloToDouble(json['largePrice']),
      available: rofloToBool(json['available'], fallback: true),
    );
  }
}

class CartItem {
  CartItem({
    required this.product,
    required this.size,
    required this.extras,
    required this.quantity,
    required this.unitPrice,
  });

  final Product product;
  final String size;
  final List<String> extras;
  int quantity;
  final double unitPrice;

  double get total => unitPrice * quantity;

  Map<String, dynamic> toJson() => {
        'product': product.toJson(),
        'size': size,
        'extras': extras,
        'quantity': quantity,
        'unitPrice': unitPrice,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final productData = json['product'];
    return CartItem(
      product: productData is Map
          ? Product.fromJson(Map<String, dynamic>.from(productData))
          : Product(
              id: 0,
              name: 'Producto guardado',
              description: 'Producto del pedido anterior',
              category: 'Nachos',
              image: 'assets/products/classic.jpg',
              smallPrice: rofloToDouble(json['unitPrice']),
              mediumPrice: rofloToDouble(json['unitPrice']),
              largePrice: rofloToDouble(json['unitPrice']),
            ),
      size: rofloToString(json['size'], fallback: 'Mediano'),
      extras: (json['extras'] is List) ? List<String>.from((json['extras'] as List).map((item) => item.toString())) : <String>[],
      quantity: rofloToInt(json['quantity'], fallback: 1),
      unitPrice: rofloToDouble(json['unitPrice']),
    );
  }
}

class RofloClient {
  RofloClient({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.note,
  });

  final int id;
  String name;
  String phone;
  String address;
  String note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'address': address,
        'note': note,
      };

  factory RofloClient.fromJson(Map<String, dynamic> json) {
    return RofloClient(
      id: rofloToInt(json['id']),
      name: rofloToString(json['name'], fallback: 'Cliente'),
      phone: rofloToString(json['phone']),
      address: rofloToString(json['address'], fallback: 'Sin dirección'),
      note: rofloToString(json['note']),
    );
  }
}

class RofloAccount {
  RofloAccount({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
  });

  String name;
  String email;
  String phone;
  String password;

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
      };

  factory RofloAccount.fromJson(Map<String, dynamic> json) {
    return RofloAccount(
      name: rofloToString(json['name'], fallback: 'Usuario'),
      email: rofloToString(json['email']).toLowerCase(),
      phone: rofloToString(json['phone']),
      password: rofloToString(json['password']),
    );
  }
}


class RofloAddress {
  RofloAddress({
    required this.id,
    required this.alias,
    required this.street,
    required this.reference,
    required this.phone,
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  final int id;
  String alias;
  String street;
  String reference;
  String phone;
  double? latitude;
  double? longitude;
  bool isDefault;

  bool get hasGps => latitude != null && longitude != null;

  String get fullAddress {
    final parts = [alias, street, reference].where((value) => value.trim().isNotEmpty).join(' · ');
    return parts.isEmpty ? 'Dirección sin detalle' : parts;
  }

  String get gpsText {
    if (!hasGps) return '';
    return 'GPS: ${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}';
  }

  String get deliveryText {
    final gps = gpsText;
    return gps.isEmpty ? fullAddress : '$fullAddress · $gps';
  }

  Uri? get mapsUri {
    if (!hasGps) return null;
    return Uri.parse('https://www.google.com/maps/search/?api=1&query=${latitude!.toStringAsFixed(6)},${longitude!.toStringAsFixed(6)}');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'alias': alias,
        'street': street,
        'reference': reference,
        'phone': phone,
        'latitude': latitude,
        'longitude': longitude,
        'isDefault': isDefault,
      };

  factory RofloAddress.fromJson(Map<String, dynamic> json) {
    return RofloAddress(
      id: rofloToInt(json['id']),
      alias: rofloToString(json['alias'], fallback: 'Dirección'),
      street: rofloToString(json['street']),
      reference: rofloToString(json['reference']),
      phone: rofloToString(json['phone']),
      latitude: json['latitude'] == null ? null : rofloToDouble(json['latitude']),
      longitude: json['longitude'] == null ? null : rofloToDouble(json['longitude']),
      isDefault: rofloToBool(json['isDefault']),
    );
  }
}

class RofloOrder {
  RofloOrder({
    required this.id,
    required this.clientName,
    required this.total,
    required this.status,
    required this.paymentMethod,
    required this.deliveryAddress,
    required this.createdAt,
    required this.items,
  });

  final int id;
  final String clientName;
  final double total;
  String status;
  String paymentMethod;
  final String deliveryAddress;
  final DateTime createdAt;
  final List<CartItem> items;

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientName': clientName,
        'total': total,
        'status': status,
        'paymentMethod': paymentMethod,
        'deliveryAddress': deliveryAddress,
        'createdAt': createdAt.toIso8601String(),
        'items': items.map((item) => item.toJson()).toList(),
      };

  factory RofloOrder.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return RofloOrder(
      id: rofloToInt(json['id']),
      clientName: rofloToString(json['clientName'], fallback: 'Cliente'),
      total: rofloToDouble(json['total']),
      status: rofloToString(json['status'], fallback: 'Recibido'),
      paymentMethod: rofloToString(json['paymentMethod'], fallback: 'Efectivo'),
      deliveryAddress: rofloToString(json['deliveryAddress'], fallback: 'Sin dirección registrada'),
      createdAt: rofloToDate(json['createdAt']),
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((item) => CartItem.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : <CartItem>[],
    );
  }
}

class RofloStore {
  static int nextClientId = 5;
  static int nextProductId = 21;
  static int nextOrderId = 1001;
  static int nextAddressId = 3;

  static final List<Product> products = [
    Product(
      id: 1,
      name: 'Roflo Cheese Classic',
      description: 'Nachos crujientes con queso fundido.',
      category: 'Nachos',
      image: 'assets/products/classic.jpg',
      smallPrice: 3.00,
      mediumPrice: 4.75,
      largePrice: 5.75,
    ),
    Product(
      id: 2,
      name: 'Roflo Meat Cheese',
      description: 'Queso + carne en salsa especial.',
      category: 'Nachos',
      image: 'assets/products/meat.jpg',
      smallPrice: 3.75,
      mediumPrice: 5.00,
      largePrice: 6.00,
    ),
    Product(
      id: 3,
      name: 'Roflo Explosion Mex',
      description: 'Queso, carne y jalapeño para valientes.',
      category: 'Especiales',
      image: 'assets/products/explosion.jpg',
      smallPrice: 3.75,
      mediumPrice: 5.50,
      largePrice: 6.50,
    ),
    Product(
      id: 4,
      name: 'Roflo Tropical Fire',
      description: 'Queso, piña y ají con contraste dulce picante.',
      category: 'Especiales',
      image: 'assets/products/tropical.jpg',
      smallPrice: 3.75,
      mediumPrice: 4.75,
      largePrice: 5.80,
    ),
    Product(
      id: 5,
      name: 'Roflo Chori Cheese',
      description: 'Queso fundido con chorizo ahumado.',
      category: 'Nachos',
      image: 'assets/products/chori.jpg',
      smallPrice: 3.80,
      mediumPrice: 5.75,
      largePrice: 6.75,
    ),
    Product(
      id: 6,
      name: 'Extra Queso Fundido',
      description: 'Porción extra de queso caliente para tu pedido.',
      category: 'Extras',
      image: 'assets/products/classic.jpg',
      smallPrice: 0.80,
      mediumPrice: 1.20,
      largePrice: 1.80,
    ),
    Product(
      id: 7,
      name: 'Salsa Jalapeño',
      description: 'Salsa picante especial ROFLO.',
      category: 'Extras',
      image: 'assets/products/explosion.jpg',
      smallPrice: 0.50,
      mediumPrice: 0.75,
      largePrice: 1.00,
    ),
    Product(
      id: 8,
      name: 'Bebida Gaseosa',
      description: 'Gaseosa fría para acompañar tus nachos.',
      category: 'Bebidas',
      image: 'assets/products/gaseosa.jpg',
      smallPrice: 1.00,
      mediumPrice: 1.50,
      largePrice: 2.00,
    ),
    Product(
      id: 9,
      name: 'Agua Personal',
      description: 'Agua fresca para tu combo.',
      category: 'Bebidas',
      image: 'assets/products/agua.jpg',
      smallPrice: 0.75,
      mediumPrice: 1.00,
      largePrice: 1.25,
    ),
    Product(
      id: 12,
      name: 'Cerveza',
      description: 'Cerveza fría para acompañar tus combos.',
      category: 'Bebidas',
      image: 'assets/products/cerveza.jpg',
      smallPrice: 2.00,
      mediumPrice: 2.50,
      largePrice: 3.00,
    ),
    Product(
      id: 10,
      name: 'Combo Pareja ROFLO',
      description: '2 nachos medianos + 2 bebidas.',
      category: 'Combos',
      image: 'assets/products/classic.jpg',
      smallPrice: 8.50,
      mediumPrice: 10.50,
      largePrice: 12.00,
    ),
    Product(
      id: 11,
      name: 'Combo Familiar',
      description: 'Nachos grandes, extras y bebidas para compartir.',
      category: 'Combos',
      image: 'assets/products/chori.jpg',
      smallPrice: 12.00,
      mediumPrice: 15.00,
      largePrice: 18.00,
    ),
  ];

  static final List<CartItem> cart = [];

  static final List<RofloAccount> accounts = [];
  static RofloAccount? currentAccount;

  static final List<RofloClient> clients = [
    RofloClient(id: 1, name: 'Juan Pérez', phone: '0999481846', address: 'Centro norte', note: 'Cliente frecuente'),
    RofloClient(id: 2, name: 'María Gómez', phone: '0987771122', address: 'La Kennedy', note: 'Sin jalapeños'),
    RofloClient(id: 3, name: 'Carlos López', phone: '0961112244', address: 'Las Acacias', note: 'Entrega rápida'),
    RofloClient(id: 4, name: 'Ana Serrano', phone: '0975558899', address: 'Vía principal', note: 'Prefiere combos'),
  ];

  static final List<RofloAddress> addresses = [
    RofloAddress(id: 1, alias: 'Casa', street: 'Centro norte', reference: 'Referencia: portón negro', phone: '0985985820', isDefault: true),
    RofloAddress(id: 2, alias: 'Trabajo', street: 'La Kennedy', reference: 'Frente al parque principal', phone: '0985985820'),
  ];

  static final List<RofloOrder> orders = [];

  static const String _productsKey = 'roflo_products';
  static const String _accountsKey = 'roflo_accounts';
  static const String _clientsKey = 'roflo_clients';
  static const String _addressesKey = 'roflo_addresses';
  static const String _ordersKey = 'roflo_orders';
  static const String _cartKey = 'roflo_cart';
  static const String _currentAccountKey = 'roflo_current_account_email';
  static const String _nextClientIdKey = 'roflo_next_client_id';
  static const String _nextProductIdKey = 'roflo_next_product_id';
  static const String _nextOrderIdKey = 'roflo_next_order_id';
  static const String _nextAddressIdKey = 'roflo_next_address_id';

  static List<dynamic>? _decodeList(SharedPreferences prefs, String key) {
    final raw = prefs.getString(key);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded;
    } catch (_) {}
    return null;
  }

  static int _nextIdFromList<T>(Iterable<T> values, int Function(T value) getId, int fallback) {
    if (values.isEmpty) return fallback;
    final maxId = values.map(getId).fold<int>(0, (previous, current) => previous > current ? previous : current);
    return fallback > maxId + 1 ? fallback : maxId + 1;
  }

  static Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final savedProducts = _decodeList(prefs, _productsKey);
    if (savedProducts != null) {
      products
        ..clear()
        ..addAll(
          savedProducts
              .whereType<Map>()
              .map((item) => Product.fromJson(Map<String, dynamic>.from(item)))
              .where((product) => product.name.trim().isNotEmpty),
        );
    }

    final savedAccounts = _decodeList(prefs, _accountsKey);
    if (savedAccounts != null) {
      accounts
        ..clear()
        ..addAll(
          savedAccounts
              .whereType<Map>()
              .map((item) => RofloAccount.fromJson(Map<String, dynamic>.from(item)))
              .where((account) => account.email.trim().isNotEmpty),
        );
    }

    final savedClients = _decodeList(prefs, _clientsKey);
    if (savedClients != null) {
      clients
        ..clear()
        ..addAll(savedClients.whereType<Map>().map((item) => RofloClient.fromJson(Map<String, dynamic>.from(item))));
    }

    final savedAddresses = _decodeList(prefs, _addressesKey);
    if (savedAddresses != null) {
      addresses
        ..clear()
        ..addAll(savedAddresses.whereType<Map>().map((item) => RofloAddress.fromJson(Map<String, dynamic>.from(item))));
    }

    final savedOrders = _decodeList(prefs, _ordersKey);
    if (savedOrders != null) {
      orders
        ..clear()
        ..addAll(savedOrders.whereType<Map>().map((item) => RofloOrder.fromJson(Map<String, dynamic>.from(item))));
    }

    final savedCart = _decodeList(prefs, _cartKey);
    if (savedCart != null) {
      cart
        ..clear()
        ..addAll(savedCart.whereType<Map>().map((item) => CartItem.fromJson(Map<String, dynamic>.from(item))));
    }

    final savedNextClientId = prefs.getInt(_nextClientIdKey) ?? nextClientId;
    final calculatedNextClientId = _nextIdFromList(clients, (client) => client.id, 5);
    nextClientId = savedNextClientId > calculatedNextClientId ? savedNextClientId : calculatedNextClientId;
    final savedNextProductId = prefs.getInt(_nextProductIdKey) ?? nextProductId;
    final calculatedNextProductId = _nextIdFromList(products, (product) => product.id, 21);
    nextProductId = savedNextProductId > calculatedNextProductId ? savedNextProductId : calculatedNextProductId;
    final savedNextOrderId = prefs.getInt(_nextOrderIdKey) ?? nextOrderId;
    final calculatedNextOrderId = _nextIdFromList(orders, (order) => order.id, 1001);
    nextOrderId = savedNextOrderId > calculatedNextOrderId ? savedNextOrderId : calculatedNextOrderId;
    final savedNextAddressId = prefs.getInt(_nextAddressIdKey) ?? nextAddressId;
    final calculatedNextAddressId = _nextIdFromList(addresses, (address) => address.id, 3);
    nextAddressId = savedNextAddressId > calculatedNextAddressId ? savedNextAddressId : calculatedNextAddressId;

    final currentEmail = prefs.getString(_currentAccountKey)?.toLowerCase().trim();
    if (currentEmail == 'admin@roflo.com') {
      currentAccount = RofloAccount(name: 'Administrador ROFLO', email: 'admin@roflo.com', phone: '', password: 'admin123');
    } else if (currentEmail != null && currentEmail.isNotEmpty) {
      for (final account in accounts) {
        if (account.email.toLowerCase().trim() == currentEmail) {
          currentAccount = account;
          break;
        }
      }
    }
  }

  static Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_productsKey, jsonEncode(products.map((product) => product.toJson()).toList()));
    await prefs.setString(_accountsKey, jsonEncode(accounts.map((account) => account.toJson()).toList()));
    await prefs.setString(_clientsKey, jsonEncode(clients.map((client) => client.toJson()).toList()));
    await prefs.setString(_addressesKey, jsonEncode(addresses.map((address) => address.toJson()).toList()));
    await prefs.setString(_ordersKey, jsonEncode(orders.map((order) => order.toJson()).toList()));
    await prefs.setString(_cartKey, jsonEncode(cart.map((item) => item.toJson()).toList()));

    await prefs.setInt(_nextClientIdKey, nextClientId);
    await prefs.setInt(_nextProductIdKey, nextProductId);
    await prefs.setInt(_nextOrderIdKey, nextOrderId);
    await prefs.setInt(_nextAddressIdKey, nextAddressId);

    final currentEmail = currentAccount?.email.toLowerCase().trim();
    if (currentEmail == null || currentEmail.isEmpty) {
      await prefs.remove(_currentAccountKey);
    } else {
      await prefs.setString(_currentAccountKey, currentEmail);
    }
  }
}

class RofloApp extends StatelessWidget {
  const RofloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Roflo Cheesy Nach',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.orange),
        scaffoldBackgroundColor: AppColors.black,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [Color(0xFF2D1600), AppColors.black],
                ),
              ),
            ),
          ),
          const Positioned(top: 0, left: 0, right: 0, child: CheeseDrip(height: 105)),
          Positioned.fill(
            child: Opacity(
              opacity: .06,
              child: Image.asset('assets/images/menu_poster.jpg', fit: BoxFit.cover),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(26),
              child: Column(
                children: [
                  const Spacer(),
                  Hero(
                    tag: 'logo',
                    child: FloatingLogo(size: 270, glow: true),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '100% QUESO\n100% ROFLO',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 28,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .8,
                    ),
                  ),
                  const SizedBox(height: 40),
                  RofloButton(
                    label: 'COMENZAR',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () {
                      final account = RofloStore.currentAccount;
                      if (account != null) {
                        final isAdmin = account.email.toLowerCase().trim() == 'admin@roflo.com';
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => RofloHome(initialIndex: isAdmin ? 4 : 0, isAdmin: isAdmin)),
                        );
                        return;
                      }
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                  ),
                  const Spacer(),
                  const Text(
                    'Aquí mandas tú, nosotros le ponemos el queso',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  void signIn() {
    final correo = email.text.trim().toLowerCase();
    final clave = password.text.trim();

    if (correo.isEmpty || clave.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa tu correo y contraseña para continuar.')),
      );
      return;
    }

    final isAdmin = correo == 'admin@roflo.com' && clave == 'admin123';
    if (isAdmin) {
      RofloStore.currentAccount = RofloAccount(
        name: 'Administrador ROFLO',
        email: correo,
        phone: '',
        password: clave,
      );
      RofloStore.saveData();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const RofloHome(
            initialIndex: 4,
            isAdmin: true,
          ),
        ),
      );
      return;
    }

    RofloAccount? authenticatedAccount;
    for (final account in RofloStore.accounts) {
      if (account.email.toLowerCase() == correo && account.password == clave) {
        authenticatedAccount = account;
        break;
      }
    }

    if (authenticatedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta no encontrada. Primero crea una cuenta para ingresar.')),
      );
      return;
    }

    RofloStore.currentAccount = authenticatedAccount;
    RofloStore.saveData();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RofloHome()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: '¡Bienvenido de nuevo!',
      subtitle: 'Inicia sesión para ordenar tus nachos favoritos.',
      showPromo: true,
      child: Column(
        children: [
          RofloTextField(controller: email, label: 'Correo electrónico', icon: Icons.email_outlined),
          const SizedBox(height: 12),
          RofloTextField(controller: password, label: 'Contraseña', icon: Icons.lock_outline, obscure: true),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: const [
                    Icon(Icons.check_circle_outline, size: 17, color: AppColors.orange),
                    SizedBox(width: 6),
                    Text('Recordarme', style: TextStyle(color: AppColors.grey, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Recuperación demo: contacta a soporte ROFLO.')),
                ),
                child: const Text('Olvidé mi contraseña', style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RofloButton(
            label: 'INICIAR SESIÓN',
            onPressed: signIn,
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.orange.withOpacity(.20)),
            ),
            child: const Text(
              'Para ingresar debes tener una cuenta registrada en la aplicación.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
            child: const Text('¿No tienes cuenta? Crear cuenta', style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    phone.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Crear cuenta',
      subtitle: 'Regístrate y empieza a pedir tus Roflo favoritos.',
      child: Column(
        children: [
          RofloTextField(controller: name, label: 'Nombre completo', icon: Icons.person_outline),
          const SizedBox(height: 10),
          RofloTextField(controller: email, label: 'Correo electrónico', icon: Icons.email_outlined),
          const SizedBox(height: 10),
          RofloTextField(controller: phone, label: 'Teléfono', icon: Icons.phone_outlined),
          const SizedBox(height: 10),
          RofloTextField(controller: password, label: 'Contraseña', icon: Icons.lock_outline, obscure: true),
          const SizedBox(height: 10),
          RofloTextField(controller: confirm, label: 'Confirmar contraseña', icon: Icons.verified_user_outlined, obscure: true),
          const SizedBox(height: 18),
          RofloButton(
            label: 'REGISTRARSE',
            onPressed: () {
              final nombre = name.text.trim();
              final correo = email.text.trim();
              final telefono = phone.text.trim();
              final clave = password.text.trim();
              final repetirClave = confirm.text.trim();

              if (nombre.isEmpty || correo.isEmpty || telefono.isEmpty || clave.isEmpty || repetirClave.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Completa todos los campos para registrar el cliente.')),
                );
                return;
              }

              if (clave != repetirClave) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Las contraseñas no coinciden.')),
                );
                return;
              }

              final correoNormalizado = correo.toLowerCase();
              final existeCuenta = RofloStore.accounts.any(
                (account) => account.email.toLowerCase() == correoNormalizado || account.phone.trim() == telefono,
              );

              if (existeCuenta) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ya existe una cuenta registrada con ese correo o teléfono.')),
                );
                return;
              }

              final newAccount = RofloAccount(
                name: nombre,
                email: correoNormalizado,
                phone: telefono,
                password: clave,
              );

              RofloStore.accounts.insert(0, newAccount);
              RofloStore.currentAccount = newAccount;

              RofloStore.clients.insert(
                0,
                RofloClient(
                  id: RofloStore.nextClientId++,
                  name: nombre,
                  phone: telefono,
                  address: 'Dirección pendiente',
                  note: 'Correo: $correoNormalizado · Cliente registrado desde la app',
                ),
              );
              RofloStore.saveData();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cuenta creada correctamente. Ya puedes ingresar.')),
              );

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const RofloHome()),
              );
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ya tengo cuenta', style: TextStyle(color: AppColors.orange)),
          ),
        ],
      ),
    );
  }
}

class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showPromo = false,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool showPromo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.soft,
      body: Stack(
        children: [
          const Positioned.fill(child: PremiumAuthBackground()),
          const Positioned(top: 0, left: 0, right: 0, child: CheeseDrip(height: 108)),
          Positioned(
            bottom: -46,
            right: -44,
            child: Opacity(
              opacity: .12,
              child: SlowZoomAsset(
                asset: 'assets/images/logo.png',
                width: 260,
                height: 260,
                radius: 40,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Hero(tag: 'logo', child: FloatingLogo(size: 118)),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.dark),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.grey, height: 1.35),
                  ),
                  if (showPromo) ...[
                    const SizedBox(height: 14),
                    const PremiumNachoBanner(),
                  ],
                  const SizedBox(height: 18),
                  child,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RofloHome extends StatefulWidget {
  const RofloHome({super.key, this.initialIndex = 0, this.isAdmin = false});

  final int initialIndex;
  final bool isAdmin;

  @override
  State<RofloHome> createState() => _RofloHomeState();
}

class _RofloHomeState extends State<RofloHome> {
  late int selectedIndex;
  String selectedCategory = 'Nachos';
  final List<Product> products = RofloStore.products;
  final List<CartItem> cart = RofloStore.cart;
  final List<RofloClient> clients = RofloStore.clients;
  final List<RofloOrder> orders = RofloStore.orders;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;
  }

  double get cartTotal => cart.fold(0, (sum, item) => sum + item.total);

  void addToCart(Product product, String size, List<String> extras, int quantity, double unitPrice) {
    setState(() {
      final index = cart.indexWhere((item) =>
          item.product.id == product.id &&
          item.size == size &&
          item.extras.join(',') == extras.join(','));
      if (index >= 0) {
        cart[index].quantity += quantity;
      } else {
        cart.add(CartItem(
          product: product,
          size: size,
          extras: extras,
          quantity: quantity,
          unitPrice: unitPrice,
        ));
      }
    });
    RofloStore.saveData();
  }

  void removeCartItem(CartItem item) {
    setState(() => cart.remove(item));
    RofloStore.saveData();
  }

  void clearCart() {
    setState(() => cart.clear());
    RofloStore.saveData();
  }

  void createOrder(String clientName, String paymentMethod, String deliveryAddress) {
    if (cart.isEmpty) return;
    setState(() {
      orders.insert(
        0,
        RofloOrder(
          id: RofloStore.nextOrderId++,
          clientName: clientName.isEmpty ? 'Cliente general' : clientName,
          total: cartTotal + 1.50,
          status: 'Recibido',
          paymentMethod: paymentMethod,
          deliveryAddress: deliveryAddress.trim().isEmpty ? 'Sin dirección registrada' : deliveryAddress,
          createdAt: DateTime.now(),
          items: List<CartItem>.from(cart),
        ),
      );
      cart.clear();
      selectedIndex = 2;
    });
    RofloStore.saveData();
  }

  void addClient(RofloClient client) {
    setState(() {
      clients.add(RofloClient(
        id: RofloStore.nextClientId++,
        name: client.name,
        phone: client.phone,
        address: client.address,
        note: client.note,
      ));
    });
    RofloStore.saveData();
  }

  void updateClient(RofloClient client) {
    setState(() {});
    RofloStore.saveData();
  }

  void deleteClient(RofloClient client) {
    setState(() => clients.remove(client));
    RofloStore.saveData();
  }

  void addProduct(Product product) {
    setState(() {
      products.add(Product(
        id: RofloStore.nextProductId++,
        name: product.name,
        description: product.description,
        category: product.category,
        image: product.image,
        smallPrice: product.smallPrice,
        mediumPrice: product.mediumPrice,
        largePrice: product.largePrice,
        available: product.available,
      ));
    });
    RofloStore.saveData();
  }

  void updateProduct(Product product) {
    setState(() {});
    RofloStore.saveData();
  }

  void deleteProduct(Product product) {
    setState(() => products.remove(product));
    RofloStore.saveData();
  }

  void updateOrderStatus(RofloOrder order, String status) {
    setState(() => order.status = status);
    RofloStore.saveData();
  }

  void selectCategory(String category) {
    setState(() {
      selectedCategory = category;
      selectedIndex = 1;
    });
  }

  void openCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CartScreen(
          cart: cart,
          onRemove: removeCartItem,
          onClear: clearCart,
          onCreateOrder: createOrder,
          onChanged: () {
            setState(() {});
            RofloStore.saveData();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        products: products,
        cartCount: cart.length,
        onProductTap: openProduct,
        onCartTap: openCart,
        onCategoryTap: selectCategory,
      ),
      MenuScreen(
        products: products,
        selectedCategory: selectedCategory,
        cartCount: cart.length,
        onProductTap: openProduct,
        onCartTap: openCart,
        onCategorySelected: (category) => setState(() => selectedCategory = category),
      ),
      widget.isAdmin
          ? AdminOrdersScreen(
              orders: orders,
              onStatusChanged: updateOrderStatus,
              showBack: false,
            )
          : OrdersScreen(orders: orders, cartCount: cart.length, onCartTap: openCart),
      ProfileScreen(
        onLogout: () {
          RofloStore.currentAccount = null;
          RofloStore.saveData();
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
        },
      ),
      if (widget.isAdmin)
        AdminScreen(
          products: products,
          clients: clients,
          orders: orders,
          onOpenProducts: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductCrudScreen(
                products: products,
                onCreate: addProduct,
                onUpdate: updateProduct,
                onDelete: deleteProduct,
              ),
            ),
          ),
          onOpenClients: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClientCrudScreen(
                clients: clients,
                onCreate: addClient,
                onUpdate: updateClient,
                onDelete: deleteClient,
              ),
            ),
          ),
          onOpenOrders: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminOrdersScreen(
                orders: orders,
                onStatusChanged: updateOrderStatus,
              ),
            ),
          ),
        ),
    ];

    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.dark,
          border: Border(top: BorderSide(color: Color(0xFF262626))),
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (index) => setState(() => selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.dark,
          selectedItemColor: AppColors.orange,
          unselectedItemColor: Colors.white60,
          showUnselectedLabels: true,
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Inicio'),
            const BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu_outlined), activeIcon: Icon(Icons.restaurant_menu), label: 'Menú'),
            const BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), activeIcon: Icon(Icons.shopping_bag), label: 'Pedidos'),
            const BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Perfil'),
            if (widget.isAdmin)
              const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings_outlined), activeIcon: Icon(Icons.admin_panel_settings), label: 'Admin'),
          ],
        ),
      ),
    );
  }

  void openProduct(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          product: product,
          onAdd: addToCart,
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.products,
    required this.onProductTap,
    required this.cartCount,
    required this.onCartTap,
    required this.onCategoryTap,
  });

  final List<Product> products;
  final ValueChanged<Product> onProductTap;
  final int cartCount;
  final VoidCallback onCartTap;
  final ValueChanged<String> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return DarkPage(
      title: 'Hola, Usuario 👋',
      subtitle: '¿Qué se te antoja hoy?',
      cartCount: cartCount,
      onCartTap: onCartTap,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        children: [
          const PremiumHomeHero(),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: StaggeredEntry(index: 0, child: CategoryCard(icon: Icons.local_pizza_outlined, label: 'Nachos', onTap: () => onCategoryTap('Nachos')))),
              const SizedBox(width: 10),
              Expanded(child: StaggeredEntry(index: 1, child: CategoryCard(icon: Icons.add_circle_outline, label: 'Extras', onTap: () => onCategoryTap('Extras')))),
              const SizedBox(width: 10),
              Expanded(child: StaggeredEntry(index: 2, child: CategoryCard(icon: Icons.local_drink_outlined, label: 'Bebidas', onTap: () => onCategoryTap('Bebidas')))),
              const SizedBox(width: 10),
              Expanded(child: StaggeredEntry(index: 3, child: CategoryCard(icon: Icons.card_giftcard_outlined, label: 'Combos', onTap: () => onCategoryTap('Combos')))),
            ],
          ),
          const SizedBox(height: 22),
          const SectionTitle(title: 'Popular ahora'),
          const SizedBox(height: 12),
          ...List.generate(math.min(3, products.length), (index) => StaggeredEntry(index: index, child: DarkProductTile(product: products[index], onTap: () => onProductTap(products[index])))),
          const SizedBox(height: 10),
          const SectionTitle(title: 'Más pedidos'),
          const SizedBox(height: 12),
          SizedBox(
            height: 190,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, index) => StaggeredEntry(index: index, child: ProductMiniCard(product: products[index], onTap: () => onProductTap(products[index]))),
            ),
          ),
        ],
      ),
    );
  }
}

class MenuScreen extends StatelessWidget {
  const MenuScreen({
    super.key,
    required this.products,
    required this.selectedCategory,
    required this.onProductTap,
    required this.cartCount,
    required this.onCartTap,
    required this.onCategorySelected,
  });

  final List<Product> products;
  final String selectedCategory;
  final ValueChanged<Product> onProductTap;
  final int cartCount;
  final VoidCallback onCartTap;
  final ValueChanged<String> onCategorySelected;

  List<Product> get filteredProducts => products.where((product) => product.category == selectedCategory && product.available).toList();

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'label': 'Nachos', 'icon': Icons.local_pizza},
      {'label': 'Extras', 'icon': Icons.food_bank_outlined},
      {'label': 'Bebidas', 'icon': Icons.local_drink_outlined},
      {'label': 'Combos', 'icon': Icons.card_giftcard_outlined},
    ];

    return LightMenuPage(
      cartCount: cartCount,
      onCartTap: onCartTap,
      onMenuTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: categories.map((category) {
              final label = category['label'] as String;
              return ListTile(
                leading: Icon(category['icon'] as IconData, color: AppColors.orange),
                title: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
                trailing: selectedCategory == label ? const Icon(Icons.check_circle, color: AppColors.orange) : null,
                onTap: () {
                  onCategorySelected(label);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 90),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: categories.asMap().entries.map((entry) {
              final category = entry.value;
              final label = category['label'] as String;
              return Expanded(
                child: StaggeredEntry(
                  index: entry.key,
                  child: MenuCategory(
                    icon: category['icon'] as IconData,
                    label: label,
                    selected: selectedCategory == label,
                    onTap: () => onCategorySelected(label),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, .035), end: Offset.zero).animate(animation),
                child: child,
              ),
            ),
            child: Column(
              key: ValueKey(selectedCategory),
              children: [
                if (filteredProducts.isEmpty)
                  const EmptyState(icon: Icons.fastfood_outlined, title: 'Sin productos', text: 'Esta categoría todavía no tiene productos disponibles.'),
                ...List.generate(filteredProducts.length, (index) {
                  final product = filteredProducts[index];
                  return StaggeredEntry(index: index, child: LightProductTile(product: product, onTap: () => onProductTap(product)));
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product, required this.onAdd});

  final Product product;
  final void Function(Product product, String size, List<String> extras, int quantity, double unitPrice) onAdd;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String size = 'Mediano';
  int quantity = 1;
  final Set<String> extras = {};

  final Map<String, double> extraPrices = {
    'Extra queso': 0.80,
    'Carne': 1.00,
    'Jalapeño': 0.50,
    'Chorizo': 1.20,
    'Piña': 0.80,
  };

  double get basePrice {
    if (size == 'Pequeño') return widget.product.smallPrice;
    if (size == 'Grande') return widget.product.largePrice;
    return widget.product.mediumPrice;
  }

  double get unitPrice => basePrice + extras.fold<double>(0, (sum, item) => sum + (extraPrices[item] ?? 0));
  double get total => unitPrice * quantity;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SlowZoomAsset(asset: widget.product.image, width: double.infinity, height: 390, radius: 0),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xDD000000), AppColors.black],
                  stops: [.18, .42, .62],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CircleIconButton(icon: Icons.arrow_back, onTap: () => Navigator.pop(context)),
                      CircleIconButton(icon: Icons.favorite_border, onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${widget.product.name} agregado a favoritos')),
                        );
                      }),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
                  decoration: const BoxDecoration(
                    color: AppColors.black,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.product.name, style: const TextStyle(color: AppColors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      Text(widget.product.description, style: const TextStyle(color: Colors.white70, fontSize: 15)),
                      const SizedBox(height: 18),
                      const Text('Presentación', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        children: ['Pequeño', 'Mediano', 'Grande'].map((option) {
                          final selected = option == size;
                          return ChoiceChip(
                            label: Text(option),
                            selected: selected,
                            labelStyle: TextStyle(color: selected ? AppColors.black : AppColors.white),
                            selectedColor: AppColors.orange,
                            backgroundColor: AppColors.card,
                            onSelected: (_) => setState(() => size = option),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      const Text('Tú decides los extras', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: extraPrices.keys.map((extra) {
                          final selected = extras.contains(extra);
                          return FilterChip(
                            label: Text('$extra +\$${extraPrices[extra]!.toStringAsFixed(2)}'),
                            selected: selected,
                            selectedColor: AppColors.gold,
                            backgroundColor: AppColors.card,
                            labelStyle: TextStyle(color: selected ? AppColors.black : Colors.white70),
                            checkmarkColor: AppColors.black,
                            onSelected: (_) {
                              setState(() {
                                selected ? extras.remove(extra) : extras.add(extra);
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          QuantityButton(icon: Icons.remove, onTap: () => setState(() => quantity = math.max(1, quantity - 1))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Text('$quantity', style: const TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                          ),
                          QuantityButton(icon: Icons.add, onTap: () => setState(() => quantity++)),
                          const Spacer(),
                          Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.orange, fontSize: 28, fontWeight: FontWeight.w900)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      RofloButton(
                        label: 'AÑADIR AL PEDIDO',
                        icon: Icons.shopping_cart_outlined,
                        onPressed: () {
                          widget.onAdd(widget.product, size, extras.toList(), quantity, unitPrice);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Producto agregado al pedido')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const List<String> rofloBanks = [
  'Banco Pichincha',
  'Banco Guayaquil',
  'Banco del Pacífico',
  'Produbanco',
  'Banco Bolivariano',
  'Banco Internacional',
  'Banco del Austro',
  'Banco Solidario',
  'Banco Machala',
  'Banco Loja',
  'Banco General Rumiñahui',
  'Cooperativa JEP',
  'Cooperativa Jardín Azuayo',
  'Cooperativa Policía Nacional',
  'Banco Diners Club',
];

const List<String> rofloCardTypes = [
  'Visa',
  'Mastercard',
  'American Express',
  'Diners Club',
  'Discover',
];


// === CONFIGURACIÓN DE COBRO REAL / TRANSFERENCIA ===
// Aquí puedes colocar los datos de la cuenta bancaria del negocio para que el
// cliente haga una transferencia real. Para una prueba puedes dejar estos datos
// de ejemplo, pero antes de entregar la app cambia los valores por los reales.
// NO coloques claves, usuarios de banca web ni datos privados de tarjeta.
const String rofloBusinessBankName = 'Banco Pichincha';
const String rofloBusinessAccountType = 'Cuenta corriente';
const String rofloBusinessAccountNumber = '0000000000';
const String rofloBusinessAccountHolder = 'ROFLO CHEESY NACH';
const String rofloBusinessDocument = '0000000000'; // Cédula/RUC si deseas mostrarlo
const String rofloBusinessPaymentEmail = 'jeffoloquito@gmail.com';
const String rofloWhatsappPaymentNumber = '593985985820';

// Para pago real con tarjeta, crea un link de cobro en PayPhone, Mercado Pago
// o Stripe y pega la URL aquí. Si queda vacío, la app abre WhatsApp para coordinar.
const String rofloPayPhonePaymentLink = ''; // Ejemplo: https://payphone.app/pay/xxxxx
const String rofloMercadoPagoPaymentLink = ''; // Ejemplo: https://mpago.la/xxxxx
const String rofloStripePaymentLink = ''; // Ejemplo: https://buy.stripe.com/xxxxx

String rofloConfiguredPaymentLink() {
  if (rofloPayPhonePaymentLink.trim().isNotEmpty) return rofloPayPhonePaymentLink.trim();
  if (rofloMercadoPagoPaymentLink.trim().isNotEmpty) return rofloMercadoPagoPaymentLink.trim();
  if (rofloStripePaymentLink.trim().isNotEmpty) return rofloStripePaymentLink.trim();
  return '';
}

String rofloBuildWhatsappPaymentUrl({
  required String orderCode,
  required String clientName,
  required double total,
  required String deliveryAddress,
}) {
  final message = Uri.encodeComponent(
    'Hola ROFLO, quiero realizar el pago real de mi pedido.\n'
    'Pedido: $orderCode\n'
    'Cliente: $clientName\n'
    'Total: \$${total.toStringAsFixed(2)}\n'
    'Dirección: $deliveryAddress\n\n'
    'Por favor envíame o confirma el link de pago.',
  );
  return 'https://wa.me/$rofloWhatsappPaymentNumber?text=$message';
}

Future<void> rofloOpenOnlinePayment(
  BuildContext context, {
  required String orderCode,
  required String clientName,
  required double total,
  required String deliveryAddress,
}) async {
  final configured = rofloConfiguredPaymentLink();
  final url = configured.isNotEmpty
      ? configured
      : rofloBuildWhatsappPaymentUrl(
          orderCode: orderCode,
          clientName: clientName,
          total: total,
          deliveryAddress: deliveryAddress,
        );
  final uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace de pago.')),
      );
    }
  }
}

String rofloDigitsOnly(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

bool rofloValidLuhn(String digits) {
  if (digits.length < 13 || digits.length > 19) return false;
  var sum = 0;
  var alternate = false;
  for (var i = digits.length - 1; i >= 0; i--) {
    var n = int.parse(digits[i]);
    if (alternate) {
      n *= 2;
      if (n > 9) n -= 9;
    }
    sum += n;
    alternate = !alternate;
  }
  return sum % 10 == 0;
}

bool rofloValidExpiry(String value) {
  final cleaned = value.trim().replaceAll(' ', '');
  final match = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(cleaned);
  if (match == null) return false;
  final month = int.tryParse(match.group(1) ?? '') ?? 0;
  final year = int.tryParse(match.group(2) ?? '') ?? -1;
  if (month < 1 || month > 12) return false;
  final now = DateTime.now();
  final fullYear = 2000 + year;
  final lastDay = DateTime(fullYear, month + 1, 0, 23, 59, 59);
  return lastDay.isAfter(now);
}

String rofloDetectedCardType(String digits) {
  if (digits.startsWith('4')) return 'Visa';
  if (RegExp(r'^(5[1-5]|2[2-7])').hasMatch(digits)) return 'Mastercard';
  if (RegExp(r'^3[47]').hasMatch(digits)) return 'American Express';
  if (RegExp(r'^(30[0-5]|36|38)').hasMatch(digits)) return 'Diners Club';
  if (digits.startsWith('6')) return 'Discover';
  return 'Tarjeta';
}

String rofloAuthorizationCode() {
  final raw = DateTime.now().millisecondsSinceEpoch.toString();
  return 'ROF-${raw.substring(raw.length - 7)}';
}

class CartScreen extends StatefulWidget {
  const CartScreen({
    super.key,
    required this.cart,
    required this.onRemove,
    required this.onClear,
    required this.onCreateOrder,
    required this.onChanged,
  });

  final List<CartItem> cart;
  final ValueChanged<CartItem> onRemove;
  final VoidCallback onClear;
  final void Function(String clientName, String paymentMethod, String deliveryAddress) onCreateOrder;
  final VoidCallback onChanged;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final client = TextEditingController(text: 'Usuario');
  final cashAmount = TextEditingController();
  final transferBank = TextEditingController();
  final transferReference = TextEditingController();
  final transferName = TextEditingController();
  final cardHolder = TextEditingController();
  final cardType = TextEditingController(text: 'Visa');
  final cardNumber = TextEditingController();
  final cardExpiry = TextEditingController();
  final cardCvv = TextEditingController();
  final couponCode = TextEditingController();
  String paymentMethod = 'Efectivo';
  bool onlinePaymentStarted = false;
  String selectedAddress = RofloStore.addresses.isNotEmpty ? RofloStore.addresses.first.deliveryText : '';

  double get total => widget.cart.fold(0, (sum, item) => sum + item.total);
  double get couponDiscount {
    final code = couponCode.text.trim().toUpperCase();
    if (code == 'ROFLO10') return total * 0.10;
    if (code == 'QUESO5') return 0.50;
    return 0;
  }

  String get appliedCouponLabel {
    final code = couponCode.text.trim().toUpperCase();
    if (code == 'ROFLO10') return 'Cupón ROFLO10 aplicado: 10% de descuento';
    if (code == 'QUESO5') return 'Cupón QUESO5 aplicado: \$0.50 de descuento';
    if (couponCode.text.trim().isNotEmpty) return 'Cupón no válido';
    return '';
  }

  double get grandTotal => (total - couponDiscount + 1.50).clamp(0, double.infinity);
  double get cashReceived => double.tryParse(cashAmount.text.replaceAll(',', '.')) ?? 0;
  double get cashChange => cashReceived - grandTotal;

  String buildPaymentDescription() {
    if (paymentMethod == 'Efectivo') {
      if (cashAmount.text.trim().isEmpty) return 'Efectivo';
      final change = cashChange >= 0 ? ' · Cambio: \$${cashChange.toStringAsFixed(2)}' : '';
      return 'Efectivo · Recibe con: \$${cashReceived.toStringAsFixed(2)}$change';
    }
    if (paymentMethod == 'Transferencia') {
      return 'Transferencia a $rofloBusinessBankName · Desde: ${transferBank.text.trim()} · Ref: ${transferReference.text.trim()}';
    }
    final provider = rofloConfiguredPaymentLink().isNotEmpty ? 'Link de pago externo' : 'WhatsApp pago manual';
    return 'Tarjeta / Pago online · $provider · Ref: ${rofloAuthorizationCode()}';
  }

  String? validateCardPayment() {
    final type = cardType.text.trim();
    final holder = cardHolder.text.trim();
    final digits = rofloDigitsOnly(cardNumber.text);
    final expiry = cardExpiry.text.trim();
    final cvv = rofloDigitsOnly(cardCvv.text);
    if (type.isEmpty) return 'Selecciona el tipo de tarjeta.';
    if (holder.length < 3) return 'Ingresa el nombre del titular de la tarjeta.';
    if (!rofloValidLuhn(digits)) return 'El número de tarjeta no es válido. Revisa los dígitos.';
    if (!rofloValidExpiry(expiry)) return 'La fecha de vencimiento debe tener formato MM/AA y no estar vencida.';
    final requiredCvvLength = type == 'American Express' ? 4 : 3;
    if (cvv.length != requiredCvvLength) return 'El CVV debe tener $requiredCvvLength dígitos para $type.';
    return null;
  }

  @override
  void dispose() {
    client.dispose();
    cashAmount.dispose();
    transferBank.dispose();
    transferReference.dispose();
    transferName.dispose();
    cardHolder.dispose();
    cardType.dispose();
    cardNumber.dispose();
    cardExpiry.dispose();
    cardCvv.dispose();
    couponCode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DarkPage(
      title: 'Pedido',
      subtitle: '${widget.cart.length} productos en carrito',
      showBack: true,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
        children: [
          if (widget.cart.isEmpty)
            const EmptyState(icon: Icons.shopping_cart_outlined, title: 'Tu pedido está vacío', text: 'Agrega productos del menú para confirmar tu orden.'),
          ...widget.cart.map((item) => CartTile(
                item: item,
                onChanged: () {
                  setState(() {});
                  widget.onChanged();
                },
                onRemove: () {
                  widget.onRemove(item);
                  setState(() {});
                },
              )),
          const SizedBox(height: 18),
          if (widget.cart.isNotEmpty) ...[
            RofloTextField(controller: client, label: 'Nombre del cliente', icon: Icons.person_outline, dark: true),
            const SizedBox(height: 16),
            const SectionTitle(title: 'Dirección de entrega'),
            const SizedBox(height: 10),
            AddressSelector(
              selectedAddress: selectedAddress,
              onChanged: (value) => setState(() => selectedAddress = value ?? ''),
              onManage: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressBookScreen()));
                setState(() {
                  if (RofloStore.addresses.isNotEmpty && !RofloStore.addresses.any((address) => address.deliveryText == selectedAddress)) {
                    selectedAddress = RofloStore.addresses.first.deliveryText;
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            const SectionTitle(title: 'Cupón de descuento'),
            const SizedBox(height: 10),
            RofloTextField(
              controller: couponCode,
              label: 'Código promocional. Ej: ROFLO10',
              icon: Icons.local_offer_outlined,
              dark: true,
              onChanged: (_) => setState(() {}),
            ),
            if (appliedCouponLabel.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                appliedCouponLabel,
                style: TextStyle(
                  color: couponDiscount > 0 ? AppColors.green : AppColors.red,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 16),
            const SectionTitle(title: 'Forma de pago'),
            const SizedBox(height: 10),
            PaymentSelector(
              selected: paymentMethod,
              onChanged: (value) => setState(() {
                paymentMethod = value;
                if (value != 'Tarjeta') onlinePaymentStarted = false;
              }),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SizeTransition(
                  sizeFactor: animation,
                  axisAlignment: -1,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, .04), end: Offset.zero).animate(animation),
                    child: child,
                  ),
                ),
              ),
              child: PaymentFormPanel(
                key: ValueKey(paymentMethod),
                method: paymentMethod,
                cashAmount: cashAmount,
                transferBank: transferBank,
                transferReference: transferReference,
                transferName: transferName,
                cardHolder: cardHolder,
                cardType: cardType,
                cardNumber: cardNumber,
                cardExpiry: cardExpiry,
                cardCvv: cardCvv,
                total: grandTotal,
                onlinePaymentStarted: onlinePaymentStarted,
                onOpenOnlinePayment: () async {
                  setState(() => onlinePaymentStarted = true);
                  await rofloOpenOnlinePayment(
                    context,
                    orderCode: 'ROF-${RofloStore.nextOrderId}',
                    clientName: client.text.trim().isEmpty ? 'Usuario' : client.text.trim(),
                    total: grandTotal,
                    deliveryAddress: selectedAddress,
                  );
                },
                onChanged: () => setState(() {}),
              ),
            ),
            const SizedBox(height: 16),
            PriceRow(label: 'Subtotal', value: total),
            if (couponDiscount > 0) PriceRow(label: 'Descuento', value: -couponDiscount),
            const PriceRow(label: 'Delivery', value: 1.50),
            const Divider(color: Color(0xFF333333), height: 28),
            PriceRow(label: 'Total', value: grandTotal, big: true),
            const SizedBox(height: 18),
            RofloButton(
              label: 'CONFIRMAR PEDIDO',
              icon: Icons.check_circle_outline,
              onPressed: () {
                final messenger = ScaffoldMessenger.of(context);
                if (selectedAddress.trim().isEmpty) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Agrega o selecciona una dirección de entrega.')),
                  );
                  return;
                }
                if (paymentMethod == 'Efectivo' && cashAmount.text.trim().isNotEmpty && cashReceived < grandTotal) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('El monto recibido no alcanza para cubrir el total.')),
                  );
                  return;
                }
                if (paymentMethod == 'Transferencia' &&
                    (transferBank.text.trim().isEmpty || transferReference.text.trim().isEmpty || transferName.text.trim().isEmpty)) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Completa banco, referencia y nombre del comprobante.')),
                  );
                  return;
                }
                if (paymentMethod == 'Tarjeta' && !onlinePaymentStarted) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Primero presiona PAGAR AHORA para abrir el link de pago real.')),
                  );
                  return;
                }
                final paymentDetail = buildPaymentDescription();
                widget.onCreateOrder(client.text.trim(), paymentDetail, selectedAddress);
                widget.onChanged();
                final createdOrder = RofloStore.orders.isNotEmpty ? RofloStore.orders.first : null;
                Navigator.pop(context);
                if (createdOrder != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => OrderSuccessScreen(order: createdOrder)),
                  );
                }
                messenger.showSnackBar(
                  SnackBar(content: Text('Pedido confirmado con pago: $paymentMethod.')),
                );
              },
            ),
            TextButton(
              onPressed: () {
                widget.onClear();
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Carrito vacío')),
                );
              },
              child: const Text('Vaciar carrito', style: TextStyle(color: AppColors.red)),
            ),
          ],
        ],
      ),
    );
  }
}


class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key, required this.order});

  final RofloOrder order;

  String get receiptText {
    final products = order.items
        .map((item) => '• ${item.quantity}x ${item.product.name} (${item.size})')
        .join('\n');

    return '🧀 COMPROBANTE ROFLO CHEESY NACH\n'
        'Pedido #${order.id}\n\n'
        '✅ Recibimos tu pedido\n\n'
        '👤 Cliente: ${order.clientName}\n'
        '💰 Total: \$${order.total.toStringAsFixed(2)}\n'
        '💳 Pago: ${order.paymentMethod}\n'
        '📍 Dirección: ${order.deliveryAddress}\n\n'
        '🛒 Productos:\n$products\n\n'
        'Estado inicial: Recibido\n'
        'Gracias por ordenar en ROFLO.';
  }

  Future<void> sendReceipt(BuildContext context) async {
    final encodedMessage = Uri.encodeComponent(receiptText);

    // Abre WhatsApp con el comprobante completo.
    // Si quieres que se envíe directo al negocio, cambia wa.me/?text por:
    // https://wa.me/$rofloWhatsappPaymentNumber?text=$encodedMessage
    final uri = Uri.parse('https://wa.me/?text=$encodedMessage');

    await openExternalUri(context, uri, 'WhatsApp');
  }

  @override
  Widget build(BuildContext context) {
    return DarkPage(
      title: 'Pedido confirmado',
      subtitle: 'Tu orden fue registrada correctamente',
      showBack: true,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppColors.orange.withOpacity(.35)),
              boxShadow: [BoxShadow(color: AppColors.orange.withOpacity(.13), blurRadius: 24, offset: const Offset(0, 14))],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: AppColors.green.withOpacity(.16), shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle_outline, color: AppColors.green, size: 58),
                ),
                const SizedBox(height: 14),
                Text('Pedido #${order.id}', style: const TextStyle(color: AppColors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                const Text('¡Recibimos tu pedido!', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
                const SizedBox(height: 18),
                ReceiptLine(label: 'Cliente', value: order.clientName),
                ReceiptLine(label: 'Total', value: '\$${order.total.toStringAsFixed(2)}'),
                ReceiptLine(label: 'Pago', value: order.paymentMethod),
                ReceiptLine(label: 'Dirección', value: order.deliveryAddress),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFF333333)),
                const SizedBox(height: 8),
                ...order.items.map((item) => ReceiptLine(label: '${item.quantity}x', value: '${item.product.name} · ${item.size}')),
              ],
            ),
          ),
          const SizedBox(height: 18),
          RofloButton(
            label: 'ENVIAR COMPROBANTE POR WHATSAPP',
            icon: Icons.share_outlined,
            onPressed: () => sendReceipt(context),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.receipt_long_outlined, color: AppColors.orange),
            label: const Text('VER SEGUIMIENTO', style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w900)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.orange), padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ],
      ),
    );
  }
}

class ReceiptLine extends StatelessWidget {
  const ReceiptLine({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 86, child: Text(label, style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.w700))),
          Expanded(child: Text(value, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key, required this.orders, required this.cartCount, required this.onCartTap});

  final List<RofloOrder> orders;
  final int cartCount;
  final VoidCallback onCartTap;

  @override
  Widget build(BuildContext context) {
    return DarkPage(
      title: 'Pedidos',
      subtitle: 'Seguimiento del cliente',
      cartCount: cartCount,
      onCartTap: onCartTap,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
        children: [
          if (orders.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(.10),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.orange.withOpacity(.35)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: AppColors.orange, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Esta pantalla es para que el cliente vea el seguimiento. Solo el administrador cambia el estado desde Panel de Administración > Pedidos confirmados.',
                      style: TextStyle(color: Colors.white70, height: 1.35, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          if (orders.isEmpty)
            const EmptyState(icon: Icons.receipt_long_outlined, title: 'Sin pedidos activos', text: 'Cuando confirmes un pedido aparecerá aquí.'),
          ...orders.map((order) => OrderCard(order: order)),
          const SizedBox(height: 12),
          if (orders.isEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(22)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Flujo del pedido', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w900, fontSize: 17)),
                  SizedBox(height: 12),
                  StepLine(label: 'Pedido recibido', active: true),
                  StepLine(label: 'En cocina', active: true),
                  StepLine(label: 'En camino', active: false),
                  StepLine(label: 'Entregado', active: false, last: true),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.onLogout});
  final VoidCallback onLogout;

  void showProfileMessage(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(title, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w900)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ENTENDIDO', style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DarkPage(
      title: 'Mi Perfil',
      subtitle: 'Datos de cuenta y preferencias',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Row(
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(50), child: Image.asset('assets/images/logo.png', width: 72, height: 72, fit: BoxFit.cover)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        RofloStore.currentAccount?.name ?? 'Usuario Roflo',
                        style: const TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        RofloStore.currentAccount?.email ?? 'Cuenta registrada',
                        style: const TextStyle(color: Colors.white60),
                      ),
                      const SizedBox(height: 8),
                      const Text('Nivel fan del queso', style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ProfileOption(
            icon: Icons.location_on_outlined,
            title: 'Mis direcciones',
            subtitle: 'Agregar o editar dirección de entrega',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressBookScreen())),
          ),
          ProfileOption(
            icon: Icons.payment_outlined,
            title: 'Pagos',
            subtitle: 'Efectivo, transferencia y tarjetas',
            onTap: () => showProfileMessage(context, 'Pagos', 'Métodos disponibles: efectivo, transferencia y tarjeta al momento de entrega.'),
          ),
          ProfileOption(
            icon: Icons.favorite_border,
            title: 'Mis favoritos',
            subtitle: 'Productos que más te gustan',
            onTap: () => showProfileMessage(context, 'Mis favoritos', 'Aquí se mostrarán los productos marcados con corazón.'),
          ),
          ProfileOption(
            icon: Icons.support_agent_outlined,
            title: 'Soporte',
            subtitle: 'Contacta con Roflo Cheesy Nach',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen())),
          ),
          const SizedBox(height: 16),
          RofloButton(label: 'CERRAR SESIÓN', icon: Icons.logout, onPressed: onLogout),
        ],
      ),
    );
  }
}

class AdminScreen extends StatelessWidget {
  const AdminScreen({
    super.key,
    required this.products,
    required this.clients,
    required this.orders,
    required this.onOpenProducts,
    required this.onOpenClients,
    required this.onOpenOrders,
  });

  final List<Product> products;
  final List<RofloClient> clients;
  final List<RofloOrder> orders;
  final VoidCallback onOpenProducts;
  final VoidCallback onOpenClients;
  final VoidCallback onOpenOrders;

  void showSalesReport(BuildContext context, double totalSales) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Reporte de ventas', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w900)),
        content: Text(
          'Ventas acumuladas: \$${totalSales.toStringAsFixed(2)}\nPedidos confirmados: ${orders.length}\nProductos registrados: ${products.length}\nClientes registrados: ${clients.length}',
          style: const TextStyle(color: Colors.white70, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CERRAR', style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalSales = orders.fold<double>(0, (sum, order) => sum + order.total);
    return DarkPage(
      title: 'Panel de Administración',
      subtitle: 'Control del negocio ROFLO',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 90),
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth >= 900
                  ? (constraints.maxWidth - 36) / 4
                  : (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(width: itemWidth, child: AdminMetric(label: 'Ventas', value: '\$${totalSales.toStringAsFixed(2)}', icon: Icons.attach_money)),
                  SizedBox(width: itemWidth, child: AdminMetric(label: 'Productos', value: '${products.length}', icon: Icons.fastfood_outlined)),
                  SizedBox(width: itemWidth, child: AdminMetric(label: 'Clientes', value: '${clients.length}', icon: Icons.people_outline)),
                  SizedBox(width: itemWidth, child: AdminMetric(label: 'Pedidos', value: '${orders.length}', icon: Icons.receipt_long_outlined)),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          const SectionTitle(title: 'Acciones rápidas'),
          const SizedBox(height: 12),
          AdminActionCard(
            icon: Icons.add_box_outlined,
            title: 'Productos del menú',
            text: 'Crear, actualizar, consultar y eliminar productos.',
            button: 'ABRIR PRODUCTOS',
            onTap: onOpenProducts,
          ),
          const SizedBox(height: 12),
          AdminActionCard(
            icon: Icons.people_alt_outlined,
            title: 'Clientes registrados',
            text: 'CRUD completo de clientes: crear, consultar, editar y eliminar.',
            button: 'ABRIR CLIENTES',
            onTap: onOpenClients,
          ),
          const SizedBox(height: 12),
          AdminActionCard(
            icon: Icons.receipt_long_outlined,
            title: 'Pedidos confirmados',
            text: 'Consultar los pedidos creados desde el carrito.',
            button: 'VER PEDIDOS',
            onTap: onOpenOrders,
          ),
          const SizedBox(height: 12),
          AdminActionCard(
            icon: Icons.bar_chart_outlined,
            title: 'Reporte de ventas',
            text: 'Ver resumen de ventas, pedidos, clientes y productos.',
            button: 'VER REPORTE',
            onTap: () => showSalesReport(context, totalSales),
          ),
          const SizedBox(height: 18),
          const SectionTitle(title: 'Pedidos recientes'),
          const SizedBox(height: 12),
          if (orders.isEmpty)
            const EmptyState(icon: Icons.inbox_outlined, title: 'Sin ventas todavía', text: 'Los pedidos confirmados aparecerán en esta sección.'),
          ...orders.take(4).map((order) => OrderCard(order: order, compact: true)),
        ],
      ),
    );
  }

}


class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({
    super.key,
    required this.orders,
    required this.onStatusChanged,
    this.showBack = true,
  });

  final List<RofloOrder> orders;
  final void Function(RofloOrder order, String status) onStatusChanged;
  final bool showBack;

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  String filter = 'Todos';

  List<RofloOrder> get filteredOrders {
    if (filter == 'Todos') return widget.orders;
    return widget.orders.where((order) => order.status == filter).toList();
  }

  void changeStatus(RofloOrder order, String status) {
    widget.onStatusChanged(order, status);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Pedido #${order.id} actualizado a: $status')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DarkPage(
      title: 'Administrar pedidos',
      subtitle: 'Solo el administrador cambia Recibido, Cocina, Camino y Entregado',
      showBack: widget.showBack,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Todos', 'Recibido', 'En cocina', 'En camino', 'Entregado']
                  .map((status) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: StatusFilterChip(
                          label: status,
                          active: filter == status,
                          onTap: () => setState(() => filter = status),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 14),
          if (widget.orders.isEmpty)
            const EmptyState(icon: Icons.receipt_long_outlined, title: 'Sin pedidos todavía', text: 'Cuando un cliente confirme un pedido aparecerá aquí.'),
          if (widget.orders.isNotEmpty && filteredOrders.isEmpty)
            EmptyState(icon: Icons.filter_alt_off_outlined, title: 'Sin pedidos en $filter', text: 'Cambia el filtro para ver otros pedidos.'),
          ...filteredOrders.map(
            (order) => AdminOrderCard(
              order: order,
              onStatusChanged: (status) => changeStatus(order, status),
            ),
          ),
        ],
      ),
    );
  }
}


class StatusFilterChip extends StatelessWidget {
  const StatusFilterChip({super.key, required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedTapScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.orange : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: active ? AppColors.orange : const Color(0xFF333333)),
        ),
        child: Text(label, style: TextStyle(color: AppColors.white, fontWeight: active ? FontWeight.w900 : FontWeight.w700, fontSize: 12)),
      ),
    );
  }
}

class AdminOrderCard extends StatelessWidget {
  const AdminOrderCard({super.key, required this.order, required this.onStatusChanged});

  final RofloOrder order;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final isDelivered = order.status == 'Entregado';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDelivered ? AppColors.green.withOpacity(.45) : const Color(0xFF292929)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.orange.withOpacity(.14), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.receipt_long_outlined, color: AppColors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pedido #${order.id}', style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                    Text('${order.clientName} · Pago: ${order.paymentMethod}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white60)),
                    const SizedBox(height: 3),
                    Text('Entrega: ${order.deliveryAddress}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
              Text('\$${order.total.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.orange, fontSize: 18, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 12),
          Text(order.items.map((item) => '${item.quantity}x ${item.product.name}').join('\n'), style: const TextStyle(color: Colors.white70, height: 1.4)),
          const SizedBox(height: 12),
          Text(
            'Estado actual: ${order.status}',
            style: TextStyle(color: adminStatusColor(order.status), fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          AdminProgressOnly(status: order.status),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusActionButton(label: 'Recibido', icon: Icons.inbox_outlined, active: order.status == 'Recibido', onTap: () => onStatusChanged('Recibido')),
              StatusActionButton(label: 'En cocina', icon: Icons.restaurant_outlined, active: order.status == 'En cocina', onTap: () => onStatusChanged('En cocina')),
              StatusActionButton(label: 'En camino', icon: Icons.delivery_dining, active: order.status == 'En camino', onTap: () => onStatusChanged('En camino')),
              StatusActionButton(label: 'Entregado', icon: Icons.check_circle_outline, active: order.status == 'Entregado', onTap: () => onStatusChanged('Entregado')),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              QuickAdminButton(
                label: 'Ver detalle',
                icon: Icons.visibility_outlined,
                onTap: () => showAdminOrderDetail(context, order),
              ),
              if (extractOrderPhone(order) != null)
                QuickAdminButton(
                  label: 'Llamar cliente',
                  icon: Icons.phone_outlined,
                  onTap: () => openExternalUri(context, Uri(scheme: 'tel', path: extractOrderPhone(order)!), extractOrderPhone(order)!),
                ),
              if (extractOrderPhone(order) != null)
                QuickAdminButton(
                  label: 'WhatsApp',
                  icon: Icons.chat_outlined,
                  onTap: () => openExternalUri(context, whatsappUri(extractOrderPhone(order)!, 'Hola ${order.clientName}, te escribimos por tu pedido #${order.id} de ROFLO.'), extractOrderPhone(order)!),
                ),
              if (deliveryMapUriFromText(order.deliveryAddress) != null)
                QuickAdminButton(
                  label: 'Ver ubicación',
                  icon: Icons.location_on_outlined,
                  onTap: () => openExternalUri(context, deliveryMapUriFromText(order.deliveryAddress)!, order.deliveryAddress),
                ),
            ],
          ),
        ],
      ),
    );
  }
}



Color adminStatusColor(String status) {
  switch (status) {
    case 'Recibido':
      return const Color(0xFF4DA3FF);
    case 'En cocina':
      return AppColors.orange;
    case 'En camino':
      return const Color(0xFFFFC247);
    case 'Entregado':
      return AppColors.green;
    default:
      return AppColors.orange;
  }
}

int adminStatusIndex(String status) {
  const steps = ['Recibido', 'En cocina', 'En camino', 'Entregado'];
  final index = steps.indexOf(status);
  return index < 0 ? 0 : index;
}

class AdminProgressOnly extends StatelessWidget {
  const AdminProgressOnly({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final activeIndex = adminStatusIndex(status);
    final color = adminStatusColor(status);
    final progress = (activeIndex + 1) / 4;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (_, value, __) => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: LinearProgressIndicator(
          value: value,
          minHeight: 8,
          backgroundColor: const Color(0xFF2A2A2A),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }
}

class QuickAdminButton extends StatelessWidget {
  const QuickAdminButton({super.key, required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedTapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF202020),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF383838)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.orange, size: 18),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w900, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

String? extractOrderPhone(RofloOrder order) {
  final match = RegExp(r'(?:Tel|Telefono|Teléfono)[:\s]*([0-9+\s-]{7,})', caseSensitive: false).firstMatch(order.deliveryAddress);
  if (match != null) return match.group(1)!.replaceAll(RegExp(r'[^0-9+]'), '');
  return null;
}

Uri whatsappUri(String phone, String message) {
  var cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (cleaned.startsWith('0') && cleaned.length == 10) {
    cleaned = '593${cleaned.substring(1)}';
  }
  return Uri.parse('https://wa.me/$cleaned?text=${Uri.encodeComponent(message)}');
}

void showAdminOrderDetail(BuildContext context, RofloOrder order) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text('Detalle pedido #${order.id}', style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w900)),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Cliente: ${order.clientName}', style: const TextStyle(color: Colors.white70)),
            Text('Pago: ${order.paymentMethod}', style: const TextStyle(color: Colors.white70)),
            Text('Estado: ${order.status}', style: TextStyle(color: adminStatusColor(order.status), fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            const Text('Dirección:', style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w900)),
            Text(order.deliveryAddress, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 10),
            const Text('Productos:', style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w900)),
            Text(order.items.map((item) => '${item.quantity}x ${item.product.name}').join('\n'), style: const TextStyle(color: Colors.white70, height: 1.4)),
            const SizedBox(height: 10),
            Text('Total: \$${order.total.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.orange, fontSize: 18, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CERRAR', style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w900))),
      ],
    ),
  );
}

class StatusActionButton extends StatelessWidget {
  const StatusActionButton({super.key, required this.label, required this.icon, required this.active, required this.onTap});

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedTapScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.orange : const Color(0xFF242424),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? AppColors.orange : const Color(0xFF333333)),
          boxShadow: active ? [BoxShadow(color: AppColors.orange.withOpacity(.22), blurRadius: 14, offset: const Offset(0, 7))] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.white, size: 18),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w900, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}


class PaymentFormPanel extends StatelessWidget {
  const PaymentFormPanel({
    super.key,
    required this.method,
    required this.cashAmount,
    required this.transferBank,
    required this.transferReference,
    required this.transferName,
    required this.cardHolder,
    required this.cardType,
    required this.cardNumber,
    required this.cardExpiry,
    required this.cardCvv,
    required this.total,
    required this.onlinePaymentStarted,
    required this.onOpenOnlinePayment,
    required this.onChanged,
  });

  final String method;
  final TextEditingController cashAmount;
  final TextEditingController transferBank;
  final TextEditingController transferReference;
  final TextEditingController transferName;
  final TextEditingController cardHolder;
  final TextEditingController cardType;
  final TextEditingController cardNumber;
  final TextEditingController cardExpiry;
  final TextEditingController cardCvv;
  final double total;
  final bool onlinePaymentStarted;
  final Future<void> Function() onOpenOnlinePayment;
  final VoidCallback onChanged;

  double get received => double.tryParse(cashAmount.text.replaceAll(',', '.')) ?? 0;
  double get change => received - total;

  @override
  Widget build(BuildContext context) {
    if (method == 'Efectivo') return buildCash();
    if (method == 'Transferencia') return buildTransfer();
    return buildCard();
  }

  Widget panel({required IconData icon, required String title, required String subtitle, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF2D2D2D)),
        boxShadow: [BoxShadow(color: AppColors.orange.withOpacity(.08), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.orange.withOpacity(.16), borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: AppColors.orange, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget buildCash() {
    return panel(
      icon: Icons.payments_outlined,
      title: 'Pago en efectivo',
      subtitle: 'Registra con cuánto paga el cliente para calcular el cambio.',
      children: [
        RofloTextField(
          controller: cashAmount,
          label: 'Monto recibido, ejemplo 20.00',
          icon: Icons.attach_money,
          dark: true,
          keyboard: TextInputType.number,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.black, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF303030))),
          child: Row(
            children: [
              const Expanded(child: Text('Cambio estimado', style: TextStyle(color: Colors.white60, fontWeight: FontWeight.w700))),
              Text(
                received <= 0 ? '\$0.00' : (change >= 0 ? '\$${change.toStringAsFixed(2)}' : 'Falta \$${(-change).toStringAsFixed(2)}'),
                style: TextStyle(color: change >= 0 ? AppColors.green : AppColors.red, fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildTransfer() {
    return panel(
      icon: Icons.account_balance_outlined,
      title: 'Pago por transferencia',
      subtitle: 'Datos de cuenta y comprobante para validar el pago.',
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.orange.withOpacity(.20), AppColors.gold.withOpacity(.10)]),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.orange.withOpacity(.35)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cuenta bancaria para transferencia', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w900)),
              SizedBox(height: 6),
              Text('Banco: $rofloBusinessBankName', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text('Tipo: $rofloBusinessAccountType', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text('Cuenta: $rofloBusinessAccountNumber', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text('Titular: $rofloBusinessAccountHolder', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text('Cédula/RUC: $rofloBusinessDocument', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text('Correo: $rofloBusinessPaymentEmail', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        BankDropdown(controller: transferBank, onChanged: onChanged),
        const SizedBox(height: 10),
        RofloTextField(controller: transferReference, label: 'Número de referencia/comprobante', icon: Icons.receipt_long_outlined, dark: true),
        const SizedBox(height: 10),
        RofloTextField(controller: transferName, label: 'Nombre de quien realizó el pago', icon: Icons.person_outline, dark: true),
      ],
    );
  }

  Widget buildCard() {
    final provider = rofloConfiguredPaymentLink().isNotEmpty ? 'pasarela configurada' : 'WhatsApp del negocio';
    return panel(
      icon: Icons.credit_card,
      title: 'Pago con tarjeta / pago online',
      subtitle: 'El cobro real se realiza fuera de la app mediante un link seguro.',
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(colors: [Color(0xFFFF8A00), Color(0xFF111111)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            boxShadow: [BoxShadow(color: AppColors.orange.withOpacity(.20), blurRadius: 22, offset: Offset(0, 12))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Icon(Icons.lock_outline, color: AppColors.white),
                  Text('PAGO SEGURO', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ],
              ),
              const SizedBox(height: 18),
              const Text('No guardes datos de tarjeta en la app', style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('Total a pagar: \$${total.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.cheese, fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text('Se abrirá: $provider', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        RofloButton(
          label: onlinePaymentStarted ? 'LINK DE PAGO ABIERTO' : 'PAGAR AHORA',
          icon: onlinePaymentStarted ? Icons.check_circle_outline : Icons.open_in_new,
          onPressed: onOpenOnlinePayment,
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: onlinePaymentStarted ? AppColors.green.withOpacity(.12) : AppColors.orange.withOpacity(.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: onlinePaymentStarted ? AppColors.green.withOpacity(.45) : AppColors.orange.withOpacity(.35)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(onlinePaymentStarted ? Icons.verified_outlined : Icons.info_outline, color: onlinePaymentStarted ? AppColors.green : AppColors.orange, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  onlinePaymentStarted
                      ? 'Cuando el cliente complete el pago, confirma el pedido. El administrador podrá validar el pago y cambiar el estado.'
                      : 'Para recibir dinero real debes pegar arriba un link real de PayPhone, Mercado Pago o Stripe. Si no hay link, se abre WhatsApp para solicitar el cobro al negocio.',
                  style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.35),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Recomendación: el cliente ingresa la tarjeta en la pasarela externa, no dentro de la app. Así el pago es más seguro.',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }
}



class BankDropdown extends StatelessWidget {
  const BankDropdown({super.key, required this.controller, required this.onChanged});

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final current = controller.text.trim();
    final selected = rofloBanks.contains(current) ? current : null;
    return DropdownButtonFormField<String>(
      value: selected,
      isExpanded: true,
      dropdownColor: AppColors.card,
      iconEnabledColor: AppColors.orange,
      decoration: InputDecoration(
        labelText: 'Banco desde donde transfiere',
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(Icons.account_balance, color: AppColors.orange),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
      style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700),
      items: rofloBanks
          .map((bank) => DropdownMenuItem<String>(
                value: bank,
                child: Text(bank, overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: (value) {
        controller.text = value ?? '';
        onChanged();
      },
    );
  }
}

class CardTypeDropdown extends StatelessWidget {
  const CardTypeDropdown({super.key, required this.controller, required this.onChanged});

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final current = controller.text.trim();
    final selected = rofloCardTypes.contains(current) ? current : rofloCardTypes.first;
    if (controller.text.trim().isEmpty) controller.text = selected;
    return DropdownButtonFormField<String>(
      value: selected,
      isExpanded: true,
      dropdownColor: AppColors.card,
      iconEnabledColor: AppColors.orange,
      decoration: InputDecoration(
        labelText: 'Tipo de tarjeta',
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(Icons.credit_card, color: AppColors.orange),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
      style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700),
      items: rofloCardTypes
          .map((type) => DropdownMenuItem<String>(
                value: type,
                child: Text(type, overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: (value) {
        controller.text = value ?? rofloCardTypes.first;
        onChanged();
      },
    );
  }
}

class PaymentSelector extends StatelessWidget {
  const PaymentSelector({super.key, required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final methods = <Map<String, Object>>[
      {'name': 'Efectivo', 'icon': Icons.payments_outlined},
      {'name': 'Transferencia', 'icon': Icons.account_balance_outlined},
      {'name': 'Tarjeta', 'icon': Icons.credit_card},
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: methods.asMap().entries.map((entry) {
        final method = entry.value;
        final name = method['name']! as String;
        final icon = method['icon']! as IconData;
        final isSelected = selected == name;
        return StaggeredEntry(
          index: entry.key,
          child: AnimatedTapScale(
            onTap: () => onChanged(name),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 230),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.orange : AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? AppColors.orange : const Color(0xFF333333)),
                boxShadow: isSelected ? [BoxShadow(color: AppColors.orange.withOpacity(.22), blurRadius: 14, offset: const Offset(0, 7))] : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedScale(duration: const Duration(milliseconds: 220), scale: isSelected ? 1.12 : 1, curve: Curves.easeOutBack, child: Icon(icon, color: AppColors.white, size: 18)),
                  const SizedBox(width: 8),
                  Text(name, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}


class ClientCrudScreen extends StatefulWidget {
  const ClientCrudScreen({super.key, required this.clients, required this.onCreate, required this.onUpdate, required this.onDelete});

  final List<RofloClient> clients;
  final ValueChanged<RofloClient> onCreate;
  final ValueChanged<RofloClient> onUpdate;
  final ValueChanged<RofloClient> onDelete;

  @override
  State<ClientCrudScreen> createState() => _ClientCrudScreenState();
}

class _ClientCrudScreenState extends State<ClientCrudScreen> {
  String query = '';

  List<RofloClient> get filtered => widget.clients
      .where((client) => client.name.toLowerCase().contains(query.toLowerCase()) || client.phone.contains(query))
      .toList();

  @override
  Widget build(BuildContext context) {
    return DarkPage(
      title: 'Clientes registrados',
      subtitle: 'Crear, consultar, actualizar y eliminar',
      showBack: true,
      action: IconButton(
        icon: const Icon(Icons.add_circle, color: AppColors.orange),
        onPressed: () => openForm(),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
        children: [
          TextField(
            style: const TextStyle(color: AppColors.white),
            decoration: InputDecoration(
              hintText: 'Buscar cliente por nombre o teléfono',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: AppColors.orange),
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
            ),
            onChanged: (value) => setState(() => query = value),
          ),
          const SizedBox(height: 16),
          ...filtered.map((client) => ClientCard(
                client: client,
                onEdit: () => openForm(client: client),
                onDelete: () {
                  widget.onDelete(client);
                  setState(() {});
                },
              )),
          if (filtered.isEmpty)
            const EmptyState(icon: Icons.people_outline, title: 'No hay clientes', text: 'Presiona + para registrar un nuevo cliente.'),
        ],
      ),
    );
  }

  void openForm({RofloClient? client}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.dark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => ClientFormSheet(
        client: client,
        onSave: (newClient) {
          if (client == null) {
            widget.onCreate(newClient);
          } else {
            client.name = newClient.name;
            client.phone = newClient.phone;
            client.address = newClient.address;
            client.note = newClient.note;
            widget.onUpdate(client);
          }
          setState(() {});
          Navigator.pop(context);
        },
      ),
    );
  }
}

class ProductCrudScreen extends StatefulWidget {
  const ProductCrudScreen({super.key, required this.products, required this.onCreate, required this.onUpdate, required this.onDelete});

  final List<Product> products;
  final ValueChanged<Product> onCreate;
  final ValueChanged<Product> onUpdate;
  final ValueChanged<Product> onDelete;

  @override
  State<ProductCrudScreen> createState() => _ProductCrudScreenState();
}

class _ProductCrudScreenState extends State<ProductCrudScreen> {
  @override
  Widget build(BuildContext context) {
    return DarkPage(
      title: 'Productos',
      subtitle: 'Administrar menú ROFLO',
      showBack: true,
      action: IconButton(icon: const Icon(Icons.add_circle, color: AppColors.orange), onPressed: () => openForm()),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
        children: [
          ...widget.products.map((product) => AdminProductCard(
                product: product,
                onEdit: () => openForm(product: product),
                onDelete: () {
                  widget.onDelete(product);
                  setState(() {});
                },
              )),
        ],
      ),
    );
  }

  void openForm({Product? product}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.dark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => ProductFormSheet(
        product: product,
        onSave: (newProduct) {
          if (product == null) {
            widget.onCreate(newProduct);
          } else {
            product.name = newProduct.name;
            product.description = newProduct.description;
            product.category = newProduct.category;
            product.smallPrice = newProduct.smallPrice;
            product.mediumPrice = newProduct.mediumPrice;
            product.largePrice = newProduct.largePrice;
            product.available = newProduct.available;
            widget.onUpdate(product);
          }
          setState(() {});
          Navigator.pop(context);
        },
      ),
    );
  }
}

class ClientFormSheet extends StatefulWidget {
  const ClientFormSheet({super.key, this.client, required this.onSave});
  final RofloClient? client;
  final ValueChanged<RofloClient> onSave;

  @override
  State<ClientFormSheet> createState() => _ClientFormSheetState();
}

class _ClientFormSheetState extends State<ClientFormSheet> {
  late final TextEditingController name = TextEditingController(text: widget.client?.name ?? '');
  late final TextEditingController phone = TextEditingController(text: widget.client?.phone ?? '');
  late final TextEditingController address = TextEditingController(text: widget.client?.address ?? '');
  late final TextEditingController note = TextEditingController(text: widget.client?.note ?? '');

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    address.dispose();
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 22, right: 22, top: 22, bottom: MediaQuery.of(context).viewInsets.bottom + 22),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.client == null ? 'Nuevo cliente' : 'Editar cliente', style: const TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            RofloTextField(controller: name, label: 'Nombre', icon: Icons.person_outline, dark: true),
            const SizedBox(height: 10),
            RofloTextField(controller: phone, label: 'Teléfono', icon: Icons.phone_outlined, dark: true),
            const SizedBox(height: 10),
            RofloTextField(controller: address, label: 'Dirección', icon: Icons.location_on_outlined, dark: true),
            const SizedBox(height: 10),
            RofloTextField(controller: note, label: 'Observación', icon: Icons.notes_outlined, dark: true),
            const SizedBox(height: 18),
            RofloButton(
              label: 'GUARDAR CLIENTE',
              onPressed: () {
                widget.onSave(RofloClient(
                  id: widget.client?.id ?? 0,
                  name: name.text.trim().isEmpty ? 'Cliente sin nombre' : name.text.trim(),
                  phone: phone.text.trim(),
                  address: address.text.trim(),
                  note: note.text.trim(),
                ));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ProductFormSheet extends StatefulWidget {
  const ProductFormSheet({super.key, this.product, required this.onSave});
  final Product? product;
  final ValueChanged<Product> onSave;

  @override
  State<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<ProductFormSheet> {
  late final TextEditingController name = TextEditingController(text: widget.product?.name ?? '');
  late final TextEditingController description = TextEditingController(text: widget.product?.description ?? '');
  late final TextEditingController category = TextEditingController(text: widget.product?.category ?? 'Especiales');
  late final TextEditingController small = TextEditingController(text: (widget.product?.smallPrice ?? 3.00).toStringAsFixed(2));
  late final TextEditingController medium = TextEditingController(text: (widget.product?.mediumPrice ?? 4.75).toStringAsFixed(2));
  late final TextEditingController large = TextEditingController(text: (widget.product?.largePrice ?? 5.75).toStringAsFixed(2));
  bool available = true;

  @override
  void initState() {
    super.initState();
    available = widget.product?.available ?? true;
  }

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    category.dispose();
    small.dispose();
    medium.dispose();
    large.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 22, right: 22, top: 22, bottom: MediaQuery.of(context).viewInsets.bottom + 22),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.product == null ? 'Agregar nuevo producto' : 'Editar producto', style: const TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            RofloTextField(controller: name, label: 'Nombre del producto', icon: Icons.fastfood_outlined, dark: true),
            const SizedBox(height: 10),
            RofloTextField(controller: description, label: 'Descripción', icon: Icons.description_outlined, dark: true),
            const SizedBox(height: 10),
            RofloTextField(controller: category, label: 'Categoría', icon: Icons.category_outlined, dark: true),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: RofloTextField(controller: small, label: 'P.', icon: Icons.attach_money, dark: true, keyboard: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: RofloTextField(controller: medium, label: 'M.', icon: Icons.attach_money, dark: true, keyboard: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: RofloTextField(controller: large, label: 'G.', icon: Icons.attach_money, dark: true, keyboard: TextInputType.number)),
              ],
            ),
            SwitchListTile(
              value: available,
              activeColor: AppColors.orange,
              title: const Text('Producto disponible', style: TextStyle(color: AppColors.white)),
              onChanged: (value) => setState(() => available = value),
            ),
            const SizedBox(height: 10),
            RofloButton(
              label: 'GUARDAR PRODUCTO',
              onPressed: () {
                widget.onSave(Product(
                  id: widget.product?.id ?? 0,
                  name: name.text.trim().isEmpty ? 'Nuevo Roflo' : name.text.trim(),
                  description: description.text.trim(),
                  category: category.text.trim(),
                  image: widget.product?.image ?? 'assets/products/classic.jpg',
                  smallPrice: double.tryParse(small.text) ?? 3.00,
                  mediumPrice: double.tryParse(medium.text) ?? 4.75,
                  largePrice: double.tryParse(large.text) ?? 5.75,
                  available: available,
                ));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class DarkPage extends StatelessWidget {
  const DarkPage({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.showBack = false,
    this.cartCount,
    this.onCartTap,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final bool showBack;
  final int? cartCount;
  final VoidCallback? onCartTap;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          const Positioned(top: 0, left: 0, right: 0, child: CheeseDrip(height: 78)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                  child: Row(
                    children: [
                      if (showBack)
                        CircleIconButton(icon: Icons.arrow_back, onTap: () => Navigator.pop(context))
                      else
                        ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset('assets/images/logo.png', width: 48, height: 48, fit: BoxFit.cover)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: const TextStyle(color: AppColors.white, fontSize: 21, fontWeight: FontWeight.w900)),
                            if (subtitle != null)
                              Text(subtitle!, style: const TextStyle(color: Colors.white60, fontSize: 13)),
                          ],
                        ),
                      ),
                      if (action != null) action!,
                      if (cartCount != null)
                        CartIcon(count: cartCount!, onTap: onCartTap ?? () {}),
                    ],
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LightMenuPage extends StatelessWidget {
  const LightMenuPage({super.key, required this.child, required this.cartCount, required this.onCartTap, required this.onMenuTap});
  final Widget child;
  final int cartCount;
  final VoidCallback onCartTap;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
              child: Row(
                children: [
                  IconButton(onPressed: onMenuTap, icon: const Icon(Icons.menu, size: 34, color: AppColors.dark)),
                  const Spacer(),
                  const Text('Menú', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                  const Spacer(),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(onPressed: onCartTap, icon: const Icon(Icons.shopping_cart_outlined, size: 34)),
                      if (cartCount > 0)
                        Positioned(
                          top: -3,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: AppColors.orange, shape: BoxShape.circle),
                            child: Text('$cartCount', style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}


class StaggeredEntry extends StatefulWidget {
  const StaggeredEntry({super.key, required this.child, this.index = 0, this.offset = 18});
  final Widget child;
  final int index;
  final double offset;

  @override
  State<StaggeredEntry> createState() => _StaggeredEntryState();
}

class _StaggeredEntryState extends State<StaggeredEntry> with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  late final Animation<double> fade;
  late final Animation<Offset> slide;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 430));
    fade = CurvedAnimation(parent: controller, curve: Curves.easeOutCubic);
    slide = Tween<Offset>(begin: Offset(0, widget.offset / 100), end: Offset.zero).animate(fade);
    Future.delayed(Duration(milliseconds: 55 * widget.index), () {
      if (mounted) controller.forward();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: widget.child),
    );
  }
}

class AnimatedTapScale extends StatefulWidget {
  const AnimatedTapScale({super.key, required this.child, this.onTap, this.scale = .965});
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<AnimatedTapScale> createState() => _AnimatedTapScaleState();
}

class _AnimatedTapScaleState extends State<AnimatedTapScale> {
  bool pressed = false;

  void setPressed(bool value) {
    if (mounted) setState(() => pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => setPressed(true),
      onTapUp: (_) => setPressed(false),
      onTapCancel: () => setPressed(false),
      child: AnimatedScale(
        scale: pressed ? widget.scale : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}

class PremiumHomeHero extends StatelessWidget {
  const PremiumHomeHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 168,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: AppColors.orange.withOpacity(.18), blurRadius: 28, offset: const Offset(0, 12))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const SlowZoomAsset(asset: 'assets/images/menu_poster.jpg', width: double.infinity, height: 168, radius: 26),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [Color(0xEE000000), Color(0x77000000), Color(0x22000000)],
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: StaggeredEntry(
                index: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('SOLO FIN DE SEMANA', style: TextStyle(color: AppColors.white, fontSize: 20, height: 1, fontWeight: FontWeight.w900, letterSpacing: .4)),
                    SizedBox(height: 5),
                    Text('Nachos con extra queso', style: TextStyle(color: AppColors.cheese, fontSize: 18, fontWeight: FontWeight.w900)),
                    SizedBox(height: 6),
                    Text('Promoción caliente, crujiente y llena de sabor.', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: AppColors.orange.withOpacity(.92), borderRadius: BorderRadius.circular(18)),
                child: const Text('HOT', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedStatusProgress extends StatelessWidget {
  const AnimatedStatusProgress({super.key, required this.status, this.editable = false});
  final String status;
  final bool editable;

  int get activeIndex {
    const steps = ['Recibido', 'En cocina', 'En camino', 'Entregado'];
    final index = steps.indexOf(status);
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final labels = editable ? const ['Recibido', 'Cocina', 'Camino', 'Entregado'] : const ['Recibido', 'Cocina', 'Camino', 'Entregado'];
    final icons = const [Icons.inbox_outlined, Icons.restaurant_outlined, Icons.delivery_dining, Icons.check_circle_outline];
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: (activeIndex + 1) / 4),
          duration: const Duration(milliseconds: 520),
          curve: Curves.easeOutCubic,
          builder: (_, value, __) => ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 7,
              backgroundColor: const Color(0xFF2A2A2A),
              valueColor: AlwaysStoppedAnimation<Color>(status == 'Entregado' ? AppColors.green : AppColors.orange),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(4, (index) {
            final active = index <= activeIndex;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index == 3 ? 0 : 6),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
                  decoration: BoxDecoration(
                    color: active ? (status == 'Entregado' ? AppColors.green : AppColors.orange) : const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: active ? [BoxShadow(color: (status == 'Entregado' ? AppColors.green : AppColors.orange).withOpacity(.22), blurRadius: 14, offset: const Offset(0, 6))] : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icons[index], color: active ? AppColors.white : Colors.white38, size: 14),
                      const SizedBox(width: 4),
                      Flexible(child: Text(labels[index], maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: active ? AppColors.white : Colors.white54, fontSize: 10, fontWeight: FontWeight.w900))),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class PremiumAuthBackground extends StatefulWidget {
  const PremiumAuthBackground({super.key});

  @override
  State<PremiumAuthBackground> createState() => _PremiumAuthBackgroundState();
}

class _PremiumAuthBackgroundState extends State<PremiumAuthBackground> with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => CustomPaint(
        painter: PremiumAuthBackgroundPainter(controller.value),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFFAEF), Color(0xFFFFF1D6), Color(0xFFFFF8EA)],
            ),
          ),
        ),
      ),
    );
  }
}

class PremiumAuthBackgroundPainter extends CustomPainter {
  const PremiumAuthBackgroundPainter(this.phase);
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final p = phase * math.pi * 2;
    final goldPaint = Paint()..color = AppColors.gold.withOpacity(.16);
    final orangePaint = Paint()..color = AppColors.orange.withOpacity(.10);
    final creamPaint = Paint()..color = Colors.white.withOpacity(.55);

    canvas.drawCircle(Offset(size.width * (.16 + math.sin(p) * .025), size.height * .22), 120, goldPaint);
    canvas.drawCircle(Offset(size.width * (.86 + math.cos(p) * .025), size.height * .48), 150, orangePaint);
    canvas.drawCircle(Offset(size.width * (.42 + math.sin(p * .7) * .02), size.height * .78), 180, creamPaint);

    final sparklePaint = Paint()..color = AppColors.orange.withOpacity(.18);
    for (int i = 0; i < 14; i++) {
      final dx = (i * 79 + math.sin(p + i) * 10) % size.width;
      final dy = 90 + ((i * 53 + math.cos(p * .8 + i) * 8) % (size.height - 140));
      canvas.drawCircle(Offset(dx, dy), 1.8 + (i % 3), sparklePaint);
    }
  }

  @override
  bool shouldRepaint(covariant PremiumAuthBackgroundPainter oldDelegate) => oldDelegate.phase != phase;
}

class FloatingLogo extends StatefulWidget {
  const FloatingLogo({super.key, required this.size, this.glow = false});
  final double size;
  final bool glow;

  @override
  State<FloatingLogo> createState() => _FloatingLogoState();
}

class _FloatingLogoState extends State<FloatingLogo> with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, child) {
        final wave = math.sin(controller.value * math.pi);
        return Transform.translate(
          offset: Offset(0, -6 * wave),
          child: Transform.scale(
            scale: 1 + .018 * wave,
            child: child,
          ),
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.size * .16),
          boxShadow: [
            BoxShadow(color: AppColors.orange.withOpacity(widget.glow ? .38 : .18), blurRadius: widget.glow ? 34 : 22, offset: const Offset(0, 14)),
            BoxShadow(color: Colors.white.withOpacity(.55), blurRadius: 18, offset: const Offset(-4, -4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.size * .16),
          child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
        ),
      ),
    );
  }
}

class SlowZoomAsset extends StatefulWidget {
  const SlowZoomAsset({
    super.key,
    required this.asset,
    required this.width,
    required this.height,
    this.radius = 20,
  });

  final String asset;
  final double width;
  final double height;
  final double radius;

  @override
  State<SlowZoomAsset> createState() => _SlowZoomAssetState();
}

class _SlowZoomAssetState extends State<SlowZoomAsset> with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: AnimatedBuilder(
          animation: controller,
          builder: (_, child) {
            final wave = math.sin(controller.value * math.pi);
            return Transform.scale(
              scale: 1.04 + (.04 * wave),
              child: Transform.translate(
                offset: Offset(10 * (controller.value - .5), 0),
                child: child,
              ),
            );
          },
          child: Image.asset(widget.asset, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

class PremiumNachoBanner extends StatelessWidget {
  const PremiumNachoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.orange.withOpacity(.20), blurRadius: 26, offset: const Offset(0, 14))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const SlowZoomAsset(asset: 'assets/images/menu_poster.jpg', width: double.infinity, height: 112, radius: 24),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Colors.black.withOpacity(.68), Colors.black.withOpacity(.20)],
                ),
              ),
            ),
            const Positioned(
              left: 18,
              bottom: 18,
              right: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('QUESO FUNDIDO AL MOMENTO', style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: .4)),
                  SizedBox(height: 4),
                  Text('Nachos calientes, crujientes y llenos de sabor.', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Positioned(top: 12, right: 14, child: Icon(Icons.local_fire_department_rounded, color: AppColors.orange, size: 30)),
          ],
        ),
      ),
    );
  }
}

class CheeseDrip extends StatefulWidget {
  const CheeseDrip({super.key, required this.height});
  final double height;

  @override
  State<CheeseDrip> createState() => _CheeseDripState();
}

class _CheeseDripState extends State<CheeseDrip> with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => CustomPaint(
        size: Size(double.infinity, widget.height),
        painter: CheeseDripPainter(phase: controller.value),
      ),
    );
  }
}

class CheeseDripPainter extends CustomPainter {
  const CheeseDripPainter({this.phase = 0});
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(colors: [AppColors.cheese, AppColors.gold, AppColors.orange]).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final highlight = Paint()..color = Colors.white.withOpacity(.18);
    final path = Path();
    final p = phase * math.pi * 2;

    path.lineTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height * .54);
    for (double x = size.width; x >= 0; x -= 42) {
      final drip = (math.sin(x / 22 + p) + 1) * 10 + 9;
      final y = size.height * (.54 + math.sin(p + x / 61) * .02);
      path.quadraticBezierTo(x - 14, y + drip, x - 32, size.height * .50);
    }
    path.close();
    canvas.drawPath(path, paint);

    final shine = Path()
      ..moveTo(0, size.height * .18)
      ..quadraticBezierTo(size.width * .25, size.height * (.14 + math.sin(p) * .02), size.width * .5, size.height * .18)
      ..quadraticBezierTo(size.width * .75, size.height * (.22 + math.cos(p) * .02), size.width, size.height * .16)
      ..lineTo(size.width, size.height * .27)
      ..quadraticBezierTo(size.width * .5, size.height * .31, 0, size.height * .25)
      ..close();
    canvas.drawPath(shine, highlight);
  }

  @override
  bool shouldRepaint(covariant CheeseDripPainter oldDelegate) => oldDelegate.phase != phase;
}

class RofloButton extends StatefulWidget {
  const RofloButton({super.key, required this.label, required this.onPressed, this.icon});
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  State<RofloButton> createState() => _RofloButtonState();
}

class _RofloButtonState extends State<RofloButton> with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, __) {
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: AppColors.orange.withOpacity(.34), blurRadius: 22, offset: const Offset(0, 10)),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: widget.onPressed,
              icon: widget.icon == null ? const SizedBox.shrink() : Icon(widget.icon, color: AppColors.white),
              label: ShaderMask(
                shaderCallback: (bounds) {
                  final x = bounds.width * controller.value;
                  return LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: const [AppColors.white, Color(0xFFFFF0BA), AppColors.white],
                    stops: <double>[
                      (controller.value - .25).clamp(0.0, 1.0).toDouble(),
                      controller.value,
                      (controller.value + .25).clamp(0.0, 1.0).toDouble(),
                    ],
                  ).createShader(Rect.fromLTWH(x - bounds.width, 0, bounds.width * 2, bounds.height));
                },
                child: Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: .4, color: AppColors.white)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
            ),
          );
        },
      ),
    );
  }
}

class RofloTextField extends StatelessWidget {
  const RofloTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.dark = false,
    this.keyboard,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final bool dark;
  final TextInputType? keyboard;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      onChanged: onChanged,
      style: TextStyle(color: dark ? AppColors.white : AppColors.dark),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: dark ? Colors.white54 : AppColors.grey),
        prefixIcon: Icon(icon, color: AppColors.orange),
        filled: true,
        fillColor: dark ? AppColors.card : AppColors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }
}

class SocialButton extends StatelessWidget {
  const SocialButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.compact = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AnimatedTapScale(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEAEAEA)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon ?? Icons.login, color: AppColors.dark, size: compact ? 20 : 24),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 13 : 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.dark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class CartIcon extends StatelessWidget {
  const CartIcon({super.key, required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedTapScale(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.card.withOpacity(.9),
              shape: BoxShape.circle,
              boxShadow: count > 0 ? [BoxShadow(color: AppColors.orange.withOpacity(.28), blurRadius: 18, offset: const Offset(0, 8))] : null,
            ),
            child: const Icon(Icons.shopping_cart_outlined, color: AppColors.white),
          ),
          Positioned(
            right: -4,
            top: -4,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              transitionBuilder: (child, animation) => ScaleTransition(scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut), child: child),
              child: count > 0
                  ? Container(
                      key: ValueKey(count),
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(color: AppColors.orange, shape: BoxShape.circle),
                      child: Text('$count', style: const TextStyle(color: AppColors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                    )
                  : const SizedBox(key: ValueKey(0), width: 0, height: 0),
            ),
          ),
        ],
      ),
    );
  }
}


class CircleIconButton extends StatelessWidget {
  const CircleIconButton({super.key, required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: AppColors.card.withOpacity(.9), shape: BoxShape.circle),
        child: Icon(icon, color: AppColors.white),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: const TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w900));
  }
}


class CategoryCard extends StatelessWidget {
  const CategoryCard({super.key, required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedTapScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 82,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.orange.withOpacity(.18)),
          boxShadow: [BoxShadow(color: AppColors.orange.withOpacity(.06), blurRadius: 14, offset: const Offset(0, 7))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: .92, end: 1),
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutBack,
              builder: (_, value, child) => Transform.scale(scale: value, child: child),
              child: Icon(icon, color: AppColors.orange, size: 27),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}



class MenuCategory extends StatelessWidget {
  const MenuCategory({super.key, required this.icon, required this.label, required this.onTap, this.selected = false});
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedTapScale(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: selected ? AppColors.orange.withOpacity(.12) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 220),
                scale: selected ? 1.12 : 1,
                curve: Curves.easeOutBack,
                child: Icon(icon, color: selected ? AppColors.orange : AppColors.dark, size: 30),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              style: TextStyle(color: selected ? AppColors.orange : AppColors.dark, fontSize: selected ? 17 : 16, fontWeight: FontWeight.w900),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(height: 7),
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              width: selected ? 70 : 18,
              height: 4,
              decoration: BoxDecoration(color: selected ? AppColors.orange : Colors.transparent, borderRadius: BorderRadius.circular(20)),
            ),
          ],
        ),
      ),
    );
  }
}



class DarkProductTile extends StatelessWidget {
  const DarkProductTile({super.key, required this.product, required this.onTap});
  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedTapScale(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2A2A2A)),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 7))],
        ),
        child: Row(
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.asset(product.image, width: 92, height: 82, fit: BoxFit.cover)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(product.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  const SizedBox(height: 8),
                  Text('\$${product.smallPrice.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.orange, fontSize: 17, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: .92, end: 1),
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutBack,
              builder: (_, value, child) => Transform.scale(scale: value, child: child),
              child: const Icon(Icons.add_circle, color: AppColors.orange, size: 34),
            ),
          ],
        ),
      ),
    );
  }
}



class LightProductTile extends StatelessWidget {
  const LightProductTile({super.key, required this.product, required this.onTap});
  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedTapScale(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8E8E8)),
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 6))],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
              child: Image.asset(product.image, width: 118, height: 102, fit: BoxFit.cover),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.dark, fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(product.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.grey)),
                  const SizedBox(height: 8),
                  Text('\$${product.smallPrice.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.dark, fontSize: 18, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: .9, end: 1),
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeOutBack,
              builder: (_, value, child) => Transform.scale(scale: value, child: child),
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: AppColors.orange, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.orange.withOpacity(.28), blurRadius: 15, offset: const Offset(0, 7))]),
                child: const Icon(Icons.add, color: AppColors.white, size: 32),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class ProductMiniCard extends StatelessWidget {
  const ProductMiniCard({super.key, required this.product, required this.onTap});
  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedTapScale(
      onTap: onTap,
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF292929)),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 7))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(18)), child: Image.asset(product.image, width: 150, height: 95, fit: BoxFit.cover)),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text('\$${product.smallPrice.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class CartTile extends StatelessWidget {
  const CartTile({super.key, required this.item, required this.onChanged, required this.onRemove});
  final CartItem item;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF292929))),
      child: Row(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.asset(item.product.image, width: 76, height: 76, fit: BoxFit.cover)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('${item.size}${item.extras.isEmpty ? '' : ' · ${item.extras.join(', ')}'}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                const SizedBox(height: 8),
                Text('\$${item.total.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          Column(
            children: [
              QuantityMini(icon: Icons.add, onTap: () { item.quantity++; onChanged(); }),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Text('${item.quantity}', style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w900)),
              ),
              QuantityMini(icon: item.quantity == 1 ? Icons.delete_outline : Icons.remove, onTap: () { if (item.quantity == 1) { onRemove(); } else { item.quantity--; onChanged(); } }),
            ],
          ),
        ],
      ),
    );
  }
}

class QuantityButton extends StatelessWidget {
  const QuantityButton({super.key, required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, color: AppColors.white),
      ),
    );
  }
}

class QuantityMini extends StatelessWidget {
  const QuantityMini({super.key, required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(color: AppColors.orange, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppColors.white, size: 18),
      ),
    );
  }
}

class PriceRow extends StatelessWidget {
  const PriceRow({super.key, required this.label, required this.value, this.big = false});
  final String label;
  final double value;
  final bool big;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: big ? AppColors.white : Colors.white60, fontSize: big ? 18 : 14, fontWeight: big ? FontWeight.w900 : FontWeight.w600)),
          Text('\$${value.toStringAsFixed(2)}', style: TextStyle(color: big ? AppColors.orange : Colors.white70, fontSize: big ? 22 : 15, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, this.compact = false});
  final RofloOrder order;
  final bool compact;

  bool reached(String step) {
    const orderSteps = ['Recibido', 'En cocina', 'En camino', 'Entregado'];
    final currentIndex = orderSteps.indexOf(order.status);
    final stepIndex = orderSteps.indexOf(step);
    if (currentIndex < 0 || stepIndex < 0) return false;
    return currentIndex >= stepIndex;
  }

  @override
  Widget build(BuildContext context) {
    final delivered = order.status == 'Entregado';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: delivered ? AppColors.green.withOpacity(.45) : const Color(0xFF292929)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.orange.withOpacity(.14), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.receipt_long_outlined, color: AppColors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pedido #${order.id}', style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                    Text('${order.clientName} · Pago: ${order.paymentMethod}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white60)),
                    const SizedBox(height: 3),
                    Text('Entrega: ${order.deliveryAddress}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
              Text('\$${order.total.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.orange, fontSize: 18, fontWeight: FontWeight.w900)),
            ],
          ),
          if (deliveryMapUriFromText(order.deliveryAddress) != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => openExternalUri(context, deliveryMapUriFromText(order.deliveryAddress)!, order.deliveryAddress),
                icon: const Icon(Icons.map_outlined, color: AppColors.orange),
                label: const Text('VER UBICACIÓN EN MAPA', style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w900, fontSize: 12)),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: delivered ? AppColors.green.withOpacity(.18) : AppColors.orange.withOpacity(.16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              order.status,
              style: TextStyle(color: delivered ? AppColors.green : AppColors.orange, fontWeight: FontWeight.w900, fontSize: 12),
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 10),
            const Text(
              'Seguimiento informativo: el estado se actualiza desde el panel del administrador.',
              style: TextStyle(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 14),
            Text(order.items.map((item) => '${item.quantity}x ${item.product.name}').join('\n'), style: const TextStyle(color: Colors.white70, height: 1.4)),
            const SizedBox(height: 14),
            AnimatedStatusProgress(status: order.status),
          ],
        ],
      ),
    );
  }
}

class StepPill extends StatelessWidget {
  const StepPill({super.key, required this.label, required this.active});
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? AppColors.orange : const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: active ? AppColors.white : Colors.white54, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }
}

class StepLine extends StatelessWidget {
  const StepLine({super.key, required this.label, required this.active, this.last = false});
  final String label;
  final bool active;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(width: 16, height: 16, decoration: BoxDecoration(color: active ? AppColors.orange : Colors.white24, shape: BoxShape.circle)),
            if (!last) Container(width: 2, height: 28, color: active ? AppColors.orange : Colors.white24),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(bottom: 22),
          child: Text(label, style: TextStyle(color: active ? AppColors.white : Colors.white54, fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}



Future<void> openExternalUri(BuildContext context, Uri uri, String fallbackText) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      await Clipboard.setData(ClipboardData(text: fallbackText));
      messenger.showSnackBar(const SnackBar(content: Text('No se pudo abrir. El dato fue copiado al portapapeles.')));
    }
  } catch (_) {
    await Clipboard.setData(ClipboardData(text: fallbackText));
    messenger.showSnackBar(const SnackBar(content: Text('No se pudo abrir. El dato fue copiado al portapapeles.')));
  }
}

Uri? deliveryMapUriFromText(String text) {
  final match = RegExp(r'GPS:\s*(-?\d+(?:\.\d+)?),\s*(-?\d+(?:\.\d+)?)').firstMatch(text);
  if (match == null) return null;
  final lat = match.group(1);
  final lng = match.group(2);
  if (lat == null || lng == null) return null;
  return Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
}

class AddressSelector extends StatelessWidget {
  const AddressSelector({
    super.key,
    required this.selectedAddress,
    required this.onChanged,
    required this.onManage,
  });

  final String selectedAddress;
  final ValueChanged<String?> onChanged;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final addresses = RofloStore.addresses;
    if (addresses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF292929)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.location_off_outlined, color: AppColors.orange),
                SizedBox(width: 10),
                Expanded(
                  child: Text('No hay dirección registrada', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Agrega una dirección para poder confirmar el pedido.', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 12),
            AnimatedTapScale(
              onTap: onManage,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: AppColors.orange, borderRadius: BorderRadius.circular(14)),
                child: const Text('AGREGAR DIRECCIÓN', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      );
    }

    final values = addresses.map((address) => address.deliveryText).toList();
    final currentValue = values.contains(selectedAddress) ? selectedAddress : values.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF292929)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, color: AppColors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currentValue,
                dropdownColor: AppColors.card,
                iconEnabledColor: AppColors.orange,
                isExpanded: true,
                style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700),
                items: addresses
                    .map(
                      (address) => DropdownMenuItem<String>(
                        value: address.deliveryText,
                        child: Text(address.deliveryText, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
          IconButton(
            onPressed: onManage,
            icon: const Icon(Icons.edit_location_alt_outlined, color: AppColors.orange),
            tooltip: 'Administrar direcciones',
          ),
        ],
      ),
    );
  }
}

class AddressBookScreen extends StatefulWidget {
  const AddressBookScreen({super.key});

  @override
  State<AddressBookScreen> createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends State<AddressBookScreen> {
  Future<Position?> getCurrentGpsPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activa el GPS o la ubicación del dispositivo.')),
        );
        await Geolocator.openLocationSettings();
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permiso de ubicación denegado.')),
        );
        return null;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permiso bloqueado. Actívalo desde ajustes de la app.')),
        );
        await Geolocator.openAppSettings();
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (_) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo obtener la ubicación. Revisa permisos y conexión.')),
      );
      return null;
    }
  }

  Future<String?> getReadableAddressFromGps(Position position) async {
    try {
      final places = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (places.isEmpty) return null;
      final place = places.first;
      final parts = <String?>[
        place.street,
        place.subLocality,
        place.locality,
        place.subAdministrativeArea,
        place.administrativeArea,
        place.country,
      ]
          .whereType<String>()
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList();
      if (parts.isEmpty) return null;
      return parts.join(', ');
    } catch (_) {
      return null;
    }
  }

  void openAddressForm({RofloAddress? address}) {
    final alias = TextEditingController(text: address?.alias ?? 'Casa');
    final street = TextEditingController(text: address?.street ?? '');
    final reference = TextEditingController(text: address?.reference ?? '');
    final phone = TextEditingController(text: address?.phone ?? '0985985820');
    double? latitude = address?.latitude;
    double? longitude = address?.longitude;
    bool isDefault = address?.isDefault ?? RofloStore.addresses.isEmpty;
    bool locating = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, dialogSetState) {
          final hasGps = latitude != null && longitude != null;
          final mapUri = hasGps
              ? Uri.parse('https://www.google.com/maps/search/?api=1&query=${latitude!.toStringAsFixed(6)},${longitude!.toStringAsFixed(6)}')
              : null;

          return AlertDialog(
            backgroundColor: AppColors.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(
              address == null ? 'Agregar dirección' : 'Editar dirección',
              style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w900),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RofloTextField(controller: alias, label: 'Alias: Casa, Trabajo, Local', icon: Icons.bookmark_outline, dark: true),
                  const SizedBox(height: 10),
                  RofloTextField(controller: street, label: 'Dirección de entrega', icon: Icons.location_on_outlined, dark: true),
                  const SizedBox(height: 10),
                  RofloTextField(controller: reference, label: 'Referencia', icon: Icons.route_outlined, dark: true),
                  const SizedBox(height: 10),
                  RofloTextField(controller: phone, label: 'Teléfono de contacto', icon: Icons.phone_outlined, dark: true, keyboard: TextInputType.phone),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.black,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: hasGps ? AppColors.green.withOpacity(.45) : AppColors.orange.withOpacity(.30)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(hasGps ? Icons.gps_fixed : Icons.gps_not_fixed, color: hasGps ? AppColors.green : AppColors.orange),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                hasGps ? 'Ubicación GPS guardada' : 'Ubicación GPS opcional',
                                style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          hasGps
                              ? 'Ubicación actual: ${street.text.trim().isEmpty ? 'Dirección detectada por GPS' : street.text.trim()}\nGPS: ${latitude!.toStringAsFixed(6)} · ${longitude!.toStringAsFixed(6)}'
                              : 'Puedes tomar la ubicación actual para que el repartidor encuentre la calle exacta en el mapa.',
                          style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.35),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ElevatedButton.icon(
                              onPressed: locating
                                  ? null
                                  : () async {
                                      dialogSetState(() => locating = true);
                                      final position = await getCurrentGpsPosition();
                                      if (!mounted) return;
                                      if (position != null) {
                                        final readableAddress = await getReadableAddressFromGps(position);
                                        dialogSetState(() {
                                          latitude = position.latitude;
                                          longitude = position.longitude;
                                          if (readableAddress != null && readableAddress.trim().isNotEmpty) {
                                            street.text = readableAddress.trim();
                                          }
                                        });
                                        ScaffoldMessenger.of(this.context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              readableAddress == null
                                                  ? 'GPS capturado. En APK Android puede mostrar calles con mejor precisión.'
                                                  : 'Ubicación actual detectada: ${readableAddress.trim()}',
                                            ),
                                          ),
                                        );
                                      }
                                      dialogSetState(() => locating = false);
                                    },
                              icon: locating
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                                  : const Icon(Icons.my_location_outlined, color: AppColors.white, size: 18),
                              label: Text(locating ? 'LOCALIZANDO...' : 'USAR MI GPS', style: const TextStyle(fontWeight: FontWeight.w900)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.orange,
                                foregroundColor: AppColors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                            if (mapUri != null)
                              OutlinedButton.icon(
                                onPressed: () => openExternalUri(dialogContext, mapUri, '${latitude!.toStringAsFixed(6)},${longitude!.toStringAsFixed(6)}'),
                                icon: const Icon(Icons.map_outlined, color: AppColors.orange, size: 18),
                                label: const Text('VER MAPA', style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w900)),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: AppColors.orange.withOpacity(.55)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            if (hasGps)
                              TextButton.icon(
                                onPressed: () => dialogSetState(() {
                                  latitude = null;
                                  longitude = null;
                                }),
                                icon: const Icon(Icons.close, color: AppColors.red, size: 18),
                                label: const Text('QUITAR GPS', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w900)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  CheckboxListTile(
                    value: isDefault,
                    onChanged: (value) => dialogSetState(() => isDefault = value ?? false),
                    activeColor: AppColors.orange,
                    checkColor: AppColors.white,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Usar como dirección principal', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('CANCELAR', style: TextStyle(color: Colors.white60, fontWeight: FontWeight.w800)),
              ),
              TextButton(
                onPressed: () {
                  if (street.text.trim().isEmpty) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(content: Text('Escribe la dirección de entrega.')),
                    );
                    return;
                  }
                  setState(() {
                    if (isDefault) {
                      for (final saved in RofloStore.addresses) {
                        saved.isDefault = false;
                      }
                    }
                    if (address == null) {
                      RofloStore.addresses.add(
                        RofloAddress(
                          id: RofloStore.nextAddressId++,
                          alias: alias.text.trim().isEmpty ? 'Dirección' : alias.text.trim(),
                          street: street.text.trim(),
                          reference: reference.text.trim(),
                          phone: phone.text.trim(),
                          latitude: latitude,
                          longitude: longitude,
                          isDefault: isDefault || RofloStore.addresses.isEmpty,
                        ),
                      );
                    } else {
                      address.alias = alias.text.trim().isEmpty ? 'Dirección' : alias.text.trim();
                      address.street = street.text.trim();
                      address.reference = reference.text.trim();
                      address.phone = phone.text.trim();
                      address.latitude = latitude;
                      address.longitude = longitude;
                      address.isDefault = isDefault;
                    }
                  });
                  RofloStore.saveData();
                  Navigator.pop(dialogContext);
                },
                child: const Text('GUARDAR', style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w900)),
              ),
            ],
          );
        },
      ),
    );
  }

  void deleteAddress(RofloAddress address) {
    setState(() {
      RofloStore.addresses.remove(address);
      if (RofloStore.addresses.isNotEmpty && !RofloStore.addresses.any((item) => item.isDefault)) {
        RofloStore.addresses.first.isDefault = true;
      }
    });
    RofloStore.saveData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dirección eliminada.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final addresses = [...RofloStore.addresses]..sort((a, b) {
      if (a.isDefault == b.isDefault) return 0;
      return a.isDefault ? -1 : 1;
    });
    return DarkPage(
      title: 'Mis direcciones',
      subtitle: 'Agrega direcciones y guarda la ubicación exacta con GPS',
      showBack: true,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
        children: [
          RofloButton(label: 'AGREGAR NUEVA DIRECCIÓN', icon: Icons.add_location_alt_outlined, onPressed: () => openAddressForm()),
          const SizedBox(height: 16),
          if (addresses.isEmpty)
            const EmptyState(icon: Icons.location_off_outlined, title: 'Sin direcciones', text: 'Agrega una dirección para entregar tus pedidos.'),
          ...addresses.map(
            (address) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: address.isDefault ? AppColors.orange.withOpacity(.55) : const Color(0xFF292929)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.orange.withOpacity(.13), borderRadius: BorderRadius.circular(16)),
                    child: Icon(address.hasGps ? Icons.gps_fixed : Icons.location_on_outlined, color: address.hasGps ? AppColors.green : AppColors.orange),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(child: Text(address.alias, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w900, fontSize: 16))),
                            if (address.isDefault) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: AppColors.orange.withOpacity(.18), borderRadius: BorderRadius.circular(20)),
                                child: const Text('Principal', style: TextStyle(color: AppColors.orange, fontSize: 11, fontWeight: FontWeight.w900)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(address.street, style: const TextStyle(color: Colors.white70)),
                        if (address.reference.trim().isNotEmpty)
                          Text(address.reference, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        Text('Tel: ${address.phone}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                        if (address.hasGps) ...[
                          const SizedBox(height: 6),
                          Text(address.gpsText, style: const TextStyle(color: AppColors.green, fontSize: 12, fontWeight: FontWeight.w800)),
                          TextButton.icon(
                            onPressed: () => openExternalUri(context, address.mapsUri!, address.gpsText),
                            icon: const Icon(Icons.map_outlined, color: AppColors.orange, size: 18),
                            label: const Text('VER EN MAPA', style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w900, fontSize: 12)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(onPressed: () => openAddressForm(address: address), icon: const Icon(Icons.edit_outlined, color: AppColors.orange)),
                      IconButton(onPressed: () => deleteAddress(address), icon: const Icon(Icons.delete_outline, color: AppColors.red)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  static const String supportEmail = 'jeffoloquito@gmail.com';
  static const String supportPhone = '0985985820';
  static const String whatsappInternational = '593985985820';

  Future<void> openLink(BuildContext context, Uri uri, String fallbackText) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await Clipboard.setData(ClipboardData(text: fallbackText));
        messenger.showSnackBar(const SnackBar(content: Text('No se pudo abrir. El dato fue copiado al portapapeles.')));
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: fallbackText));
      messenger.showSnackBar(const SnackBar(content: Text('No se pudo abrir. El dato fue copiado al portapapeles.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final emailUri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      queryParameters: {
        'subject': 'Soporte ROFLO Cheesy Nach',
        'body': 'Hola ROFLO, necesito ayuda con mi pedido.',
      },
    );
    final whatsappUri = Uri.parse('https://wa.me/$whatsappInternational?text=${Uri.encodeComponent('Hola ROFLO, necesito soporte con mi pedido.')}');

    return DarkPage(
      title: 'Soporte ROFLO',
      subtitle: 'Comunícate con el negocio por correo o WhatsApp',
      showBack: true,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.orange.withOpacity(.35)),
              boxShadow: [BoxShadow(color: AppColors.orange.withOpacity(.10), blurRadius: 24, offset: const Offset(0, 12))],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.support_agent_outlined, color: AppColors.orange, size: 38),
                SizedBox(height: 12),
                Text('¿Necesitas ayuda con tu pedido?', style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                SizedBox(height: 6),
                Text('Escríbenos y te ayudamos con el estado del pedido, pagos, cambios de dirección o cualquier consulta.', style: TextStyle(color: Colors.white60, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SupportContactCard(
            icon: Icons.email_outlined,
            title: 'Correo de soporte',
            value: supportEmail,
            buttonText: 'ENVIAR CORREO',
            onTap: () => openLink(context, emailUri, supportEmail),
          ),
          SupportContactCard(
            icon: Icons.chat_outlined,
            title: 'WhatsApp de soporte',
            value: supportPhone,
            buttonText: 'ABRIR WHATSAPP',
            onTap: () => openLink(context, whatsappUri, supportPhone),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nota: en Android real abrirá la aplicación de correo o WhatsApp si está instalada. En navegador puede abrir una pestaña nueva.',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class SupportContactCard extends StatelessWidget {
  const SupportContactCard({super.key, required this.icon, required this.title, required this.value, required this.buttonText, required this.onTap});
  final IconData icon;
  final String title;
  final String value;
  final String buttonText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFF292929))),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.orange.withOpacity(.13), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: AppColors.orange),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: Colors.white60)),
                const SizedBox(height: 10),
                AnimatedTapScale(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: AppColors.orange, borderRadius: BorderRadius.circular(14)),
                    child: Text(buttonText, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileOption extends StatelessWidget {
  const ProfileOption({super.key, required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFF292929))),
        child: Row(
          children: [
            Icon(icon, color: AppColors.orange),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w900)),
                  Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}

class AdminMetric extends StatelessWidget {
  const AdminMetric({super.key, required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 105,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF292929))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: AppColors.orange, size: 24),
          Text(value, style: const TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        ],
      ),
    );
  }
}

class AdminActionCard extends StatelessWidget {
  const AdminActionCard({super.key, required this.icon, required this.title, required this.text, required this.button, required this.onTap});
  final IconData icon;
  final String title;
  final String text;
  final String button;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(colors: [Color(0xFF1C1C1C), Color(0xFF111111)]),
            border: Border.all(color: const Color(0xFF303030)),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(color: AppColors.orange.withOpacity(.15), borderRadius: BorderRadius.circular(18)),
                child: Icon(icon, color: AppColors.orange, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(text, style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.35)),
                    const SizedBox(height: 10),
                    Text(button, style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.orange),
            ],
          ),
        ),
      ),
    );
  }

}


class ClientCard extends StatelessWidget {
  const ClientCard({
    super.key,
    required this.client,
    required this.onEdit,
    required this.onDelete,
  });

  final RofloClient client;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF303030)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.person_outline, color: AppColors.orange),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.name,
                  style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                if (client.phone.trim().isNotEmpty)
                  Text(client.phone, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                if (client.address.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(client.address, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ),
                if (client.note.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(client.note, style: const TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic)),
                  ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                tooltip: 'Editar cliente',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, color: AppColors.orange),
              ),
              IconButton(
                tooltip: 'Eliminar cliente',
                onPressed: () => _confirmDelete(context),
                icon: const Icon(Icons.delete_outline, color: AppColors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Eliminar cliente', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w900)),
        content: Text('¿Deseas eliminar a ${client.name}?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child: const Text('ELIMINAR', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class AdminProductCard extends StatelessWidget {
  const AdminProductCard({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF303030)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              product.image,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 72,
                height: 72,
                color: const Color(0xFF252525),
                child: const Icon(Icons.fastfood_outlined, color: AppColors.orange),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w900),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: product.available ? AppColors.green.withOpacity(.16) : AppColors.red.withOpacity(.16),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        product.available ? 'Activo' : 'Inactivo',
                        style: TextStyle(
                          color: product.available ? AppColors.green : AppColors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(product.category, style: const TextStyle(color: AppColors.orange, fontSize: 12, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  product.description,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  'P: \$${product.smallPrice.toStringAsFixed(2)}   M: \$${product.mediumPrice.toStringAsFixed(2)}   G: \$${product.largePrice.toStringAsFixed(2)}',
                  style: const TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                tooltip: 'Editar producto',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, color: AppColors.orange),
              ),
              IconButton(
                tooltip: 'Eliminar producto',
                onPressed: () => _confirmDelete(context),
                icon: const Icon(Icons.delete_outline, color: AppColors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Eliminar producto', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w900)),
        content: Text('¿Deseas eliminar ${product.name}?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child: const Text('ELIMINAR', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.text});
  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      margin: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF292929))),
      child: Column(
        children: [
          Icon(icon, color: AppColors.orange, size: 52),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60, height: 1.35)),
        ],
      ),
    );
  }
}

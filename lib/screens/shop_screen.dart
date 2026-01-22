import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:juegotodosmienten/models/user_model.dart';
import 'package:juegotodosmienten/services/firestore_service.dart';
import 'package:juegotodosmienten/services/user_service.dart';

// Modelo para los datos de color del JSON
class ColorInfo {
  final String? name;
  final String type;
  final dynamic value;
  final int price;
  final List<double>? stops;

  ColorInfo({
    this.name,
    required this.type,
    required this.value,
    required this.price,
    this.stops,
  });

  factory ColorInfo.fromJson(Map<String, dynamic> json) {
    return ColorInfo(
      name: json['name'],
      type: json['type'] ?? 'solid',
      value: json['value'] ?? json['colors'],
      price: json['price'],
      stops: json.containsKey('stops')
          ? List<double>.from(json['stops'].map((x) => x.toDouble()))
          : null,
    );
  }
}

// Modelo para personajes
class Character {
  final String id;
  final String name;
  final String imagePath;
  final int price;
  final bool isUnlocked;

  Character({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.price,
    this.isUnlocked = false,
  });
}

class ShopScreen extends StatefulWidget {
  static const routeName = '/shop';
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = Provider.of<UserService>(context).currentUser;
    final backgroundImage = theme.brightness == Brightness.dark
        ? 'assets/img/Backgound_darkMode.png'
        : 'assets/img/Background_lightMode.png';

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Tienda',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black.withOpacity(0.8),
        elevation: 0,
        centerTitle: true,
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                children: [
                  Image.asset(
                    'assets/img/gold_coin.png',
                    width: 20,
                    height: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${user.goldCoins}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Image.asset(
                    'assets/img/bronze_coin.png',
                    width: 20,
                    height: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${user.bronzeCoins}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(backgroundImage),
            fit: BoxFit.cover,
          ),
        ),
        child: const SafeArea(child: _ShopCategoriesView()),
      ),
    );
  }
}

class _ShopCategoriesView extends StatefulWidget {
  const _ShopCategoriesView();

  @override
  State<_ShopCategoriesView> createState() => _ShopCategoriesViewState();
}

class _ShopCategoriesViewState extends State<_ShopCategoriesView>
    with TickerProviderStateMixin {
  final List<String> _categories = ['Personajes', 'Colores', 'Monedas'];
  int _selectedCategory = 0;
  Timer? _timer;
  Duration? _timeUntilRefresh;
  Map<String, List<ColorInfo>> _colorsData = {};

  @override
  void initState() {
    super.initState();
    _timeUntilRefresh = const Duration(hours: 2);
    _startTimer();
    _loadColorData();
  }

  Future<void> _loadColorData() async {
    final String response = await rootBundle.loadString(
      'assets/lang/colors.json',
    );
    final data = json.decode(response);
    final Map<String, List<ColorInfo>> loadedColors = {};
    (data['listcolors'] as Map<String, dynamic>).forEach((key, value) {
      loadedColors[key] = (value as List)
          .map((i) => ColorInfo.fromJson(i))
          .toList();
    });
    if (mounted) {
      setState(() {
        _colorsData = loadedColors;
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_timeUntilRefresh != null && _timeUntilRefresh!.inSeconds > 0) {
            _timeUntilRefresh = _timeUntilRefresh! - const Duration(seconds: 1);
          } else {
            _timeUntilRefresh = const Duration(hours: 2);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 60,
          color: Colors.black.withOpacity(0.6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_categories.length, (index) {
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = index),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _selectedCategory == index
                        ? Colors.blue.withOpacity(0.8)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _categories[index],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: _selectedCategory == index
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'La tienda se actualiza en: ${_formatDuration(_timeUntilRefresh!)}',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _selectedCategory,
            children: [
              _buildCharactersSection(),
              _buildColorsSection(),
              _buildCoinsSection(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCharactersSection() {
    final characters = [
      Character(
        id: 'char_1',
        name: 'Explorador',
        imagePath: 'assets/img/logo.png',
        price: 1000,
      ),
      Character(
        id: 'char_2',
        name: 'Guerrero',
        imagePath: 'assets/img/logo.png',
        price: 1500,
      ),
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: characters.length,
      itemBuilder: (context, index) =>
          CharacterShopItem(character: characters[index]),
    );
  }

  Widget _buildColorsSection() {
    if (_colorsData.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildColorCategory(
          title: 'Especiales',
          colorList: _colorsData['especiales'] ?? [],
        ),
        const SizedBox(height: 24),
        _buildColorCategory(
          title: 'Premium',
          colorList: _colorsData['premium'] ?? [],
        ),
        const SizedBox(height: 24),
        _buildColorCategory(
          title: 'Sólidos',
          colorList: _colorsData['solidos'] ?? [],
        ),
      ],
    );
  }

  Widget _buildCoinsSection() {
    final coinPackages = [
      {'coins': 100, 'price': '\$0.99', 'bonus': ''},
      {'coins': 300, 'price': '\$2.99', 'bonus': '+20% extra'},
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            'Paquetes de Monedas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        ...coinPackages.map((package) {
          return Card(
            color: Colors.black.withOpacity(0.5),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/img/gold_coin.png',
                    width: 30,
                    height: 30,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${package['coins']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              title: Text(
                package['bonus'].toString(),
                style: TextStyle(color: Colors.yellow[300], fontSize: 14),
              ),
              trailing: Text(
                package['price'].toString(),
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () => _showPurchaseDialog(context, package),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildColorCategory({
    required String title,
    required List<ColorInfo> colorList,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: colorList.length,
          itemBuilder: (context, index) =>
              ColorShopItem(colorInfo: colorList[index]),
        ),
      ],
    );
  }

  void _showPurchaseDialog(BuildContext context, Map<String, Object> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Compra'),
        content: Text(
          '¿Deseas comprar ${item['coins']} monedas por ${item['price']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              // Lógica de compra
              Navigator.of(ctx).pop();
            },
            child: const Text('Comprar'),
          ),
        ],
      ),
    );
  }
}

class CharacterShopItem extends StatelessWidget {
  final Character character;
  const CharacterShopItem({super.key, required this.character});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black.withOpacity(0.5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Image.asset(character.imagePath, fit: BoxFit.contain),
          ),
          Text(
            character.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              /* Lógica de compra */
            },
            icon: const Icon(Icons.shopping_cart, size: 14),
            label: Text('${character.price}'),
          ),
        ],
      ),
    );
  }
}

class ColorShopItem extends StatelessWidget {
  final ColorInfo colorInfo;

  const ColorShopItem({super.key, required this.colorInfo});

  Color _hexToColor(String hex) =>
      Color(int.parse(hex.substring(1, 7), radix: 16) + 0xFF000000);

  Gradient? _buildGradient() {
    List<Color> gradientColors = (colorInfo.value as List<dynamic>)
        .map((c) => _hexToColor(c))
        .toList();
    if (colorInfo.type == 'linear_gradient' ||
        colorInfo.type == 'flag_gradient') {
      return LinearGradient(colors: gradientColors, stops: colorInfo.stops);
    }
    if (colorInfo.type == 'radial_gradient') {
      return RadialGradient(colors: gradientColors, stops: colorInfo.stops);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Tooltip(
              message: colorInfo.name ?? '',
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorInfo.type == 'solid'
                      ? _hexToColor(colorInfo.value)
                      : null,
                  gradient: _buildGradient(),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              /* Lógica de compra */
            },
            icon: const Icon(Icons.shopping_cart, size: 14),
            label: Text('${colorInfo.price}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

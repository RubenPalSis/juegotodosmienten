import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/theme_service.dart';
import '../services/user_service.dart';
import '../utils/ui_helpers.dart';

class ShopScreen extends StatelessWidget {
  static const routeName = '/shop';

  const ShopScreen({super.key});

  void _exchangeCoins(BuildContext context, int bronze, int gold) async {
    final userService = Provider.of<UserService>(context, listen: false);
    final success = await userService.exchangeBronzeForGold(bronze, gold);

    if (success) {
      showCustomSnackBar(context, 'Intercambio realizado con éxito.');
    } else {
      showCustomSnackBar(
        context,
        'No tienes suficientes monedas de bronce.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final isDarkMode =
            themeService.themeMode == ThemeMode.dark ||
            (themeService.themeMode == ThemeMode.system &&
                MediaQuery.of(context).platformBrightness == Brightness.dark);

        final fabBackgroundColor = isDarkMode ? Colors.black : Colors.white;
        final fabIconColor = isDarkMode ? Colors.white : Colors.black;

        final backgroundImage = isDarkMode
            ? 'assets/img/Backgound_darkMode.png'
            : 'assets/img/Background_lightMode.png';

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Image.asset(
                backgroundImage,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24.0, 70.0, 24.0, 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildShopSection(
                        context,
                        title: 'Personajes',
                        items: List.generate(
                          6,
                          (index) => ShopItem(
                            name: 'Personaje ${index + 1}',
                            price: 100,
                            image: 'assets/img/character_placeholder.png',
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildShopSection(
                        context,
                        title: 'Colores',
                        items: List.generate(
                          3,
                          (index) => ShopItem(
                            name: 'Color ${index + 1}',
                            price: 50,
                            image: 'assets/img/color_placeholder.png',
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildShopSection(
                        context,
                        title: 'Accesorios',
                        items: List.generate(
                          4,
                          (index) => ShopItem(
                            name: 'Accesorio ${index + 1}',
                            price: 75,
                            image: 'assets/img/accessory_placeholder.png',
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildCoinExchangeSection(context),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 20,
                left: 20,
                child: FloatingActionButton(
                  onPressed: () => Navigator.of(context).pop(),
                  backgroundColor: fabBackgroundColor,
                  child: Icon(Icons.arrow_back, color: fabIconColor),
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: Consumer<UserService>(
                  builder: (context, userService, child) {
                    return Row(
                      children: [
                        _CoinDisplay(
                          icon: 'assets/img/bronze_coin.png',
                          amount: userService.currentUser?.bronzeCoins ?? 0,
                        ),
                        const SizedBox(width: 16),
                        _CoinDisplay(
                          icon: 'assets/img/gold_coin.png',
                          amount: userService.currentUser?.goldCoins ?? 0,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShopSection(
    BuildContext context, {
    required String title,
    required List<ShopItem> items,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: items
              .map((item) => _ShopItemCard(item: item, isDarkMode: isDarkMode))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildCoinExchangeSection(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monedas',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildExchangeOffer(
              context,
              bronze: 50,
              gold: 1,
              isDarkMode: isDarkMode,
            ),
            _buildExchangeOffer(
              context,
              bronze: 100,
              gold: 3,
              isDarkMode: isDarkMode,
            ),
            _buildExchangeOffer(
              context,
              bronze: 200,
              gold: 5,
              isDarkMode: isDarkMode,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExchangeOffer(
    BuildContext context, {
    required int bronze,
    required int gold,
    required bool isDarkMode,
  }) {
    return Card(
      color: isDarkMode
          ? Colors.black.withOpacity(0.4)
          : Colors.white.withOpacity(0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDarkMode ? Colors.white.withOpacity(0.5) : Colors.black,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/img/bronze_coin.png',
                  width: 24,
                  height: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '$bronze',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Icon(
              Icons.arrow_downward,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/img/gold_coin.png', width: 24, height: 24),
                const SizedBox(width: 8),
                Text(
                  '$gold',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _exchangeCoins(context, bronze, gold),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text('Canjear'),
            ),
          ],
        ),
      ),
    );
  }
}

class ShopItem {
  final String name;
  final int price;
  final String image;

  ShopItem({required this.name, required this.price, required this.image});
}

class _ShopItemCard extends StatelessWidget {
  final ShopItem item;
  final bool isDarkMode;

  const _ShopItemCard({required this.item, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isDarkMode
          ? Colors.black.withOpacity(0.4)
          : Colors.white.withOpacity(0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDarkMode ? Colors.white.withOpacity(0.5) : Colors.black,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(item.image, width: 60, height: 60),
          const SizedBox(height: 8),
          Text(
            item.name,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${item.price}',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(width: 4),
              Image.asset('assets/img/gold_coin.png', width: 16, height: 16),
            ],
          ),
        ],
      ),
    );
  }
}

class _CoinDisplay extends StatelessWidget {
  final String icon;
  final int amount;

  const _CoinDisplay({required this.icon, required this.amount});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.black.withOpacity(0.4)
            : Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode ? Colors.white.withOpacity(0.5) : Colors.black,
        ),
      ),
      child: Row(
        children: [
          Image.asset(icon, width: 24, height: 24),
          const SizedBox(width: 8),
          Text(
            '$amount',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

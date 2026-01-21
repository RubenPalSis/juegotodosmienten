import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:juegotodosmienten/models/user_model.dart';
import 'package:juegotodosmienten/services/firestore_service.dart';
import 'package:juegotodosmienten/services/user_service.dart';

class ShopScreen extends StatefulWidget {
  static const routeName = '/shop';
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = Provider.of<UserService>(context).currentUser;
    final backgroundImage = theme.brightness == Brightness.dark
        ? 'assets/img/Backgound_darkMode.png'
        : 'assets/img/Background_lightMode.png';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tienda'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (user != null)
            Row(
              children: [
                _CoinDisplay(icon: 'assets/img/gold_coin.png', amount: user.goldCoins),
                const SizedBox(width: 8),
                _CoinDisplay(icon: 'assets/img/bronze_coin.png', amount: user.bronzeCoins),
                const SizedBox(width: 16),
              ],
            )
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Personajes'),
            Tab(icon: Icon(Icons.color_lens), text: 'Colores'),
            Tab(icon: Icon(Icons.monetization_on), text: 'Monedas'),
          ],
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(image: AssetImage(backgroundImage), fit: BoxFit.cover),
        ),
        child: SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPlaceholderTab('Personajes'),
              const _ColorsShopView(),
              _buildPlaceholderTab('Monedas'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderTab(String title) {
    return Center(
      child: Text(
        'La sección de $title no está disponible.',
        style: const TextStyle(color: Colors.white, fontSize: 18),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Image.asset(icon, width: 20, height: 20),
          const SizedBox(width: 4),
          Text('$amount', style: const TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }
}

class _ColorsShopView extends StatefulWidget {
  const _ColorsShopView();

  @override
  State<_ColorsShopView> createState() => _ColorsShopViewState();
}

class _ColorsShopViewState extends State<_ColorsShopView> with SingleTickerProviderStateMixin {
  late TabController _colorTabController;

  @override
  void initState() {
    super.initState();
    _colorTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _colorTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _colorTabController,
          tabs: const [Tab(text: 'PREMIUM'), Tab(text: 'ESPECIALES')],
        ),
        Expanded(
          child: TabBarView(
            controller: _colorTabController,
            children: const [_PremiumColorsGrid(), _SpecialColorsGrid()],
          ),
        )
      ],
    );
  }
}

class _PremiumColorsGrid extends StatelessWidget {
  const _PremiumColorsGrid();

  static final List<Color> _premiumColors = List.generate(100, (index) => HSLColor.fromAHSL(1.0, (index * 3.6), 0.8, 0.6).toColor());
  static const int _colorCost = 50;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, crossAxisSpacing: 10, mainAxisSpacing: 10),
      itemCount: _premiumColors.length,
      itemBuilder: (context, index) {
        final color = _premiumColors[index];
        return _ColorShopItem(color: color, cost: _colorCost);
      },
    );
  }
}

class _SpecialColorsGrid extends StatelessWidget {
  const _SpecialColorsGrid();

  static const int _spainColorValue = 12345; // Special identifier
  static final spainColor = const Color(_spainColorValue);
  static final Map<Color, int> _specialColors = {spainColor: 50};

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, crossAxisSpacing: 10, mainAxisSpacing: 10),
      itemCount: _specialColors.length,
      itemBuilder: (context, index) {
        final color = _specialColors.keys.elementAt(index);
        final cost = _specialColors[color]!;
        return _ColorShopItem(color: color, cost: cost, isSpecial: true);
      },
    );
  }
}

class _ColorShopItem extends StatelessWidget {
  final Color color;
  final int cost;
  final bool isSpecial;

  const _ColorShopItem({required this.color, required this.cost, this.isSpecial = false});

  Future<void> _purchaseColor(BuildContext context) async {
    final userService = Provider.of<UserService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final currentUser = userService.currentUser;

    if (currentUser == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Compra'),
        content: Text('¿Deseas comprar este color por $cost monedas de oro?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Comprar')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await firestoreService.purchaseAndUnlockColor(currentUser.alias, color.value, cost);
        await userService.loadUser();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Color comprado!'), backgroundColor: Colors.green));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserService>(context).currentUser;
    final isUnlocked = user?.unlockedColors.contains(color.value) ?? false;

    return Card(
      color: Colors.black.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          isSpecial
              ? Container(
                  width: 50, height: 50, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1)),
                  child: const Center(child: Text('🇪🇸', style: TextStyle(fontSize: 30)))
              )
              : Container(width: 50, height: 50, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
          ElevatedButton.icon(
            onPressed: isUnlocked ? null : () => _purchaseColor(context),
            icon: Icon(isUnlocked ? Icons.check : Icons.shopping_cart, size: 16),
            label: Text(isUnlocked ? 'OK' : '$cost'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isUnlocked ? Colors.grey.shade700 : Colors.orange.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

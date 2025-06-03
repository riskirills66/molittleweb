import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';

// =============================================================================
// CONFIGURATION SECTION - Change these values as needed
// =============================================================================
class AppConfig {
  // API Base URLs
  static const String baseApiUrl = 'https://known-instantly-bison.ngrok-free.app';

  // Base Provider ID
  static String get baseProviderId {
    // Try to get the current path from the browser address bar (Flutter web only)
    final path = Uri.base.pathSegments.isNotEmpty ? Uri.base.pathSegments.first : '';
    switch (path.toLowerCase()) {
      case 'telkomsel':
        return 'telkomsel';
      case 'xlaxis':
        return 'xlaxis';
      case 'indosat':
        return 'indosat';
      case 'tri':
        return 'tri';
      default:
        return 'telkomsel';
    }
  }
  
  // API Endpoints
  static String get configEndpoint => '/config/$baseProviderId';
  static String get queryEndpoint => '/query/$baseProviderId';
  static String get inquiryEndpoint => '/inquiry/$baseProviderId';
  static const String orderEndpoint = '/order';
  
  // Full API URLs (constructed from base + endpoints)
  static String get configUrl => '$baseApiUrl$configEndpoint';
  static String get queryUrl => '$baseApiUrl$queryEndpoint';
  static String get inquiryUrl => '$baseApiUrl$inquiryEndpoint';
  static String getOrderUrl(String invId) => '$baseApiUrl$orderEndpoint/$invId';
  
  // Default App Configuration
  static const Map<String, dynamic> defaultConfig = {
    "theme": {
      "primaryColor": "#d0010d",
      "backgroundColor": "#d0010d",
      "surfaceColor": "#F5F5DC",
      "onPrimaryColor": "#FFFFFF",
      "onSurfaceColor": "#000000",
      "accentColor": "#FF3A2C",
      "errorColor": "#D32F2F",
      "successColor": "#388E3C",
      "activeColor": "#e73b29"
    },
    "buttons": [
      {"label": "Paket Terbaik", "listType": "listTerbaik", "category": "DATA"},
      {"label": "Paket Data", "listType": "list_product", "category": "DATA"},
      {"label": "Roaming Terbaik", "listType": "listTerbaik", "category": "ROAMING"},
      {"label": "Nelpon Terbaik", "listType": "listTerbaik", "category": "VOICE_SMS"},
      {"label": "Paket Nelpon & SMS", "listType": "listVoiceSMS", "category": null},
      {"label": "Digital & Game", "listType": "listTerbaik", "category": "DIGITAL_GAME"}
    ]
  };
  
  // App Settings
  static const String appTitle = 'Sale All Provider';
  static const String homePageTitle = 'Sale All Provider';
  static const String phoneInputHint = 'Masukkan Nomor';
  static const int maxPhoneLength = 15;
  
  // Default Values
  static const String defaultCategory = 'DATA';
  static const String defaultListType = 'listTerbaik';
  
  // UI Constants
  static const Duration loadingAnimationDuration = Duration(milliseconds: 800);
  static const Duration minimumLoadingDelay = Duration(milliseconds: 1500);
  static const Duration snackBarDuration = Duration(seconds: 3);
  
  // HTTP Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
// =============================================================================

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 255, 58, 44)),
        scaffoldBackgroundColor: const Color.fromARGB(255, 165, 11, 0),
      ),
      home: const MyHomePage(title: AppConfig.homePageTitle),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _phoneController = TextEditingController();
  List<dynamic> _packages = [];
  List<dynamic> _filteredPackages = [];
  List<String> _subCategories = [];
  String? _selectedSubCategory;
  bool _isLoading = false;
  String _errorMessage = '';
  String _selectedCategory = AppConfig.defaultCategory;
  String _currentListType = AppConfig.defaultListType;
  
  // Configuration variables
  Map<String, dynamic> _config = {};
  List<dynamic> _buttons = [];
  bool _configLoaded = false;
  
  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }
  
  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadConfiguration() async {
    try {
      final dio = Dio();
      
      final response = await dio.post(
        AppConfig.configUrl,
        options: Options(headers: AppConfig.defaultHeaders),
        data: {},
      );
      
      if (response.statusCode == 200) {
        setState(() {
          _config = response.data;
          _buttons = _config['buttons'] ?? [];
          _configLoaded = true;
        });
      } else {
        _useDefaultConfig();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load configuration: $e'),
            backgroundColor: Colors.orange,
            duration: AppConfig.snackBarDuration,
          ),
        );
      }
      _useDefaultConfig();
    }
  }

  void _useDefaultConfig() {
    setState(() {
      _config = AppConfig.defaultConfig;
      _buttons = _config['buttons'] ?? [];
      _configLoaded = true;
    });
  }

  Color _getColorFromHex(String hexColor) {
    try {
      final color = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$color', radix: 16));
    } catch (e) {
      return Colors.red; // fallback color
    }
  }

  Color get _primaryColor => _getColorFromHex(_config['theme']?['primaryColor'] ?? '#d0010d');
  Color get _backgroundColor => _getColorFromHex(_config['theme']?['backgroundColor'] ?? '#d0010d');
  Color get _surfaceColor => _getColorFromHex(_config['theme']?['surfaceColor'] ?? '#F5F5DC');
  Color get _activeColor => _getColorFromHex(_config['theme']?['activeColor'] ?? '#e73b29');

  bool _isButtonActive(dynamic button) {
    final buttonListType = button['listType'];
    final buttonCategory = button['category'];
    
    if (buttonCategory == null && buttonListType == 'listVoiceSMS') {
      return _currentListType == 'listVoiceSMS';
    }
    
    return _currentListType == buttonListType && _selectedCategory == buttonCategory;
  }

  void _onButtonPressed(dynamic button) {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon masukkan nomor telepon')),
      );
      return;
    }

    final buttonListType = button['listType'];
    final buttonCategory = button['category'];

    setState(() {
      _currentListType = buttonListType;
      if (buttonCategory != null) {
        _selectedCategory = buttonCategory;
      }
    });

    if (buttonListType == 'listVoiceSMS' && buttonCategory == null) {
      _fetchPackagesWithVoiceSMS();
    } else {
      _fetchPackages();
    }
  }

  Future<void> _fetchPackages({String? listType}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _packages = [];
      _filteredPackages = [];
      _subCategories = [];
      _selectedSubCategory = null;
      if (listType != null) {
        _currentListType = listType;
      }
    });
    
    try {
      final dio = Dio();
      
      final response = await dio.post(
        AppConfig.queryUrl,
        options: Options(headers: AppConfig.defaultHeaders),
        data: {
          'number': _phoneController.text,
          'list': _currentListType,
          'category': _selectedCategory,
        },
      );
      
      if (response.statusCode == 200) {
        // Extract unique sub-categories
        final Set<String> uniqueSubCategories = {};
        for (var package in response.data) {
          if (package['product_sub_category'] != null) {
            uniqueSubCategories.add(package['product_sub_category'].toString());
          }
        }
        
        setState(() {
          _packages = response.data;
          _subCategories = uniqueSubCategories.toList();
          
          // Set default selected category if available
          if (_subCategories.isNotEmpty) {
            _selectedSubCategory = _subCategories.first;
            _filterPackages(_selectedSubCategory!);
          } else {
            _filteredPackages = _packages;
          }
          
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Error: ${response.statusCode} - ${response.data}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
        _isLoading = false;
      });
    }
  }
  
  void _filterPackages(String subCategory) {
    setState(() {
      _selectedSubCategory = subCategory;
      _filteredPackages = _packages.where((package) => 
        package['product_sub_category'] == subCategory).toList();
    });
  }

  void _fetchPackagesWithVoiceSMS() {
    if (_phoneController.text.isNotEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
        _packages = [];
        _filteredPackages = [];
        _subCategories = [];
        _selectedSubCategory = null;
        _currentListType = 'listVoiceSMS';
      });
      
      try {
        final dio = Dio();
        
        dio.post(
          AppConfig.queryUrl,
          options: Options(headers: AppConfig.defaultHeaders),
          data: {
            'number': _phoneController.text,
            'list': 'listVoiceSMS',
          },
        ).then((response) {
          if (response.statusCode == 200) {
            // Extract unique sub-categories
            final Set<String> uniqueSubCategories = {};
            for (var package in response.data) {
              if (package['product_sub_category'] != null) {
                uniqueSubCategories.add(package['product_sub_category'].toString());
              }
            }
            
            setState(() {
              _packages = response.data;
              _subCategories = uniqueSubCategories.toList();
              
              // Set default selected category if available
              if (_subCategories.isNotEmpty) {
                _selectedSubCategory = _subCategories.first;
                _filterPackages(_selectedSubCategory!);
              } else {
                _filteredPackages = _packages;
              }
              
              _isLoading = false;
            });
          } else {
            setState(() {
              _errorMessage = 'Error: ${response.statusCode} - ${response.data}';
              _isLoading = false;
            });
          }
        }).catchError((e) {
          setState(() {
            _errorMessage = 'Network error: $e';
            _isLoading = false;
          });
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'Network error: $e';
          _isLoading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon masukkan nomor telepon')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_configLoaded) {
      return Scaffold(
        backgroundColor: _backgroundColor,
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // Red background section
          Container(
            color: _backgroundColor,
            padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 20.0),
            child: Column(
              children: [
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(20.0)),
                      borderSide: BorderSide(color: _primaryColor),
                    ),
                    hintText: AppConfig.phoneInputHint,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 15.0),
                      child: Icon(Icons.phone),
                    ),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                        _phoneController.clear();
                        _packages = [];
                        _filteredPackages = [];
                        _subCategories = [];
                        _selectedSubCategory = null;
                        _isLoading = false;
                        _errorMessage = '';
                        _selectedCategory = AppConfig.defaultCategory;
                        _currentListType = AppConfig.defaultListType;
                        });
                      },
                      padding: const EdgeInsets.all(8.0),
                      constraints: const BoxConstraints(),
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(AppConfig.maxPhoneLength),
                  ],
                ),
                const SizedBox(height: 10),
                // Dynamic scrollable row of buttons
                SizedBox(
                  height: 40,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _buttons.map<Widget>((button) {
                        final isActive = _isButtonActive(button);
                        
                        return Padding(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isActive ? _activeColor : Colors.white,
                              foregroundColor: isActive ? Colors.white : _primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 24.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: () => _onButtonPressed(button),
                            child: Text(button['label'] ?? ''),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Cream background section for subcategories and content
          Expanded(
            child: Container(
              color: _surfaceColor,
              child: _isLoading || _errorMessage.isNotEmpty || _filteredPackages.isNotEmpty || _subCategories.isNotEmpty
      ? SingleChildScrollView(
          child: Column(
            children: [
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Animated loading header
                      TweenAnimationBuilder(
                        duration: AppConfig.loadingAnimationDuration,
                        tween: Tween<double>(begin: 0, end: 1),
                        builder: (context, double value, child) {
                          return Opacity(
                            opacity: value,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.signal_cellular_alt,
                                  color: _primaryColor.withValues(alpha: value),
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Mencari paket terbaik...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: _primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      // Shimmer skeleton cards
                      ...List.generate(3, (index) => _buildShimmerCard(index)),
                      // Animated dots indicator
                      const SizedBox(height: 16),
                      TweenAnimationBuilder(
                        duration: const Duration(milliseconds: 1000),
                        tween: Tween<double>(begin: 0, end: 1),
                        builder: (context, double value, child) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildLoadingDot(value > 0.2, 0),
                              const SizedBox(width: 8),
                              _buildLoadingDot(value > 0.5, 100),
                              const SizedBox(width: 8),
                              _buildLoadingDot(value > 0.8, 200),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: _getColorFromHex(_config['theme']?['errorColor'] ?? '#D32F2F')),
                  ),
                ),
              if (_subCategories.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Container(
                    height: 30,
                    alignment: Alignment.center,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _subCategories.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      clipBehavior: Clip.none,
                      itemBuilder: (context, index) {
                        final subCategory = _subCategories[index];
                        final isSelected = _selectedSubCategory == subCategory;

                        return Padding(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: Center(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSelected ? _activeColor : Colors.white,
                                foregroundColor: isSelected ? Colors.white : _primaryColor,
                                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: isSelected
                                    ? BorderSide.none
                                    : BorderSide(
                                      color: _primaryColor,
                                      width: 1.0,
                                      ),
                                ),
                                visualDensity: VisualDensity.compact,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                fixedSize: const Size.fromHeight(36),
                                elevation: 0,
                              ),
                              onPressed: () => _filterPackages(subCategory),
                              child: Text(subCategory),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              if (_filteredPackages.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      ..._filteredPackages.map((package) => PackageCard(
                        package: package,
                        phoneNumber: _phoneController.text,
                        currentListType: _currentListType,
                        selectedCategory: _selectedCategory,
                        primaryColor: _primaryColor,
                        activeColor: _activeColor,
                      )),
                    ],
                  ),
                ),
            ],
          ),
        )
      : Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.phone_android,
                  size: 64,
                  color: _primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Masukkan nomor telepon dan pilih jenis paket',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: _primaryColor,
                  ),
                ),
                const SizedBox(height: 24),  
              ],
            ),
          ),
        ),
            ),
          ),
        ],
      ),
    );
  }

  // Update shimmer and loading dot methods to use dynamic colors
  Widget _buildShimmerCard(int index) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 600 + (index * 200)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _primaryColor,
                  width: 1.0,
                ),
                color: Colors.white,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShimmerBox(
                      width: 200 + (index * 30).toDouble(),
                      height: 20,
                      delay: index * 100,
                    ),
                    const SizedBox(height: 8),
                    _buildShimmerBox(
                      width: 150 + (index * 20).toDouble(),
                      height: 16,
                      delay: index * 100 + 50,
                    ),
                    const SizedBox(height: 4),
                    _buildShimmerBox(
                      width: 120,
                      height: 16,
                      delay: index * 100 + 100,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildShimmerBox(
                          width: 100,
                          height: 18,
                          delay: index * 100 + 150,
                        ),
                        _buildShimmerButton(delay: index * 100 + 200),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    required int delay,
  }) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 1500),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + delay),
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + (value * 2), 0),
              end: Alignment(1.0 + (value * 2), 0),
              colors: [
                Colors.grey[300]!,
                Colors.grey[100]!,
                Colors.grey[300]!,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerButton({required int delay}) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 800 + delay),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Container(
            width: 60,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(
                begin: Alignment(-1.0 + (value * 2), 0),
                end: Alignment(1.0 + (value * 2), 0),
                colors: [
                  _primaryColor.withValues(alpha: 0.3),
                  _primaryColor.withValues(alpha: 0.1),
                  _primaryColor.withValues(alpha: 0.3),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingDot(bool isActive, int delay) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 500 + delay),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isActive ? 12 : 8,
          height: isActive ? 12 : 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive 
              ? _primaryColor.withValues(alpha: value)
              : Colors.grey[300],
            boxShadow: isActive ? [
              BoxShadow(
                color: _primaryColor.withValues(alpha: 0.3 * value),
                spreadRadius: 2,
                blurRadius: 4,
              ),
            ] : null,
          ),
        );
      },
    );
  }
}

class PackageCard extends StatelessWidget {
  final dynamic package;
  final String phoneNumber;
  final String currentListType;
  final String selectedCategory;
  final Color primaryColor;
  final Color activeColor;

  const PackageCard({
    super.key, 
    required this.package,
    required this.phoneNumber,
    required this.currentListType,
    required this.selectedCategory,
    required this.primaryColor,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: primaryColor,
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              package['product_name'] ?? 'Nama Paket Tidak Tersedia',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              package['quota']?.toString().split(',').join('\n') ?? 'Tidak tersedia',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Harga: Rp ${_formatPrice(package['price'])}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activeColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    _buyPackage(context);
                  },
                  child: const Text('Beli'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _buyPackage(BuildContext context) async {
    try {
      // Show improved loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated shopping cart icon
                  TweenAnimationBuilder(
                    duration: const Duration(seconds: 1),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: 0.8 + (0.4 * value),
                        child: Icon(
                          Icons.shopping_cart,
                          size: 60,
                          color: primaryColor.withValues(alpha: value),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  // Animated loading indicator
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Animated text
                  TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 800),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, double value, child) {
                      return Opacity(
                        opacity: value,
                        child: const Text(
                          "Sedang memproses pembelian...",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  // Processing steps indicator
                  TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 1200),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, double value, child) {
                      return Opacity(
                        opacity: value,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildDot(value > 0.3),
                            const SizedBox(width: 8),
                            _buildDot(value > 0.6),
                            const SizedBox(width: 8),
                            _buildDot(value > 0.9),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );

      final dio = Dio();
      
      // Start both the API call and minimum delay simultaneously
      final apiCallFuture = dio.post(
        AppConfig.inquiryUrl,
        options: Options(headers: AppConfig.defaultHeaders),
        data: {
          'number': phoneNumber,
          'list': currentListType,
          'product_id': package['product_id'],
          'category': selectedCategory,
        },
      );

      final minimumDelayFuture = Future.delayed(AppConfig.minimumLoadingDelay);

      // Wait for both the API call and minimum delay to complete
      final results = await Future.wait([apiCallFuture, minimumDelayFuture]);
      final response = results[0] as Response;

      // Check if widget is still mounted before using context
      if (!context.mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      if (response.statusCode == 200) {
        // Directly open Telkomsel link with inv_id
        final invId = response.data['inv_id']?.toString() ?? '';
        final url = AppConfig.getOrderUrl(invId);
        
        try {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tidak dapat membuka link'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error membuka link: $e'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } else {
        // Check if widget is still mounted before using context
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${response.statusCode} - ${response.data}')),
          );
        }
      }
    } catch (e) {
      // Check if widget is still mounted before using context
      if (context.mounted) {
        // Close loading dialog
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error: $e')),
        );
      }
    }
  }

  Widget _buildDot(bool isActive) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? primaryColor : Colors.grey[300],
      ),
    );
  }
  
  String _formatPrice(dynamic price) {
    if (price == null) return '0';
    
    try {
      final priceInt = int.parse(price.toString());
      return priceInt.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match match) => '${match[1]}.',
      );
    } catch (e) {
      return price.toString();
    }
  }
}

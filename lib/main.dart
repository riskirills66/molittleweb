import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sale All Provider',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 255, 58, 44)),
        scaffoldBackgroundColor: const Color.fromARGB(255, 165, 11, 0),
      ),
      home: const MyHomePage(title: 'Sale All Provider'),
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
  String _selectedCategory = 'DATA'; // Default category
  String _currentListType = 'listTerbaik'; // Add this to track current list type
  
  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
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
      // final apiUrl = 'http://localhost:4444/query/telkomsel';
      final apiUrl = 'https://known-instantly-bison.ngrok-free.app/query/telkomsel';
      final dio = Dio();
      
      final response = await dio.post(
        apiUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
        data: {
          'number': _phoneController.text,
          'list': _currentListType, // Use the current list type
          'category': _selectedCategory, // Use the selected category
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

  // Add this method to fetch packages with a specific list type and category
  void _fetchPackagesWithType(String listType) {
    if (_phoneController.text.isNotEmpty) {
      _fetchPackages(listType: listType);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon masukkan nomor telepon')),
      );
    }
  }

  // Add this method to fetch packages for Voice_SMS category
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
        final apiUrl = 'https://known-instantly-bison.ngrok-free.app/query/telkomsel';
        final dio = Dio();
        
        dio.post(
          apiUrl,
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
          data: {
            'number': _phoneController.text,
            'list': 'listVoiceSMS',
            // No category parameter is sent
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
    return Scaffold(
      // Removed appBar completely
      body: Column(
        children: [
          // Red background section
          Container(
            color: const Color.fromARGB(255, 165, 11, 0),
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
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    hintText: 'Masukkan Nomor',
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
                        _selectedCategory = 'DATA';
                        _currentListType = 'listTerbaik';
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
                    LengthLimitingTextInputFormatter(15),
                  ],
                ),
                const SizedBox(height: 10),
                // Scrollable row of buttons
                SizedBox(
                  height: 40,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _currentListType == 'listTerbaik' && _selectedCategory == 'DATA'? Colors.red : Colors.white,
                            foregroundColor: _currentListType == 'listTerbaik' && _selectedCategory == 'DATA'? Colors.white : Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 24.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () {
                            if (_phoneController.text.isNotEmpty) {
                              setState(() {
                                _currentListType = 'listTerbaik';
                                _selectedCategory = 'DATA'; // Directly set category to DATA
                              });
                              _fetchPackages(); // Call fetchPackages directly instead of showing dialog
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Mohon masukkan nomor telepon')),
                              );
                            }
                          },
                          child: const Text('Paket Terbaik'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _currentListType == 'list_product' ? Colors.red : Colors.white,
                            foregroundColor: _currentListType == 'list_product' ? Colors.white : Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 24.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () {
                            _selectedCategory = 'DATA'; // Always use DATA category
                            _fetchPackagesWithType('list_product');
                          },
                          child: const Text('Paket Data'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (_currentListType == 'listTerbaik' && _selectedCategory == 'ROAMING') ? Colors.red : Colors.white,
                            foregroundColor: (_currentListType == 'listTerbaik' && _selectedCategory == 'ROAMING') ? Colors.white : Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 24.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () {
                            if (_phoneController.text.isNotEmpty) {
                              setState(() {
                                _currentListType = 'listTerbaik';
                                _selectedCategory = 'ROAMING';
                              });
                              _fetchPackages();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Mohon masukkan nomor telepon')),
                              );
                            }
                          },
                          child: const Text('Roaming Terbaik'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (_currentListType == 'listTerbaik' && _selectedCategory == 'VOICE_SMS') ? Colors.red : Colors.white,
                            foregroundColor: (_currentListType == 'listTerbaik' && _selectedCategory == 'VOICE_SMS') ? Colors.white : Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 24.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () {
                            if (_phoneController.text.isNotEmpty) {
                              setState(() {
                                _currentListType = 'listTerbaik';
                                _selectedCategory = 'VOICE_SMS';
                              });
                              _fetchPackages();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Mohon masukkan nomor telepon')),
                              );
                            }
                          },
                          child: const Text('Nelpon Terbaik'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _currentListType == 'listVoiceSMS' ? Colors.red : Colors.white,
                            foregroundColor: _currentListType == 'listVoiceSMS' ? Colors.white : Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 24.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () {
                            _fetchPackagesWithVoiceSMS();
                          },
                          child: const Text('Paket Nelpon & SMS'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (_currentListType == 'listTerbaik' && _selectedCategory == 'DIGITAL_GAME') ? Colors.red : Colors.white,
                            foregroundColor: (_currentListType == 'listTerbaik' && _selectedCategory == 'DIGITAL_GAME') ? Colors.white : Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 24.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () {
                            if (_phoneController.text.isNotEmpty) {
                              setState(() {
                                _currentListType = 'listTerbaik';
                                _selectedCategory = 'DIGITAL_GAME';
                              });
                              _fetchPackages();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Mohon masukkan nomor telepon')),
                              );
                            }
                          },
                          child: const Text('Digital & Game'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Cream background section for subcategories and content
          Expanded(
            child: Container(
              color: const Color(0xFFF5F5DC), // Cream color
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
                        duration: const Duration(milliseconds: 800),
                        tween: Tween<double>(begin: 0, end: 1),
                        builder: (context, double value, child) {
                          return Opacity(
                            opacity: value,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.signal_cellular_alt,
                                  color: Colors.red.withValues(alpha: value),
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Mencari paket terbaik...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Color.fromARGB(255, 165, 11, 0),
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
                    style: const TextStyle(color: Colors.red),
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
                                backgroundColor: isSelected ? Colors.red : Colors.white,
                                foregroundColor: isSelected ? Colors.white : Colors.red,
                                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: isSelected
                                    ? BorderSide.none
                                    : const BorderSide(
                                      color: Color.fromARGB(255, 165, 11, 0),
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
                const Icon(
                  Icons.phone_android,
                  size: 64,
                  color: Color.fromARGB(255, 165, 11, 0),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Masukkan nomor telepon dan pilih jenis paket',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color.fromARGB(255, 165, 11, 0),
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
  
}

class PackageCard extends StatelessWidget {
  final dynamic package;
  final String phoneNumber;
  final String currentListType;
  final String selectedCategory;

  const PackageCard({
    super.key, 
    required this.package,
    required this.phoneNumber,
    required this.currentListType,
    required this.selectedCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(
          color: Color.fromARGB(255, 165, 11, 0),
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
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
                          color: Colors.red.withValues(alpha: value),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  // Animated loading indicator
                  const SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
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
      final apiUrl = 'https://known-instantly-bison.ngrok-free.app/inquiry/telkomsel';
      
      // Start both the API call and minimum delay simultaneously
      final apiCallFuture = dio.post(
        apiUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
        data: {
          'number': phoneNumber,
          'list': currentListType,
          'product_id': package['product_id'],
          'category': selectedCategory,
        },
      );

      final minimumDelayFuture = Future.delayed(const Duration(milliseconds: 1500));

      // Wait for both the API call and minimum delay to complete
      final results = await Future.wait([apiCallFuture, minimumDelayFuture]);
      final response = results[0] as Response;

      // Check if widget is still mounted before using context
      if (!context.mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      if (response.statusCode == 200) {
        // Show success dialog with purchase details
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'Detail Pembelian',
                        style: TextStyle(
                          color: Color.fromARGB(255, 255, 51, 0),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Nomor', phoneNumber),
                    _buildDetailRow('Produk', package['product_name'] ?? 'Tidak tersedia'),
                    _buildDetailRow('Kuota', package['quota']?.toString() ?? 'Tidak tersedia'),
                    _buildDetailRow('Harga', 'Rp ${_formatPrice(package['price'])}'),
                    const SizedBox(height: 16),
                    // Barcode section
                    const Text(
                      'Kode Bayar:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Large code text with animation
                    Center(
                      child: TweenAnimationBuilder(
                        duration: const Duration(milliseconds: 600),
                        tween: Tween<double>(begin: 0, end: 1),
                        builder: (context, double value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withValues(alpha: 0.3),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  response.data['inv_id']?.toString() ?? 'Tidak tersedia',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    ),
                    onPressed: () async {
                      // Open Telkomsel link with inv_id
                      final invId = response.data['inv_id']?.toString() ?? '';
                      final url = 'https://known-instantly-bison.ngrok-free.app/order/$invId';
                      
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
                      
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('Lanjutkan'),
                  ),
                ),
              ],
            );
          },
        );
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
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

// Add this helper method for the animated dots
Widget _buildDot(bool isActive) {
  return Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: isActive ? Colors.red : Colors.grey[300],
    ),
  );
}

// Shimmer card for loading state
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
                color: const Color.fromARGB(255, 165, 11, 0),
                width: 1.0,
              ),
              color: Colors.white,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Animated shimmer effect for title
                  _buildShimmerBox(
                    width: 200 + (index * 30).toDouble(),
                    height: 20,
                    delay: index * 100,
                  ),
                  const SizedBox(height: 8),
                  // Shimmer for description
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
                  // Price and button row
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
                Colors.red[300]!,
                Colors.red[100]!,
                Colors.red[300]!,
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
            ? Colors.red.withValues(alpha: value)
            : Colors.grey[300],
          boxShadow: isActive ? [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.3 * value),
              spreadRadius: 2,
              blurRadius: 4,
            ),
          ] : null,
        ),
      );
    },
  );
}

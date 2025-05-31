import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';

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

  // Add this method to the _MyHomePageState class
  void _showCategorySelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCategoryButton(context, 'Paket Data', 'DATA'),
              const SizedBox(height: 8),
              _buildCategoryButton(context, 'Paket Nelpon & SMS', 'VOICE_SMS'),
              const SizedBox(height: 8),
              _buildCategoryButton(context, 'Roaming & Haji', 'ROAMING'),
              const SizedBox(height: 8),
              _buildCategoryButton(context, 'Digital & Game', 'DIGITAL_GAME'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryButton(BuildContext context, String label, String categoryValue) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () {
          setState(() {
            _selectedCategory = categoryValue;
          });
          Navigator.of(context).pop(); // Close dialog
          if (_phoneController.text.isNotEmpty) {
            _fetchPackages();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Mohon masukkan nomor telepon')),
            );
          }
        },
        child: Text(label),
      ),
    );
  }

  // Keep existing _showCategorySelectionDialog method
  
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
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 20),
              // Title and input section in a more compact layout
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22, // Reduced from 24
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Masukkan nomor pelanggan:',
                      style: TextStyle(fontSize: 14, color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    // Phone number input field - full width
                    TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20.0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20.0)),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20.0)),
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        hintText: '081234567890',
                        prefixIcon: Icon(Icons.phone),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                      ),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(15),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Replace the single button with a scrollable row of buttons
                    SizedBox(
                      height: 40,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _currentListType == 'listTerbaik' ? Colors.red : Colors.white,
                                foregroundColor: _currentListType == 'listTerbaik' ? Colors.white : Colors.red,
                                padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 24.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              onPressed: () {
                                if (_phoneController.text.isNotEmpty) {
                                  _showCategorySelectionDialog();
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
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Kategori: ${_getCategoryDisplayName(_selectedCategory)}',
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12), // Reduced from 20
              if (_isLoading)
                const CircularProgressIndicator(color: Colors.white),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              if (_subCategories.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _subCategories.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemBuilder: (context, index) {
                        final subCategory = _subCategories[index];
                        final isSelected = _selectedSubCategory == subCategory;
                        
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSelected ? Colors.red : Colors.white,
                              foregroundColor: isSelected ? Colors.white : Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: () => _filterPackages(subCategory),
                            child: Text(subCategory),
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
                      const Text(
                        'Paket Tersedia:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._filteredPackages.map((package) => PackageCard(package: package)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'DATA':
        return 'Paket Data';
      case 'VOICE_SMS':
        return 'Paket Nelpon & SMS';
      case 'ROAMING':
        return 'Roaming & Haji';
      case 'DIGITAL_GAME':
        return 'Digital & Game';
      default:
        return category;
    }
  }
}

class PackageCard extends StatelessWidget {
  final dynamic package;

  const PackageCard({super.key, required this.package});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              package['product_name'] ?? 'Nama Paket Tidak Tersedia',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kategori: ${package['kategori'] ?? 'Tidak tersedia'}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Kuota: ${package['quota']?.toString().split(',').join('\n') ?? 'Tidak tersedia'}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Durasi: ${package['duration'] ?? 'Tidak tersedia'}',
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
                    // Handle buy action
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Membeli ${package['product_name']}')),
                    );
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

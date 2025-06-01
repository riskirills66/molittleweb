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
                    hintText: 'Masukkan Nomor',
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
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator(color: Colors.red)),
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
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Memproses pembelian..."),
              ],
            ),
          );
        },
      );

      final dio = Dio();
      // final apiUrl = 'http://localhost:4444/inquiry/telkomsel';
      final apiUrl = 'https://known-instantly-bison.ngrok-free.app/inquiry/telkomsel';
      
      final response = await dio.post(
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

      // Close loading dialog
      Navigator.of(context).pop();

      if (response.statusCode == 200) {
        // Show success dialog with purchase details
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text(
                'Detail Pembelian',
                style: TextStyle(
                  color: Color.fromARGB(255, 255, 51, 0),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
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
                  // Barcode image
                  Center(
                    child: Image.network(
                      'https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=${response.data['inv_id']?.toString() ?? 'Tidak tersedia'}',
                      height: 100,
                      width: 200,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 100,
                          width: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Center(
                            child: Text(
                              'Barcode tidak tersedia',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return SizedBox(
                          height: 100,
                          width: 200,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Large code text
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
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
                ],
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    // Open Telkomsel link with inv_id
                    final invId = response.data['inv_id']?.toString() ?? '';
                    final url = 'https://known-instantly-bison.ngrok-free.app/order$invId';
                    
                    try {
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tidak dapat membuka link'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error membuka link: $e'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                    
                    Navigator.of(context).pop();
                  },
                  child: const Text('Lanjutkan'),
                ),
              ],
            );
          },
        );
      } else {
        // Close loading dialog and show error
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.statusCode} - ${response.data}')),
        );
      }
    } catch (e) {
      // Close loading dialog and show error
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
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
            child: Text(value),
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

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user/models/attribute_model.dart';
import 'package:user/models/snack_place_model.dart';
import 'package:user/screens/snack_place_detail_screen.dart';
import 'package:user/services/snackplace_services.dart';
import 'package:user/widgets/home/snack_place_card.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  // State cho các thuộc tính filter
  List<Attribute> _tastes = [];
  List<Attribute> _diets = [];
  List<Attribute> _foodTypes = [];

  // State cho các lựa chọn của người dùng
  final Set<String> _selectedTasteIds = {};
  final Set<String> _selectedDietIds = {};
  final Set<String> _selectedFoodTypeIds = {};
  final _priceFromController = TextEditingController();
  final _priceToController = TextEditingController();

  // State cho kết quả và trạng thái loading
  List<SnackPlace> _snackPlaces = [];
  bool _attributesLoading = true;
  bool _resultsLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAttributes();
  }

  @override
  void dispose() {
    _priceFromController.dispose();
    _priceToController.dispose();
    super.dispose();
  }

  Future<void> _fetchAttributes() async {
    try {
      final response = await SnackPlaceServices.getAllSnackPlaceAttributesApi();
      if (response.status == 200 && response.data != null) {
        setState(() {
          _tastes = (response.data['tastes'] as List)
              .map((e) => Attribute.fromJson(e))
              .toList();
          _diets = (response.data['diets'] as List)
              .map((e) => Attribute.fromJson(e))
              .toList();
          _foodTypes = (response.data['foodTypes'] as List)
              .map((e) => Attribute.fromJson(e))
              .toList();
        });
      } else {
        setState(() {
          _error = 'Không thể tải bộ lọc';
        });
      }
    } catch (err) {
      setState(() {
        _error = 'Không thể tải bộ lọc';
      });
    } finally {
      setState(() {
        _attributesLoading = false;
      });
    }
  }

  Future<void> _handleApplyFilters() async {
    setState(() {
      _resultsLoading = true;
      _error = null;
    });

    try {
      final response = await SnackPlaceServices.filterSnackPlacesApi(
        priceFrom: num.tryParse(_priceFromController.text) ?? 0,
        priceTo: num.tryParse(_priceToController.text) ?? 99999999, // Giá trị lớn
        tasteIds: _selectedTasteIds.toList(),
        dietIds: _selectedDietIds.toList(),
        foodTypeIds: _selectedFoodTypeIds.toList(),
      );

      if (response.status == 200 && response.data != null) {
        final List<dynamic> responseData = response.data;
        setState(() {
          _snackPlaces =
              responseData.map((e) => SnackPlace.fromJson(e)).toList();
          if (_snackPlaces.isEmpty) {
            _error = 'Không tìm thấy kết quả phù hợp';
          }
        });
      } else {
        setState(() {
          _snackPlaces = [];
          _error = 'Không tìm thấy kết quả';
        });
      }
    } catch (err) {
      setState(() {
        _snackPlaces = [];
        _error = 'Có lỗi xảy ra, vui lòng thử lại';
      });
    } finally {
      setState(() {
        _resultsLoading = false;
      });
    }
  }

  Future<void> _handleCardPress(String snackPlaceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId != null) {
        await SnackPlaceServices.recordSnackPlaceClickApi(
            userId: userId, snackPlaceId: snackPlaceId);
      }
    } catch (e) {
      debugPrint('Error recording click: $e');
    }
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SnackPlaceDetailScreen(snackPlaceId: snackPlaceId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bộ lọc'),
        centerTitle: true,
      ),
      // THÊM SAFE AREA Ở ĐÂY
      body: SafeArea(
        child: _attributesLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildFilterBody(),
      ),
    );
  }

  Widget _buildFilterBody() {
    return CustomScrollView(
      slivers: [
        // Phần chứa các lựa chọn filter
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Khoảng giá (VND)'),
                _buildPriceRange(),
                _buildSectionTitle('Hương vị'),
                _buildChipGroup(_tastes, _selectedTasteIds),
                _buildSectionTitle('Chế độ ăn'),
                _buildChipGroup(_diets, _selectedDietIds),
                _buildSectionTitle('Loại món ăn'),
                _buildChipGroup(_foodTypes, _selectedFoodTypeIds),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _handleApplyFilters,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('Áp dụng bộ lọc'),
                ),
                if (_error != null && _snackPlaces.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Center(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                  )
              ],
            ),
          ),
        ),

        // Phần hiển thị kết quả
        if (_resultsLoading)
          const SliverToBoxAdapter(
            child: Center(child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            )),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final item = _snackPlaces[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SnackPlaceCard(
                      item: item, onTap: () => _handleCardPress(item.snackPlaceId)),
                );
              },
              childCount: _snackPlaces.length,
            ),
          ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPriceRange() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _priceFromController,
            decoration: const InputDecoration(labelText: 'Từ', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text('-'),
        ),
        Expanded(
          child: TextField(
            controller: _priceToController,
            decoration: const InputDecoration(labelText: 'Đến', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  Widget _buildChipGroup(List<Attribute> attributes, Set<String> selectedIds) {
    // Dùng Wrap để tự động xuống hàng các chip
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: attributes.map((attribute) {
        // Dùng FilterChip cho tiện, nó có sẵn trạng thái selected
        return FilterChip(
          label: Text(attribute.name),
          selected: selectedIds.contains(attribute.id),
          onSelected: (bool selected) {
            setState(() {
              if (selected) {
                selectedIds.add(attribute.id);
              } else {
                selectedIds.remove(attribute.id);
              }
            });
          },
        );
      }).toList(),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user/constants/app_colors.dart';
import 'package:user/constants/app_fonts.dart';
import 'package:user/models/snack_place_model.dart';
import 'package:user/screens/filter_screen.dart';
import 'package:user/screens/snack_place_detail_screen.dart';
import 'package:user/services/snackplace_services.dart';
import 'package:user/widgets/home/snack_place_card.dart';

class SearchSection extends StatefulWidget {
  final ValueChanged<bool> onSearchStateChange;

  const SearchSection({super.key, required this.onSearchStateChange});

  @override
  State<SearchSection> createState() => _SearchSectionState();
}

class _SearchSectionState extends State<SearchSection> {
  final TextEditingController _searchController = TextEditingController();
  final List<SnackPlace> _snackPlaces = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  bool _hasMore = true;
  bool _isFetchingMore = false;
  int _pageNum = 1;
  final int _pageSize = 10;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onClear() {
    _searchController.clear();
    setState(() {
      _snackPlaces.clear();
      _hasSearched = false;
      _pageNum = 1;
      _hasMore = true;
    });
    widget.onSearchStateChange(false);
    FocusScope.of(context).unfocus();
  }

  Future<void> _fetchSnackPlaces({bool reset = false}) async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    if (reset) {
      _pageNum = 1;
      _snackPlaces.clear();
      _hasMore = true;
      setState(() {
        _isLoading = true;
      });
    }

    if (!_hasMore || _isFetchingMore) return;

    setState(() {
      _isFetchingMore = true;
    });

    try {
      final response = await SnackPlaceServices.searchSnackPlacesApi(
        pageNum: _pageNum,
        pageSize: _pageSize,
        searchKeyword: query,
        status: true,
      );
      final List<dynamic> pageData = response.data['pageData'] ?? [];
      final List<SnackPlace> newData = pageData
          .map((json) => SnackPlace.fromJson(json))
          .toList();

      setState(() {
        _snackPlaces.addAll(newData);
        _hasMore = newData.length == _pageSize;
        _pageNum++;
      });
    } catch (e) {
      debugPrint('Error searching snack places: $e');
      setState(() {
        _hasMore = false;
      });
    } finally {
      setState(() {
        _isFetchingMore = false;
        _isLoading = false;
      });
    }
  }

  void _onSearchSubmitted(String value) {
    if (value.trim().isNotEmpty) {
      setState(() {
        _hasSearched = true;
      });
      widget.onSearchStateChange(true);
      _fetchSnackPlaces(reset: true);
    }
  }

  Future<void> _handleCardPress(String snackPlaceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId != null) {
        await SnackPlaceServices.recordSnackPlaceClickApi(
          userId: userId,
          snackPlaceId: snackPlaceId,
        );
      }
    } catch (e) {
      debugPrint('Error recording click: $e');
    }
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              SnackPlaceDetailScreen(snackPlaceId: snackPlaceId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar UI
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cần gì đó có mình đây ...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _onClear,
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                  onSubmitted: _onSearchSubmitted,
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () {
                  // Mở màn hình filter
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FilterScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        // Search Results
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_hasSearched && _snackPlaces.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(child: Text('Không tìm thấy kết quả nào.')),
          )
        else if (_snackPlaces.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _snackPlaces.length,
            itemBuilder: (context, index) {
              final item = _snackPlaces[index];
              return SnackPlaceCard(
                item: item,
                onTap: () => _handleCardPress(item.snackPlaceId),
              );
            },
          ),
      ],
    );
  }
}

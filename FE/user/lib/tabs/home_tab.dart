// File: lib/tabs/home_tab.dart
import 'package:flutter/material.dart';
import 'package:user/widgets/home/introduction_section.dart';
import 'package:user/widgets/home/search_section.dart';
import 'package:user/widgets/home/snack_place_list.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool _isSearching = false;
  // TAO THÊM CONTROLLER Ở ĐÂY
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose(); // Nhớ dispose nó
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          // Gắn controller vào SingleChildScrollView
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SearchSection(
                  onSearchStateChange: (isSearching) {
                    setState(() {
                      _isSearching = isSearching;
                    });
                  },
                ),
                if (!_isSearching)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const IntroductionSection(),
                      // Truyền controller xuống widget con
                      SnackPlaceList(scrollController: _scrollController),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
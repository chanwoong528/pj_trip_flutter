import 'package:flutter/material.dart';

class ScreenSearch extends StatefulWidget {
  const ScreenSearch({super.key});

  @override
  State<ScreenSearch> createState() => _ScreenSearchState();
}

class _ScreenSearchState extends State<ScreenSearch> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // 화면이 마운트되면 자동으로 포커스
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  search() {
    if (_searchController.text.isNotEmpty) {
      debugPrint('검색어: ${_searchController.text}');
      //TODO: fetch to naver api
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey, height: 1),
        ),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(color: Colors.white),
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  textAlignVertical: TextAlignVertical.center,
                  style: const TextStyle(fontSize: 18, height: 1.5),
                  decoration: InputDecoration(
                    hintText: '장소를 검색하세요',
                    border: InputBorder.none,
                  ),
                  onSubmitted: (value) {
                    debugPrint('검색어: $value');
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 40,
              width: 40,

              child: IconButton(
                onPressed: () {
                  if (_searchController.text.isNotEmpty) {
                    debugPrint('검색어: ${_searchController.text}');
                  }
                },
                icon: const Icon(Icons.search),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            '검색 결과가 여기에 표시됩니다',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}

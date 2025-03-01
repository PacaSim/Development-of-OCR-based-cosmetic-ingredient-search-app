import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:io';

import '../analysis/analysis_page.dart';

class OcrPage extends StatefulWidget {
  const OcrPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _OcrPageState();
  }
}

class _OcrPageState extends State<OcrPage> {
  File? _image;
  final picker = ImagePicker();
  bool isLoading = false;
  List<Map<String, dynamic>> _ocrTexts = [];
  List<TextEditingController> _controllers = [];
  String? _errorMessage;
  int _selectedIndex = 1; // 초기 선택된 인덱스
  final ScrollController _scrollController = ScrollController();

  // BottomNavigationBar 탭 선택 시 호출
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // '분석' 탭이 선택되었을 때 AnalysisPage로 이동
    if (_selectedIndex == 0) {
      if (_ocrTexts.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnalysisPage(ocrTexts: _ocrTexts),
          ),
        );
      } else {
        _showErrorDialog('먼저 성분을 인식해주세요.');
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _ocrTexts = [];
        _controllers.clear();
        _errorMessage = null;
        isLoading = true;
      });

      _image = File(pickedFile.path);
      await _uploadImage();

      setState(() {
        isLoading = false;
      });
    } else {
      print('이미지 선택 취소됨');
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null) return;

    Dio dio = Dio();
    try {
      dio.options.contentType = 'multipart/form-data';
      var formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(_image!.path, filename: 'upload.jpg'),
      });

      final response = await dio.post('http://127.0.0.1:5000/upload', data: formData);

      if (response.statusCode == 200) {
        final jsonResponse = response.data;
        setState(() {
          _ocrTexts = List<Map<String, dynamic>>.from(jsonResponse['texts']);
          _ocrTexts.sort((a, b) => b['score'].compareTo(a['score']));
          _controllers = _ocrTexts
              .map((textData) => TextEditingController(text: textData['text']))
              .toList();
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = '서버 응답 오류: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '이미지 업로드 중 오류 발생: $e';
      });
    }
  }

  Future<void> _searchIngredientInDB(String ingredient) async {
    if (ingredient.isEmpty) return;

    setState(() {
      isLoading = true;
    });

    try {
      Dio dio = Dio();
      final response = await dio.post(
        'http://127.0.0.1:5000/search_ingredient',
        data: {'ingredient': ingredient},
      );

      if (response.statusCode == 200) {
        final jsonResponse = response.data;
        List<String> results = List<String>.from(jsonResponse['results'] ?? []);

        if (results.isNotEmpty) {
          _showResultsDialog(results);
        } else {
          _showErrorDialog('성분이 DB에 존재하지 않습니다.');
        }
      } else {
        _showErrorDialog('서버 응답 오류: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('관련 정보가 없습니다.');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showResultsDialog(List<String> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('검색 결과'),
        content: SingleChildScrollView(
          child: ListBody(
            children: results.map((result) => Text(result)).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Color _getTextColor(double score) {
    if (score >= 0.6) {
      return Colors.green;
    } else if (score >= 0.3) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR 인식'),
        actions: [
          IconButton(onPressed: _pickAndUploadImage, icon: const Icon(Icons.upload)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            if (_image != null)
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16.0),
                child: Image.file(
                  _image!,
                  fit: BoxFit.contain,
                ),
              ),
            Expanded(
              child: _ocrTexts.isEmpty
                  ? const Center(
                child: Text(
                  '이미지를 선택하고 텍스트를 인식하세요.',
                  style: TextStyle(fontSize: 16),
                ),
              )
                  : ListView.builder(
                controller: _scrollController,
                itemCount: _ocrTexts.length,
                itemBuilder: (context, index) {
                  final textData = _ocrTexts[index];
                  return ListTile(
                    title: TextField(
                      controller: _controllers[index],
                      onChanged: (newText) {
                        setState(() {
                          _ocrTexts[index]['text'] = newText;
                        });
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '성분 수정',
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        _searchIngredientInDB(
                            _ocrTexts[index]['text']);
                      },
                    ),
                    subtitle: Text(
                      'Confidence: ${(textData['score'] * 100).toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: _getTextColor(textData['score']),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: '분석',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.text_snippet),
            label: 'OCR',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
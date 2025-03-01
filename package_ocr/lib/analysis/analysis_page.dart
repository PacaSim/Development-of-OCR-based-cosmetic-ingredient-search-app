import 'package:flutter/material.dart';

class AnalysisPage extends StatefulWidget {
  final List<Map<String, dynamic>> ocrTexts;

  AnalysisPage({required this.ocrTexts});

  @override
  _AnalysisPageState createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  String selectedSkinType = '보통'; // 기본 피부 타입 설정

  // 피부 타입별 성분 데이터
  final Map<String, List<String>> skinTypeIngredients = {
    '보통': ['알란토인', '솔비톨', '라임', '알몬드', '카모마일', '알로에베라', '아줄렌', '스위트아몬드오일', '아미노산',
      '글리세린', '히알루론산', '세라마이드', '프로테인', '비타민 복합체', '천연보습인자', '아보카도오일', '로즈베리', '콜라겐',
      '마이크로리포좀', '알로에'],
    '건성': ['라벤더', '하마멜리스', '알란토인', '카모마일', '레시틴', '알로에베라', '스위트아몬드오일', '천연보습인자',
      '레시틴', '콜라겐', '라임', '밀크프로테인', '파슬리', '홉스', '세이지', '호스체스넛', '아보카도오일', '모이춰라이징',
      '로얄젤리', '해초농축액', '비타민A', '비타민E', '태반추출물', '윗점오일', '알로에', '씨위드콤플렉스', '아미노산'],
    '지성': ['소듐타우릴', '코코넛오일', '오이추출물', '솔비톨', '알몬드', '라임', '캄포', '마로니에', '히아멜리스', '사이프러스',
      '레몬', '세이지', '캄포', '아줄렌', '화이트네롤', '큐캄퍼', '쇠뜨기추출물', '퀸씨드추출물', '그레이프후룻', '비타민A콤플렉스',
      '우엉', '아미노산', '젠틀수딩젤', '퓨리화잉', '그린클레이', '클로로필', '멘톨', '허브'],
    '여드름성': ['라임블러섬', '위치하젤', '제퍼니스캄퍼', '아줄렌', '쐐기풀추출물', '천연보습인자', '씨토비올아이리스', '멜라루카오일',
      '캄퍼', '바질', '네홀리', '카모마일', '큐캄버', '소브후르트', '일랑일랑', '월계수잎', '제라늄', '로즈마리', '더마줄렌',
      '씨토비올아이리스', '클로로필', '클레이', '세이지', '멜라루카오일'],
  };

  // 성분과 피부 타입별 적합도 점수 계산
  int _calculateSkinFitScore(String ingredient, String skinType) {
    if (skinTypeIngredients[skinType]?.contains(ingredient) ?? false) {
      return 10; // 성분이 적합하면 10점 부여
    }
    return 0; // 성분이 적합하지 않으면 0점
  }

  @override
  Widget build(BuildContext context) {
    // 성분 데이터를 적합도 점수를 기준으로 정렬
    final sortedTexts = widget.ocrTexts
        .map((textData) => {
      ...textData,
      'score': _calculateSkinFitScore(textData['text'], selectedSkinType),
    })
        .toList();

    sortedTexts.sort((a, b) => b['score'].compareTo(a['score']));

    return Scaffold(
      appBar: AppBar(
        title: const Text('성분 적합도 분석'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 피부 타입 선택을 위한 직관적인 디자인
            Text(
              '피부 타입을 선택하세요:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
              ),
              child: DropdownButton<String>(
                value: selectedSkinType,
                items: ['보통', '건성', '지성', '여드름성']
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedSkinType = newValue!;
                  });
                },
                dropdownColor: Colors.deepPurple.shade50,
                icon: Icon(Icons.arrow_drop_down, color: Colors.deepPurple),
              ),
            ),
            SizedBox(height: 20),
            Text(
              '적합도 분석 결과:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: sortedTexts.length,
                itemBuilder: (context, index) {
                  final textData = sortedTexts[index];
                  final ingredient = textData['text'];
                  final score = textData['score'];

                  // 성분 적합도 점수 색상 변경
                  Color scoreColor;
                  String scoreText;

                  if (score == 10) {
                    scoreColor = Colors.green;
                    scoreText = '적합';
                  } else {
                    scoreColor = Colors.red;
                    scoreText = '연관성 없음';
                  }

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 5,
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      title: Text(
                        ingredient,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '적합도 점수: $scoreText',
                        style: TextStyle(color: scoreColor, fontSize: 14),
                      ),
                      trailing: Icon(
                        score == 10 ? Icons.check_circle : Icons.cancel,
                        color: scoreColor,
                        size: 28,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
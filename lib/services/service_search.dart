import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// import 'dart:math';

import '../domain/location.dart';

class ServiceSearch {
  // static Map<String, dynamic> convertWGS84ToLatLon(num mapy, num mapx) {
  //   final lat = mapy / 180.0 * pi;
  //   final lon = mapx / 180.0 * pi;

  //   return {'lat': lat, 'lon': lon};
  // }

  Future<List<Location>> searchPlaceKakao(String query) async {
    try {
      final url = Uri.parse(
        'https://dapi.kakao.com/v2/local/search/keyword.json',
      ).replace(queryParameters: {'query': query});
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'KakaoAK ${dotenv.env['KAKAO_REST_API_KEY']}',
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> items = data['documents'] ?? [];
        final result = items.map((item) => Location.kakaoFromJson(item));

        debugPrint('result: ${items.toString()}');

        return result.toList();
      } else {
        debugPrint('API 요청 실패: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('검색 중 오류 발생: $e');
      return [];
    }
  }

  Future<List<Location>> searchPlaceNominatim(String query) async {
    debugPrint('query: $query');
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/search')
          .replace(
            queryParameters: {
              'q': query,
              'format': 'json',
              'limit': '10',
              // 'accept-language': 'en-US',
              'addressdetails': '1',
              'accept-language': 'ko-KR',
            },
          );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'PJTripApp/1.0 (Flutter Travel App)'},
      );
      debugPrint('response: ${response.body}');

      // Nominatim API는 배열을 직접 반환합니다
      final List<dynamic> items = json.decode(response.body);
      final result = items.map((item) => Location.nominatimFromJson(item));
      debugPrint('result: ${result.toString()}');
      return result.toList();
    } catch (e) {
      debugPrint('검색 중 오류 발생: $e');
      return [];
    }
  }
  // Future<List<Map<String, dynamic>>> search(String query) async {
  //   // query	String	Y	-
  //   // display	Integer	N	한 번에 표시할 검색 결과 개수(기본값: 1, 최댓값: 5)
  //   // start	Integer	N	검색 시작 위치(기본값: 1, 최댓값: 1)
  //   // sort	String	N	검색 결과 정렬 방법
  //   // - random: 정확도순으로 내림차순 정렬(기본값)
  //   // - comment: 업체 및 기관에 대한 카페, 블로그의 리뷰 개수순으로 내림차순 정렬

  //   try {
  //     final url = Uri.parse('https://openapi.naver.com/v1/search/local.json')
  //         .replace(
  //           queryParameters: {
  //             'query': query,
  //             'display': '5',
  //             'start': '1',
  //             'sort': 'random',
  //           },
  //         );

  //     final response = await http.get(
  //       url,
  //       headers: {
  //         'X-Naver-Client-Id': dotenv.env['NAVER_SEARCH_CLIENT_ID'] ?? '',
  //         'X-Naver-Client-Secret':
  //             dotenv.env['NAVER_SEARCH_CLIENT_SECRET'] ?? '',
  //       },
  //     );

  //     if (response.statusCode == 200) {
  //       debugPrint('response.body: ${response.body}');
  //       final Map<String, dynamic> data = json.decode(response.body);
  //       final List<dynamic> items = data['items'] ?? [];

  //       final result = items
  //           .map(
  //             (item) => {
  //               ...Map<String, dynamic>.from(item),
  //               ...convertWGS84ToLatLon(
  //                 double.parse(item['mapy']),
  //                 double.parse(item['mapx']),
  //               ),
  //             },
  //           )
  //           .toList();

  //       // debugPrint('result: $result');

  //       return result as List<Map<String, dynamic>>;
  //     } else {
  //       debugPrint('API 요청 실패: ${response.statusCode}');
  //       return [];
  //     }
  //   } catch (e) {
  //     debugPrint('검색 중 오류 발생: $e');
  //     return [];
  //   }
  // }
}

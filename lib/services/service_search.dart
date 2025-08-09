import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:pj_trip/domain/location.dart';
import 'package:pj_trip/db/model/model_place.dart';
import 'package:pj_trip/utils/coordinate_converter.dart';

class ServiceSearch {
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
        debugPrint('response:  kakao ${response.body}');
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> items = data['documents'] ?? [];
        final result = items.map((item) => Location.kakaoFromJson(item));
        return result.toList();
      }
      debugPrint('API 요청 실패: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('검색 중 오류 발생: $e');
      return [];
    }
  }

  Future<List<Location>> searchPlaceGoogle(
    String query, [
    Bounds? bounds,
  ]) async {
    try {
      final url = Uri.parse(
        'https://places.googleapis.com/v1/places:searchText',
      );
      // .replace(
      //   queryParameters: {
      //     'query': query,
      //     'key': dotenv.env['GOOGLE_PLACE_API_KEY'],
      //     'language': 'ko', //TODO: 언어 설정 필요
      //     'locationRestriction': jsonEncode({
      //       "rectangle": {
      //         "low": {"latitude": 33.0, "longitude": 124.0},
      //         "high": {"latitude": 38.6, "longitude": 132.0},
      //       },
      //     }),
      //   },
      // );
      debugPrint('bounds: ${bounds?.lowLatitude}');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': dotenv.env['GOOGLE_PLACE_API_KEY'] ?? "",
          'X-Goog-FieldMask':
              'places.displayName,places.formattedAddress,places.location,',
        },
        body: jsonEncode({
          'textQuery': query,

          'languageCode': 'en',
          if (bounds != null)
            'locationBias': {
              "rectangle": {
                "low": {
                  "latitude": bounds.lowLatitude,
                  "longitude": bounds.lowLongitude,
                },
                "high": {
                  "latitude": bounds.highLatitude,
                  "longitude": bounds.highLongitude,
                },
              },
            },
          // 'language': 'ko',
          // 'locationRestriction': jsonEncode({

          // }),
        }),
      );
      debugPrint('response:  google ${response.body}');
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> items = data['places'] ?? [];
        final result = items.map((item) => Location.googleFromJson(item));
        return result.toList();
      }
      debugPrint('API 요청 실패: ${response.statusCode}');
      return [];
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
      debugPrint('response:  nominatim ${response.body}');
      // Nominatim API는 배열을 직접 반환합니다
      final List<dynamic> items = json.decode(response.body);
      final result = items.map((item) => Location.nominatimFromJson(item));
      return result.toList();
    } catch (e) {
      debugPrint('검색 중 오류 발생: $e');
      return [];
    }
  }

  Future<List<SearchPlaceNaverResult>> searchPlaceNaver(String query) async {
    // query	String	Y	-
    // display	Integer	N	한 번에 표시할 검색 결과 개수(기본값: 1, 최댓값: 5)
    // start	Integer	N	검색 시작 위치(기본값: 1, 최댓값: 1)
    // sort	String	N	검색 결과 정렬 방법
    // - random: 정확도순으로 내림차순 정렬(기본값)
    // - comment: 업체 및 기관에 대한 카페, 블로그의 리뷰 개수순으로 내림차순 정렬

    try {
      final url = Uri.parse('https://openapi.naver.com/v1/search/local.json')
          .replace(
            queryParameters: {
              'query': query,
              'display': '5',
              'start': '1',
              'sort': 'random',
            },
          );

      final response = await http.get(
        url,
        headers: {
          'X-Naver-Client-Id': dotenv.env['NAVER_SEARCH_CLIENT_ID'] ?? '',
          'X-Naver-Client-Secret':
              dotenv.env['NAVER_SEARCH_CLIENT_SECRET'] ?? '',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('response.body: ${response.body}');
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> items = data['items'] ?? [];

        final result = items.map(
          (item) => SearchPlaceNaverResult.fromJson(item),
        );
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

  Future<void> getLocationInfoByLatLngNaver(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://naveropenapi.apigw.ntruss.com/map-reversegeocode/v2/gc',
      ).replace(queryParameters: {'coords': '$lat,$lng', 'output': 'json'});

      final response = await http.get(
        url,
        headers: {
          'x-ncp-apigw-api-key-id': dotenv.env['NAVER_SEARCH_CLIENT_ID'] ?? '',
          'x-ncp-apigw-api-key': dotenv.env['NAVER_SEARCH_CLIENT_SECRET'] ?? '',
        },
      );

      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> items = data['items'] ?? [];
      debugPrint('items: ${items.toString()}');
    } catch (e) {
      debugPrint('getLocationInfoByLatLngNaver error: $e');
    }
  }
}

class SearchPlaceNaverResult {
  final String title;
  final String link;
  final String category;
  final String description;
  final String telephone;
  final String address;
  final String roadAddress;
  final double mapx;
  final double mapy;

  SearchPlaceNaverResult({
    required this.title,
    required this.link,
    required this.category,
    required this.description,
    required this.telephone,
    required this.address,
    required this.roadAddress,
    required this.mapx,
    required this.mapy,
  });

  factory SearchPlaceNaverResult.fromJson(Map<String, dynamic> json) {
    return SearchPlaceNaverResult(
      title: json['title'],
      link: json['link'],
      category: json['category'],
      description: json['description'],
      telephone: json['telephone'],
      address: json['address'],
      roadAddress: json['roadAddress'],
      mapx:
          CoordinateConverter.tm128ToWgs84(json['mapx'], json['mapy'])['lon'] ??
          0,

      mapy:
          CoordinateConverter.tm128ToWgs84(json['mapx'], json['mapy'])['lat'] ??
          0,
    );
  }
}

// {
// flutter: 			"title":"<b>파라다이스호텔 부산<\/b> 부티크 베이커리",
// flutter: 			"link":"https:\/\/www.busanparadisehotel.co.kr\/dining\/bar.do?seq=10",
// flutter: 			"category":"카페,디저트>베이커리",
// flutter: 			"description":"",
// flutter: 			"telephone":"",
// flutter: 			"address":"부산광역시 해운대구 중동 1411-1 본관 1층",
// flutter: 			"roadAddress":"부산광역시 해운대구 해운대해변로 296 본관 1층",
// flutter: 			"mapx":"1291652183",
// flutter: 			"mapy":"351601894"
// flutter: 		},

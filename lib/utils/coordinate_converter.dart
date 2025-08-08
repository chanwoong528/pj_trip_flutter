import 'dart:math';

class CoordinateConverter {
  /// Web Mercator 좌표를 WGS84 위도/경도로 변환
  ///
  /// [x] - Web Mercator X 좌표 (mapx)
  /// [y] - Web Mercator Y 좌표 (mapy)
  ///
  /// Returns: Map with 'lat' and 'lng' keys
  ///
  ///
  ///

  static Map<String, double> tm128ToWgs84(String mapxStr, String mapyStr) {
    // 문자열 → double 변환 후 10,000으로 나눔
    double x = double.parse(mapxStr) / 10000;
    double y = double.parse(mapyStr) / 10000;

    double RE = 6378137.0;
    double GRID = 5.0;
    double SLAT1 = 30.0;
    double SLAT2 = 60.0;
    double OLON = 126.0;
    double OLAT = 38.0;
    double XO = 200000.0 / GRID;
    double YO = 500000.0 / GRID;

    double DEGRAD = pi / 180.0;
    double RADDEG = 180.0 / pi;

    double re = RE / GRID;
    double slat1 = SLAT1 * DEGRAD;
    double slat2 = SLAT2 * DEGRAD;
    double olon = OLON * DEGRAD;
    double olat = OLAT * DEGRAD;

    double sn = tan(pi * 0.25 + slat2 * 0.5) / tan(pi * 0.25 + slat1 * 0.5);
    sn = log(cos(slat1) / cos(slat2)) / log(sn);
    double sf = tan(pi * 0.25 + slat1 * 0.5);
    sf = pow(sf, sn) * cos(slat1) / sn;
    double ro = tan(pi * 0.25 + olat * 0.5);
    ro = re * sf / pow(ro, sn);

    double xn = x - XO;
    double yn = ro - (y - YO);
    double ra = sqrt(xn * xn + yn * yn);
    if (sn < 0.0) ra = -ra;
    double theta = atan2(xn, yn);
    double alat = pow(re * sf / ra, 1.0 / sn).toDouble();
    alat = 2.0 * atan(alat) - pi * 0.5;

    double alon = theta / sn + olon;

    return {"lat": alat * RADDEG, "lon": alon * RADDEG};
  }
}

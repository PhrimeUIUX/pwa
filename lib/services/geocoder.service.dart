import 'dart:math';
import 'dart:convert';
import 'package:pwa/utils/data.dart';
import 'package:pwa/constants/api.dart';
import 'package:singleton/singleton.dart';
import 'package:pwa/utils/functions.dart';
import 'package:pwa/constants/strings.dart';
import 'package:pwa/models/address.model.dart';
import 'package:pwa/services/http.service.dart';
import 'package:pwa/models/coordinates.model.dart';
import 'package:pwa/models/api_response.model.dart';
import 'package:google_maps/google_maps.dart' as gmaps;

class GeocoderService extends HttpService {
  factory GeocoderService() => Singleton.lazy(() => GeocoderService._());

  GeocoderService._();

  Future<List<Address>> findAddressesFromCoordinates(
      Coordinates coordinates) async {
    final apiResult = await get(
      !isBool(AppStrings.appSettingsObject?["strings"][useExt] ?? true)
          ? Api.geoCoordinates
          : "https://backrideph.online/api/geocoder/forward",
      queryParameters: {
        "lat": coordinates.latitude,
        "lng": coordinates.longitude,
      },
    ).timeout(const Duration(seconds: 30));

    final apiResponse = ApiResponse.fromResponse(apiResult);
    if (apiResponse.allGood) {
      return (apiResponse.data).map((e) => Address.fromServerMap(e)).toList();
    }
    return [];
  }

  bool isReadableAddress(String? address) {
    if (address == null || address.trim().isEmpty) return false;
    final plusCodePattern = RegExp(
        r'^[23456789CFGHJMPQRVWX]{4,}\+?[23456789CFGHJMPQRVWX]{2,}',
        caseSensitive: false);
    final coordinatePattern = RegExp(r'^-?\d+(\.\d+)?,\s*-?\d+(\.\d+)?$');
    if (plusCodePattern.hasMatch(address.trim().split(',').first)) return false;
    if (coordinatePattern.hasMatch(address.trim())) return false;
    return true;
  }

  Future<List<Address>> findAddressesFromQuery(String keyword) async {
    if (isBool(AppStrings.homeSettingsObject?["use_external"] ?? true)) {
      final apiResult = await get(
        !isBool(AppStrings.appSettingsObject?["strings"][useExt] ?? true)
            ? Api.geoAddresses
            : "https://backrideph.online/api/geocoder/reserve",
      );
      final apiResponse = ApiResponse.fromResponse(apiResult);
      if (apiResponse.allGood) {
        List<dynamic> results = apiResponse.body["results"];
        List<Address> finalAddresses = [];
        for (var e in results) {
          double? lat = e["geometry"]?["location"]?["lat"];
          double? lng = e["geometry"]?["location"]?["lng"];
          if (lat == null || lng == null) continue;
          String? rawAddress = e["formatted_address"];
          if (isReadableAddress(rawAddress)) {
            final address = Address.fromServerMap(e);
            address.gMapPlaceId = e["place_id"] ?? "";
            finalAddresses.add(address);
          } else {
            final fallbackAddresses = await findAddressesFromCoordinates(
              Coordinates(
                lat,
                lng,
              ),
            );
            if (fallbackAddresses.isNotEmpty) {
              final address = fallbackAddresses.first;
              address.gMapPlaceId = e["place_id"] ?? "";
              finalAddresses.add(address);
            }
          }
        }
        return finalAddresses;
      }
      return [];
    } else {
      String latLng = "${initLatLng?.lat},${initLatLng?.lat}";
      final apiResult = await get(
        !isBool(AppStrings.appSettingsObject?["strings"][useExt] ?? false)
            ? Api.geoAddresses
            : "https://backrideph.online/api/geocoder/reserve",
        queryParameters: {
          "keyword": keyword,
          "location": latLng,
        },
      ).timeout(const Duration(seconds: 30));
      final apiResponse = ApiResponse.fromResponse(apiResult);
      if (apiResponse.allGood) {
        return (apiResponse.data).map((e) {
          final address = Address.fromServerMap(e);
          address.gMapPlaceId = e["place_id"] ?? "";
          return address;
        }).toList();
      }
      return [];
    }
  }

  Future<Address> fetchPlaceDetails(Address address) async {
    final apiResult = await get(
      !isBool(AppStrings.appSettingsObject?["strings"][useExt] ?? true)
          ? Api.geoAddresses
          : "https://backrideph.online/api/geocoder/reserve",
      queryParameters: {
        "place_id": address.gMapPlaceId,
      },
    ).timeout(const Duration(seconds: 30));
    final apiResponse = ApiResponse.fromResponse(apiResult);
    if (apiResponse.allGood) {
      try {
        return Address.fromServerMap(apiResponse.body as Map<String, dynamic>);
      } catch (_) {
        return address;
      }
    }
    return address;
  }

  Future<List<List<double>>> getPolyline(
    gmaps.LatLng pointA,
    gmaps.LatLng pointB,
    String purpose,
  ) async {
    final apiResult = await get(
      !isBool(AppStrings.appSettingsObject?["strings"][useExt] ?? true)
          ? Api.geoPolylines
          : "https://backrideph.online/api/polylines",
      queryParameters: {
        "purpose": purpose,
        "key": AppStrings.googleMapApiKey,
        "origin": "${pointA.lat},${pointA.lng}",
        "destination": "${pointB.lat},${pointB.lng}",
      },
    ).timeout(const Duration(seconds: 30));
    final apiResponse = ApiResponse.fromResponse(apiResult);
    if (apiResponse.allGood) {
      final decoded = decodeEncodedPolyline(
        apiResponse.body["data"].toString(),
      );
      return decoded;
    }
    throw apiResponse.message;
  }

  List<List<double>> decodeEncodedPolyline(String encoded) {
    // --- SAME PREPROCESSING AS ANDROID ---
    try {
      encoded = jsonDecode('"$encoded"');
    } catch (_) {}

    try {
      encoded = Uri.decodeFull(encoded);
    } catch (_) {}

    List<List<double>> poly = [];

    int index = 0;
    final int len = encoded.length;

    double lat = 0.0;
    double lng = 0.0;

    while (index < len) {
      double result = 0.0;
      int shift = 0;
      int b;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result += (b & 0x1F) * pow(2, shift);
        shift += 5;
      } while (b >= 0x20);

      double dlat =
          (result % 2 != 0) ? -(result / 2 + 1).floorToDouble() : (result / 2);

      lat += dlat;

      result = 0.0;
      shift = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result += (b & 0x1F) * pow(2, shift);
        shift += 5;
      } while (b >= 0x20);
      double dlng =
          (result % 2 != 0) ? -(result / 2 + 1).floorToDouble() : (result / 2);
      lng += dlng;
      poly.add([lat, lng]);
    }
    if (poly.isEmpty) return [];
    final isPolyline6 = poly.any(
      (p) => p[0].abs() > 9e6 || p[1].abs() > 18e6,
    );
    final precision = isPolyline6 ? 1e6 : 1e5;
    return poly.map((p) => [p[0] / precision, p[1] / precision]).toList();
  }
}

// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'package:get/get.dart';
import 'dart:js_util' as js_util;
import 'package:pwa/utils/data.dart';
import 'package:pwa/utils/functions.dart';
import 'package:stacked/stacked.dart';
import 'package:flutter/material.dart';
import 'package:pwa/models/address.model.dart';
import 'package:pwa/requests/taxi.request.dart';
import 'package:pwa/models/coordinates.model.dart';
import 'package:pwa/models/api_response.model.dart';
import 'package:pwa/services/geocoder.service.dart';
import 'package:google_maps/google_maps.dart' as gmaps;

class GMapViewModel extends BaseViewModel {
  gmaps.Map? _map;
  Timer? _debounce;
  bool _isResolvingCameraMove = false;
  DateTime? _ignoreCameraMoveUntil;
  double? total = 0.0;
  double? subTotal = 0.0;
  double? discount = 0.0;
  bool isLoading = false;
  bool isInitializing = false;
  List<WebMarker> markers = [];
  List<gmaps.Polyline>? polylines = [];
  TaxiRequest taxiRequest = TaxiRequest();
  gmaps.LatLng? lastCenter;
  GeocoderService geocoderService = GeocoderService();
  ValueNotifier<Address?> selectedAddress = ValueNotifier(null);

  @override
  void dispose() {
    _debounce?.cancel();
    _debounce = null;
    selectedAddress.dispose();
    _map?.controls.clear();
    _map = null;
    super.dispose();
  }

  setMap(gmaps.Map map) {
    _map = map;
    lastCenter = map.center;
    isInitializing = true;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        mapCameraMove("setMap", _map?.center);
      },
    );
  }

  gmaps.Map? get map => _map;

  zoomToCurrentLocation({double zoom = 16}) async {
    await getMyLatLng();
    if (_map != null) {
      final target = initLatLng;
      _map!.panTo(target!);
      _map!.zoom = zoom;
    }
  }

  zoomToLocation(
    gmaps.LatLng target, {
    double zoom = 16,
  }) async {
    if (_map != null) {
      _map!.panTo(target);
      _map!.zoom = zoom;
    }
  }

  zoomIn() async {
    if (_map != null) {
      final currentZoom = _map!.zoom.toDouble();
      _map!.zoom = (currentZoom + 1).clamp(2, 21);
    }
  }

  zoomOut() async {
    if (_map != null) {
      final currentZoom = _map!.zoom.toDouble();
      _map!.zoom = (currentZoom - 1).clamp(2, 21);
    }
  }

  mapCameraMove(
    String function,
    gmaps.LatLng? target, {
    bool skipSelectedAddress = false,
  }) async {
    if (target == null || _isResolvingCameraMove) {
      isLoading = false;
      isInitializing = false;
      return;
    }
    debugPrint("Map move - $function");
    final previousAddress = selectedAddress.value;
    if (!skipSelectedAddress) {
      selectedAddress.value = null;
      notifyListeners();
    }
    locUnavailable = false;
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 3000),
      () async {
        if (_isResolvingCameraMove) {
          return;
        }
        _isResolvingCameraMove = true;
        try {
          if (!skipSelectedAddress) {
            selectedAddress.value = null;
            isLoading = true;
            notifyListeners();
          }
          setBusyForObject(selectedAddress, true);
          try {
            List<Address> addresses =
                await geocoderService.findAddressesFromCoordinates(
              Coordinates(
                double.parse("${target.lat ?? 9.7638}"),
                double.parse("${target.lng ?? 118.7473}"),
              ),
            );
            final Address address = Address(
              addressLine: addresses.first.addressLine,
              countryName: addresses.first.countryName,
              countryCode: addresses.first.countryCode,
              featureName: addresses.first.featureName,
              postalCode: addresses.first.postalCode,
              adminArea: addresses.first.adminArea,
              subAdminArea: addresses.first.subAdminArea,
              subLocality: addresses.first.subLocality,
              thoroughfare: addresses.first.thoroughfare,
              subThoroughfare: addresses.first.subThoroughfare,
              gMapPlaceId: addresses.first.gMapPlaceId,
              coordinates: Coordinates(
                double.parse("${target.lat ?? 9.7638}"),
                double.parse("${target.lng ?? 118.7473}"),
              ),
            );
            isLoading = false;
            isInitializing = false;
            await addressSelected(address, animate: true);
            notifyListeners();
          } catch (e) {
            isLoading = false;
            isInitializing = false;
            selectedAddress.value = previousAddress;
            ApiResponse? apiResponse;
            try {
              apiResponse = await taxiRequest.locationAvailableRequest(
                double.parse("${target.lat}"),
                double.parse("${target.lng}"),
              );
              if (!apiResponse.allGood) {
                locUnavailable = true;
              }
            } catch (_) {
              apiResponse = null;
            }
            ScaffoldMessenger.of(Get.context!).clearSnackBars();
            ScaffoldMessenger.of(
              Get.context!,
            ).showSnackBar(
              SnackBar(
                backgroundColor: Colors.red,
                content: Text(
                  (apiResponse?.message.contains("service") ?? false)
                      ? "Please try another location"
                      : e.toString().toLowerCase().contains("dio")
                          ? "There was an error while processing"
                              " your request. Please try again later"
                          : e.toString().toLowerCase().contains("bad")
                              ? "There was a problem with your location "
                                  "detection or your internet connection"
                              : e.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            );
            notifyListeners();
          }
          if (gVehicleTypes.isEmpty) {
            try {
              gVehicleTypes = await taxiRequest.vehicleTypesRequest();
              debugPrint(
                "gmap vehicleTypesRequest success",
              );
            } catch (e) {
              debugPrint(
                "gmap vehicleTypesRequest error 1: $e",
              );
            }
          }
        } finally {
          setBusyForObject(selectedAddress, false);
          _isResolvingCameraMove = false;
        }
      },
    );
  }

  addressSelected(
    Address address, {
    bool animate = false,
  }) async {
    setBusyForObject(selectedAddress, true);
    try {
      if (address.gMapPlaceId != null) {
        address = await geocoderService.fetchPlaceDetails(address);
      }
      selectedAddress.value = address;
      pickupAddress = address;
      if (_map != null) {
        num currentZoom = _map!.zoom;
        final nextCenter = gmaps.LatLng(
          address.coordinates.latitude,
          address.coordinates.longitude,
        );
        lastCenter = nextCenter;
        if (animate) {
          _ignoreCameraMoveUntil = DateTime.now().add(
            const Duration(milliseconds: 800),
          );
          _map!.panTo(nextCenter);
        } else {
          _map!.center = nextCenter;
        }
        _map!.zoom = currentZoom;
      }
    } catch (e) {
      debugPrint("Error in addressSelected: $e");
    } finally {
      setBusyForObject(selectedAddress, false);
    }
  }

  drawPickPolyLines(
    String purpose,
    gmaps.LatLng pickupLatLng,
    gmaps.LatLng driverLatLng,
  ) async {
    if (_map == null) return;
    for (var m in markers) {
      m.marker.map = null;
    }
    markers.clear();
    polylines?.forEach((p) => p.map = null);
    polylines?.clear();
    final pickupMarker = gmaps.Marker(
      gmaps.MarkerOptions(
        map: _map,
        position: pickupLatLng,
        title: "Pickup Location",
      )..icon = gmaps.Icon(
          url:
              'https://storage.googleapis.com/ppctoda_website/ppctoda_pwa/pickup.png',
          scaledSize: gmaps.Size(50, 50),
        ),
    );
    markers.add(WebMarker(id: "pickupMarker", marker: pickupMarker));
    final driverMarker = gmaps.Marker(
      gmaps.MarkerOptions(
        map: _map,
        position: driverLatLng,
        title: "Driver Location",
      )..icon = gmaps.Icon(
          url:
              'https://storage.googleapis.com/ppctoda_website/ppctoda_pwa/driver.png',
          scaledSize: gmaps.Size(35, 35),
        ),
    );
    markers.add(WebMarker(id: "driverMarker", marker: driverMarker));
    try {
      final result = await geocoderService.getPolyline(
        driverLatLng,
        pickupLatLng,
        purpose,
      );
      if (result.isNotEmpty) {
        final points = result.map((p) => gmaps.LatLng(p[0], p[1])).toList();
        final pathJs = js_util.jsify(points);
        final polyline = gmaps.Polyline(
          gmaps.PolylineOptions()
            ..path = pathJs
            ..strokeColor = "#42A5F5"
            ..strokeOpacity = 1
            ..strokeWeight = 6
            ..map = _map,
        );
        polylines?.add(polyline);
        final allPoints = [driverLatLng, ...points, pickupLatLng];
        num minLat = allPoints.first.lat;
        num minLng = allPoints.first.lng;
        num maxLat = allPoints.last.lat;
        num maxLng = allPoints.last.lng;
        for (var point in allPoints) {
          if (point.lat < minLat) minLat = point.lat;
          if (point.lat > maxLat) maxLat = point.lat;
          if (point.lng < minLng) minLng = point.lng;
          if (point.lng > maxLng) maxLng = point.lng;
        }
        const offset = 0.002;
        if ((maxLat - minLat).abs() < offset) {
          maxLat += offset;
          minLat -= offset;
        }
        if ((maxLng - minLng).abs() < offset) {
          maxLng += offset;
          minLng -= offset;
        }
        final bounds = gmaps.LatLngBounds(
          gmaps.LatLng(minLat, minLng),
          gmaps.LatLng(maxLat, maxLng),
        );
        _map!.fitBounds(bounds);
      } else {
        debugPrint("No polyline points received from backend");
      }
    } catch (e) {
      debugPrint("Error drawing pick polyline: $e");
    }
  }

  drawDropPolyLines(
    String purpose,
    gmaps.LatLng pickupLatLng,
    gmaps.LatLng dropoffLatLng,
    gmaps.LatLng? driverLatLng,
  ) async {
    if (_map == null) return;
    for (var m in markers) {
      m.marker.map = null;
    }
    markers.clear();
    polylines?.forEach((p) => p.map = null);
    polylines?.clear();
    final pickupMarker = gmaps.Marker(
      gmaps.MarkerOptions(
        map: _map,
        position: pickupLatLng,
        title: "Pickup Location",
      )..icon = gmaps.Icon(
          url:
              'https://storage.googleapis.com/ppctoda_website/ppctoda_pwa/pickup.png',
          scaledSize: gmaps.Size(50, 50),
        ),
    );
    markers.add(WebMarker(id: "pickupMarker", marker: pickupMarker));
    final dropoffMarker = gmaps.Marker(
      gmaps.MarkerOptions(
        map: _map,
        position: dropoffLatLng,
        title: "Dropoff Location",
      )..icon = gmaps.Icon(
          url:
              'https://storage.googleapis.com/ppctoda_website/ppctoda_pwa/dropoff.png',
          scaledSize: gmaps.Size(50, 50),
        ),
    );
    markers.add(WebMarker(id: "dropoffMarker", marker: dropoffMarker));
    if (driverLatLng != null) {
      final driverMarker = gmaps.Marker(
        gmaps.MarkerOptions(
          map: _map,
          position: driverLatLng,
          title: "Driver Location",
        )..icon = gmaps.Icon(
            url:
                'https://storage.googleapis.com/ppctoda_website/ppctoda_pwa/driver.png',
            scaledSize: gmaps.Size(35, 35),
          ),
      );
      markers.add(WebMarker(id: "driverMarker", marker: driverMarker));
    }
    try {
      final result = await geocoderService.getPolyline(
        pickupLatLng,
        dropoffLatLng,
        purpose,
      );
      if (result.isNotEmpty) {
        final points = result.map((p) => gmaps.LatLng(p[0], p[1])).toList();
        final pathJs = js_util.jsify(points);
        final polyline = gmaps.Polyline(
          gmaps.PolylineOptions()
            ..path = pathJs
            ..strokeColor = "#42A5F5"
            ..strokeOpacity = 1
            ..strokeWeight = 8
            ..map = _map,
        );
        polylines?.add(polyline);
        final allPoints = [pickupLatLng, ...points, dropoffLatLng];
        num minLat = allPoints.first.lat;
        num minLng = allPoints.first.lng;
        num maxLat = allPoints.last.lat;
        num maxLng = allPoints.last.lng;
        for (var point in allPoints) {
          if (point.lat < minLat) minLat = point.lat;
          if (point.lat > maxLat) maxLat = point.lat;
          if (point.lng < minLng) minLng = point.lng;
          if (point.lng > maxLng) maxLng = point.lng;
        }
        const offset = 0.002;
        if ((maxLat - minLat).abs() < offset) {
          maxLat += offset;
          minLat -= offset;
        }
        if ((maxLng - minLng).abs() < offset) {
          maxLng += offset;
          minLng -= offset;
        }
        final bounds = gmaps.LatLngBounds(
          gmaps.LatLng(minLat, minLng),
          gmaps.LatLng(maxLat, maxLng),
        );
        _map!.fitBounds(bounds);
      } else {
        debugPrint("No polyline points received from backend");
      }
    } catch (e) {
      debugPrint("Error drawing drop polyline: $e");
    }
  }

  clearGMapDetails() {
    for (var m in markers) {
      m.marker.map = null;
    }
    markers.clear();
    polylines?.forEach((p) => p.map = null);
    polylines = [];
  }

  updateDriverMarkerPosition(gmaps.LatLng position) {
    if (_map == null) return;
    WebMarker? existing;
    try {
      existing = markers.firstWhere((m) => m.id == 'driverMarker');
    } catch (e) {
      existing = null;
    }
    if (existing == null) {
      final marker = gmaps.Marker(
        gmaps.MarkerOptions(
          map: _map,
          position: position,
          title: "Driver Location",
        )..icon = gmaps.Icon(
            url:
                'https://storage.googleapis.com/ppctoda_website/ppctoda_pwa/driver.png',
            scaledSize: gmaps.Size(35, 35),
          ),
      );
      markers.add(WebMarker(id: 'driverMarker', marker: marker));
    } else {
      existing.marker.position = position;
    }
  }

  bool shouldProcessCameraMove(gmaps.LatLng center) {
    final ignoreUntil = _ignoreCameraMoveUntil;
    if (ignoreUntil != null && DateTime.now().isBefore(ignoreUntil)) {
      lastCenter = center;
      return false;
    }
    if (_sameLatLng(lastCenter, center)) {
      return false;
    }
    lastCenter = center;
    return true;
  }

  bool _sameLatLng(gmaps.LatLng? a, gmaps.LatLng? b) {
    if (a == null || b == null) return false;
    return a.lat == b.lat && a.lng == b.lng;
  }
}

class WebMarker {
  final String id;
  final gmaps.Marker marker;

  WebMarker({required this.id, required this.marker});
}

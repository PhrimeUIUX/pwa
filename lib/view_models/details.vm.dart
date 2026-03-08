import 'package:pwa/utils/data.dart';
import 'package:stacked/stacked.dart';
import 'package:pwa/models/order.model.dart';

class DetailsViewModel extends BaseViewModel {
  Map<String, dynamic>? orderData;

  Future<void> initialise(Order order) async {
    setBusy(true);
    final snapshot = await fbStore.collection("orders").doc(order.code).get();
    orderData = snapshot.data();
    setBusy(false);
    notifyListeners();
  }
}

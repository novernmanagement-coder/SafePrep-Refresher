import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'app_state.dart';
import 'app_state_persistence.dart';

const String kProductUnlock = 'com.geraldmiller.safepreprefresher.unlock';

class IAPService {
  IAPService._();
  static final IAPService instance = IAPService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  ProductDetails? _unlockProduct;
  bool _available = false;

  bool get isAvailable => _available;
  String get unlockPrice => _unlockProduct?.price ?? '\$2.99';

  Future<void> initialize() async {
    _available = await _iap.isAvailable();
    if (!_available) return;

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (e) => debugPrint('IAP stream error: $e'),
    );

    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    final response = await _iap.queryProductDetails({kProductUnlock});
    if (response.error != null) {
      debugPrint('IAP product load error: ${response.error}');
      return;
    }
    for (final p in response.productDetails) {
      if (p.id == kProductUnlock) _unlockProduct = p;
    }
    debugPrint(
      'IAP products loaded: ${response.productDetails.map((p) => p.id).toList()}',
    );
  }

  void dispose() {
    _subscription?.cancel();
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _handleSuccess(purchase);
          break;
        case PurchaseStatus.error:
          debugPrint('IAP error: ${purchase.error?.message}');
          break;
        case PurchaseStatus.canceled:
          debugPrint('IAP canceled');
          break;
        case PurchaseStatus.pending:
          debugPrint('IAP pending');
          break;
      }
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> _handleSuccess(PurchaseDetails purchase) async {
    final state = AppState();
    state.hasUnlockedApp = true;
    await AppStatePersistence.save();
    debugPrint('IAP success: ${purchase.productID}');
  }

  Future<IAPResult> buyUnlock() async {
    if (!_available) return IAPResult.storeUnavailable;
    if (_unlockProduct == null) await _loadProducts();
    if (_unlockProduct == null) return IAPResult.productNotFound;
    try {
      await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: _unlockProduct!),
      );
      return IAPResult.initiated;
    } catch (e) {
      debugPrint('IAP buy error: $e');
      return IAPResult.error;
    }
  }

  Future<void> restorePurchases() async {
    if (!_available) return;
    await _iap.restorePurchases();
  }
}

enum IAPResult { initiated, storeUnavailable, productNotFound, error }

extension IAPErrorMessage on IAPResult {
  String? get userMessage {
    switch (this) {
      case IAPResult.initiated:
        return null;
      case IAPResult.storeUnavailable:
        return 'The App Store is not available right now. Please try again later.';
      case IAPResult.productNotFound:
        return 'Purchase could not be loaded. Please check your connection and try again.';
      case IAPResult.error:
        return 'Something went wrong. Please try again.';
    }
  }
}

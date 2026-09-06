import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:cubix_blast/core/score_manager.dart';

class IAPService {
  static final IAPService instance = IAPService._();
  IAPService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  static const String premiumProductId = 'cubix_premium_upgrade';

  bool isAvailable = false;
  List<ProductDetails> products = [];

  // En modo Release, usará Google Play real. En Debug usará Mock.
  bool get _useMock => !kReleaseMode;

  Future<void> init() async {
    if (_useMock) {
      debugPrint('IAPService: Running in MOCK mode (Debug).');
      isAvailable = true;
      return;
    }

    isAvailable = await _iap.isAvailable();
    if (!isAvailable) {
      debugPrint('IAPService: InAppPurchase no disponible en este dispositivo.');
      return;
    }

    _subscription = _iap.purchaseStream.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription?.cancel();
    }, onError: (error) {
      debugPrint('IAPService Error: $error');
    });

    await loadProducts();
  }

  Future<void> loadProducts() async {
    if (_useMock || !isAvailable) return;
    
    final response = await _iap.queryProductDetails({premiumProductId});
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('IAPService: Premium product ID no encontrado en Google Play.');
    }
    products = response.productDetails;
  }

  Future<void> buyPremium() async {
    if (_useMock) {
      debugPrint('IAPService MOCK: Simulando compra exitosa...');
      await Future.delayed(const Duration(seconds: 1));
      await ScoreManager.setPremium(true);
      return;
    }

    if (!isAvailable) {
      debugPrint('IAPService: IAP no está disponible.');
      return;
    }

    if (products.isEmpty) {
      debugPrint('IAPService: No hay productos cargados.');
      return;
    }

    try {
      final productDetails = products.firstWhere((p) => p.id == premiumProductId);
      final purchaseParam = PurchaseParam(productDetails: productDetails);
      
      // Inicia el flujo nativo de compra
      _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('IAPService: Producto premium no encontrado en la lista.');
    }
  }

  Future<void> restorePurchases() async {
    if (_useMock) {
      debugPrint('IAPService MOCK: Simulando restauración...');
      await Future.delayed(const Duration(seconds: 1));
      return;
    }
    if (isAvailable) {
      await _iap.restorePurchases();
    }
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        debugPrint('IAPService: Compra pendiente...');
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        debugPrint('IAPService: Error en compra - ${purchaseDetails.error}');
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                 purchaseDetails.status == PurchaseStatus.restored) {
        
        // ¡Compra exitosa o restaurada!
        if (purchaseDetails.productID == premiumProductId) {
          ScoreManager.setPremium(true);
        }

        if (purchaseDetails.pendingCompletePurchase) {
          _iap.completePurchase(purchaseDetails);
        }
      }
    }
  }

  void dispose() {
    if (!_useMock) {
      _subscription?.cancel();
    }
  }
}

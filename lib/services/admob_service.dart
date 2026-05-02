import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'storage_service.dart';

class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  final StorageService _storage = StorageService();

  // Test Ad Units - Replace with production IDs before release
  static String get bannerAdUnitId {
    if (kDebugMode || Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111'; // Android test banner
    }
    return 'ca-app-pub-3940256099942544/2934735716'; // iOS test banner
  }

  static String get interstitialAdUnitId {
    if (kDebugMode || Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712'; // Android test interstitial
    }
    return 'ca-app-pub-3940256099942544/4411468910'; // iOS test interstitial
  }

  static String get rewardedAdUnitId {
    if (kDebugMode || Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917'; // Android test rewarded
    }
    return 'ca-app-pub-3940256099942544/1712485313'; // iOS test rewarded
  }

  static String get appOpenAdUnitId {
    if (kDebugMode || Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/9257395921';
    }
    return 'ca-app-pub-3940256099942544/5575463023';
  }

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  AppOpenAd? _appOpenAd;

  bool _isInterstitialAdLoaded = false;
  bool _isRewardedAdLoaded = false;

  // Banner Ad
  void loadBannerAd(Function(BannerAd) onLoaded) {
    _bannerAd?.dispose();
    _bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          onLoaded(ad as BannerAd);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
    _bannerAd!.load();
  }

  Widget getBannerWidget() {
    if (_bannerAd == null) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }

  // Interstitial Ad - Load aggressively
  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoaded = true;
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isInterstitialAdLoaded = false;
              loadInterstitialAd(); // Preload next
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _isInterstitialAdLoaded = false;
              loadInterstitialAd(); // Retry
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isInterstitialAdLoaded = false;
          Future.delayed(const Duration(seconds: 3), loadInterstitialAd);
        },
      ),
    );
  }

  void showInterstitialAd({VoidCallback? onComplete}) {
    if (_isInterstitialAdLoaded && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _isInterstitialAdLoaded = false;
          loadInterstitialAd();
          onComplete?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _isInterstitialAdLoaded = false;
          loadInterstitialAd();
        },
      );
      _interstitialAd!.show();
      _storage.incrementInterstitialCount();
    } else {
      onComplete?.call();
      loadInterstitialAd();
    }
  }

  // Rewarded Ad
  void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoaded = true;
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isRewardedAdLoaded = false;
              loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _isRewardedAdLoaded = false;
              loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isRewardedAdLoaded = false;
          Future.delayed(const Duration(seconds: 5), loadRewardedAd);
        },
      ),
    );
  }

  void showRewardedAd({required Function(int amount) onReward, VoidCallback? onDismiss}) {
    if (_isRewardedAdLoaded && _rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _isRewardedAdLoaded = false;
          loadRewardedAd();
          onDismiss?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _isRewardedAdLoaded = false;
          loadRewardedAd();
        },
      );
      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          onReward(reward.amount.toInt());
        },
      );
    } else {
      onDismiss?.call();
      loadRewardedAd();
    }
  }

  // App Open Ad
  void loadAppOpenAd() {
    AppOpenAd.load(
      adUnitId: appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
        },
        onAdFailedToLoad: (error) {},
      ),
    );
  }

  void showAppOpenAd() {
    _appOpenAd?.show();
  }

  // Aggressive interstitial strategy: show every 3 runs
  bool shouldShowInterstitial() {
    final runCount = _storage.getRunCount();
    return runCount > 0 && runCount % 3 == 0;
  }

  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _appOpenAd?.dispose();
  }
}

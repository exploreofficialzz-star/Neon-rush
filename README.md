# Neon Rush

A premium endless runner game built with Flutter, featuring cyberpunk visuals, aggressive AdMob monetization, and high-retention gameplay mechanics.

## Game Overview

**Neon Rush** is a high-octane endless runner set in a neon-drenched cyberpunk metropolis. Players dash through three lanes, dodging futuristic obstacles, collecting coins, and activating power-ups to achieve the highest score possible.

## Features

- **Stunning Cyberpunk Visuals** - Neon-lit cityscapes with holographic billboards and rain-slicked streets
- **Three-Lane Endless Running** - Swipe to switch lanes, jump over barriers, slide under drones
- **Power-Up System** - Magnet, Jetpack, Shield, and 2x Score Multiplier
- **Character Collection** - Unlock and equip different cyberpunk runners
- **Hoverboard Customization** - Equip futuristic hoverboards
- **Daily Rewards** - Login streak system with escalating rewards
- **Shop System** - Spend earned coins on characters and boards
- **Professional Sound Design** - Cyberpunk synthwave music and satisfying SFX

## AdMob Monetization Strategy

This game implements an aggressive but professional AdMob strategy:

- **Banner Ads** - Non-intrusive bottom banner during gameplay
- **Interstitial Ads** - Full-screen ads every 3 game runs at natural break points
- **Rewarded Video Ads** - Player-initiated for extra lives, bonus coins, and shop currency
- **App Open Ads** - Shown when user returns to the app

## Tech Stack

- **Flutter** 3.24+
- **Dart** 3.0+
- **google_mobile_ads** for AdMob integration
- **audioplayers** for game audio
- **shared_preferences** for local data persistence

## Package Structure

```
com.chastechgroup.neonrush
```

## Screens

1. **Splash Screen** - "chAs Tech Group" branding with neon glow animation
2. **Main Menu** - Character preview, currency display, navigation
3. **Game Screen** - Core endless runner gameplay
4. **Game Over** - Score display with rewarded ad continue option
5. **Shop** - Character and hoverboard unlock/purchase
6. **Daily Rewards** - Streak-based login rewards
7. **Settings** - Audio toggles, tutorial reset, progress reset

## Build Instructions

### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## GitHub Actions CI/CD

Automated builds are configured via GitHub Actions:
- **Android**: Builds APK and App Bundle on every push to main
- **iOS**: Builds and exports IPA (requires code signing setup)

## Retention Psychology

The game implements proven retention mechanics from top-grossing endless runners:
- Simple one-touch controls (easy to learn, hard to master)
- Score chasing with high score persistence
- Daily login streak rewards
- Coin economy with shop progression
- Power-up variety for gameplay depth
- Visual character progression

## Developer

**chAs Tech Group**

## License

All rights reserved.

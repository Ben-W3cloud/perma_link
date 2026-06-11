class AppConstants {
  const AppConstants._();

  // Walrus testnet endpoints for HTTP publisher/aggregator mode.
  static const String walrusPublisher =
      'https://publisher.walrus-testnet.walrus.space';
  static const String walrusAggregator =
      'https://aggregator.walrus-testnet.walrus.space';

  // Walrus testnet epochs are roughly one day.
  static const int storageEpochs = 3;

  static const int shortCodeLength = 6;
  static const int maxFileSizeBytes = 10 * 1024 * 1024;

  // Change this before deploying with a real domain.
  static const String appDomain = 'https://perma.link';
}

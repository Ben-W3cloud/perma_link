class AppConstants {
  const AppConstants._();

  // Walrus testnet endpoints for HTTP publisher/aggregator mode.
  static const String walrusPublisher =
      'https://publisher.walrus-testnet.walrus.space';
  static const String walrusAggregator =
      'https://aggregator.walrus-testnet.walrus.space';
  // Endpoint paths
  static const String walrusStorePath = '/v1/blobs'; // PUT to upload
  static const String walrusReadPath = '/v1/blobs'; // GET to retrieve

  // Walrus testnet epochs are roughly one day.
  static const int storageEpochs = 3;

  static const int shortCodeLength = 6;
  static const int maxFileSizeBytes = 120 * 1024 * 1024;

  // Change this before deploying with a real domain.
  static const String appDomain = 'https://permalink-gamma.vercel.app';

  // External destinations used by the navbar + landing footer.
  static const String githubUrl = 'https://github.com/Ben-W3Cloud/fluffy_link';
  static const String walrusSiteUrl = 'https://walrus.site';
  static const String suiExplorerUrl = 'https://suiscan.xyz';
}

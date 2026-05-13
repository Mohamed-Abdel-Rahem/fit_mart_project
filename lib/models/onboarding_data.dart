class OnboardingData {
  final String title;
  final String description;
  final String? subDescription;
  final String imagePath;

  OnboardingData({
    required this.title,
    required this.description,
    this.subDescription,
    required this.imagePath,
  });
}

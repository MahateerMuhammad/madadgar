class AppConstants {
  // App General
  static const String appName = 'Madadgar';
  static const String appTagline = 'Community Aid & Resource Sharing';
  
  // Categories
  static const List<String> categories = [
    'Food',
    'Clothing',
    'Education',
    'Medical',
    'Services',
    'Shelter',
    'Other',
  ];
  
  // Regions (Example for Pakistan)
  static const List<String> majorRegions = [
    'Karachi - Gulshan',
    'Karachi - Clifton',
    'Karachi - DHA',
    'Lahore - Model Town',
    'Lahore - Gulberg',
    'Islamabad - F Sectors',
    'Islamabad - G Sectors',
    'Rawalpindi',
    'Peshawar',
    'Quetta',
    // Add more regions as needed
  ];
  
  // Post Types
  static const String typeNeed = 'need';
  static const String typeOffer = 'offer';
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String postsCollection = 'posts';
  static const String chatsCollection = 'chats';
}
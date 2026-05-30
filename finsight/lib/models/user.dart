class User {
  final int userID;
  final String userName;
  final String userEmail;
  final double userMonthlyIncome;
  final DateTime lastLogin;
  final String authMethod;
  final String password;

  User({
    required this.userID,
    required this.userName,
    required this.userEmail,
    required this.userMonthlyIncome,
    required this.lastLogin,
    required this.authMethod,
    required this.password
  });
}
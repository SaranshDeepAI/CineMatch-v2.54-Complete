import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = Get.find<FirestoreService>();

  /// Why Rx variables? → Rx means "reactive". When this value changes,
  /// every widget listening to it automatically rebuilds. Like a live feed!
  final Rxn<User> firebaseUser = Rxn<User>();
  final Rxn<UserModel> userModel = Rxn<UserModel>();
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString loginError = ''.obs;
  final RxString signupError = ''.obs;

  @override
  void onInit() {
    super.onInit();

    /// Why listen to authStateChanges here? → This runs once when app starts.
    /// It keeps watching Firebase — if user logs in/out anywhere,
    /// firebaseUser updates automatically and app reacts instantly
    firebaseUser.bindStream(_authService.authStateChanges);
    ever(firebaseUser, _handleAuthChange);
  }

  /// Called automatically whenever firebaseUser changes
  // NEW
  void _handleAuthChange(User? user) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (user != null) {
      await _loadUserModel(user.uid);

      /// Why check onboardingDone? → new users go to onboarding first
      /// returning users skip straight to home
      if (userModel.value?.onboardingDone == true) {
        Get.offAllNamed('/home');
      } else {
        Get.offAllNamed('/onboarding');
      }
    } else {
      userModel.value = null;
      Get.offAllNamed('/auth');
    }
  }

  Future<void> _loadUserModel(String uid) async {
    final model = await _firestoreService.getUser(uid);
    userModel.value = model;
    if (model != null) {
      await _firestoreService.updateLastActive(uid);
    }
  }

  // --------------------------------------------------
  // SIGN UP
  // --------------------------------------------------

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final credential = await _authService.signUpWithEmail(
        email: email,
        password: password,
        displayName: name,
      );

      if (credential?.user != null) {
        final user = credential!.user!;

        /// Create user document in Firestore on first signup
        final newUser = UserModel(
          uid: user.uid,
          displayName: name,
          email: email,
          photoUrl: user.photoURL,
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
        );
        await _firestoreService.createUser(newUser);
      }
    } on FirebaseAuthException catch (e) {
      signupError.value = _authService.getErrorMessage(e.code);
    } finally {
      isLoading.value = false;
      // clear login error when signup is attempted
      loginError.value = '';
    }
  }

  // --------------------------------------------------
  // SIGN IN
  // --------------------------------------------------

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      await _authService.signInWithEmail(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      loginError.value = _authService.getErrorMessage(e.code);
    } finally {
      isLoading.value = false;
      // clear signup error when login is attempted
      signupError.value = '';
    }
  }

  // --------------------------------------------------
  // GOOGLE SIGN IN
  // --------------------------------------------------

  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final credential = await _authService.signInWithGoogle();
      if (credential?.user != null) {
        final user = credential!.user!;
        final exists = await _firestoreService.userExists(user.uid);

        /// Only create Firestore doc if this is their first time
        if (!exists) {
          final newUser = UserModel(
            uid: user.uid,
            displayName: user.displayName ?? 'CineMatch User',
            email: user.email ?? '',
            photoUrl: user.photoURL,
            createdAt: DateTime.now(),
            lastActiveAt: DateTime.now(),
          );
          await _firestoreService.createUser(newUser);
        }
      }
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _authService.getErrorMessage(e.code);
    } catch (e) {
      loginError.value = 'Google sign-in failed. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  // --------------------------------------------------
  // SIGN OUT
  // --------------------------------------------------

  Future<void> signOut() async {
    await _authService.signOut();
  }

  // --------------------------------------------------
  // HELPERS
  // --------------------------------------------------

  bool get isLoggedIn => firebaseUser.value != null;
  String get userId => firebaseUser.value?.uid ?? '';
  String get userName => userModel.value?.displayName ?? 'User';
  String? get userPhoto => userModel.value?.photoUrl;
}

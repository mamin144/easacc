import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../state/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthState.initial()) {
    _checkAuthState();
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId:
        '911981193074-qoi3ncu8tlkgevqctsha3ppc9pl28sjc.apps.googleusercontent.com',
  );

  Future<void> _checkAuthState() async {
    emit(state.copyWith(isLoading: true));

    try {
      final user = _auth.currentUser;
      if (user != null) {
        emit(AuthState.authenticated(user));
      } else {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('user_id');
        if (userId != null) {
          await _auth.currentUser?.reload();
          final currentUser = _auth.currentUser;
          if (currentUser != null && currentUser.uid == userId) {
            emit(AuthState.authenticated(currentUser));
            return;
          }
        }
        emit(AuthState.unauthenticated());
      }
    } catch (e) {
      emit(AuthState.unauthenticated());
    }
  }

  Future<void> signInWithFacebook() async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final loginResult = await FacebookAuth.instance.login(
        permissions: ['public_profile'],
      );

      if (loginResult.status != LoginStatus.success) {
        emit(state.copyWith(
          isLoading: false,
          error:
              'Facebook login failed: ${loginResult.message ?? 'Unknown error'}',
        ));
        return;
      }

      final accessToken = loginResult.accessToken;
      if (accessToken == null) {
        emit(state.copyWith(
          isLoading: false,
          error: 'Failed to get Facebook access token',
        ));
        return;
      }

      final tokenString = accessToken.token;
      if (tokenString.isEmpty) {
        emit(state.copyWith(
          isLoading: false,
          error: 'Facebook access token is empty',
        ));
        return;
      }

      final credential = FacebookAuthProvider.credential(tokenString);

      final userCredential = await _auth.signInWithCredential(credential);

      final user = userCredential.user;
      if (user == null) {
        emit(state.copyWith(
          isLoading: false,
          error: 'Failed to get user information',
        ));
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', user.uid);

      emit(AuthState.authenticated(user));
    } on FirebaseAuthException catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Authentication failed: ${e.message ?? 'Unknown error'}',
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'An error occurred: ${e.toString()}',
      ));
    }
  }

  Future<void> signInWithGoogle() async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        emit(state.copyWith(isLoading: false));
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      final user = userCredential.user;
      if (user == null) {
        emit(state.copyWith(
          isLoading: false,
          error: 'Failed to get user information',
        ));
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', user.uid);

      emit(AuthState.authenticated(user));
    } on FirebaseAuthException catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Authentication failed: ${e.message ?? 'Unknown error'}',
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'An error occurred: ${e.toString()}',
      ));
    }
  }

  Future<void> signOut() async {
    emit(state.copyWith(isLoading: true));

    try {
      await _auth.signOut();

      await FacebookAuth.instance.logOut();

      await _googleSignIn.signOut();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');

      emit(AuthState.unauthenticated());
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to sign out: ${e.toString()}',
      ));
    }
  }
}

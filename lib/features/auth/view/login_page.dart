import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../controller/auth_controller.dart';
import '../state/auth_state.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authCubit = context.read<AuthCubit>();

    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (previous, next) => previous.error != next.error,
      listener: (context, state) {
        if (state.error != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error ?? 'An error occurred'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      builder: (context, authState) {
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Welcome to EASACC',
                      style: Theme.of(context).textTheme.headlineMedium ??
                          Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Please sign in to continue',
                      style: Theme.of(context).textTheme.bodyLarge ??
                          Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    if (authState.isLoading)
                      const CircularProgressIndicator()
                    else
                      Column(
                        children: [
                          FilledButton.icon(
                            onPressed: () => authCubit.signInWithFacebook(),
                            icon: const Icon(Icons.facebook),
                            label: const Text('Sign in with Facebook'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              minimumSize: const Size(double.infinity, 56),
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () => authCubit.signInWithGoogle(),
                            icon: const Icon(Icons.g_mobiledata),
                            label: const Text('Sign in with Google'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              minimumSize: const Size(double.infinity, 56),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

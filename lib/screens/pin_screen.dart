import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/pin_storage.dart';
import '../services/token_storage.dart';
import '../services/api_service.dart';

class PinScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const PinScreen({super.key, required this.onUnlocked});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final PinStorage _pinStorage = PinStorage();
  String _enteredPin = '';
  String? _error;

  void _onDigitPressed(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += digit;
        _error = null;
      });
      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() => _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1));
    }
  }

  Future<void> _verifyPin() async {
    final savedPin = await _pinStorage.getPin();
    if (_enteredPin == savedPin) {
      widget.onUnlocked();
    } else {
      setState(() {
        _enteredPin = '';
        _error = 'Incorrect PIN';
      });
    }
  }

  void _showForgotPinDialog() {
    final passwordController = TextEditingController();
    final tokenStorage = TokenStorage();
    String? dialogError;
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              title: const Text('Re-authenticate'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter your password to continue',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<String?>(
                    future: tokenStorage.getUsername(),
                    builder: (context, snapshot) {
                      return Text(
                        snapshot.data ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      errorText: dialogError,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : TextButton(
                        onPressed: () async {
                          final password = passwordController.text;
                          if (password.isEmpty) {
                            setDialogState(() => dialogError = 'Enter your password');
                            return;
                          }
                          setDialogState(() {
                            isLoading = true;
                            dialogError = null;
                          });
                          try {
                            final username = await tokenStorage.getUsername();
                            if (username == null) {
                              setDialogState(() {
                                isLoading = false;
                                dialogError = 'Session error. Please login again.';
                              });
                              return;
                            }
                            await ApiService().login(username, password);
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                              widget.onUnlocked();
                            }
                          } catch (e) {
                            setDialogState(() {
                              isLoading = false;
                              dialogError = 'Incorrect password';
                            });
                          }
                        },
                        child: const Text('Verify'),
                      ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.gradientStart, AppColors.gradientEnd],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 36,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'FamilyVault',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your PIN',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final filled = index < _enteredPin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 52,
                    height: 52,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? AppColors.primary : Colors.transparent,
                      border: Border.all(
                        color: filled ? AppColors.primary : AppColors.border,
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                ),
              const SizedBox(height: 40),
              _buildNumpad(),
              const SizedBox(height: 24),
              TextButton(
                onPressed: _showForgotPinDialog,
                child: Text(
                  'Forgot PIN?',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['1', '2', '3'].map((d) => _buildDigitButton(d)).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['4', '5', '6'].map((d) => _buildDigitButton(d)).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['7', '8', '9'].map((d) => _buildDigitButton(d)).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 72, height: 56),
            _buildDigitButton('0'),
            SizedBox(
              width: 72,
              height: 56,
              child: IconButton(
                onPressed: _onBackspace,
                icon: const Icon(Icons.backspace_outlined, size: 22),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDigitButton(String digit) {
    return SizedBox(
      width: 72,
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onDigitPressed(digit),
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Text(
              digit,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }
}

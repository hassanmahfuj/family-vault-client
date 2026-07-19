import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/pin_storage.dart';

class SetPinDialog extends StatefulWidget {
  final bool isChange;

  const SetPinDialog({super.key, this.isChange = false});

  @override
  State<SetPinDialog> createState() => _SetPinDialogState();
}

class _SetPinDialogState extends State<SetPinDialog> {
  final _pinStorage = PinStorage();
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirmStep = false;
  String? _error;

  void _onDigitPressed(String digit) {
    if (_isConfirmStep) {
      if (_confirmPin.length < 4) {
        setState(() {
          _confirmPin += digit;
          _error = null;
        });
        if (_confirmPin.length == 4) {
          _verifyAndSave();
        }
      }
    } else {
      if (_pin.length < 4) {
        setState(() {
          _pin += digit;
          _error = null;
        });
        if (_pin.length == 4) {
          setState(() => _isConfirmStep = true);
        }
      }
    }
  }

  void _onBackspace() {
    if (_isConfirmStep) {
      if (_confirmPin.isNotEmpty) {
        setState(() => _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1));
      } else {
        setState(() => _isConfirmStep = false);
      }
    } else {
      if (_pin.isNotEmpty) {
        setState(() => _pin = _pin.substring(0, _pin.length - 1));
      }
    }
  }

  Future<void> _verifyAndSave() async {
    if (_pin != _confirmPin) {
      setState(() {
        _error = 'PINs do not match';
        _confirmPin = '';
        _isConfirmStep = false;
        _pin = '';
      });
      return;
    }
    await _pinStorage.setPin(_pin);
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPin = _isConfirmStep ? _confirmPin : _pin;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.isChange ? Icons.lock : Icons.lock_outline,
              color: AppColors.primary,
              size: 32,
            ),
            const SizedBox(height: 16),
            Text(
              widget.isChange ? 'Change PIN' : 'Set PIN',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _isConfirmStep ? 'Confirm your PIN' : 'Enter a 4-digit PIN',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final filled = index < currentPin.length;
                return Container(
                  width: 48,
                  height: 48,
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
            const SizedBox(height: 24),
            _buildNumpad(),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['1', '2', '3']
              .map((d) => _buildDigitButton(d))
              .toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['4', '5', '6']
              .map((d) => _buildDigitButton(d))
              .toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['7', '8', '9']
              .map((d) => _buildDigitButton(d))
              .toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 64, height: 48),
            _buildDigitButton('0'),
            SizedBox(
              width: 64,
              height: 48,
              child: IconButton(
                onPressed: _onBackspace,
                icon: const Icon(Icons.backspace_outlined, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDigitButton(String digit) {
    return SizedBox(
      width: 64,
      height: 48,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onDigitPressed(digit),
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Text(
              digit,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }
}

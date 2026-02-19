import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routes/navigation_helper.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/security/secure_session_manager.dart';

/// Confirm Mnemonic Screen
/// 
/// User confirms they've backed up mnemonic by selecting words.
/// 
/// SECURITY ARCHITECTURE:
/// - Mnemonic received via SECURE SESSION (not navigation argument)
/// - Session ID passed in navigation (safe)
/// - Mnemonic retrieved from SecureSessionManager
/// - Mnemonic stored in local variable (NOT reactive state)
/// - Mnemonic cleared from memory when screen is disposed
/// - Session cleared when screen is disposed
/// - Mnemonic NEVER logged or printed
/// - After successful verification, navigate with offAllNamed to clear stack
/// 
/// Memory Management:
/// 1. Receive session ID from navigation argument
/// 2. Retrieve mnemonic from SecureSessionManager
/// 3. Store in local String variable (not Rx)
/// 4. Generate random verification indices
/// 5. Validate user selections
/// 6. Clear from memory in dispose()
/// 7. Clear session in dispose()
/// 8. Clear navigation stack after success
/// 
/// Security Principles:
/// - Minimize mnemonic lifetime in memory
/// - No persistence in reactive state
/// - No logging or debugging output
/// - Clear navigation stack to remove mnemonic from memory
/// - Validation happens locally (no network calls)
/// - Auto-expiring sessions (5 minutes)
/// 
/// Navigation Flow:
/// - Receives: sessionId (String) from BackupMnemonicScreen
/// - After success: Navigate to Home with offAllNamed (clears stack)
/// - This ensures mnemonic is removed from navigation memory
class ConfirmMnemonicScreen extends StatefulWidget {
  const ConfirmMnemonicScreen({super.key});

  @override
  State<ConfirmMnemonicScreen> createState() => _ConfirmMnemonicScreenState();
}

class _ConfirmMnemonicScreenState extends State<ConfirmMnemonicScreen> {
  // SECURITY: Session ID (safe to store)
  String? _sessionId;

  // SECURITY: Mnemonic stored in local variable, NOT reactive state
  String? _mnemonic;
  List<String>? _mnemonicWords;

  // Random indices to verify (generated from mnemonic)
  List<int> _requiredIndices = [];
  final Map<int, String?> _selectedWords = {};
  bool _isLoading = false;
  String? _errorMessage;

  // Available words for selection (shuffled)
  List<String> _availableWords = [];

  @override
  void initState() {
    super.initState();
    _loadMnemonicAndGenerateVerification();
  }

  /// Load mnemonic from secure session and generate verification
  /// 
  /// SECURITY:
  /// - Session ID passed via Get.arguments (safe)
  /// - Mnemonic retrieved from SecureSessionManager
  /// - Stored in local variable (not reactive state)
  /// - Never logged or printed
  /// - Random indices generated for verification
  void _loadMnemonicAndGenerateVerification() {
    try {
      // Get session ID from navigation arguments
      final args = Get.arguments as Map<String, dynamic>?;
      _sessionId = args?['sessionId'] as String?;

      if (_sessionId != null) {
        // Retrieve mnemonic from secure session
        _mnemonic = SecureSessionManager.getMnemonic(_sessionId!);

        if (_mnemonic != null && _mnemonic!.isNotEmpty) {
          // Split into words
          _mnemonicWords = _mnemonic!.trim().split(RegExp(r'\s+'));

          // SECURITY: Validate word count (should be 24 words)
          if (_mnemonicWords!.length != 24) {
            _showErrorAndGoBack('Invalid recovery phrase format');
            return;
          }

          // Generate random indices for verification (3 words)
          _generateRandomIndices();

          // Generate shuffled word list for selection
          _generateAvailableWords();
        } else {
          // Session expired or invalid
          _showErrorAndGoBack('Session expired. Please try again.');
        }
      } else {
        _showErrorAndGoBack('No session provided');
      }
    } catch (e) {
      _showErrorAndGoBack('Failed to load recovery phrase');
    }
  }

  /// Generate random indices for word verification
  /// 
  /// SECURITY: Uses cryptographically secure random for unpredictability
  void _generateRandomIndices() {
    final random = math.Random.secure();
    final indices = <int>{};

    // Generate 3 unique random indices
    while (indices.length < 3) {
      indices.add(random.nextInt(24));
    }

    _requiredIndices = indices.toList()..sort();
  }

  /// Generate available words for selection
  /// 
  /// Includes correct words + random incorrect words, then shuffles
  void _generateAvailableWords() {
    final random = math.Random.secure();
    final words = <String>{};

    // Add correct words
    for (final index in _requiredIndices) {
      words.add(_mnemonicWords![index]);
    }

    // Add random incorrect words (9 more to make 12 total)
    while (words.length < 12) {
      final randomIndex = random.nextInt(24);
      words.add(_mnemonicWords![randomIndex]);
    }

    // Shuffle the words
    _availableWords = words.toList()..shuffle(random);
  }

  void _showErrorAndGoBack(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.accentRed,
      colorText: AppTheme.textPrimary,
    );
    Get.back();
  }

  @override
  void dispose() {
    // SECURITY: Clear mnemonic from memory when screen is disposed
    // This ensures mnemonic doesn't remain in memory longer than necessary
    if (_mnemonic != null) {
      // Overwrite string in memory (best effort in Dart)
      _mnemonic = '';
      _mnemonic = null;
    }
    if (_mnemonicWords != null) {
      _mnemonicWords!.clear();
      _mnemonicWords = null;
    }
    _availableWords.clear();
    
    // SECURITY: Clear session when leaving screen
    // This ensures session doesn't persist longer than needed
    if (_sessionId != null) {
      SecureSessionManager.clearSession(_sessionId!);
      _sessionId = null;
    }
    
    super.dispose();
  }

  bool get _allWordsSelected =>
      _requiredIndices.every((index) => _selectedWords[index] != null);

  void _selectWord(int index, String word) {
    setState(() {
      _selectedWords[index] = word;
      _errorMessage = null;
    });
  }

  void _clearWord(int index) {
    setState(() {
      _selectedWords[index] = null;
      _errorMessage = null;
    });
  }

  void _handleVerify() {
    if (!_allWordsSelected) {
      setState(() {
        _errorMessage = 'Please select all required words';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // SECURITY: Validate locally without network calls
    // Compare selected words with actual mnemonic words
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;

      // Validate all selected words match the mnemonic
      bool isValid = _requiredIndices.every((index) {
        final selectedWord = _selectedWords[index];
        final correctWord = _mnemonicWords![index];
        return selectedWord == correctWord;
      });

      if (isValid) {
        // SECURITY: Success - navigate to home with offAllNamed
        // This clears the entire navigation stack, removing mnemonic from memory
        // The dispose() method will also clear local mnemonic variables
        NavigationHelper.completeWalletCreation();
      } else {
        // Failed verification - allow retry
        setState(() {
          _isLoading = false;
          _errorMessage = 'Incorrect words selected. Please try again.';
          // Clear selections to allow retry
          _selectedWords.clear();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Recovery Phrase'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Instructions
                Text(
                  'Verify Your Backup',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppTheme.spacingM),
                Text(
                  'Select the correct words to verify you have written down your recovery phrase.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: AppTheme.spacingXL),

                // Word Selection Slots
                ..._requiredIndices.map((index) => Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
                      child: _buildWordSlot(context, index),
                    )),

                const SizedBox(height: AppTheme.spacingXL),

                // Error Message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    decoration: BoxDecoration(
                      color: AppTheme.accentRed.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      border: Border.all(
                        color: AppTheme.accentRed.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppTheme.accentRed,
                          size: 20,
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.accentRed,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                ],

                // Available Words Label
                Text(
                  'Select from these words:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: AppTheme.spacingM),

                // Available Words Grid
                Wrap(
                  spacing: AppTheme.spacingS,
                  runSpacing: AppTheme.spacingS,
                  children: _availableWords.map((word) {
                    final isSelected = _selectedWords.values.contains(word);
                    return _buildWordChip(word, isSelected);
                  }).toList(),
                ),

                const SizedBox(height: AppTheme.spacingXXL),

                // Verify Button
                PrimaryButton(
                  text: 'Verify & Complete Setup',
                  onPressed: _allWordsSelected ? _handleVerify : null,
                  isLoading: _isLoading,
                  icon: Icons.check_circle_outline,
                ),
                const SizedBox(height: AppTheme.spacingL),

                // Help Text
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppTheme.primaryPurple,
                        size: 20,
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: Text(
                          'Tap a word to select it. Tap the selected word in the slot to remove it.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWordSlot(BuildContext context, int index) {
    final selectedWord = _selectedWords[index];
    final hasWord = selectedWord != null;

    return InkWell(
      onTap: hasWord ? () => _clearWord(index) : null,
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
            color: hasWord
                ? AppTheme.primaryPurple.withOpacity(0.5)
                : AppTheme.textTertiary.withOpacity(0.2),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: hasWord
                    ? AppTheme.primaryPurple.withOpacity(0.2)
                    : AppTheme.cardDark,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: hasWord
                            ? AppTheme.primaryPurple
                            : AppTheme.textTertiary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: Text(
                selectedWord ?? 'Select word ${index + 1}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: hasWord ? AppTheme.textPrimary : AppTheme.textTertiary,
                      fontFamily: hasWord ? 'monospace' : null,
                      fontWeight: hasWord ? FontWeight.w600 : FontWeight.normal,
                    ),
              ),
            ),
            if (hasWord)
              Icon(
                Icons.close,
                size: 20,
                color: AppTheme.textSecondary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordChip(String word, bool isSelected) {
    return InkWell(
      onTap: isSelected
          ? null
          : () {
              // Find first empty slot
              final emptyIndex = _requiredIndices.firstWhere(
                (index) => _selectedWords[index] == null,
                orElse: () => -1,
              );
              if (emptyIndex != -1) {
                _selectWord(emptyIndex, word);
              }
            },
      borderRadius: BorderRadius.circular(AppTheme.radiusL),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingS,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.textTertiary.withOpacity(0.2)
              : AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(
            color: isSelected
                ? AppTheme.textTertiary.withOpacity(0.3)
                : AppTheme.primaryPurple.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          word,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected ? AppTheme.textTertiary : AppTheme.textPrimary,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
              ),
        ),
      ),
    );
  }
}

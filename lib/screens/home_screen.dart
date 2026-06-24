import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kids_tracing_app/constants/app_constants.dart';
import 'package:kids_tracing_app/providers/learning_provider.dart';
import 'package:kids_tracing_app/screens/completion_screen.dart';
import 'package:kids_tracing_app/widgets/progress_indicator_widget.dart';
import 'package:kids_tracing_app/widgets/success_dialog.dart';
import 'package:kids_tracing_app/widgets/tracing_canvas.dart';
import 'package:provider/provider.dart';

/// Main learning screen where children trace a single large number.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  DateTime? _lastBackPressed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<LearningProvider>();
      debugPrint('HomeScreen: initializing audio');
      await provider.initialize();
      debugPrint('HomeScreen: calling playBackgroundMusic()');
      await provider.audioService.playBackgroundMusic();
      debugPrint('HomeScreen: playBackgroundMusic() returned');
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    context.read<LearningProvider>().audioService.stopBackgroundMusic();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    debugPrint('HomeScreen: lifecycle -> $state');

    if (!mounted) return;

    final audio = context.read<LearningProvider>().audioService;

    switch (state) {
      case AppLifecycleState.resumed:
        audio.resumeBackgroundMusic();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        audio.pauseBackgroundMusic();
        break;
      case AppLifecycleState.detached:
        audio.stopBackgroundMusic();
        break;
    }
  }

  Future<void> _handleSuccessFinished(LearningProvider provider) async {
    final wasLast = provider.isLastNumber;
    await provider.advanceAfterSuccess();

    if (!mounted) {
      return;
    }

    if (wasLast) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const CompletionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LearningProvider>(
      builder: (context, provider, _) {
        final currentNumber = provider.currentItem.number;

        return PopScope<Object?>(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, Object? result) async {
            if (didPop) return;
            final now = DateTime.now();

            if (_lastBackPressed == null ||
                now.difference(_lastBackPressed!) >
                    const Duration(seconds: 2)) {
              _lastBackPressed = now;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Press back again to exit'),
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }

            final choice = await showDialog<String>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Exit App?'),
                content: const Text(
                  'Do you want to exit or continue learning?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop('resume'),
                    child: const Text('Resume'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop('exit'),
                    child: const Text('Exit'),
                  ),
                ],
              ),
            );

            if (choice == 'exit') {
              SystemNavigator.pop();
            }
          },
          child: Scaffold(
            backgroundColor: AppConstants.backgroundColor,
            body: SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      Flexible(
                        flex: 5,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Trace the Number',
                                style: GoogleFonts.baloo2(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  color: AppConstants.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Number $currentNumber of ${AppConstants.maxNumber}',
                                style: GoogleFonts.baloo2(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: AppConstants.primaryColor.withValues(
                                    alpha: 0.85,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Flexible(
                        flex: 9,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: TracingCanvas(
                            key: ValueKey(currentNumber),
                            digit: currentNumber,
                          ),
                        ),
                      ),
                      Flexible(
                        flex: 6,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ProgressIndicatorWidget(
                                progress: provider.tracingProgress,
                              ),
                              const SizedBox(height: 18),
                              _BottomButtonRow(
                                currentNumber: currentNumber,
                                canGoPrevious: provider.canGoPrevious,
                                canGoNext: provider.canGoNext,
                                isTracingComplete: provider.isTracingComplete,
                                onClear: provider.clearTracing,
                                onPrevious: provider.goToPrevious,
                                onNext: provider.goToNext,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (provider.showSuccessOverlay)
                    SuccessOverlay(
                      onFinished: () => _handleSuccessFinished(provider),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BottomButtonRow extends StatelessWidget {
  const _BottomButtonRow({
    required this.currentNumber,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.isTracingComplete,
    required this.onClear,
    required this.onPrevious,
    required this.onNext,
  });

  final int currentNumber;
  final bool canGoPrevious;
  final bool canGoNext;
  final bool isTracingComplete;
  final VoidCallback onClear;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: isTracingComplete ? null : onClear,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.secondaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.buttonBorderRadius,
                    ),
                  ),
                ),
                child: Text(
                  'Clear',
                  style: GoogleFonts.baloo2(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: canGoPrevious ? onPrevious : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.buttonBorderRadius,
                    ),
                  ),
                ),
                icon: const Icon(Icons.arrow_back_rounded),
                label: Text(
                  'Previous',
                  style: GoogleFonts.baloo2(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: AppConstants.surfaceColor,
                borderRadius: BorderRadius.circular(
                  AppConstants.buttonBorderRadius,
                ),
                border: Border.all(
                  color: AppConstants.guideDotColor.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                '$currentNumber/${AppConstants.maxNumber}',
                textAlign: TextAlign.center,
                style: GoogleFonts.baloo2(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: canGoNext ? onNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.buttonBorderRadius,
                    ),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(
                  'Next',
                  style: GoogleFonts.baloo2(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

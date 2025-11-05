import 'package:flutter/material.dart';

/// Error state widget
/// Displays error messages with optional retry action

class ErrorWidget extends StatelessWidget {
  final String message;
  final String? title;
  final IconData? icon;
  final VoidCallback? onRetry;
  final String? retryText;
  
  const ErrorWidget({
    super.key,
    required this.message,
    this.title,
    this.icon,
    this.onRetry,
    this.retryText,
  });
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error icon
            Icon(
              icon ?? Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            
            // Title
            if (title != null) ...[
              Text(
                title!,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
            
            // Error message
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
              textAlign: TextAlign.center,
            ),
            
            // Retry button
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryText ?? 'Retry'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Inline error message widget
class InlineError extends StatelessWidget {
  final String message;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  
  const InlineError({
    super.key,
    required this.message,
    this.icon,
    this.backgroundColor,
    this.textColor,
  });
  
  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ??
        Theme.of(context).colorScheme.error.withValues(alpha: 0.1);
    final txtColor = textColor ?? Theme.of(context).colorScheme.error;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: txtColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon ?? Icons.error_outline,
            color: txtColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: txtColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Network error widget with specific messaging
class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;
  
  const NetworkErrorWidget({
    super.key,
    this.onRetry,
  });
  
  @override
  Widget build(BuildContext context) {
    return ErrorWidget(
      title: 'Connection Error',
      message: 'Unable to connect to the server. Please check your internet connection and try again.',
      icon: Icons.wifi_off,
      onRetry: onRetry,
    );
  }
}

/// Not found error widget
class NotFoundWidget extends StatelessWidget {
  final String? message;
  final VoidCallback? onGoBack;
  
  const NotFoundWidget({
    super.key,
    this.message,
    this.onGoBack,
  });
  
  @override
  Widget build(BuildContext context) {
    return ErrorWidget(
      title: 'Not Found',
      message: message ?? 'The requested content could not be found.',
      icon: Icons.search_off,
      onRetry: onGoBack,
      retryText: 'Go Back',
    );
  }
}

/// Permission denied widget
class PermissionDeniedWidget extends StatelessWidget {
  final String? message;
  
  const PermissionDeniedWidget({
    super.key,
    this.message,
  });
  
  @override
  Widget build(BuildContext context) {
    return ErrorWidget(
      title: 'Permission Denied',
      message: message ?? 'You don\'t have permission to access this content.',
      icon: Icons.lock_outline,
    );
  }
}
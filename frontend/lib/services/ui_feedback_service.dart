
import 'package:flutter/material.dart';
import 'package:frontend/app.dart';
import 'package:frontend/UI/app_colors.dart';
import 'package:frontend/UI/constants.dart';

enum NotificationType {
	error,
	neutral,
	success,
}

class UIfeedbackService {
	static OverlayEntry? _activeTopMessage;
	static int _activeTopMessageId = 0;

	static void notification({
		required String message,
		required NotificationType type,
	}) {
		final navigatorState = rootNavigatorKey.currentState;
		final BuildContext? rootContext = navigatorState?.context;
		final OverlayState? overlay = navigatorState?.overlay;

		if (rootContext == null || overlay == null) {
			return;
		}

		final colorScheme = Theme.of(rootContext).colorScheme;
		final appColors = Theme.of(rootContext).extension<AppColors>();
		final int messageId = ++_activeTopMessageId;

		_activeTopMessage?.remove();

		void hideMessage() {
			_activeTopMessage?.remove();
			_activeTopMessage = null;
		}

		final Color backgroundColor = switch (type) {
			NotificationType.error => colorScheme.errorContainer,
			NotificationType.success => appColors?.success ?? colorScheme.tertiaryContainer,
			NotificationType.neutral => colorScheme.primary,
		};

		final Color foregroundColor = switch (type) {
			NotificationType.error => colorScheme.onErrorContainer,
			NotificationType.success => appColors?.onSuccess ?? colorScheme.onTertiaryContainer,
			NotificationType.neutral => colorScheme.onPrimary,
		};

		_activeTopMessage = OverlayEntry(
			builder: (context) {
				return Positioned(
					top: 0,
					left: 0,
					right: 0,
					child: SafeArea(
						minimum: const EdgeInsets.fromLTRB(12, 12, 12, 0),
						child: Align(
							alignment: Alignment.topCenter,
							child: ConstrainedBox(
								constraints: const BoxConstraints(maxWidth: 760),
								child: Material(
									color: backgroundColor,
									elevation: 8,
									borderRadius: BorderRadius.circular(Const.containerRadius),
									child: Padding(
										padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
										child: Row(
											children: [
												Expanded(
													child: Text(
														message,
														style: TextStyle(color: foregroundColor),
													),
												),
												const SizedBox(width: 8),
												TextButton(
													onPressed: hideMessage,
													child: Text(
														'Schließen',
														style: TextStyle(color: foregroundColor),
													),
												),
											],
										),
									),
								),
							),
						),
					),
				);
			},
		);

		overlay.insert(_activeTopMessage!);

		Future<void>.delayed(const Duration(seconds: 3), () {
			if (messageId == _activeTopMessageId) {
				hideMessage();
			}
		});
	}
}
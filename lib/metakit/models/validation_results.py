from __future__ import annotations

from collections import defaultdict

# Tracks validation results for a system's database attributes
class ValidationResults:
    def __init__(self) -> None:
        self.errors = defaultdict(list)
        self.warnings = defaultdict(list)

        # The scope (typically the database key) to group related errors
        self.scope = ''

    # Track a new error in the given (or default) scope.
    # 
    # Errors will result in a non-zero exit code for validation.
    def error(self, message: str, scope: str = None) -> None:
        self._add(self.errors, message, scope)

    # Track a new warning in the given (or default) scope.
    # 
    # Warnings will *not* result in a non-zero exit code for validation.
    def warning(self, message: str, scope: str = None) -> None:
        self._add(self.warnings, message, scope)

    # Adds a new validation result
    def _add(self, results, message: str, scope: str = None) -> None:
        if not scope:
            scope = self.scope

        results[scope].append(message)

"""User-selectable UI language.

The language choice lives in GSettings and is applied to the process
environment before any widget is built, because gettext resolves a message at
call time and GTK resolves builder strings at parse time.
"""

from __future__ import annotations

import gettext
import locale
import os
from typing import Any, Callable

LANGUAGE_CHOICES: tuple[str, ...] = ("system", "zh_CN", "en_US")
SETTINGS_SCHEMA_ID = "com.jaoushingan.WaydroidHelper"
TEXT_DOMAIN = "waydroid-helper"

# Locale the C library should run in for each language.  The catalog lookup
# uses the language list, the locale decides the character encoding.
LOCALE_BY_LANGUAGE: dict[str, str] = {
    "zh_CN": "zh_CN.UTF-8",
    "en_US": "en_US.UTF-8",
}
LANGUAGE_LIST_BY_LANGUAGE: dict[str, str] = {
    "zh_CN": "zh_CN",
    "en_US": "en_US:en:C",
}
# Used when the language's own locale is not generated on the system.  Any
# locale that is not "C" works, because LANGUAGE still selects the catalog.
FALLBACK_LOCALE = "en_US.UTF-8"
# Always UTF-8, so translated text survives the conversion gettext applies.
UTF8_FALLBACK = "C.UTF-8"

_LANGUAGE_KEY = "LANGUAGE"
_LOCALE_KEYS = ("LC_ALL", "LC_MESSAGES", "LC_CTYPE")
_SYSTEM_ENV_KEYS = (_LANGUAGE_KEY,) + _LOCALE_KEYS
_INITIAL_SYSTEM_ENV: dict[str, str | None] = {
    key: os.environ.get(key) for key in _SYSTEM_ENV_KEYS
}


def _locale_activatable(name: str) -> bool:
    """Report whether the C library can switch to the given locale."""
    current = locale.setlocale(locale.LC_ALL)
    try:
        locale.setlocale(locale.LC_ALL, name)
        return True
    except locale.Error:
        return False
    finally:
        try:
            locale.setlocale(locale.LC_ALL, current)
        except locale.Error:
            pass


def _restore(keys: tuple[str, ...], baseline: dict[str, str | None], target_env: dict[str, str]) -> None:
    for key in keys:
        value = baseline.get(key)
        if value is None:
            target_env.pop(key, None)
        else:
            target_env[key] = value


def apply_language_preference(
    language: str,
    environ: dict[str, str] | None = None,
    system_env: dict[str, str | None] | None = None,
    locale_probe: Callable[[str], bool] | None = None,
) -> str:
    """Point gettext and the C library at the requested language.

    Returns the normalized language, which is "system" for an unknown value.
    """
    target_env = os.environ if environ is None else environ
    baseline = _INITIAL_SYSTEM_ENV if system_env is None else system_env
    normalized = language if language in LANGUAGE_CHOICES else "system"
    probe = _locale_activatable if locale_probe is None else locale_probe

    if normalized == "system":
        _restore(_SYSTEM_ENV_KEYS, baseline, target_env)
    else:
        target_env[_LANGUAGE_KEY] = LANGUAGE_LIST_BY_LANGUAGE[normalized]
        # LC_ALL wins over LC_MESSAGES in the C library, so an inherited
        # LC_ALL would keep overriding the language the user picked.
        target_env.pop("LC_ALL", None)

        message_locale = LOCALE_BY_LANGUAGE[normalized]
        if not probe(message_locale):
            message_locale = FALLBACK_LOCALE
        if probe(message_locale):
            target_env["LC_MESSAGES"] = message_locale
        else:
            _restore(("LC_MESSAGES",), baseline, target_env)

        ctype = LOCALE_BY_LANGUAGE[normalized]
        if not probe(ctype):
            ctype = UTF8_FALLBACK
        if probe(ctype):
            target_env["LC_CTYPE"] = ctype
        else:
            _restore(("LC_CTYPE",), baseline, target_env)

    if target_env is os.environ:
        _bind_text_domain()

    return normalized


def _bind_text_domain() -> None:
    """Bind the text domain and refresh the C library message locale."""
    for category in (locale.LC_MESSAGES, locale.LC_CTYPE):
        try:
            locale.setlocale(category, "")
        except locale.Error:
            pass
    localedir = os.environ.get("LOCALEDIR", "/usr/share/locale")
    locale.bindtextdomain(TEXT_DOMAIN, localedir)
    locale.textdomain(TEXT_DOMAIN)
    gettext.bindtextdomain(TEXT_DOMAIN, localedir)
    gettext.textdomain(TEXT_DOMAIN)


def read_language_preference(settings: Any | None = None) -> str:
    """Read the stored language, or "system" when the schema is unavailable."""
    try:
        from gi.repository import Gio

        source = Gio.SettingsSchemaSource.get_default()
        if source is None or source.lookup(SETTINGS_SCHEMA_ID, True) is None:
            return "system"
        active_settings = settings or Gio.Settings(schema_id=SETTINGS_SCHEMA_ID)
        return active_settings.get_string("language")
    except Exception:
        return "system"


def load_saved_language_preference(settings: Any | None = None) -> str:
    """Apply the stored language to the current process."""
    return apply_language_preference(read_language_preference(settings))

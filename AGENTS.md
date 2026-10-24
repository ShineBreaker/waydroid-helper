# AGENTS.md

Working notes for agents and contributors to waydroid-helper.

## What this project is

waydroid-helper is a PyGObject (GTK4 + libadwaita) desktop app for configuring
Waydroid, managing key mappings, and installing extensions. It ships as:

- a main GUI process (`waydroid-helper`)
- a separate key mapper overlay process, spawned with `multiprocessing` using the
  `spawn` start method, so it needs the locale and GSettings state set up
  independently
- a privileged helper shell script (`waydroid-cli`) invoked through
  `pkexec` under a polkit policy

Two directories carry the whole UI: `waydroid_helper/` (Python) and `data/ui/`
(GtkBuilder XML).

## Build and test

The build system is Meson. `meson.build` wires the `po/`, `data/`, `dbus/`,
`systemd/`, and `waydroid_helper/` subdirectories.

```bash
meson setup --prefix /usr build
ninja -C build install
meson test -C build          # runs pytest over tests/
```

`meson test` shells out to `pytest`, so `pytest -q tests` works too.

Dependencies for a dev checkout: GTK4, libadwaita, PyGObject 3.50, pycairo,
pywayland, dbus-python, aiofiles, httpx, PyYAML, gettext, meson, ninja.

### Running tests without a display

`tests/conftest.py` stubs out `waydroid_helper.controller` and
`waydroid_helper.util` before importing controller internals, so unit tests
never create a window, start the log listener process, or need a display
server. Keep new tests inside that constraint: if a test needs a widget, use a
fake object (see `tests/controller/test_widget_transparency_controller.py` for
the pattern) instead of instantiating GTK.

## Architecture rules the tests enforce

`tests/controller/test_controller_architecture_boundaries.py` is the executable
spec for the controller's layering. Read it before restructuring.

- **No global screen state.** The controller reads geometry from
  `ScreenGeometry`, never from `ScreenInfo` or a `_screen_info` attribute.
- **No bare `except:`** in `skill_casting.py`. Every handler names the
  exception it catches.
- **`editable.py` owns no session state.** It reads editing state from
  `EditableCaptureSession` (`editable_session.py`) and key registration from
  `EditableKeyMappingRegistrar` (`editable_mapping.py`).

The layering that satisfies those rules:

```
controller/core/       toolkit-free logic: event bus, key system, control
                       messages, runtime context, event handler chain
controller/app/        GTK adapters: window, input router, mode controller,
                       layout service, widget services
controller/ui/         menus and styles
controller/widgets/     base widget, components, decorators, config system
controller/platform/   wayland and x11 backends
```

Two conventions hold the layers apart:

- **Runtime state is injected, never global.** `ControllerRuntimeContext`
  carries the event bus, key registry, screen geometry, and pointer ownership
  into widgets. Widgets receive it in their constructor.
- **Cross-layer capability checks go through protocols.**
  `controller/app/widget_capabilities.py` defines `Protocol` classes
  (`SelectableWidget`, `ResizableWidget`, and so on) plus helper functions that
  check with `isinstance` against the protocol. Use those helpers rather than
  `isinstance` against a concrete widget class, and rather than
  `hasattr` duck typing.

`controller/widgets/factory.py` discovers widget classes by scanning
`controller/widgets/components/`, so a new component file is picked up
automatically. It still needs an entry in `components/__init__.py`.

Pointer ownership is exclusive and instance-scoped. `PointerInputOwnership`
in `controller/core/runtime.py` hands the pointer to exactly one owner at a
time. `transfer()` exists so a handoff (Aim to Fire) never passes through
`None`, which would let the default mouse handler inject a second pointer
stream.

## Adding a file

Files are installed by explicit lists, so a new file that is not registered
silently does not ship.

- Python source: add the path to the matching list in
  `waydroid_helper/meson.build`.
- Translatable Python source or `.ui` file: also add it to `po/POTFILES`.
  A file missing from `POTFILES` produces no translation entries.
- New locale: add it to `po/LINGUAS`, and add the `.mo` path to the `%files`
  list in `waydroid-helper.spec`.

## Internationalization

The gettext domain is `waydroid-helper`. Strings reach the UI through two
paths.

**Python strings** use `from gettext import gettext as _` and the `_("...")`
call. Widget metadata uses a context so the same English word can differ by
screen:

```python
from gettext import pgettext

WIDGET_NAME = pgettext("Controller Widgets", "Fire")
```

**`.ui` files** mark translatable properties with `translatable="yes"` on
`label`, `title`, `subtitle`, `tooltip-text`, and `placeholder-text`. GTK
resolves those at parse time, so the text domain must be bound before the
template loads.

### Regenerating the translation template

```bash
ninja -C build waydroid-helper-pot          # regenerate po/waydroid-helper.pot
msgmerge --no-fuzzy-matching po/zh_CN.po po/waydroid-helper.pot
msgfmt --check --statistics -o /dev/null po/zh_CN.po
```

`po/meson.build` passes `--keyword=pgettext:1c,2` to xgettext. Meson's `glib`
preset has no Python keywords, so without that argument every
`Controller Widgets` entry disappears on regeneration.

### The language switch

`waydroid_helper/config/language.py` holds the logic. The choice lives in the
`language` GSettings key with three values: `system`, `zh_CN`, `en_US`.
`apply_language_preference()` sets `LANGUAGE`, `LC_MESSAGES`, and `LC_CTYPE`,
then binds the text domain for both the C library and Python's `gettext`.

Three facts drive the design:

- Python's `gettext` resolves a message at call time, so changing the
  environment changes later `_()` calls.
- GTK resolves builder strings at parse time, so the domain must be bound
  before a `.ui` template loads. `waydroid-helper.in` binds it at startup, and
  `controller/app/window.py` binds it again in the spawned overlay process,
  which does not inherit the parent's bindings.
- The C library resolves catalogs through the *effective* `LC_MESSAGES`
  locale, not through `LANGUAGE` alone. A process running in the `C` locale
  finds no catalog even with `LANGUAGE=zh_CN` set.

That last point shapes the environment manipulation:

- `LC_ALL` is removed when a language is chosen. `LC_ALL` overrides
  `LC_MESSAGES`, so an inherited `LC_ALL=C` would keep the old locale and
  silently split the UI: GTK strings stay English while Python strings turn
  Chinese.
- `LC_MESSAGES` is set to a locale that actually exists on the system. The
  probe in `_locale_activatable()` checks before use, falling back to
  `en_US.UTF-8` so the catalog lookup still works.
- `LC_CTYPE` is set separately. The C library transcodes catalog text into the
  `LC_CTYPE` encoding, so a non-UTF-8 `LC_CTYPE` turns Chinese into `???`.

`LOCALEDIR` carries the locale directory to the spawned process through the
environment.

The Preferences dialog writes the setting and prompts for a restart, because
widgets already built keep the strings they were parsed with.

### Translating by hand

- Write the English `msgid` in the source, then fill in `msgstr` in every
  locale you maintain. A `msgstr` left empty falls back to English.
- `msgfmt --check --statistics` reports untranslated and fuzzy counts. Keep
  `zh_CN` at zero untranslated.
- `#, python-brace-format` markers are required for messages using
  `str.format` placeholders.
- Chinese `zh_TW` uses traditional characters; `zh_CN` uses simplified. The
  two files are separate, not generated from each other.

## Runtime configuration

`RootConfig` in `waydroid_helper/config/models.py` maps GObject properties to
GSettings keys through the declarative `SettingsBinding` tables. New
persistent settings follow the same pattern:

1. Add the key to `data/com.jaoushingan.WaydroidHelper.gschema.xml`.
2. Add a `SettingsBinding` to the relevant group in `RootConfig`.
3. Add the key to `DEFAULT_SETTINGS` and `SETTING_TYPES` in
   `tests/config/test_root_config_gsettings.py`.

The old JSON config file under `~/.config/waydroid-helper/` is read exactly
once, for migration, and never written.

`data/com.jaoushingan.WaydroidHelper.gschema.xml` carries
`gettext-domain="waydroid-helper"`, so schema summaries are translated too.

## Documentation

`README.md`, `README_zh.md`, and `README_ru.md` are parallel files linked from
each other's first section. `docs/KEY_MAPPING.md` and
`docs/KEY_MAPPING_zh.md` are the parallel key mapping guides. When behavior
changes, update the English file and its translated counterpart together.

Documentation describes what the code does today. Verify against the source
before writing.

## Code style

- Comments and docstrings are written in Chinese, matching the existing
  files. Newer modules use English docstrings; match the file you edit.
- Type hints on public functions. `from __future__ import annotations` at the
  top of modules that use modern syntax.
- Logging goes through `from waydroid_helper.util.log import logger`. Do not
  use `print`.
- GObject signal handlers that would otherwise keep a dead object alive use
  `connect_weakly` from `waydroid_helper/util/weak_ref.py`.
- `# pyright: ...` pragmas at the top of a file suppress type-checker noise.
  Add one rather than scattering ignores.

## Commit conventions

Commit messages follow the global `~/.config/git/gitmessage` types: `feat`,
`fix`, `refactor`, `perf`, `style`, `chore`, `build`, `ci`, `docs`, `test`,
`revert`. Use the scoped form `type(scope): subject` where a scope applies.

AI-assisted commits carry an `Assisted-by:` trailer naming the agent and
model. `Co-authored-by:` is reserved for human co-authors.

Do not push. The user decides when to publish.

## Release

`waydroid-helper.spec` (RPM) and `debian/` (Debian) package the same
Meson build. The version lives in `meson.build`; keep `debian/changelog` in
step when it changes.

`.github/workflows/release.yml` builds the AppImage on tag push and
`.github/workflows/obs.yml` uploads Debian packages to OBS on `main`. Both
call `appimage/build.sh`, which needs `meson`, `ninja`, `cmake`, and network
access to fetch android-tools.

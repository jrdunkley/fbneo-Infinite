// Client-owned preferences. Paths/NVRAM remain relative to each runtime; only
// preferences are shared. Old standalone launches retain the original IO paths.
#ifndef INFINITE_SETTINGS_H
#define INFINITE_SETTINGS_H
#ifdef _WIN32
#pragma push_macro("__in")
#pragma push_macro("__out")
#undef __in
#undef __out
#include <string>
#include <map>
#pragma pop_macro("__out")
#pragma pop_macro("__in")
#include <windows.h>

typedef std::basic_string<TCHAR> InfiniteSettingString;
typedef std::map<InfiniteSettingString, InfiniteSettingString> InfiniteSettingMap;

static const TCHAR* InfiniteSettingPath(bool game, bool session = false)
{
	const TCHAR* p = _tgetenv(game ? (session ? _T("INFINITE_SETTINGS_SESSION_INPUT") : _T("INFINITE_SETTINGS_INPUT"))
		: (session ? _T("INFINITE_SETTINGS_SESSION_GLOBAL") : _T("INFINITE_SETTINGS_GLOBAL")));
	return p && _tcslen(p) < MAX_PATH - 40 ? p : NULL;
}

static InfiniteSettingString InfiniteSettingKey(const TCHAR* line)
{
	while (*line == _T(' ') || *line == _T('\t')) ++line;
	if (!*line || *line == _T('/') || *line == _T(';') || *line == _T('#')) return InfiniteSettingString();
	const TCHAR* end = line;
	while (*end && *end != _T(' ') && *end != _T('\t') && *end != _T('\r') && *end != _T('\n')) ++end;
	InfiniteSettingString key(line, end);
	if (key == _T("input") || key == _T("macro") || key == _T("custom") || key == _T("afire")) {
		const TCHAR* quote = _tcschr(end, _T('"'));
		const TCHAR* close = quote ? _tcschr(quote + 1, _T('"')) : NULL;
		if (!close) return InfiniteSettingString();
		key += _T(" "); key.append(quote, close + 1);
	}
	for (size_t i = 0; i < key.size(); ++i) key[i] = _totlower(key[i]);
	return key;
}

static bool InfiniteSettingLocal(const InfiniteSettingString& key)
{
	// These select a package/runtime or its assets, not a player's presentation.
	return key == _T("niniversion") || key == _T("cdemuimage") ||
		key.compare(0, 5, _T("szapp")) == 0 || key.compare(0, 11, _T("szprevgames")) == 0 ||
		key.compare(0, 14, _T("nburndrvselect")) == 0 || key.compare(0, 7, _T("szneocd")) == 0;
}

static InfiniteSettingMap InfiniteReadSettings(const TCHAR* path)
{
	InfiniteSettingMap result;
	FILE* f = path ? _tfopen(path, _T("rt")) : NULL;
	if (!f) return result;
	TCHAR line[2048];
	while (_fgetts(line, 2048, f)) {
		InfiniteSettingString key = InfiniteSettingKey(line);
		if (!key.empty()) {
			InfiniteSettingString value(line);
			while (!value.empty() && (value[value.size()-1] == _T('\n') || value[value.size()-1] == _T('\r'))) value.erase(value.size()-1);
			result[key] = value;
		}
	}
	fclose(f); return result;
}

// Read local configuration first, then universal choices, then a session-only
// overlay. Session keys are restored from the store at every save, even when
// the emulator's Save settings command is used before exit.
static FILE* InfiniteOpenSettings(bool game, int pass, const TCHAR* local)
{
	const TCHAR* path = pass == 0 ? local : InfiniteSettingPath(game, pass == 2);
	if (pass && !InfiniteSettingPath(game)) return NULL;
	return path ? _tfopen(path, _T("rt")) : NULL;
}

struct InfiniteSettingsLock {
	HANDLE handle;
	InfiniteSettingsLock(const TCHAR* path) : handle(INVALID_HANDLE_VALUE) {
		TCHAR lock[MAX_PATH]; _stprintf(lock, _T("%s.lock"), path);
		for (int n = 0; n < 100; ++n) {
			handle = CreateFile(lock, GENERIC_READ | GENERIC_WRITE, 0, NULL, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
			if (handle != INVALID_HANDLE_VALUE) break;
			Sleep(50);
		}
	}
	~InfiniteSettingsLock() { if (handle != INVALID_HANDLE_VALUE) CloseHandle(handle); }
};

static int InfiniteCommitSettings(bool game, const TCHAR* temp)
{
	const TCHAR* path = InfiniteSettingPath(game);
	InfiniteSettingsLock lock(path);
	if (lock.handle == INVALID_HANDLE_VALUE) { _tremove(temp); return 1; }
	InfiniteSettingMap current = InfiniteReadSettings(path), saved = InfiniteReadSettings(temp);
	InfiniteSettingMap forced = InfiniteReadSettings(InfiniteSettingPath(game, true));
	if (game) {
		// Deleting a custom macro or disabling autofire is a preference too.
		// Retain unknown automatic rows for other drivers/older replay runtimes.
		for (InfiniteSettingMap::iterator i = current.begin(); i != current.end();) {
			if ((i->first.compare(0, 7, _T("custom ")) == 0 || i->first.compare(0, 6, _T("afire ")) == 0) && !saved.count(i->first)) current.erase(i++); else ++i;
		}
	}
	// FBNeo persists one selected buffer count. Imported module-indexed aliases
	// would otherwise override that saved choice when loaded in sorted order.
	if (!game && saved.count(_T("naudsegcount"))) {
		for (InfiniteSettingMap::iterator i = current.begin(); i != current.end();) {
			if (i->first.compare(0, 13, _T("naudsegcount[")) == 0) current.erase(i++); else ++i;
		}
	}
	if (!game && nAppShowCmd == SW_HIDE) {
		forced[_T("bautopause")] = _T("");
		forced[_T("nvidfullscreen")] = _T("");
	}
	for (InfiniteSettingMap::const_iterator i = saved.begin(); i != saved.end(); ++i) {
		if ((!game && InfiniteSettingLocal(i->first)) || forced.count(i->first)) continue;
		current[i->first] = i->second;
	}
	FILE* f = _tfopen(temp, _T("wt"));
	if (!f) return 1;
	// The game parser requires version before any input rows.
	if (game && current.count(_T("version"))) _ftprintf(f, _T("%s\n"), current[_T("version")].c_str());
	if (!game && current.count(_T("naudselect"))) _ftprintf(f, _T("%s\n"), current[_T("naudselect")].c_str());
	for (InfiniteSettingMap::const_iterator i = current.begin(); i != current.end(); ++i) {
		if ((!game && (InfiniteSettingLocal(i->first) || i->first == _T("naudselect"))) || (game && i->first == _T("version"))) continue;
		_ftprintf(f, _T("%s\n"), i->second.c_str());
	}
	int error = ferror(f); if (fclose(f)) error = 1;
	if (error || !MoveFileEx(temp, path, MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH)) {
		_tremove(temp); return 1;
	}
	return 0;
}

static void InfiniteSettingsTemp(TCHAR* target, bool game)
{
	_stprintf(target, _T("%s.%lu.tmp"), InfiniteSettingPath(game), GetCurrentProcessId());
}
#endif
#endif

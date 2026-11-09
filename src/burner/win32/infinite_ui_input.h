// UI input provenance only. DirectInput polling and the emulated input path do
// not pass through this filter. No hooks, sleeps or Raw Input registrations.
#pragma once
#include <tlhelp32.h>

// Dynamically resolve the Windows 8+ API to retain older-Windows startup.
// INPUT_MESSAGE_SOURCE consists of two 32-bit enums. Keep a private layout so
// the portable compiler's older WINVER setting does not expose a new import.
struct InfiniteUiMessageSource { DWORD deviceType, originId; };
typedef BOOL (WINAPI *InfiniteUiSourceFn)(InfiniteUiMessageSource*);

static inline bool InfiniteUiInputMessage(UINT message)
{
    return (message >= WM_KEYFIRST && message <= WM_KEYLAST) ||
           (message >= WM_MOUSEFIRST && message <= WM_MOUSELAST);
}

static inline bool InfiniteUiBlockOrigin(UINT message, bool identified, DWORD origin)
{
    // IMO_INJECTED = non-UIAccess SendInput. Unknown, system, touchpad and
    // hardware sources remain usable. A null RAWINPUTHEADER::hDevice is NOT
    // proof of injection (precision touchpads can legitimately use it).
    return InfiniteUiInputMessage(message) && identified && origin == 2;
}

static inline bool InfiniteUiBlockInput(UINT message)
{
    if (!InfiniteUiInputMessage(message)) return false;
    static InfiniteUiSourceFn source = (InfiniteUiSourceFn)GetProcAddress(
        GetModuleHandleW(L"user32.dll"), "GetCurrentInputMessageSource");
    InfiniteUiMessageSource info = {};
    bool identified = source && source(&info);
    bool blocked = InfiniteUiBlockOrigin(message, identified, info.originId);
    if (blocked) {
        static unsigned logged = 0;
        if (logged++ < 4) InfiniteLog("ui: ignored injected keyboard/mouse message 0x%04x", message);
    }
    return blocked;
}

static inline bool InfiniteUiSteamRunning()
{
    HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (snapshot == INVALID_HANDLE_VALUE) return false;
    PROCESSENTRY32W entry = {}; entry.dwSize = sizeof(entry);
    bool found = false;
    if (Process32FirstW(snapshot, &entry)) do {
        if (!_wcsicmp(entry.szExeFile, L"steam.exe")) { found = true; break; }
    } while (Process32NextW(snapshot, &entry));
    CloseHandle(snapshot);
    return found;
}

static inline void InfiniteUiWarnSteam(int pads)
{
    static bool checked = false;
    if (checked) return;
    checked = true;
    // Process presence plus a pad is a risk indication, not proof that Steam
    // owns this particular device. Do not change Steam, Game Bar or pad prefs.
    if (pads > 0 && InfiniteUiSteamRunning()) {
        InfiniteLog("ui: Steam is running with %d gamepad(s); Desktop Layout/Guide mappings may affect play", pads);
        VidSNewShortMsg(_T("Steam is running: check Desktop Layout and Guide bindings."));
    }
}

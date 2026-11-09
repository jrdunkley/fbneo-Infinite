// Opt-in black-flicker diagnostics. OS queries run only at startup/loss/reset,
// never on the successful per-frame path. No hooks or presentation changes.
#pragma once
#include <tlhelp32.h>
// Older DirectX headers define SAL macros that collide with GCC 16 STL names.
#pragma push_macro("__in")
#pragma push_macro("__out")
#undef __in
#undef __out
#include <vector>
#pragma pop_macro("__out")
#pragma pop_macro("__in")

inline bool InfiniteVideoTraceEnabled()
{
    static const bool enabled = getenv("INFINITE_VIDEO_TRACE") &&
        !strcmp(getenv("INFINITE_VIDEO_TRACE"), "1");
    return enabled;
}

inline unsigned long long InfiniteVideoTraceTicks()
{
    typedef ULONGLONG (WINAPI *TicksFn)();
    static TicksFn ticks = (TicksFn)GetProcAddress(GetModuleHandleA("kernel32.dll"), "GetTickCount64");
    return ticks ? (unsigned long long)ticks() : (unsigned long long)GetTickCount();
}

inline void InfiniteVideoTraceState(const char* event, HWND window,
    unsigned code, UINT_PTR detail1 = 0, UINT_PTR detail2 = 0)
{
    if (!InfiniteVideoTraceEnabled()) return;
    HWND foreground = GetForegroundWindow();
    DWORD foregroundPid = 0;
    GetWindowThreadProcessId(foreground, &foregroundPid);
    RECT client = {}; GetClientRect(window, &client);
    InfiniteLog("video trace: t=%lu event=%s code=0x%08x detail=%llu,%llu pid=%lu foreground_pid=%lu active=%d visible=%d minimized=%d client=%ldx%ld ticks64=%llu",
        timeGetTime(), event, code, (unsigned long long)detail1, (unsigned long long)detail2,
        GetCurrentProcessId(), foregroundPid, foreground == window,
        (int)IsWindowVisible(window), (int)IsIconic(window), client.right, client.bottom, InfiniteVideoTraceTicks());
}

struct InfiniteVideoTraceModule {
    UINT_PTR base;
    DWORD size;
    char path[MAX_PATH * 3];
};
struct InfiniteVideoTraceInventory {
    bool started;
    unsigned event;
    DWORD baselineError;
    std::vector<InfiniteVideoTraceModule> baseline;
    InfiniteVideoTraceInventory() : started(false), event(0), baselineError(0) {}
};
// External inline linkage shares this baseline across main.cpp and the blitter.
inline InfiniteVideoTraceInventory& InfiniteVideoTraceData()
{
    static InfiniteVideoTraceInventory data;
    return data;
}

inline DWORD InfiniteVideoTraceModules(std::vector<InfiniteVideoTraceModule>& modules)
{
    HANDLE snapshot = INVALID_HANDLE_VALUE;
    for (int attempt = 0; attempt < 3; ++attempt) {
        snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPMODULE | TH32CS_SNAPMODULE32, GetCurrentProcessId());
        if (snapshot != INVALID_HANDLE_VALUE || GetLastError() != ERROR_BAD_LENGTH) break;
    }
    if (snapshot == INVALID_HANDLE_VALUE) return GetLastError();
    MODULEENTRY32W entry = {}; entry.dwSize = sizeof(entry);
    BOOL found = Module32FirstW(snapshot, &entry);
    DWORD error = found ? ERROR_SUCCESS : GetLastError();
    while (found) {
        InfiniteVideoTraceModule module = {};
        module.base = (UINT_PTR)entry.modBaseAddr;
        module.size = entry.modBaseSize;
        WideCharToMultiByte(CP_UTF8, 0, entry.szExePath, -1, module.path, sizeof(module.path), NULL, NULL);
        modules.push_back(module);
        found = Module32NextW(snapshot, &entry);
        if (!found && GetLastError() != ERROR_NO_MORE_FILES) error = GetLastError();
    }
    CloseHandle(snapshot);
    return error;
}

inline void InfiniteVideoTraceStart()
{
    if (!InfiniteVideoTraceEnabled()) return;
    InfiniteVideoTraceInventory& data = InfiniteVideoTraceData();
    if (data.started) return;
    data.started = true;
    data.baselineError = InfiniteVideoTraceModules(data.baseline);
    InfiniteLog("video inventory start: t=%lu ticks64=%llu pid=%lu count=%u error=%lu", timeGetTime(),
        InfiniteVideoTraceTicks(), GetCurrentProcessId(), (unsigned)data.baseline.size(), data.baselineError);
    for (size_t i = 0; i < data.baseline.size(); ++i)
        InfiniteLog("video module: event=0 delta=start base=0x%llx size=%lu path=%s",
            (unsigned long long)data.baseline[i].base, data.baseline[i].size, data.baseline[i].path);
}

inline bool InfiniteVideoTraceHasModule(const std::vector<InfiniteVideoTraceModule>& modules,
    const InfiniteVideoTraceModule& module)
{
    for (size_t i = 0; i < modules.size(); ++i)
        if (modules[i].base == module.base && modules[i].size == module.size &&
            !_stricmp(modules[i].path, module.path)) return true;
    return false;
}

inline void InfiniteVideoTraceDeviceEvent(const char* reason, HWND window,
    unsigned coop, bool coopKnown, unsigned present, bool presentKnown)
{
    if (!InfiniteVideoTraceEnabled()) return;
    InfiniteVideoTraceStart();
    InfiniteVideoTraceInventory& data = InfiniteVideoTraceData();
    const unsigned event = ++data.event;
    HWND foreground = GetForegroundWindow();
    DWORD pid = 0;
    DWORD tid = GetWindowThreadProcessId(foreground, &pid);
    char exe[32768] = "<unavailable>";
    DWORD exeError = ERROR_INVALID_HANDLE;
    typedef BOOL (WINAPI *QueryImageFn)(HANDLE, DWORD, LPSTR, PDWORD);
    QueryImageFn queryImage = (QueryImageFn)GetProcAddress(GetModuleHandleA("kernel32.dll"), "QueryFullProcessImageNameA");
    HANDLE process = pid ? OpenProcess(0x1000 /* PROCESS_QUERY_LIMITED_INFORMATION */, FALSE, pid) : NULL;
    if (process) {
        DWORD length = sizeof(exe);
        if (queryImage && queryImage(process, 0, exe, &length)) exeError = ERROR_SUCCESS;
        else { exeError = queryImage ? GetLastError() : ERROR_PROC_NOT_FOUND; strcpy(exe, "<unavailable>"); }
        CloseHandle(process);
    } else if (pid) exeError = GetLastError();
    // Documented BOOLEAN WINAPI(void), system-wide, not an owning PID or an
    // adapter-specific verdict. Resolve from the already loaded system DLL.
    typedef BOOLEAN (WINAPI *CheckExclusiveFn)();
    CheckExclusiveFn check = (CheckExclusiveFn)GetProcAddress(GetModuleHandleA("gdi32.dll"), "D3DKMTCheckExclusiveOwnership");
    int exclusive = check ? (check() ? 1 : 0) : -1;
    InfiniteLog("video device event: t=%lu ticks64=%llu event=%u reason=%s pid=%lu window=0x%llx foreground=0x%llx foreground_pid=%lu foreground_tid=%lu foreground_exe=%s exe_error=%lu exclusive_api=D3DKMTCheckExclusiveOwnership exclusive_available=%d exclusive_any=%d coop=0x%08x coop_known=%d present=0x%08x present_known=%d",
        timeGetTime(), InfiniteVideoTraceTicks(), event, reason, GetCurrentProcessId(), (unsigned long long)(UINT_PTR)window,
        (unsigned long long)(UINT_PTR)foreground, pid, tid, exe, exeError, check != NULL, exclusive,
        coop, coopKnown, present, presentKnown);
    std::vector<InfiniteVideoTraceModule> modules;
    DWORD error = InfiniteVideoTraceModules(modules);
    unsigned added = 0, removed = 0;
    for (size_t i = 0; i < modules.size(); ++i) {
        if (InfiniteVideoTraceHasModule(data.baseline, modules[i])) continue;
        ++added;
        InfiniteLog("video module: event=%u delta=added-since-start base=0x%llx size=%lu path=%s",
            event, (unsigned long long)modules[i].base, modules[i].size, modules[i].path);
    }
    // A failed snapshot cannot establish removals. Retain explicit error codes.
    if (!error && !data.baselineError) for (size_t i = 0; i < data.baseline.size(); ++i) {
        if (InfiniteVideoTraceHasModule(modules, data.baseline[i])) continue;
        ++removed;
        InfiniteLog("video module: event=%u delta=removed-since-start base=0x%llx size=%lu path=%s",
            event, (unsigned long long)data.baseline[i].base, data.baseline[i].size, data.baseline[i].path);
    }
    InfiniteLog("video inventory delta: event=%u baseline=%u current=%u added=%u removed=%u error=%lu baseline_error=%lu",
        event, (unsigned)data.baseline.size(), (unsigned)modules.size(), added, removed, error, data.baselineError);
}

inline bool InfiniteRefuseHiddenFullscreen(const char* source)
{
    if (!bInfiniteHiddenLaunch) return false;
    nVidFullscreen = 0;
    InfiniteLog("video: hidden fullscreen refused source=%s", source);
    return true;
}

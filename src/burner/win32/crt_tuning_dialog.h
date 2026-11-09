// Included by numdial.cpp. Modal preview redraws without advancing emulation.
static int crtPage,crtShader;
static bool crtUpdating;
static float crtBefore[RC_OPTION_COUNT];

static void CRTEnd(HWND dialog,int result)
{
    if(bInfiniteHiddenLaunch)DestroyWindow(dialog);
    else EndDialog(dialog,result);
}

static void CRTPreview()
{
    if (bVidOkay) { VidRedraw(); VidPaint(0); }
}

static void CRTValues(HWND dialog)
{
    crtUpdating=true;
    for(int row=0;row<4;row++) {
        int i=crtPage*4+row;
        const RCOption& o=rcOptions[i];
        float value=HardFXConfigs[crtShader].fOptions[i];
        TCHAR label[128],text[32];
        _sntprintf(label,128,_T("%hs"),o.label);
        SetDlgItemText(dialog,IDC_SPRITE1+row,label);
        int steps=(int)floorf((o.maximum-o.minimum)/o.step+0.5f);
        SendDlgItemMessage(dialog,IDC_HARDFX_SLIDER1+row,TBM_SETRANGEMIN,FALSE,0);
        SendDlgItemMessage(dialog,IDC_HARDFX_SLIDER1+row,TBM_SETRANGEMAX,FALSE,steps);
        SendDlgItemMessage(dialog,IDC_HARDFX_SLIDER1+row,TBM_SETLINESIZE,0,1);
        SendDlgItemMessage(dialog,IDC_HARDFX_SLIDER1+row,TBM_SETPAGESIZE,0,steps/10?steps/10:1);
        SendDlgItemMessage(dialog,IDC_HARDFX_SLIDER1+row,TBM_SETPOS,TRUE,(int)floorf((value-o.minimum)/o.step+0.5f));
        _sntprintf(text,32,_T("%.6g"),value);
        SetDlgItemText(dialog,IDC_HARDFX_SLIDER_EDIT1+row,text);
    }
    TCHAR tip[512];_sntprintf(tip,512,_T("%hs"),rcTips[crtPage]);SetDlgItemText(dialog,IDC_CRT_TIP,tip);
    crtUpdating=false;
}

static INT_PTR CALLBACK CRTTuningProc(HWND dialog,UINT message,WPARAM wParam,LPARAM lParam)
{
    switch(message) {
    case WM_WINDOWPOSCHANGING:
        if(bInfiniteHiddenLaunch) {
            WINDOWPOS* position=(WINDOWPOS*)lParam;
            position->flags=(position->flags&~SWP_SHOWWINDOW)|SWP_NOACTIVATE;
        }
        break;
    case WM_INITDIALOG: {
        crtShader=nVidDX9HardFX;crtPage=0;crtUpdating=true;
        memcpy(crtBefore,HardFXConfigs[crtShader].fOptions,sizeof(crtBefore));
        SendDlgItemMessage(dialog,IDC_CRT_PRESET,CB_ADDSTRING,0,(LPARAM)_T("Custom / saved settings"));
        for(unsigned i=0;i<sizeof(rcProfiles)/sizeof(rcProfiles[0]);i++) {
            TCHAR name[128];_sntprintf(name,128,_T("%hs"),rcProfiles[i].name);
            SendDlgItemMessage(dialog,IDC_CRT_PRESET,CB_ADDSTRING,0,(LPARAM)name);
        }
        SendDlgItemMessage(dialog,IDC_CRT_PRESET,CB_SETCURSEL,0,0);
        for(int i=0;i<5;i++) {
            TCHAR name[128];_sntprintf(name,128,_T("%hs"),rcPages[i]);
            SendDlgItemMessage(dialog,IDC_CRT_PAGE,CB_ADDSTRING,0,(LPARAM)name);
        }
        SendDlgItemMessage(dialog,IDC_CRT_PAGE,CB_SETCURSEL,0,0);
        if(!bInfiniteHiddenLaunch)WndInMid(dialog,hScrnWnd);
        else SetWindowLongPtr(dialog,GWL_EXSTYLE,GetWindowLongPtr(dialog,GWL_EXSTYLE)|WS_EX_NOACTIVATE);
        CRTValues(dialog);CRTPreview();
        return !bInfiniteHiddenLaunch;
    }
    case WM_HSCROLL: {
        int row=GetDlgCtrlID((HWND)lParam)-IDC_HARDFX_SLIDER1;
        if(row<0 || row>=4 || crtUpdating)return FALSE;
        int i=crtPage*4+row;
        int position=(int)SendMessage((HWND)lParam,TBM_GETPOS,0,0);
        HardFXConfigs[crtShader].fOptions[i]=RCClamp(i,rcOptions[i].minimum+position*rcOptions[i].step);
        SendDlgItemMessage(dialog,IDC_CRT_PRESET,CB_SETCURSEL,0,0);
        CRTValues(dialog);CRTPreview();return TRUE;
    }
    case WM_COMMAND: {
        int id=LOWORD(wParam),notification=HIWORD(wParam);
        if(id==IDC_CRT_PAGE && notification==CBN_SELCHANGE) {
            crtPage=(int)SendDlgItemMessage(dialog,IDC_CRT_PAGE,CB_GETCURSEL,0,0);CRTValues(dialog);return TRUE;
        }
        if(id==IDC_CRT_PRESET && notification==CBN_SELCHANGE) {
            int profile=(int)SendDlgItemMessage(dialog,IDC_CRT_PRESET,CB_GETCURSEL,0,0)-1;
            if(profile>=0 && profile<(int)(sizeof(rcProfiles)/sizeof(rcProfiles[0]))) {
                memcpy(HardFXConfigs[crtShader].fOptions,rcProfiles[profile].values,sizeof(crtBefore));
                CRTValues(dialog);CRTPreview();
            }
            return TRUE;
        }
        int row=id-IDC_HARDFX_SLIDER_EDIT1;
        if(row>=0 && row<4 && !crtUpdating && (notification==EN_CHANGE || notification==EN_KILLFOCUS)) {
            TCHAR text[64],*end=NULL;GetDlgItemText(dialog,id,text,64);
            double value=_tcstod(text,&end);
            if(end!=text && !*end && isfinite(value)) {
                int i=crtPage*4+row;
                HardFXConfigs[crtShader].fOptions[i]=RCClamp(i,(float)value);
                SendDlgItemMessage(dialog,IDC_HARDFX_SLIDER1+row,TBM_SETPOS,TRUE,(int)floorf((HardFXConfigs[crtShader].fOptions[i]-rcOptions[i].minimum)/rcOptions[i].step+0.5f));
                SendDlgItemMessage(dialog,IDC_CRT_PRESET,CB_SETCURSEL,0,0);
                CRTPreview();
            }
            if(notification==EN_KILLFOCUS)CRTValues(dialog);
            return TRUE;
        }
        if(id==IDRETRY) {
            HardFXConfigs[crtShader].hardfx_config_load_defaults();
            SendDlgItemMessage(dialog,IDC_CRT_PRESET,CB_SETCURSEL,crtShader==10?1:crtShader==11?2:3,0);
            CRTValues(dialog);CRTPreview();return TRUE;
        }
        if(id==IDOK) { CRTEnd(dialog,IDOK);return TRUE; }
        if(id!=IDCANCEL)break;
        // Escape and Cancel restore the complete entry snapshot.
    }
    // fall through
    case WM_CLOSE:
        memcpy(HardFXConfigs[crtShader].fOptions,crtBefore,sizeof(crtBefore));
        CRTPreview();CRTEnd(dialog,IDCANCEL);return TRUE;
    }
    return FALSE;
}

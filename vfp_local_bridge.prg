FUNCTION BridgeInitForm
    LPARAMETERS toForm, tcBridgePath

    LOCAL lcProjectDir

    lcProjectDir = JUSTPATH(FULLPATH(tcBridgePath))

    IF !PEMSTATUS(toForm, "cBaseUrl", 5)
        toForm.AddProperty("cBaseUrl", "http://127.0.0.1:8765")
    ENDIF

    IF !PEMSTATUS(toForm, "cProjectDir", 5)
        toForm.AddProperty("cProjectDir", lcProjectDir)
    ELSE
        toForm.cProjectDir = lcProjectDir
    ENDIF

    IF !PEMSTATUS(toForm, "cBridgePath", 5)
        toForm.AddProperty("cBridgePath", tcBridgePath)
    ELSE
        toForm.cBridgePath = tcBridgePath
    ENDIF

    IF !PEMSTATUS(toForm, "cBackendBat", 5)
        toForm.AddProperty("cBackendBat", ADDBS(lcProjectDir) + "scripts\start_backend.bat")
    ELSE
        toForm.cBackendBat = ADDBS(lcProjectDir) + "scripts\start_backend.bat"
    ENDIF

    IF !PEMSTATUS(toForm, "cStartDemoPs1", 5)
        toForm.AddProperty("cStartDemoPs1", ADDBS(lcProjectDir) + "scripts\start_demo.ps1")
    ELSE
        toForm.cStartDemoPs1 = ADDBS(lcProjectDir) + "scripts\start_demo.ps1"
    ENDIF

    IF !PEMSTATUS(toForm, "cHostExe", 5)
        toForm.AddProperty("cHostExe", ADDBS(lcProjectDir) + "dotnet\host\bin\Debug\net8.0-windows\VfpWebViewHost.exe")
    ELSE
        toForm.cHostExe = ADDBS(lcProjectDir) + "dotnet\host\bin\Debug\net8.0-windows\VfpWebViewHost.exe"
    ENDIF

    IF !PEMSTATUS(toForm, "cWebViewProgId", 5)
        toForm.AddProperty("cWebViewProgId", "VfpWebViewBridge.Host")
    ELSE
        toForm.cWebViewProgId = "VfpWebViewBridge.Host"
    ENDIF

    IF !PEMSTATUS(toForm, "cRegisterBridgePs1", 5)
        toForm.AddProperty("cRegisterBridgePs1", ADDBS(lcProjectDir) + "scripts\register_vfp_webview_bridge.ps1")
    ELSE
        toForm.cRegisterBridgePs1 = ADDBS(lcProjectDir) + "scripts\register_vfp_webview_bridge.ps1"
    ENDIF

    IF !PEMSTATUS(toForm, "oWebViewHost", 5)
        toForm.AddProperty("oWebViewHost", .NULL.)
    ELSE
        toForm.oWebViewHost = .NULL.
    ENDIF

    IF !PEMSTATUS(toForm, "lAutoStartScheduled", 5)
        toForm.AddProperty("lAutoStartScheduled", .F.)
    ELSE
        toForm.lAutoStartScheduled = .F.
    ENDIF

    IF !PEMSTATUS(toForm, "lBackendReady", 5)
        toForm.AddProperty("lBackendReady", .F.)
    ELSE
        toForm.lBackendReady = .F.
    ENDIF

    IF !PEMSTATUS(toForm, "oBridgeEvents", 5)
        toForm.AddProperty("oBridgeEvents", CreateBridgeEventSink(toForm, tcBridgePath))
    ELSE
        toForm.oBridgeEvents = CreateBridgeEventSink(toForm, tcBridgePath)
    ENDIF

    IF VARTYPE(toForm.oBridgeEvents) # "O"
        ERROR "No se pudo crear el objeto BridgeEventSink."
    ENDIF

    BuildDiagnosticUi(toForm)
    =BINDEVENT(toForm, "Resize", toForm.oBridgeEvents, "OnFormResize")
    =BINDEVENT(toForm, "Destroy", toForm.oBridgeEvents, "OnFormDestroy")

    toForm.edtContextJson.Value = BuildSampleContext()
    toForm.edtChatMessage.Value = "Prueba desde VFP"
    toForm.edtLog.Value = ""

    AppendLog(toForm, "Panel de diagnostico listo.")
    AppendLog(toForm, "Proyecto: " + toForm.cProjectDir)

    IF BackendAlive(toForm.cBaseUrl)
        toForm.lBackendReady = .T.
        UpdateStatus(toForm, "Backend disponible", .T.)
        AppendLog(toForm, "GET /health -> disponible.")
    ELSE
        UpdateStatus(toForm, "Backend detenido", .F.)
        AppendLog(toForm, "GET /health -> sin respuesta.")
    ENDIF

    IF PEMSTATUS(toForm, "tmrAutoStart", 5)
        toForm.lAutoStartScheduled = .T.
        toForm.tmrAutoStart.Enabled = .T.
        AppendLog(toForm, "Autoinicio del bridge programado.")
    ENDIF

    RETURN .T.
ENDFUNC

FUNCTION BridgeDestroyForm
    LPARAMETERS toForm

    IF VARTYPE(toForm) = "O"
        AppendLog(toForm, "Cierre del formulario.")
        =ReleaseWebViewHost(toForm)
    ENDIF

    RETURN .T.
ENDFUNC

FUNCTION BuildDiagnosticUi
    LPARAMETERS toForm

    LOCAL loControl

    toForm.Caption = "VFP Local Bridge"
    toForm.Width = 1100
    toForm.Height = 760
    toForm.AutoCenter = .T.

    WITH toForm.Command1
        .Top = 16
        .Left = 16
        .Width = 120
        .Height = 32
        .Caption = "Iniciar bridge"
        .Visible = .T.
    ENDWITH
    =BINDEVENT(toForm.Command1, "Click", toForm.oBridgeEvents, "OnStartBridge")

    IF !PEMSTATUS(toForm, "cmdHealth", 5)
        toForm.AddObject("cmdHealth", "CommandButton")
    ENDIF
    WITH toForm.cmdHealth
        .Top = 16
        .Left = 148
        .Width = 90
        .Height = 32
        .Caption = "Health"
        .Visible = .T.
    ENDWITH
    =BINDEVENT(toForm.cmdHealth, "Click", toForm.oBridgeEvents, "OnHealthCheck")

    IF !PEMSTATUS(toForm, "cmdSendContext", 5)
        toForm.AddObject("cmdSendContext", "CommandButton")
    ENDIF
    WITH toForm.cmdSendContext
        .Top = 16
        .Left = 250
        .Width = 120
        .Height = 32
        .Caption = "Enviar contexto"
        .Visible = .T.
    ENDWITH
    =BINDEVENT(toForm.cmdSendContext, "Click", toForm.oBridgeEvents, "OnSendContext")

    IF !PEMSTATUS(toForm, "cmdSendChat", 5)
        toForm.AddObject("cmdSendChat", "CommandButton")
    ENDIF
    WITH toForm.cmdSendChat
        .Top = 16
        .Left = 382
        .Width = 110
        .Height = 32
        .Caption = "Enviar chat"
        .Visible = .T.
    ENDWITH
    =BINDEVENT(toForm.cmdSendChat, "Click", toForm.oBridgeEvents, "OnSendChat")

    IF !PEMSTATUS(toForm, "cmdOpenUi", 5)
        toForm.AddObject("cmdOpenUi", "CommandButton")
    ENDIF
    WITH toForm.cmdOpenUi
        .Top = 16
        .Left = 504
        .Width = 110
        .Height = 32
        .Caption = "Cargar UI"
        .Visible = .T.
    ENDWITH
    =BINDEVENT(toForm.cmdOpenUi, "Click", toForm.oBridgeEvents, "OnOpenUi")

    IF !PEMSTATUS(toForm, "lblStatus", 5)
        toForm.AddObject("lblStatus", "Label")
    ENDIF
    WITH toForm.lblStatus
        .Top = 56
        .Left = 18
        .Caption = "Estado: inicializando"
        .AutoSize = .T.
        .Visible = .T.
        .FontBold = .T.
    ENDWITH

    IF !PEMSTATUS(toForm, "lblContextTitle", 5)
        toForm.AddObject("lblContextTitle", "Label")
    ENDIF
    WITH toForm.lblContextTitle
        .Top = 92
        .Left = 18
        .Caption = "Contexto JSON"
        .AutoSize = .T.
        .Visible = .T.
    ENDWITH

    IF !PEMSTATUS(toForm, "edtContextJson", 5)
        toForm.AddObject("edtContextJson", "EditBox")
    ENDIF
    WITH toForm.edtContextJson
        .Top = 114
        .Left = 16
        .Width = 516
        .Height = 276
        .ScrollBars = 2
        .Visible = .T.
    ENDWITH

    IF !PEMSTATUS(toForm, "lblChatTitle", 5)
        toForm.AddObject("lblChatTitle", "Label")
    ENDIF
    WITH toForm.lblChatTitle
        .Top = 406
        .Left = 18
        .Caption = "Mensaje de prueba"
        .AutoSize = .T.
        .Visible = .T.
    ENDWITH

    IF !PEMSTATUS(toForm, "edtChatMessage", 5)
        toForm.AddObject("edtChatMessage", "TextBox")
    ENDIF
    WITH toForm.edtChatMessage
        .Top = 428
        .Left = 16
        .Width = 516
        .Visible = .T.
    ENDWITH

    IF !PEMSTATUS(toForm, "lblBrowserTitle", 5)
        toForm.AddObject("lblBrowserTitle", "Label")
    ENDIF
    WITH toForm.lblBrowserTitle
        .Top = 92
        .Left = 552
        .Caption = "UI embebida"
        .AutoSize = .T.
        .Visible = .T.
    ENDWITH

    IF !PEMSTATUS(toForm, "cntBrowserHost", 5)
        toForm.AddObject("cntBrowserHost", "Container")
    ENDIF
    WITH toForm.cntBrowserHost
        .Top = 114
        .Left = 550
        .Width = 520
        .Height = 350
        .Visible = .T.
        .BackColor = RGB(255, 255, 255)
        .BorderWidth = 1
        .SpecialEffect = 1
    ENDWITH

    IF !PEMSTATUS(toForm, "lblLogTitle", 5)
        toForm.AddObject("lblLogTitle", "Label")
    ENDIF
    WITH toForm.lblLogTitle
        .Top = 482
        .Left = 552
        .Caption = "Log"
        .AutoSize = .T.
        .Visible = .T.
    ENDWITH

    IF !PEMSTATUS(toForm, "edtLog", 5)
        toForm.AddObject("edtLog", "EditBox")
    ENDIF
    WITH toForm.edtLog
        .Top = 504
        .Left = 550
        .Width = 520
        .Height = 170
        .ScrollBars = 2
        .ReadOnly = .T.
        .Visible = .T.
    ENDWITH

    IF !PEMSTATUS(toForm, "tmrAutoStart", 5)
        toForm.AddObject("tmrAutoStart", "Timer")
    ENDIF
    WITH toForm.tmrAutoStart
        .Interval = 750
        .Enabled = .F.
    ENDWITH
    =BINDEVENT(toForm.tmrAutoStart, "Timer", toForm.oBridgeEvents, "OnAutoStart")

    =LayoutDiagnosticUi(toForm)
    toForm.Refresh()

    RETURN .T.
ENDFUNC

FUNCTION LayoutDiagnosticUi
    LPARAMETERS toForm

    LOCAL lnRightLeft, lnRightWidth, lnBrowserTop, lnBrowserHeight, lnLogTop, lnLogHeight, lnFormWidth, lnFormHeight

    lnFormWidth = MAX(1100, toForm.Width)
    lnFormHeight = MAX(760, toForm.Height)
    lnRightLeft = 550
    lnRightWidth = MAX(320, lnFormWidth - lnRightLeft - 30)
    lnBrowserTop = 114
    lnBrowserHeight = MAX(260, lnFormHeight - 390)
    lnLogTop = lnBrowserTop + lnBrowserHeight + 40
    lnLogHeight = MAX(120, lnFormHeight - lnLogTop - 54)

    IF PEMSTATUS(toForm, "lblBrowserTitle", 5)
        toForm.lblBrowserTitle.Left = lnRightLeft + 2
        toForm.lblBrowserTitle.Top = 92
    ENDIF

    IF PEMSTATUS(toForm, "cntBrowserHost", 5)
        toForm.cntBrowserHost.Left = lnRightLeft
        toForm.cntBrowserHost.Top = lnBrowserTop
        toForm.cntBrowserHost.Width = lnRightWidth
        toForm.cntBrowserHost.Height = lnBrowserHeight
    ENDIF

    IF PEMSTATUS(toForm, "lblLogTitle", 5)
        toForm.lblLogTitle.Left = lnRightLeft + 2
        toForm.lblLogTitle.Top = lnLogTop - 22
    ENDIF

    IF PEMSTATUS(toForm, "edtLog", 5)
        toForm.edtLog.Left = lnRightLeft
        toForm.edtLog.Top = lnLogTop
        toForm.edtLog.Width = lnRightWidth
        toForm.edtLog.Height = lnLogHeight
    ENDIF

    =ResizeEmbeddedWebView(toForm)
    RETURN .T.
ENDFUNC

FUNCTION HandleStartBridge
    LPARAMETERS toForm

    LOCAL llOk

    AppendLog(toForm, "Iniciando bridge local...")

    IF !BackendAlive(toForm.cBaseUrl)
        IF StartBackend(toForm.cProjectDir)
            AppendLog(toForm, "Backend lanzado con scripts\start_backend.bat.")
        ELSE
            AppendLog(toForm, "No se pudo lanzar el backend.")
            UpdateStatus(toForm, "Error al lanzar backend", .F.)
            RETURN .F.
        ENDIF
    ELSE
        AppendLog(toForm, "El backend ya estaba activo.")
    ENDIF

    llOk = WaitForBackend(toForm.cBaseUrl, 12)
    toForm.lBackendReady = llOk

    IF !llOk
        AppendLog(toForm, "El backend no respondio dentro del tiempo esperado.")
        UpdateStatus(toForm, "Backend sin respuesta", .F.)
        RETURN .F.
    ENDIF

    AppendLog(toForm, "GET /health -> backend listo.")
    UpdateStatus(toForm, "Backend listo", .T.)

    IF StartWebViewHost(toForm, .F.)
        AppendLog(toForm, "UI WebView2 embebida en el formulario.")
    ELSE
        AppendLog(toForm, "No se pudo inicializar la UI embebida.")
        UpdateStatus(toForm, "Error al lanzar UI", .T.)
        RETURN .F.
    ENDIF

    RETURN .T.
ENDFUNC

FUNCTION HandleHealthCheck
    LPARAMETERS toForm

    LOCAL lnStatus, lcStatusText, lcResponseText, llOk

    llOk = HttpJsonRequest("GET", NormalizeBaseUrl(toForm.cBaseUrl) + "/health", "", @lnStatus, @lcStatusText, @lcResponseText)

    IF llOk
        toForm.lBackendReady = .T.
        UpdateStatus(toForm, "Backend disponible", .T.)
        AppendLog(toForm, "GET /health -> " + TRANSFORM(lnStatus) + " " + lcStatusText)
        AppendLog(toForm, lcResponseText)
    ELSE
        toForm.lBackendReady = .F.
        UpdateStatus(toForm, "Backend detenido", .F.)
        AppendLog(toForm, "GET /health fallo: " + lcStatusText)
        IF !EMPTY(lcResponseText)
            AppendLog(toForm, lcResponseText)
        ENDIF
    ENDIF

    RETURN llOk
ENDFUNC

FUNCTION HandleSendContext
    LPARAMETERS toForm

    LOCAL lcJson, lnStatus, lcResponseText, llOk

    lcJson = ALLTRIM(toForm.edtContextJson.Value)

    IF EMPTY(lcJson)
        AppendLog(toForm, "El contexto JSON esta vacio.")
        UpdateStatus(toForm, "Contexto vacio", toForm.lBackendReady)
        RETURN .F.
    ENDIF

    IF LEFT(lcJson, 1) # "{" OR RIGHT(lcJson, 1) # "}"
        AppendLog(toForm, "El contexto JSON no parece valido.")
        UpdateStatus(toForm, "Contexto invalido", toForm.lBackendReady)
        RETURN .F.
    ENDIF

    llOk = PostContext(toForm.cBaseUrl, lcJson, @lnStatus, @lcResponseText)

    IF llOk
        AppendLog(toForm, "POST /api/context -> " + TRANSFORM(lnStatus))
        AppendLog(toForm, lcResponseText)
        UpdateStatus(toForm, "Contexto enviado", .T.)
    ELSE
        AppendLog(toForm, "POST /api/context fallo.")
        IF !EMPTY(lcResponseText)
            AppendLog(toForm, lcResponseText)
        ENDIF
        UpdateStatus(toForm, "Error al enviar contexto", toForm.lBackendReady)
    ENDIF

    RETURN llOk
ENDFUNC

FUNCTION HandleSendChat
    LPARAMETERS toForm

    LOCAL lcMessage, lnStatus, lcResponseText, llOk

    lcMessage = ALLTRIM(toForm.edtChatMessage.Value)

    IF EMPTY(lcMessage)
        AppendLog(toForm, "El mensaje de chat esta vacio.")
        UpdateStatus(toForm, "Mensaje vacio", toForm.lBackendReady)
        RETURN .F.
    ENDIF

    llOk = PostChat(toForm.cBaseUrl, lcMessage, @lnStatus, @lcResponseText)

    IF llOk
        AppendLog(toForm, "POST /api/chat -> " + TRANSFORM(lnStatus))
        AppendLog(toForm, lcResponseText)
        UpdateStatus(toForm, "Chat enviado", .T.)
    ELSE
        AppendLog(toForm, "POST /api/chat fallo.")
        IF !EMPTY(lcResponseText)
            AppendLog(toForm, lcResponseText)
        ENDIF
        UpdateStatus(toForm, "Error al enviar chat", toForm.lBackendReady)
    ENDIF

    RETURN llOk
ENDFUNC

FUNCTION HandleOpenUi
    LPARAMETERS toForm

    LOCAL llReady

    llReady = BackendAlive(toForm.cBaseUrl)
    toForm.lBackendReady = llReady

    IF !llReady
        AppendLog(toForm, "No se puede abrir la UI: el backend no responde.")
        UpdateStatus(toForm, "Backend detenido", .F.)
        RETURN .F.
    ENDIF

    IF StartWebViewHost(toForm, .F.)
        AppendLog(toForm, "UI embebida cargada.")
        UpdateStatus(toForm, "UI abierta", .T.)
        RETURN .T.
    ENDIF

    AppendLog(toForm, "No se pudo cargar la UI embebida.")
    UpdateStatus(toForm, "Error al abrir UI", .T.)
    RETURN .F.
ENDFUNC

FUNCTION HandleFormResize
    LPARAMETERS toForm

    IF VARTYPE(toForm) # "O"
        RETURN .F.
    ENDIF

    RETURN LayoutDiagnosticUi(toForm)
ENDFUNC

FUNCTION HandleAutoStart
    LPARAMETERS toForm

    IF VARTYPE(toForm) # "O"
        RETURN .F.
    ENDIF

    IF PEMSTATUS(toForm, "tmrAutoStart", 5)
        toForm.tmrAutoStart.Enabled = .F.
    ENDIF

    IF PEMSTATUS(toForm, "lAutoStartScheduled", 5)
        IF !toForm.lAutoStartScheduled
            RETURN .T.
        ENDIF
        toForm.lAutoStartScheduled = .F.
    ENDIF

    IF VARTYPE(toForm.oWebViewHost) = "O"
        RETURN .T.
    ENDIF

    AppendLog(toForm, "Autoiniciando backend y UI embebida...")
    RETURN HandleStartBridge(toForm)
ENDFUNC

FUNCTION BackendAlive
    LPARAMETERS tcBaseUrl

    LOCAL lnStatus, lcStatusText, lcResponseText

    RETURN HttpJsonRequest("GET", NormalizeBaseUrl(tcBaseUrl) + "/health", "", @lnStatus, @lcStatusText, @lcResponseText)
ENDFUNC

FUNCTION StartBackend
    LPARAMETERS tcProjectDir

    LOCAL lcBatch, loShell, lcCommand, llOk

    lcBatch = ADDBS(tcProjectDir) + "scripts\start_backend.bat"
    IF !FILE(lcBatch)
        RETURN .F.
    ENDIF

    llOk = .F.
    TRY
        loShell = CREATEOBJECT("WScript.Shell")
        lcCommand = "cmd.exe /c " + QuotePath(lcBatch)
        loShell.Run(lcCommand, 0, .F.)
        llOk = .T.
    CATCH
        llOk = .F.
    ENDTRY

    RETURN llOk
ENDFUNC

FUNCTION StartWebViewHost
    LPARAMETERS toForm, tlUseDotnetRun

    LOCAL loHost, lcUrl, llOk, lcError

    llOk = .F.
    lcError = ""

    IF VARTYPE(toForm) # "O"
        RETURN .F.
    ENDIF

    =LayoutDiagnosticUi(toForm)

    IF VARTYPE(toForm.oWebViewHost) # "O"
        TRY
            toForm.oWebViewHost = CREATEOBJECT(toForm.cWebViewProgId)
            AppendLog(toForm, "Bridge COM creado: " + toForm.cWebViewProgId)
        CATCH TO loEx
            lcError = loEx.Message
            toForm.oWebViewHost = .NULL.
        ENDTRY
    ENDIF

    loHost = toForm.oWebViewHost
    IF VARTYPE(loHost) # "O"
        IF EMPTY(lcError)
            lcError = "No se pudo crear el bridge COM."
        ENDIF

        AppendLog(toForm, "Bridge COM no disponible: " + lcError)
        IF FILE(toForm.cRegisterBridgePs1)
            AppendLog(toForm, "Registra el COM con: " + toForm.cRegisterBridgePs1)
        ENDIF
        RETURN .F.
    ENDIF

    lcUrl = NormalizeBaseUrl(toForm.cBaseUrl) + "/ui"

    TRY
        llOk = loHost.Attach(toForm.HWnd, toForm.cntBrowserHost.Left, toForm.cntBrowserHost.Top, toForm.cntBrowserHost.Width, toForm.cntBrowserHost.Height, lcUrl)
    CATCH TO loEx
        llOk = .F.
        lcError = loEx.Message
    ENDTRY

    IF !llOk
        IF EMPTY(lcError)
            lcError = GetWebViewHostLastError(loHost)
        ENDIF

        IF EMPTY(lcError)
            lcError = "Error desconocido al adjuntar WebView2."
        ENDIF

        AppendLog(toForm, "Bridge COM fallo: " + lcError)
        RETURN .F.
    ENDIF

    RETURN .T.
ENDFUNC

FUNCTION ResizeEmbeddedWebView
    LPARAMETERS toForm

    LOCAL llOk, lcError

    IF VARTYPE(toForm) # "O" OR VARTYPE(toForm.oWebViewHost) # "O"
        RETURN .F.
    ENDIF

    llOk = .F.
    lcError = ""

    TRY
        llOk = toForm.oWebViewHost.Resize(toForm.cntBrowserHost.Left, toForm.cntBrowserHost.Top, toForm.cntBrowserHost.Width, toForm.cntBrowserHost.Height)
    CATCH TO loEx
        llOk = .F.
        lcError = loEx.Message
    ENDTRY

    IF !llOk .AND. !EMPTY(lcError)
        AppendLog(toForm, "No se pudo reajustar WebView2: " + lcError)
    ENDIF

    RETURN llOk
ENDFUNC

FUNCTION ReleaseWebViewHost
    LPARAMETERS toForm

    IF VARTYPE(toForm) # "O" OR VARTYPE(toForm.oWebViewHost) # "O"
        RETURN .T.
    ENDIF

    TRY
        toForm.oWebViewHost.Destroy()
    CATCH
    ENDTRY

    toForm.oWebViewHost = .NULL.
    RETURN .T.
ENDFUNC

FUNCTION GetWebViewHostLastError
    LPARAMETERS toHost

    LOCAL lcError

    lcError = ""
    IF VARTYPE(toHost) # "O"
        RETURN lcError
    ENDIF

    TRY
        lcError = TRANSFORM(toHost.LastError)
    CATCH
        lcError = ""
    ENDTRY

    RETURN lcError
ENDFUNC

FUNCTION WaitForBackend
    LPARAMETERS tcBaseUrl, tnSeconds

    LOCAL lnTry, lnTries

    IF VARTYPE(tnSeconds) # "N" OR tnSeconds <= 0
        tnSeconds = 10
    ENDIF

    lnTries = INT(tnSeconds)
    IF lnTries < 1
        lnTries = 1
    ENDIF

    FOR lnTry = 1 TO lnTries
        IF BackendAlive(tcBaseUrl)
            RETURN .T.
        ENDIF

        DOEVENTS
        =INKEY(1)
    ENDFOR

    RETURN .F.
ENDFUNC

FUNCTION PostContext
    LPARAMETERS tcBaseUrl, tcJson, lnStatus, lcResponseText

    LOCAL lcStatusText

    RETURN HttpJsonRequest("POST", NormalizeBaseUrl(tcBaseUrl) + "/api/context", tcJson, @lnStatus, @lcStatusText, @lcResponseText)
ENDFUNC

FUNCTION PostChat
    LPARAMETERS tcBaseUrl, tcMessage, lnStatus, lcResponseText

    LOCAL lcJson, lcStatusText

    lcJson = '{"message":"' + JsonEscape(tcMessage) + '"}'

    RETURN HttpJsonRequest("POST", NormalizeBaseUrl(tcBaseUrl) + "/api/chat", lcJson, @lnStatus, @lcStatusText, @lcResponseText)
ENDFUNC

FUNCTION BuildSampleContext
    LOCAL lcJson

    TEXT TO lcJson NOSHOW TEXTMERGE PRETEXT 15
{
  "source_app": "vfp_demo",
  "user_id": "alex",
  "filters": {
    "sucursal": "Centro",
    "fecha_inicio": "2026-03-01",
    "fecha_fin": "2026-03-24"
  },
  "dataset_info": {
    "filename": "reporte_filtrado.csv",
    "row_count": 1245,
    "columns": ["fecha", "sucursal", "ventas"]
  }
}
    ENDTEXT

    RETURN lcJson
ENDFUNC

FUNCTION JsonEscape
    LPARAMETERS tcText

    LOCAL lcValue

    lcValue = TRANSFORM(tcText)
    lcValue = STRTRAN(lcValue, "\", "\\")
    lcValue = STRTRAN(lcValue, CHR(13) + CHR(10), "\n")
    lcValue = STRTRAN(lcValue, CHR(13), "\n")
    lcValue = STRTRAN(lcValue, CHR(10), "\n")
    lcValue = STRTRAN(lcValue, CHR(9), "\t")
    lcValue = STRTRAN(lcValue, CHR(34), "\")

    RETURN lcValue
ENDFUNC

FUNCTION AppendLog
    LPARAMETERS toForm, tcText

    LOCAL lcLine

    IF VARTYPE(toForm) # "O" OR !PEMSTATUS(toForm, "edtLog", 5)
        RETURN .F.
    ENDIF

    lcLine = "[" + TIME() + "] " + TRANSFORM(tcText)

    IF EMPTY(toForm.edtLog.Value)
        toForm.edtLog.Value = lcLine
    ELSE
        toForm.edtLog.Value = toForm.edtLog.Value + CHR(13) + CHR(10) + lcLine
    ENDIF

    toForm.edtLog.SelStart = LEN(toForm.edtLog.Value)
    RETURN .T.
ENDFUNC

FUNCTION UpdateStatus
    LPARAMETERS toForm, tcText, tlBackendReady

    IF VARTYPE(toForm) = "O" AND PEMSTATUS(toForm, "lblStatus", 5)
        toForm.lblStatus.Caption = "Estado: " + TRANSFORM(tcText)
    ENDIF

    IF VARTYPE(toForm) = "O" AND PCOUNT() >= 3 AND PEMSTATUS(toForm, "lBackendReady", 5)
        toForm.lBackendReady = tlBackendReady
    ENDIF

    RETURN .T.
ENDFUNC

FUNCTION HttpJsonRequest
    LPARAMETERS tcMethod, tcUrl, tcBody, lnStatus, lcStatusText, lcResponseText

    LOCAL loHttp, llOk

    lnStatus = 0
    lcStatusText = ""
    lcResponseText = ""
    llOk = .F.

    TRY
        loHttp = CREATEOBJECT("MSXML2.ServerXMLHTTP.6.0")
        loHttp.setTimeouts(2000, 2000, 5000, 5000)
        loHttp.Open(tcMethod, tcUrl, .F.)
        loHttp.setRequestHeader("Accept", "application/json")

        IF VARTYPE(tcBody) = "C" AND !EMPTY(tcBody)
            loHttp.setRequestHeader("Content-Type", "application/json")
            loHttp.Send(tcBody)
        ELSE
            loHttp.Send()
        ENDIF

        lnStatus = loHttp.Status
        lcStatusText = loHttp.statusText
        lcResponseText = loHttp.responseText

        llOk = BETWEEN(lnStatus, 200, 299)
    CATCH TO loEx
        lcStatusText = loEx.Message
        llOk = .F.
    ENDTRY

    RETURN llOk
ENDFUNC

FUNCTION NormalizeBaseUrl
    LPARAMETERS tcBaseUrl

    LOCAL lcUrl

    lcUrl = ALLTRIM(tcBaseUrl)
    IF RIGHT(lcUrl, 1) = "/"
        lcUrl = LEFT(lcUrl, LEN(lcUrl) - 1)
    ENDIF

    RETURN lcUrl
ENDFUNC

FUNCTION QuotePath
    LPARAMETERS tcPath

    RETURN CHR(34) + tcPath + CHR(34)
ENDFUNC

FUNCTION CreateBridgeEventSink
    LPARAMETERS toForm, tcBridgePath

    LOCAL loSink

    loSink = .NULL.

    TRY
        loSink = NEWOBJECT("BridgeEventSink", tcBridgePath, "", toForm)
    CATCH
        loSink = .NULL.
    ENDTRY

    RETURN loSink
ENDFUNC

DEFINE CLASS BridgeEventSink AS Custom
    oForm = .NULL.

    PROCEDURE Init
        LPARAMETERS toForm
        THIS.oForm = toForm
    ENDPROC

    PROCEDURE OnStartBridge
        IF VARTYPE(THIS.oForm) = "O"
            =HandleStartBridge(THIS.oForm)
        ENDIF
    ENDPROC

    PROCEDURE OnHealthCheck
        IF VARTYPE(THIS.oForm) = "O"
            =HandleHealthCheck(THIS.oForm)
        ENDIF
    ENDPROC

    PROCEDURE OnSendContext
        IF VARTYPE(THIS.oForm) = "O"
            =HandleSendContext(THIS.oForm)
        ENDIF
    ENDPROC

    PROCEDURE OnSendChat
        IF VARTYPE(THIS.oForm) = "O"
            =HandleSendChat(THIS.oForm)
        ENDIF
    ENDPROC

    PROCEDURE OnOpenUi
        IF VARTYPE(THIS.oForm) = "O"
            =HandleOpenUi(THIS.oForm)
        ENDIF
    ENDPROC

    PROCEDURE OnFormResize
        IF VARTYPE(THIS.oForm) = "O"
            =HandleFormResize(THIS.oForm)
        ENDIF
    ENDPROC

    PROCEDURE OnFormDestroy
        IF VARTYPE(THIS.oForm) = "O"
            =BridgeDestroyForm(THIS.oForm)
        ENDIF
    ENDPROC

    PROCEDURE OnAutoStart
        IF VARTYPE(THIS.oForm) = "O"
            =HandleAutoStart(THIS.oForm)
        ENDIF
    ENDPROC
ENDDEFINE

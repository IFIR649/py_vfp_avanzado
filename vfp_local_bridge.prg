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
        toForm.AddProperty("cBackendBat", ADDBS(lcProjectDir) + "start_backend.bat")
    ELSE
        toForm.cBackendBat = ADDBS(lcProjectDir) + "start_backend.bat"
    ENDIF

    IF !PEMSTATUS(toForm, "cStartDemoPs1", 5)
        toForm.AddProperty("cStartDemoPs1", ADDBS(lcProjectDir) + "start_demo.ps1")
    ELSE
        toForm.cStartDemoPs1 = ADDBS(lcProjectDir) + "start_demo.ps1"
    ENDIF

    IF !PEMSTATUS(toForm, "cHostExe", 5)
        toForm.AddProperty("cHostExe", ADDBS(lcProjectDir) + "bin\Debug\net8.0-windows\VfpWebViewHost.exe")
    ELSE
        toForm.cHostExe = ADDBS(lcProjectDir) + "bin\Debug\net8.0-windows\VfpWebViewHost.exe"
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

    RETURN .T.
ENDFUNC

FUNCTION BridgeDestroyForm
    LPARAMETERS toForm

    IF VARTYPE(toForm) = "O"
        AppendLog(toForm, "Cierre del formulario.")
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
        .Caption = "Abrir UI"
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

    IF !PEMSTATUS(toForm, "lblLogTitle", 5)
        toForm.AddObject("lblLogTitle", "Label")
    ENDIF
    WITH toForm.lblLogTitle
        .Top = 92
        .Left = 552
        .Caption = "Log"
        .AutoSize = .T.
        .Visible = .T.
    ENDWITH

    IF !PEMSTATUS(toForm, "edtLog", 5)
        toForm.AddObject("edtLog", "EditBox")
    ENDIF
    WITH toForm.edtLog
        .Top = 114
        .Left = 550
        .Width = 520
        .Height = 560
        .ScrollBars = 2
        .ReadOnly = .T.
        .Visible = .T.
    ENDWITH

    toForm.Refresh()

    RETURN .T.
ENDFUNC

FUNCTION HandleStartBridge
    LPARAMETERS toForm

    LOCAL llOk

    AppendLog(toForm, "Iniciando bridge local...")

    IF !BackendAlive(toForm.cBaseUrl)
        IF StartBackend(toForm.cProjectDir)
            AppendLog(toForm, "Backend lanzado con start_backend.bat.")
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

    IF StartWebViewHost(toForm.cProjectDir, .F.)
        AppendLog(toForm, "Host WebView2 lanzado.")
    ELSE
        AppendLog(toForm, "No se pudo lanzar el host WebView2.")
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

    IF StartWebViewHost(toForm.cProjectDir, .F.)
        AppendLog(toForm, "UI lanzada.")
        UpdateStatus(toForm, "UI abierta", .T.)
        RETURN .T.
    ENDIF

    AppendLog(toForm, "No se pudo lanzar la UI.")
    UpdateStatus(toForm, "Error al abrir UI", .T.)
    RETURN .F.
ENDFUNC

FUNCTION BackendAlive
    LPARAMETERS tcBaseUrl

    LOCAL lnStatus, lcStatusText, lcResponseText

    RETURN HttpJsonRequest("GET", NormalizeBaseUrl(tcBaseUrl) + "/health", "", @lnStatus, @lcStatusText, @lcResponseText)
ENDFUNC

FUNCTION StartBackend
    LPARAMETERS tcProjectDir

    LOCAL lcBatch, loShell, lcCommand, llOk

    lcBatch = ADDBS(tcProjectDir) + "start_backend.bat"
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
    LPARAMETERS tcProjectDir, tlUseDotnetRun

    LOCAL lcHostExe, lcPowerShell, lcCommand, loShell, llOk

    lcHostExe = ADDBS(tcProjectDir) + "bin\Debug\net8.0-windows\VfpWebViewHost.exe"
    lcPowerShell = ADDBS(tcProjectDir) + "start_demo.ps1"

    llOk = .F.
    TRY
        loShell = CREATEOBJECT("WScript.Shell")

        IF !tlUseDotnetRun .AND. FILE(lcHostExe)
            loShell.Run(QuotePath(lcHostExe), 1, .F.)
            llOk = .T.
        ELSE
            IF FILE(lcPowerShell)
                lcCommand = "powershell.exe -ExecutionPolicy Bypass -File " + QuotePath(lcPowerShell)
                loShell.Run(lcCommand, 1, .F.)
                llOk = .T.
            ENDIF
        ENDIF
    CATCH
        llOk = .F.
    ENDTRY

    RETURN llOk
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
ENDDEFINE

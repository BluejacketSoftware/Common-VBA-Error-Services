Attribute VB_Name = "mErH"
Option Explicit
Option Private Module
' -----------------------------------------------------------------------------------------------
' Standard  Module mErrHndlr: Global error handling for any VBA Project.
'
' Methods: - AppErr   Converts a positive number into a negative error number ensuring it not
'                     conflicts with a VB Runtime Error. A negative error number is turned back into the
'                     original positive Application  Error Number.
'          - ErrMsg Either passes on the error to the caller or when the entry procedure is
'                     reached, displays the error with a complete path from the entry procedure
'                     to the procedure with the error.
'          - BoP      Maintains the call stack at the Begin of a Procedure (optional when using
'                     this common error handler)
'          - EoP      Maintains the call stack at the End of a Procedure, triggers the display of
'                     the Execution Trace when the entry procedure is finished and the
'                     Conditional Compile Argument ExecTrace = 1
'          - ErrDsply Displays the error message in a proper formated manner
'                     The local Conditional Compile Argument "AlternativeMsgBox = 1" enforces the use
'                     of the Alternative VBA MsgBox which provideds an improved readability.
'
' Usage:   Private/Public Sub/Function any()
'              Const PROC = "any"  ' procedure's name as error source
'
'              On Error GoTo eh
'              mErH.BoP ErrSrc(PROC)   ' puts the procedure on the call stack
'
'              ' <any code>
'
'          xt: ' <any "finally" code like re-protecting an unprotected sheet for instance>
'                               mErH.EoP ErrSrc(PROC)   ' takes the procedure off from the call stack
'                               Exit Sub/Function
'
'           eh: mErH.ErrMsg Err.Number, ErrSrc(PROC), Err.Description, Erl
'           End ....
'
' Note: When never a mErH.BoP/mErH.EoP procedure had been executed the ErrMsg
'       is displayed with the procedure the error occoured. Else the error is
'       passed on back up to the first procedure with a mErH.BoP/mErH.EoP code
'       line executed and displayed when it had been reached.
'
' Uses: fMsg
'       mTrc (optionally, when the Conditional Compile Argument ExecTrace = 1)
'
' Requires: Reference to "Microsoft Scripting Runtime"
'
'          For further details see the Github blog post
'          "A comprehensive common VBA Error Handler inspired by the best of the web"
' https://warbe-maker.github.io/vba/common/2020/10/02/Comprehensive-Common-VBA-Error-Handler.html
'
' W. Rauschenberger, Berlin, Nov 2020
' -----------------------------------------------------------------------------------------------

Private Const TYPE_APP_ERR  As String = "Application error "
Private Const TYPE_VB_ERR   As String = "VB Runtime error "
Private Const TYPE_DB_ERROR As String = "Database error "
Public Const CONCAT         As String = "||"

Public Enum StartupPosition         ' ---------------------------
    Manual = 0                      ' Used to position the
    CenterOwner = 1                 ' final setup message form
    CenterScreen = 2                ' horizontally and vertically
    WindowsDefault = 3              ' centered on the screen
End Enum                            ' ---------------------------

Private Enum enErrorType
    VBRuntimeError
    ApplicationError
    DatabaseError
End Enum

Public Type tSection                ' ------------------
       sLabel As String             ' Structure of the
       sText As String              ' UserForm's
       bMonspaced As Boolean        ' message area which
End Type                            ' consists of
Public Type tMessage                ' three message
       section(1 To 3) As tSection  ' sections
End Type                            ' -------------------

Private cllErrPath          As Collection
Private cllErrorPath        As Collection   ' managed by ErrPath... procedures exclusively
Private dctStck             As Dictionary
Private sErrHndlrEntryProc  As String
Private lSubsequErrNo       As Long ' a number possibly different from lInitialErrNo when it changes when passed on to the Entry Procedure
Private lInitialErrLine     As Long
Private lInitialErrNo       As Long
Private sInitialErrSource   As String
Private sInitialErrDscrptn  As String
Private sInitialErrInfo     As String

' Test button, displayed with Conditional Compile Argument Test = 1
Public Property Get ExitAndContinue() As String:        ExitAndContinue = "Exit procedure" & vbLf & "and continue" & vbLf & "with next":    End Property

' Debugging button, displayed with Conditional Compile Argument Debugging = 1
Public Property Get ResumeError() As String:            ResumeError = "Resume" & vbLf & "error code line":                                  End Property

' Test button, displayed with Conditional Compile Argument Test = 1
Public Property Get ResumeNext() As String:             ResumeNext = "Continue with code line" & vbLf & "following the error line":         End Property

' Default error message button
Public Property Get ErrMsgDefaultButton() As String:    ErrMsgDefaultButton = "Terminate execution":                                                  End Property

Private Property Get StackEntryProc() As String
    If Not StackIsEmpty _
    Then StackEntryProc = dctStck.Items()(0) _
    Else StackEntryProc = vbNullString
End Property

Public Function AppErr(ByVal errno As Long) As Long
' -----------------------------------------------------------------
' Used with Err.Raise AppErr(<l>).
' When the error number <l> is > 0 it is considered an "Application
' Error Number and vbObjectErrror is added to it into a negative
' number in order not to confuse with a VB runtime error.
' When the error number <l> is negative it is considered an
' Application Error and vbObjectError is added to convert it back
' into its origin positive number.
' ------------------------------------------------------------------
    If errno < 0 Then
        AppErr = errno - vbObjectError
    Else
        AppErr = vbObjectError + errno
    End If
End Function

Public Sub BoP(ByVal s As String)
' ----------------------------------
' Trace and stack Begin of Procedure
' ----------------------------------
    Const PROC = "BoP"
    
    On Error GoTo eh
    
    StackPush s
#If ExecTrace Then
    mTrc.BoP s    ' start of the procedure's execution trace
#End If

xt: Exit Sub

eh: MsgBox err.Description, vbOKOnly, "Error in " & ErrSrc(PROC)
    Stop: Resume
End Sub

Public Sub EoP(ByVal s As String)
' --------------------------------
' Trace and stack End of Procedure
' --------------------------------
    StackPop s
#If ExecTrace Then
    mTrc.EoP s
#End If
End Sub

Public Function ErrMsg(ByVal errnumber As Long, _
                         ByVal errsource As String, _
                         ByVal errdscrptn As String, _
                         ByVal errline As Long, _
                Optional ByVal buttons As Variant = vbNullString) As Variant
' ----------------------------------------------------------------------
' When the buttons argument specifies more than one button the error
' message is immediately displayed and the users choice is returned,
' else when the caller (errsource) is the "Entry Procedure" the error
' is displayed with the path to the error,
' else the error is passed on to the "Entry Procedure" whereby the
' .ErrorPath string is assebled.
' ----------------------------------------------------------------------
    
    Static sLine    As String   ' provided error line (if any) for the the finally displayed message
    
    If ErrHndlrFailed(errnumber, errsource, buttons) Then Exit Function
    If cllErrPath Is Nothing Then Set cllErrPath = New Collection
    If errline <> 0 Then sLine = errline Else sLine = "0"
    ErrHndlrManageButtons buttons

    If sInitialErrSource = vbNullString Then
        '~~ This is the initial/first execution of the error handler within the error raising procedure.
        sInitialErrInfo = ErrorDetails(errnumber, errsource, errline)
        lInitialErrLine = errline
        lInitialErrNo = errnumber
        sInitialErrSource = errsource
        sInitialErrDscrptn = errdscrptn
    ElseIf errnumber <> lInitialErrNo _
        And errnumber <> lSubsequErrNo _
        And errsource <> sInitialErrSource Then
        '~~ In the rare case when the error number had changed during the process of passing it back up to the entry procedure
        lSubsequErrNo = errnumber
        sInitialErrInfo = ErrorDetails(lSubsequErrNo, errsource, errline)
    End If
    
    If ErrBttns(buttons) = 1 _
    And sErrHndlrEntryProc <> vbNullString _
    And StackEntryProc <> errsource Then
        '~~ When the user has no choice to press any button but the only one displayed button
        '~~ and the Entry Procedure is known but yet not reached the error is passed on back
        '~~ up to the Entry Procedure whereupon the path to the error is assembled
        ErrPathAdd errsource
#If ExecTrace Then
        mTrc.EoP errsource, sInitialErrInfo
#End If
        StackPop errsource, sInitialErrInfo
        sInitialErrInfo = vbNullString
        err.Raise errnumber, errsource, errdscrptn
    End If
    
    If ErrBttns(buttons) > 1 _
    Or StackEntryProc = errsource _
    Or StackEntryProc = vbNullString Then
        '~~ When the user has the choice between several buttons displayed
        '~~ or the Entry Procedure is unknown or has been reached
        If Not ErrPathIsEmpty Then ErrPathAdd errsource
        '~~ Display the error message
        ErrMsg = ErrDsply(errnumber:=lInitialErrNo, errsource:=sInitialErrSource, errdscrptn:=sInitialErrDscrptn, errline:=lInitialErrLine, buttons:=buttons)
        Select Case ErrMsg
            Case ResumeError, ResumeNext, ExitAndContinue
            Case Else: ErrPathErase
        End Select
#If ExecTrace Then
        mTrc.EoP errsource, sInitialErrInfo
#End If
        StackPop errsource, sInitialErrInfo
        sInitialErrInfo = vbNullString
        sInitialErrSource = vbNullString
        sInitialErrDscrptn = vbNullString
        lInitialErrNo = 0
    End If
    
    '~~ Each time a known Entry Procedure is reached the execution trace
    '~~ maintained by the BoP and mErH.EoP and the BoC and EoC statements is displayed
    If StackEntryProc = errsource _
    Or StackEntryProc = vbNullString Then
        Select Case ErrMsg
            Case ResumeError, ResumeNext, ExitAndContinue
            Case vbOK
            Case Else: StackErase
        End Select
    End If
    StackPop errsource
    
End Function

Private Sub ErrHndlrDisplayTrace()
' --------------------------------------
' Display the trace in the fMsg UserForm
' --------------------------------------
#If ExecTrace Then
    mTrc.Dsply
#End If
End Sub

Private Sub ErrHndlrManageButtons(ByRef buttons As Variant)

    If buttons = vbNullString _
    Then buttons = ErrMsgDefaultButton _
    Else ErrHndlrAddButtons ErrMsgDefaultButton, buttons ' add the default button before the buttons specified
    
'~~ Special features are only available with the Alternative VBA MsgBox
#If Debugging Or Test Then
    ErrHndlrAddButtons buttons, vbLf ' buttons in new row
#End If
#If Debugging Then
    ErrHndlrAddButtons buttons, ResumeError
#End If
#If Test Then
     ErrHndlrAddButtons buttons, ResumeNext
     ErrHndlrAddButtons buttons, ExitAndContinue
#End If

End Sub
Private Function ErrHndlrFailed( _
        ByVal errnumber As Long, _
        ByVal errsource As String, _
        ByVal buttons As Variant) As Boolean
' ------------------------------------------
'
' ------------------------------------------

    If errnumber = 0 Then
        MsgBox "The error handling has been called with an error number = 0 !" & vbLf & vbLf & _
               "This indicates that in procedure" & vbLf & _
               ">>>>> " & errsource & " <<<<<" & vbLf & _
               "an ""Exit ..."" statement before the call of the error handling is missing!" _
               , vbExclamation, _
               "Exit ... statement missing in " & errsource & "!"
                ErrHndlrFailed = True
        Exit Function
    End If
    
    If IsNumeric(buttons) Then
        '~~ When buttons is a numeric value, only the VBA MsgBox values for the button argument are supported
        Select Case buttons
            Case vbOKOnly, vbOKCancel, vbYesNo, vbRetryCancel, vbYesNoCancel, vbAbortRetryIgnore
            Case Else
                MsgBox "When the buttons argument is a numeric value Only the valid VBA MsgBox vaulues are supported. " & _
                       "For valid values please refer to:" & vbLf & _
                       "https://docs.microsoft.com/en-us/office/vba/Language/Reference/User-Interface-Help/msgbox-function" _
                       , vbOKOnly, "Only the valid VBA MsgBox vaulues are supported!"
                ErrHndlrFailed = True
                Exit Function
        End Select
    End If

End Function

Private Sub ErrHndlrAddButtons(ByRef v1 As Variant, _
                               ByRef v2 As Variant)
' ---------------------------------------------------
' Returns v1 followed by v2 whereby both may be a
' buttons argument which means  a string, a
' Dictionary or a Collection. When v1 is a Dictionary
' or Collection v2 must be a string or long and vice
' versa.
' ---------------------------------------------------
    
    Dim dct As New Dictionary
    Dim cll As New Collection
    Dim v   As Variant
    
    Select Case TypeName(v1)
        Case "Dictionary"
            Select Case TypeName(v2)
                Case "String", "Long": v1.Add v2, v2
                Case Else ' Not added !
            End Select
        Case "Collection"
            Select Case TypeName(v2)
                Case "String", "Long": v1.Add v2
                Case Else ' Not added !
            End Select
        Case "String", "Long"
            Select Case TypeName(v2)
                Case "String"
                    v1 = v1 & "," & v2
                Case "Dictionary"
                    dct.Add v1, v1
                    For Each v In v2
                        dct.Add v, v
                    Next v
                    Set v2 = dct
                Case "Collection"
                    cll.Add v1
                    For Each v In v2
                        cll.Add v
                    Next v
                    Set v2 = cll
            End Select
    End Select
    
End Sub

Public Function ErrDsply( _
                ByVal errnumber As Long, _
                ByVal errsource As String, _
                ByVal errdscrptn As String, _
                ByVal errline As Long, _
       Optional ByVal buttons As Variant = vbOKOnly) As Variant
' -------------------------------------------------------------
' Displays the error message either by means of VBA MsgBox or,
' when the Conditional Compile Argument AlternativeMsgBox = 1 by
' means of the Alternative VBA MsgBox (UserForm fMsg). In any
' case the path to the error may be displayed, provided the
' entry procedure has BoP/EoP code lines.
'
' W. Rauschenberger, Berlin, Sept 2020
' -------------------------------------------------------------
    
    Dim sErrPath    As String:      sErrPath = ErrPathErrMsg
    Dim sTitle      As String
    
    Select Case ErrorType(errnumber, errsource)
        Case VBRuntimeError, DatabaseError:         sTitle = ErrorTypeString(ErrorType(errnumber, errsource)) & errnumber & " in " & errsource & ErrorLine(errline)
        Case ApplicationError:                      sTitle = ErrorTypeString(ErrorType(errnumber, errsource)) & AppErr(errnumber) & " in " & errsource & ErrorLine(errline)
    End Select
    
    '~~ Display the error message by means of the Common UserForm fMsg
    With fMsg
        .MsgTitle = sTitle
        .MsgLabel(1) = "Error description:":            .MsgText(1) = ErrorDescription(sInitialErrDscrptn)
        If Not ErrPathIsEmpty Then
            .MsgLabel(2) = "Error path (call stack):":  .MsgText(2) = sErrPath:   .MsgMonoSpaced(2) = True
        Else
            .MsgLabel(2) = "Error source:":             .MsgText(2) = sInitialErrSource & ErrorLine(lInitialErrLine)
        End If
        .MsgLabel(3) = "Info:":                         .MsgText(3) = ErrorInfo(errdscrptn)
        .MsgButtons = buttons
        .Setup
        .Show
        If ErrBttns(buttons) = 1 Then
            ErrDsply = buttons ' a single reply buttons return value cannot be obtained since the form is unloaded with its click
        Else
            ErrDsply = .ReplyValue ' when more than one button is displayed the form is unloadhen the return value is obtained
        End If
    End With

End Function

Private Function ErrBttns( _
                 ByVal bttns As Variant) As Long
' ------------------------------------------------
' Returns the number of specified bttns.
' ------------------------------------------------
    Dim v As Variant
    
    For Each v In Split(bttns, ",")
        If IsNumeric(v) Then
            Select Case v
                Case vbOKOnly:                              ErrBttns = ErrBttns + 1
                Case vbOKCancel, vbYesNo, vbRetryCancel:    ErrBttns = ErrBttns + 2
                Case vbAbortRetryIgnore, vbYesNoCancel:     ErrBttns = ErrBttns + 3
            End Select
        Else
            Select Case v
                Case vbNullString, vbLf, vbCr, vbCrLf
                Case Else:  ErrBttns = ErrBttns + 1
            End Select
        End If
    Next v

End Function

Private Function ErrorDescription(ByVal s As String) As String
' ------------------------------------------------------------
' Returns the string which follows a "||" in the error
' description which indicates an additional information
' regarding the error.
' ------------------------------------------------------------
    If InStr(s, CONCAT) <> 0 _
    Then ErrorDescription = Split(s, CONCAT)(0) _
    Else ErrorDescription = s
End Function

Private Function ErrorDetails( _
                 ByVal errnumber As Long, _
                 ByVal errsource As String, _
                 ByVal sErrLine As String) As String
' --------------------------------------------------
' Returns the kind of error, the error number, and
' the error line (if available) as string.
' --------------------------------------------------
    
    Select Case ErrorType(errnumber, errsource)
        Case ApplicationError:              ErrorDetails = ErrorTypeString(ErrorType(errnumber, errsource)) & AppErr(errnumber)
        Case DatabaseError, VBRuntimeError: ErrorDetails = ErrorTypeString(ErrorType(errnumber, errsource)) & errnumber
    End Select
        
    If sErrLine <> 0 Then ErrorDetails = ErrorDetails & ErrorLine(lInitialErrLine)

End Function

Private Function ErrorInfo(ByVal s As String) As String
' -----------------------------------------------------
' Returns the string which follows a "||" in the error
' description which indicates an additional information
' regarding the error.
' -----------------------------------------------------
    If InStr(s, CONCAT) <> 0 _
    Then ErrorInfo = Split(s, CONCAT)(1) _
    Else ErrorInfo = vbNullString
End Function

Private Function ErrorLine( _
                 ByVal errline As Long) As String
' -----------------------------------------------
' Returns a complete errol line message.
' -----------------------------------------------
    If errline <> 0 _
    Then ErrorLine = " (at line " & errline & ")" _
    Else ErrorLine = vbNullString
End Function

Private Function ErrorTypeString(ByVal errtype As enErrorType) As String
    Select Case errtype
        Case ApplicationError:  ErrorTypeString = TYPE_APP_ERR
        Case DatabaseError:     ErrorTypeString = TYPE_DB_ERROR
        Case VBRuntimeError:    ErrorTypeString = TYPE_VB_ERR
    End Select
End Function

Private Function ErrorType( _
                 ByVal errnumber As Long, _
                 ByVal errsource As String) As enErrorType
' --------------------------------------------------------
' Return the kind of error considering the error source
' (errsource) and the error number (errnumber).
' --------------------------------------------------------

   If InStr(1, errsource, "DAO") <> 0 _
   Or InStr(1, errsource, "ODBC Teradata Driver") <> 0 _
   Or InStr(1, errsource, "ODBC") <> 0 _
   Or InStr(1, errsource, "Oracle") <> 0 Then
      ErrorType = DatabaseError
   Else
      If errnumber > 0 _
      Then ErrorType = VBRuntimeError _
      Else ErrorType = ApplicationError
   End If
   
End Function

Private Sub ErrPathAdd(ByVal s As String)
    
    If cllErrorPath Is Nothing Then Set cllErrorPath = New Collection _

    If Not ErrPathItemExists(s) Then
        Debug.Print s & " added to path"
        cllErrorPath.Add s ' avoid duplicate recording of the same procedure/item
    End If
End Sub

Private Function ErrPathItemExists(ByVal s As String) As Boolean

    Dim v As Variant
    
    For Each v In cllErrorPath
        If InStr(v & " ", s & " ") <> 0 Then
            ErrPathItemExists = True
            Exit Function
        End If
    Next v
    
End Function

Private Sub ErrPathErase()
    Set cllErrorPath = Nothing
End Sub

Private Function ErrPathErrMsg() As String
' ----------------------------------------
' Returns the error path for being
' displayed in the error message.
' ----------------------------------------
    
    Dim i   As Long:    i = 0
    Dim j   As Long:    j = 0
    Dim s   As String
    
    ErrPathErrMsg = vbNullString
    If Not ErrPathIsEmpty Then
        '~~ When the error path is not empty and not only contains the error source procedure
        For i = cllErrorPath.Count To 1 Step -1
            s = cllErrorPath.TrcEntryItem(i)
            If i = cllErrorPath.Count _
            Then ErrPathErrMsg = s _
            Else ErrPathErrMsg = ErrPathErrMsg & vbLf & Space(j * 2) & "|_" & s
            j = j + 1
        Next i
    End If
    ErrPathErrMsg = ErrPathErrMsg & vbLf & Space(j * 2) & "|_" & sInitialErrSource & " " & ErrorDetails(lInitialErrNo, sInitialErrSource, lInitialErrLine)

End Function

Private Function ErrPathIsEmpty() As Boolean
    ErrPathIsEmpty = cllErrorPath Is Nothing
    If Not ErrPathIsEmpty Then ErrPathIsEmpty = cllErrorPath.Count = 0
End Function

Private Function ErrSrc(ByVal sProc As String) As String
    ErrSrc = "mErH." & sProc
End Function

Public Function Space(ByVal l As Long) As String
' --------------------------------------------------
' Unifies the VB differences SPACE$ and Space$ which
' lead to code diferences where there aren't any.
' --------------------------------------------------
    Space = VBA.Space$(l)
End Function

Private Function StackBottom() As String
    If Not StackIsEmpty Then StackBottom = dctStck.Items()(0)
End Function

Private Sub StackErase()
    If Not dctStck Is Nothing Then dctStck.RemoveAll
End Sub

Public Function StackIsEmpty() As Boolean
    StackIsEmpty = dctStck Is Nothing
    If Not StackIsEmpty Then StackIsEmpty = dctStck.Count = 0
End Function

Public Function StackPop( _
       Optional ByVal itm As String = vbNullString, _
       Optional ByVal inf As String = vbNullString) As String
' -----------------------------------------------------------
' Returns the popped of the stack. When itm is provided and
' is not on the top of the stack pop is suspended.
' -----------------------------------------------------------
    Const PROC = "StackPop"
    
    On Error GoTo eh

    If Not StackIsEmpty Then
        If itm <> vbNullString And StackTop = itm Then
            StackPop = dctStck.Items()(dctStck.Count - 1) ' Return the poped item
            dctStck.Remove dctStck.Count                  ' Remove item itm from stack
        ElseIf itm = vbNullString Then
            dctStck.Remove dctStck.Count                  ' Unwind! Remove item itm from stack
        End If
    End If
    
xt: Exit Function

eh: MsgBox err.Description, vbOKOnly, "Error in " & ErrSrc(PROC)
End Function

Private Sub StackPush(ByVal s As String)

    If dctStck Is Nothing Then Set dctStck = New Dictionary
    If dctStck.Count = 0 Then
        sErrHndlrEntryProc = s ' First pushed = bottom item = entry procedure
#If ExecTrace Then
        mTrc.Terminate ' ensures any previous trace is erased
#End If
    End If
    dctStck.Add dctStck.Count + 1, s

End Sub

Private Function StackTop() As String
    If Not StackIsEmpty Then StackTop = dctStck.Items()(dctStck.Count - 1)
End Function


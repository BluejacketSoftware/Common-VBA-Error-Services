Attribute VB_Name = "mTest"
Option Explicit
Public bVBAError    As Boolean

Private Sub ErrHndlr_Test_5()

    On Error GoTo on_error
    Const PROC = "ErrHndlr_Test_5"
      
    BoP ErrSrc(PROC)
    ErrHndlr_Test_5a
    EoP ErrSrc(PROC)
    Exit Sub

on_error:
    mErrHndlr.ErrHndlr errnumber:=Err.Number, errsource:=ErrSrc(PROC), errdscrptn:=Err.Description, errline:=Erl
End Sub

Private Sub ErrHndlr_Test_5a()

    Const PROC = "ErrHndlr_Test_5a"
    On Error GoTo on_error
       
    BoP ErrSrc(PROC)
15  Debug.Print ThisWorkbook.Named

end_proc:
    EoP ErrSrc(PROC)
    Exit Sub
    
on_error:
    Select Case mErrHndlr.ErrHndlr(errnumber:=Err.Number, errsource:=ErrSrc(PROC), errdscrptn:=Err.Description, errline:=Erl)
        Case ResumeButton: Stop: Resume ' Continue with F8 to end up at the code line which caused the error
    End Select
End Sub

Sub ErrHndlr_Test_No_Exit_Statement()
    
    Const PROC = "ErrHndlr_Test_No_Exit_Statement"
    
    On Error GoTo on_error
'    Exit Sub
    
on_error:
    mErrHndlr.ErrHndlr errnumber:=Err.Number, errsource:=ErrSrc(PROC), errdscrptn:=Err.Description, errline:=Erl
End Sub

Sub ErrHndlr_Test_1()
' ------------------------------------------------------
' White-box- and the regression-test procedure performed
' after any change in this module.
' Display of an execution trace along with this test
' requires a conditional compile argument ExecTrace = 1.
' ------------------------------------------------------
Const PROC      As String = "ErrHndlr_Test_1"
   
    '~~ Note that there is no BoP/EoP code line in this test procedure. Each of
    '~~ the performed test procedures is therefore and "entry procedure", i.e.
    '~~ a top level procedure of which the execution is put to a stack and so
    '~~ are all subprocedures which do have a BoP/EoP code line. When the
    '~~ execution returns to the entry procedure due to an error the corresponding
    '~~ error message is displayed. In any case the execution trace is displayed
    '~~ provideded the conditional compile argument ExecTrace = 1.
    
    '~~ Test 1: Unpaired BoP/EoP (A BoP without an EoP and vice versa)
    TestProc_4
    
exit_proc:
    EoP ErrSrc(PROC)
    Exit Sub

on_error:
    mErrHndlr.ErrHndlr errnumber:=Err.Number, errsource:=ErrSrc(PROC), errdscrptn:=Err.Description, errline:=Erl
End Sub

Sub ErrHndlr_Test_2()
' ------------------------------------------------------
' White-box- and the regression-test procedure performed
' after any change in this module.
' Display of an execution trace along with this test
' requires a conditional compile argument ExecTrace = 1.
' ------------------------------------------------------
Const PROC      As String = "ErrHndlr_Test_2"
   
    '~~ Note that there is no BoP/EoP code line in this test procedure. Each of
    '~~ the performed test procedures is therefore and "entry procedure", i.e.
    '~~ a top level procedure of which the execution is put to a stack and so
    '~~ are all subprocedures which do have a BoP/EoP code line. When the
    '~~ execution returns to the entry procedure due to an error the corresponding
    '~~ error message is displayed. In any case the execution trace is displayed
    '~~ provideded the conditional compile argument ExecTrace = 1.
    
    On Error GoTo on_error
    BoP ErrSrc(PROC)
    
    '~~ Test 1: Application Error 1
    '~~         TestProc_1 is regarded the "entry procedure"
    bVBAError = False
    TestProc_1
    
exit_proc:
    EoP ErrSrc(PROC)
    Exit Sub

on_error:
    mErrHndlr.ErrHndlr errnumber:=Err.Number, errsource:=ErrSrc(PROC), errdscrptn:=Err.Description, errline:=Erl
End Sub

Sub ErrHndlr_Test_3()
' -----------------------------------------------
' - With Conditional Compile Argument BopEop = 0:
'   Display of the error with the error path only
' - With Conditional Compile Argument BopEop = 1:
'   Display of the error with the error path plus
'   Display of a full execution trace
'
' Requires:
' - Conditional Compile Argument ExecTrace = 1.
' -----------------------------------------------
Const PROC      As String = "ErrHndlr_Test_3"
#Const BopEop = 1 ' 0 = Entry and error proc only, 1 = full call sequence
   
    On Error GoTo on_error
    BoP ErrSrc(PROC)
        
    '~~ Test: VBA-Error 11 (Division by 0)
    bVBAError = True
    TestProc_1
    
exit_proc:
    EoP ErrSrc(PROC)
    Exit Sub

on_error:
    mErrHndlr.ErrHndlr errnumber:=Err.Number, errsource:=ErrSrc(PROC), errdscrptn:=Err.Description, errline:=Erl
End Sub

Sub TestProc_4()
' ----------------------------------------------------------------
' The error handler is trying its very best not to confuse with
' unpaired BoP/EoP code lines. However, it depends at which level
' this is the case.
' ----------------------------------------------------------------
Const PROC = "Test_4"
    
'    On Error GoTo on_error
    
    TestProc_4_1 ' missing End of Procedure statement
    
#If BopEop Then
    BoP ErrSrc(PROC)
#End If
    TestProc_4_2b   ' missing Begin of Procedure statement
    TestProc_4_2a   ' missing Begin of Procedure statement
#If BopEop Then
    EoP ErrSrc(PROC)
#End If
exit_proc:
    Exit Sub

on_error:
    mErrHndlr.ErrHndlr errnumber:=Err.Number, errsource:=ErrSrc(PROC), errdscrptn:=Err.Description, errline:=Erl
End Sub

Sub TestProc_4_1()
Const PROC = "Test_4_1"
    
    On Error GoTo on_error
    
#If BopEop Then
    BoP ErrSrc(PROC)
#End If
    TestProc_4_1a
    
exit_proc:
#If BopEop Then
    EoP ErrSrc(PROC)
#End If
    Exit Sub
on_error:
#If Debugging Then
    Debug.Print Err.Description: Stop: Resume
#End If
    mErrHndlr.ErrHndlr errnumber:=Err.Number, errsource:=ErrSrc(PROC), errdscrptn:=Err.Description, errline:=Erl
End Sub

Sub TestProc_4_1a()
Const PROC = "Test_4_1a"
    
    On Error GoTo on_error
#If BopEop Then
    BoP ErrSrc(PROC)
#End If
    Dim l As Long
    
exit_proc:
#If BopEop Then
    EoP ErrSrc(PROC)
#End If
    Exit Sub
on_error:
#If Debugging Then
    Debug.Print Err.Description: Stop: Resume
#End If
    mErrHndlr.ErrHndlr errnumber:=Err.Number, errsource:=ErrSrc(PROC), errdscrptn:=Err.Description, errline:=Erl
End Sub

Sub TestProc_4_2a()
Const PROC = "Test_4_2a"
    
    On Error GoTo on_error
    BoP ErrSrc(PROC) & " (missing EoP)"
    
exit_proc:
'    EoP ErrSrc(PROC) & " (missing EoP)"
    Exit Sub

on_error:
#If Debugging Then
    Debug.Print Err.Description: Stop: Resume
#End If
    mErrHndlr.ErrHndlr errnumber:=Err.Number, errsource:=ErrSrc(PROC), errdscrptn:=Err.Description, errline:=Erl
End Sub

Sub TestProc_4_2b()
Const PROC = "Test_4_2b"
    
    On Error GoTo on_error
'    BoP ErrSrc(PROC) & " (missing BoP)"
    
exit_proc:
    EoP ErrSrc(PROC) & " (missing BoP)"
    Exit Sub

on_error:
#If Debugging Then
    Debug.Print Err.Description: Stop: Resume
#End If
    mErrHndlr.ErrHndlr errnumber:=Err.Number, errsource:=ErrSrc(PROC), errdscrptn:=Err.Description, errline:=Erl
End Sub

Sub TestProc_1()
Const PROC      As String = "Test_1"

#If BopEop Then
    BoP ErrSrc(PROC)
#End If
    On Error GoTo on_error
    TestProc_2

exit_proc:
#If BopEop Then
    EoP ErrSrc(PROC)
#End If
    Exit Sub

on_error:
    mErrHndlr.ErrHndlr errnumber:=Err.Number, errsource:=ErrSrc(PROC), errdscrptn:=Err.Description, errline:=Erl
End Sub

Sub TestProc_2()
Const PROC      As String = "Test_2"

#If BopEop Then
    BoP ErrSrc(PROC)
#End If
    On Error GoTo on_error
    
    TestProc_3
    
exit_proc:
#If BopEop Then
    EoP ErrSrc(PROC)
#End If
    Exit Sub

on_error:
    mErrHndlr.ErrHndlr errnumber:=Err.Number, errsource:=ErrSrc(PROC), errdscrptn:=Err.Description, errline:=Erl
End Sub

Sub TestProc_3()

    Const PROC      As String = "Test_3"

#If BopEop Then
    BoP ErrSrc(PROC)
#End If
    On Error GoTo on_error
    
    TestProc_3a
    
exit_proc:
#If BopEop Then
    EoP ErrSrc(PROC)
#End If
    Exit Sub

on_error:
#If Debugging Then
    Debug.Print Err.Description: Stop: Resume
#End If
    mErrHndlr.ErrHndlr errnumber:=Err.Number, errsource:=ErrSrc(PROC), errdscrptn:=Err.Description, errline:=Erl
End Sub

Sub TestProc_3a()

    Const PROC = "Test_4"

#If BopEop Then
    BoP ErrSrc(PROC)
#End If
    On Error GoTo on_error
    
    TestProc_3b
    
exit_proc:
#If BopEop Then
    EoP ErrSrc(PROC)
#End If
    Exit Sub

on_error:
#If Debugging Then
    Debug.Print Err.Description: Stop: Resume
#End If
    mErrHndlr.ErrHndlr errnumber:=Err.Number, errsource:=ErrSrc(PROC), errdscrptn:=Err.Description, errline:=Erl
End Sub


Sub TestProc_3b()

    Const PROC = "Test_3b"

#If BopEop Then
    BoP ErrSrc(PROC)
#End If
    On Error GoTo on_error
    
    TestProc_3c
    
exit_proc:
#If BopEop Then
    EoP ErrSrc(PROC)
#End If
    Exit Sub

on_error:
#If Debugging Then
'    Debug.Print Err.Description: Stop: Resume
#End If
    mErrHndlr.ErrHndlr errnumber:=Err.Number, errsource:=ErrSrc(PROC), errdscrptn:=Err.Description, errline:=Erl
End Sub

Sub TestProc_3c()
    
    Const PROC = "Test_3c"

    BoP ErrSrc(PROC)
    On Error GoTo on_error
    
    ' VBA Error:
'    Application.Wait Now() + 0.0001 ' ca. 10 Sek
    If bVBAError Then
        Dim l As Long
197     l = 7 / 0
    Else
199     Err.Raise AppErr(1), ErrSrc(PROC), _
                  "This is a programmed error!" & DCONCAT & _
                  "Attention: This is not a VBA error!" & vbLf & _
                  "The function AppErr() adds the 'vbObjectError' variable to assure non-conflicting programmed (Application) error numbers " & _
                  "which allows programmed error numbers 1 to n for each individual procedure." & vbLf & _
                  "Furthermore the error line has been added manually to the code to demonstrate its use when available." & vbLf & _
                  "This additional info had been concatenated with the error description by two vertical bars indicating it as additional message."
    End If

exit_proc:
    EoP ErrSrc(PROC)
    Exit Sub

on_error:
#If Debugging Then
    ' Debug.Print Err.Description: Stop: Resume
#End If
    mErrHndlr.ErrHndlr errnumber:=Err.Number, errsource:=ErrSrc(PROC), errdscrptn:=Err.Description, errline:=Erl
End Sub

Private Property Get ErrSrc(Optional ByVal sProc As String) As String:   ErrSrc = "mTest." & sProc: End Property

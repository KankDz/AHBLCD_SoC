;------------------------------------------------------------------------------------------------------
; UART -> LCD via AHB
; UART receive string: 0Hello / 1ABC
; '0' : print string to LCD line 1
; '1' : print string to LCD line 2
; Delay implemented using AHB Timer
;------------------------------------------------------------------------------------------------------

                PRESERVE8
                THUMB

;-------------------------------------------------------
; VECTOR TABLE
;-------------------------------------------------------
        AREA    RESET, DATA, READONLY
        EXPORT  __Vectors

__Vectors
        DCD     0x00003FFC
        DCD     Reset_Handler
        DCD     0,0,0,0,0,0,0,0,0,0,0,0,0,0

;-------------------------------------------------------
; AHB ADDRESS MAP
;-------------------------------------------------------
UART_DATA_ADDR     EQU 0x51000000
UART_STATUS_ADDR   EQU 0x51000004

LCD_CMD_ADDR       EQU 0x50000000
LCD_DATA_ADDR      EQU 0x50000004

TIMER_LOAD_ADDR    EQU 0x52000000
TIMER_VALUE_ADDR   EQU 0x52000004
TIMER_CTRL_ADDR    EQU 0x52000008

;-------------------------------------------------------
; CODE SECTION
;-------------------------------------------------------
        AREA    |.text|, CODE, READONLY

;-------------------------------------------------------
; Reset Handler
;-------------------------------------------------------
Reset_Handler PROC
        EXPORT Reset_Handler

        BL  LCD_Init

MAIN_LOOP
        BL  UART_GetChar      ; R0 = first char
		BL  UART_PutChar      ; echo '0'/'1' to PuTTY

        CMP R0, #'0'
        BEQ LINE1

        CMP R0, #'1'
        BEQ LINE2

        B   MAIN_LOOP

LINE1
        MOVS R0, #0x80
        BL   LCD_Write_Cmd
        B    READ_STRING

LINE2
        MOVS R0, #0xC0
        BL   LCD_Write_Cmd

READ_STRING
        BL  UART_GetChar
		BL  UART_PutChar      ; echo '0'/'1' to PuTTY

        CMP R0, #0x0A
        BEQ MAIN_LOOP

        CMP R0, #0x0D
        BEQ MAIN_LOOP

        BL  LCD_Write_Data
        B   READ_STRING

        ENDP

;-------------------------------------------------------
; UART Get Char (Polling)
;-------------------------------------------------------
UART_GetChar PROC
UG_WAIT
        LDR R1, =UART_STATUS_ADDR
        LDR R0, [R1]
        MOVS R2, #1
        ANDS R0, R0, R2
        BNE UG_WAIT

        LDR R1, =UART_DATA_ADDR
        LDR R0, [R1]
        BX  LR
        ENDP
			
UART_PutChar PROC
UP_WAIT
        LDR  R1, =UART_STATUS_ADDR
        LDR  R2, [R1]
        MOVS R3, #2          ; mask bit1
        ANDS R2, R2, R3
        BNE  UP_WAIT

        LDR  R1, =UART_DATA_ADDR
        STR  R0, [R1]
        BX   LR
        ENDP

;-------------------------------------------------------
; LCD INIT
;-------------------------------------------------------
LCD_Init PROC
        PUSH {LR}

        BL  Delay_Long

        MOVS R0, #0x33
        BL   LCD_Write_Cmd
        MOVS R0, #0x32
        BL   LCD_Write_Cmd

        MOVS R0, #0x28
        BL   LCD_Write_Cmd

        MOVS R0, #0x08
        BL   LCD_Write_Cmd

        MOVS R0, #0x01
        BL   LCD_Write_Cmd
        BL   Delay_Long

        MOVS R0, #0x06
        BL   LCD_Write_Cmd

        MOVS R0, #0x0C
        BL   LCD_Write_Cmd

        POP {PC}
        ENDP
;-------------------------------------------------------
; LCD WRITE CMD
;-------------------------------------------------------
LCD_Write_Cmd PROC
        PUSH {R1, LR}
        BL   Delay_Long 
        LDR  R1, =LCD_CMD_ADDR
        STR  R0, [R1]
        POP  {R1, PC}
        ENDP

;-------------------------------------------------------
; LCD WRITE DATA
;-------------------------------------------------------
LCD_Write_Data PROC
        PUSH {R1, LR}
        BL   Delay_Long 
        LDR  R1, =LCD_DATA_ADDR
        STR  R0, [R1]
        POP  {R1, PC}
        ENDP



;-------------------------------------------------------
; DELAY SHORT (Timer)
;-------------------------------------------------------
Delay_Short PROC
        PUSH {R0, R1}

        LDR  R1, =TIMER_LOAD_ADDR
        LDR  R0, =4800          ; ~100us @48MHz
        STR  R0, [R1]

        LDR  R1, =TIMER_CTRL_ADDR
        MOVS R0, #0x07
        STR  R0, [R1]

DS_WAIT
        LDR  R1, =TIMER_VALUE_ADDR
        LDR  R0, [R1]
        CMP  R0, #0
        BNE  DS_WAIT

        POP  {R0, R1}
        BX   LR
        ENDP

;-------------------------------------------------------
; DELAY LONG (Timer)
;-------------------------------------------------------
Delay_Long PROC
        PUSH {R0, R1}

        LDR  R1, =TIMER_LOAD_ADDR
        LDR  R0, =48000         ; ~1ms @48MHz
        STR  R0, [R1]

        LDR  R1, =TIMER_CTRL_ADDR
        MOVS R0, #0x07
        STR  R0, [R1]

DL_WAIT
        LDR  R1, =TIMER_VALUE_ADDR
        LDR  R0, [R1]
        CMP  R0, #0
        BNE  DL_WAIT

        POP  {R0, R1}
        BX   LR
        ENDP

        ALIGN 4
        END

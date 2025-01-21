;-------------------------------------------------------------------------------
; Include files
            .cdecls C,LIST,"msp430.h"  ; Include device header file
;-------------------------------------------------------------------------------


;------------------------------------------------------------------------------
;           Constants
;------------------------------------------------------------------------------
SDA_PIN .equ BIT0
SCL_PIN .equ BIT2
SDA_OUT .equ P6OUT
SCL_OUT .equ P6OUT
SDA_DIR .equ P6DIR
SCL_DIR .equ P6DIR            


init_i2c:
            ; stop watchdog timer
            mov.w   #WDTPW+WDTHOLD,&WDTCTL

            ; Setup SCL and SDA
            mov.b   #00h, &P1SEL0           ; sets to digital IO
            mov.b   #00h, &P1SEL1

            bis.b   #SDA_PIN, SDA_DIR       ; set SDA and SCL as output
            bis.b   #SCL_PIN, SCL_DIR 
            bis.b   #SDA_PIN, SDA_OUT       ; set SDA and SCL to High
            bis.b   #SCL_PIN, SCL_OUT


            ; Disable low-power mode
            bic.w   #LOCKLPM5,&PM5CTL0


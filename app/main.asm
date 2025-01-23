;-------------------------------------------------------------------------------
; Include files
            .cdecls C,LIST,"msp430.h"  ; Include device header file
;-------------------------------------------------------------------------------

            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.

            .global __STACK_END
            .sect   .stack                  ; Make stack linker segment ?known?

            .text                           ; Assemble to Flash memory
            .retain                         ; Ensure current section gets linked
            .retainrefs

RESET       mov.w   #__STACK_END,SP         ; Initialize stack pointer

;------------------------------------------------------------------------------
;           Constants
;------------------------------------------------------------------------------
SDA_PIN .equ BIT0
SCL_PIN .equ BIT2
SDA_OUT .equ P6OUT
SCL_OUT .equ P6OUT
SDA_DIR .equ P6DIR
SCL_DIR .equ P6DIR  

init:
            ; stop watchdog timer
            mov.w   #WDTPW+WDTHOLD,&WDTCTL
            
SetupSCLSDA            
            mov.b   #00h, &P1SEL0           ; sets to digital IO
            mov.b   #00h, &P1SEL1

            bis.b   #SDA_PIN, SDA_DIR       ; set SDA and SCL as output
            bis.b   #SCL_PIN, SCL_DIR 
            bis.b   #SDA_PIN, SDA_OUT       ; set SDA and SCL to High
            bis.b   #SCL_PIN, SCL_OUT

SetupP2     bic.b   #BIT0, &P1OUT
            bis.b   #BIT0, &P1DIR

SetupTimerBO
            bis.w   #TBCLR, &TB0CTL
            bis.w   #TBSSEL__ACLK, &TB0CTL
            bis.w   #MC__UP, &TB0CTL

            mov.w   #32768, &TB0CCR0
            bic.w   #CCIFG, &TB0CCTL0
            bis.w   #CCIE, &TB0CCTL0

            NOP
            bis.w   #GIE, SR
            NOP

            ; Disable low-power mode
            bic.w   #LOCKLPM5,&PM5CTL0

main:

            nop 
            jmp main
            nop

;------------------------------------------------------------------------------
;           I2C Sub routines
;------------------------------------------------------------------------------

i2c_init:

i2c_start:

i2c_stop:

i2c_tx_ack:

i2c_rx_ack:

i2c_tx_byte:

i2c_rx_byte:

i2c_sda_delay: ;(for satisfying setup and hold times)

i2c_scl_delay: ;(for setting your clock period)

i2c_send_address:

i2c_write:   ;(top-level function that would handle an entire write operation)

i2c_read:    ;(top-level function that would handle an entire read operation)






;------------------------------------------------------------------------------
;           Interrupt Service Routines
;------------------------------------------------------------------------------
HeartbeatLED:
            xor.b   #BIT0, &P1OUT
            bic.w   #CCIFG, &TB0CCTL0
            reti


;------------------------------------------------------------------------------
;           Interrupt Vectors
;------------------------------------------------------------------------------
            .sect   RESET_VECTOR            ; MSP430 RESET Vector
            .short  RESET                   ;

            .sect   ".int43"
            .short  HeartbeatLED

            .end
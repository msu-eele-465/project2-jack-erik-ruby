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


init:
            ; stop watchdog timer
            mov.w   #WDTPW+WDTHOLD,&WDTCTL

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
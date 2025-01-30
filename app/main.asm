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
SDA_REN .equ P6REN 

;------------------------------------------------------------------------------
;           Varaibles
;------------------------------------------------------------------------------
        .data

tx_byte .space 1

rx_byte .space 1

hours   .space 1
min     .space 1
sec    .space 1

        .text

;------------------------------------------------------------------------------
;           Macros
;------------------------------------------------------------------------------

delay_5us   .macro
            nop
            nop
            nop
            nop
            nop
            .endm


init:
            ; stop watchdog timer
            mov.w   #WDTPW+WDTHOLD,&WDTCTL
            call   #i2c_init
            

SetupP2     bic.b   #BIT0, &P1OUT
            bis.b   #BIT0, &P1DIR

SetupTimerBO
            bis.w   #TBCLR, &TB0CTL
            bis.w   #TBSSEL__ACLK, &TB0CTL
            bis.w   #MC__UP, &TB0CTL

            mov.w   #32768, &TB0CCR0
            bic.w   #CCIFG, &TB0CCTL0
            bis.w   #CCIE, &TB0CCTL0

            nop
            bis.w   #GIE, SR
            nop
            bic.w   #LOCKLPM5,&PM5CTL0

main:
            
            ;call    #i2c_write
            call    #i2c_read
            

            nop 
            jmp main
            nop

;------------------------------------------------------------------------------
;           I2C Sub routines
;------------------------------------------------------------------------------

i2c_init:          
            mov.b   #00h, &P1SEL0           ; sets to digital IO
            mov.b   #00h, &P1SEL1

            bis.b   #SDA_PIN, SDA_DIR       ; set SDA and SCL as output
            bis.b   #SCL_PIN, SCL_DIR 
            bis.b   #SDA_PIN, SDA_OUT       ; set SDA and SCL to High
            bis.b   #SCL_PIN, SCL_OUT
            ret

i2c_start:  ; Falling edge on SDA, delay, falling edge on clock for start.
            bic.b   #SDA_PIN, SDA_OUT
            delay_5us               ; Start hold time
            bic.b   #SCL_PIN, SCL_OUT
            ret

i2c_stop:   ; Set SCL to high wait, then set SDA to high. This is because SDA-high needs a delay after we set SCL-high.
            ; bis.b   #SDA_PIN, SDA_OUT           ; HMMMMMMMMMM
            bis.b   #SCL_PIN, SCL_OUT
            delay_5us               ; Stop hold time
            bis.b   #SDA_PIN, SDA_OUT
            delay_5us               ; Buffer delay is 4.7usec min. Bus free time after stop before nect start cond.
            ret

i2c_tx_ack:
            ;Hold SDA low in order to send ack
            bis.b   #SDA_PIN, SDA_DIR
            bic.b   #SCL_PIN, SCL_OUT
            nop
            bic.b   #SDA_PIN, SDA_OUT
            delay_5us
            bis.b   #SCL_PIN, SCL_OUT
            delay_5us
            bic.b   #SCL_PIN, SCL_OUT
            ret

i2c_tx_nack:
            ;Hold SDA low in order to send ack
            bic.b   #SCL_PIN, SCL_OUT
            nop
            bis.b   #SDA_PIN, SDA_OUT
            delay_5us
            bis.b   #SCL_PIN, SCL_OUT
            delay_5us
            bic.b   #SCL_PIN, SCL_OUT
            ret


i2c_rx_ack:
            ;Change SDA to an input after sending byte
            bic.b   #SDA_PIN, SDA_DIR   ; enable resistor
            bis.b   #SDA_PIN, SDA_REN   ; SDA is connected to a pullup ressitor (turns on)
            bis.b   #SDA_PIN, SDA_OUT   ; Pullup resistor
            bis.b   #SCL_PIN, SCL_OUT   ; Drive SCL high to begin clock pulse
            push    R5
            clr.w   R5
            mov.b   #SDA_PIN, R5        ; poll SDA input to see if NACK or ACK
            bic.b   #SCL_PIN, SCL_OUT   ; end clock pulse
            cmp.b   #00h, R5            ; If 0, is NACK. Sets z if not equal
            jz      ACK_NOT_REC 
            bic.b   #SDA_PIN, SDA_OUT   ; clear
            bis.b   #SDA_PIN, SDA_DIR   ; Set SDA back to output
            pop     R5
            ret

ACK_NOT_REC
            pop     R5
            call    #i2c_stop           ; If NACK, you can stop or send another start
            ret

i2c_tx_byte:

            push    R4          ; Tx byte
            push    R6          ; Counter to 8

            clr.b   R6
            mov.b   #8, R6           

shift_tx
            rlc.b   tx_byte 
            jc      set_sda     ; check if carry has been set to 1


clear_sda
            bic.b   #SDA_PIN, SDA_OUT
            jmp     set_up_delay

set_sda
            bis.b   #SDA_PIN, SDA_OUT

set_up_delay

            nop                 ; satisfy SDA setup time (min 250ns)
            bis.b   #SCL_PIN, SCL_OUT
            delay_5us
            bic.b   #SCL_PIN, SCL_OUT

            delay_5us           ; satisfy SDA hold time

            dec.w   R6
            jnz     shift_tx
            pop     R6
            pop     R4
            call    #i2c_rx_ack
            ret

i2c_rx_byte:
            push    R6          ; Counter to 8
            push    R5
            clr.b   R5
            clr.b   R6
            mov.b   #8, R6

shift_rx
            nop                 ; satisfy SDA setup time (min 250ns)
            bis.b   #SCL_PIN, SCL_OUT
            mov.b   #SDA_PIN, R5        ; poll SDA input to see what the bit is
            delay_5us
            bic.b   #SCL_PIN, SCL_OUT   ; end clock pulse
            bis.b   rx_byte, R5
            rla.b   rx_byte
            delay_5us           ; satisfy SDA hold time
            dec.w   R6
            jnz     shift_rx

            pop     R5
            pop     R6
            ;Change SDA to an output
            bis.b   #SDA_PIN, SDA_DIR 
            bic.b   #SDA_PIN, SDA_OUT       ; set SDA low 
            call    #i2c_tx_ack
            ret

i2c_sda_delay: ;(for satisfying setup and hold times)

i2c_scl_delay: ;(for setting your clock period)

i2c_send_address:

i2c_write:   ;(top-level function that would handle an entire write operation)
            call    #i2c_start
            push    R7
            clr.w   R7
            mov.b   #55h, tx_byte
            rla.b   tx_byte 
            call    #i2c_tx_byte ; transmit address

SEND_ANOTHER
            mov.b   R7, tx_byte
            call    #i2c_tx_byte
            inc.b   R7
            cmp.b   #10d, R7
            jnz     SEND_ANOTHER
            pop     R7  
            call    #i2c_stop
            ret           

i2c_read:    ;(top-level function that would handle an entire read operation)
            call    #i2c_start
            push    R7
            push    R5          ; 1/0 (R/W) bit
            clr.w   R7
            clr.w   R5

            ; Transmit a write with the address (RTC)
            ; mov.b   #55h, tx_byte
            ; rla.b   tx_byte
            ; bis.b   tx_byte, R5 
            ; call    #i2c_tx_byte ; transmit address

            ; ; call a start      (RTC)
            ; call    #i2c_start

            ; send the slave address again with R/W set to R
            mov.b   #55h, tx_byte
            rla.b   tx_byte
            mov.b   #1d, R5
            bis.b   R5, tx_byte 
            call    #i2c_tx_byte ; transmit address, tell we are reading
            call    #i2c_rx_ack
            
            ;Change SDA to an input
            bic.b   #SDA_PIN, SDA_DIR   
            bis.b   #SDA_PIN, SDA_REN   ; SDA is connected to a pullup ressitor (turns on)
            bis.b   #SDA_PIN, SDA_OUT   ; Pullup resistor
            
            mov.b   #02h, R7    ; loop variable 
READ_LOOP
            bic.b   #SDA_PIN, SDA_DIR   ;Change SDA to an input
            bis.b   #SDA_PIN, SDA_REN   ; SDA is connected to a pullup ressitor (turns on)
            bis.b   #SDA_PIN, SDA_OUT   ; Pullup resistor
            call    #i2c_rx_byte
            call    #i2c_tx_ack
            dec.b   R7
            ;jnz     READ_LOOP

            pop     R5 
            pop     R7
            ;Change SDA to an output
            bis.b   #SDA_PIN, SDA_DIR   
            call    #i2c_tx_nack
            call    #i2c_stop
            ret

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
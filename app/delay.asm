    .if !$defined(_DELAY_ASM)
_DELAY_ASM .set 1


delay_ms    .macro n_ms

            push R14
            push R15

            mov.w n_ms, R14
            call #_delay_ms

            pop R15
            pop R14

            .endm


.endif

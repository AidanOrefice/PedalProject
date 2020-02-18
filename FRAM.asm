#include p18f87k22.inc

    extern  Delay_Time
    extern  delay_ms, delay_x4us
    
;ONLY TRYING TO WRITE TO ONE         
    
;acs0    udata_acs ;permanent variables

;acs_ovr	access_ovr  ;temporary varibales

;************ FRAM PORT ASSIGNMENTS **************************************	    
	    Constant CS_FRAM1_Pin = 1	;Chip select is on C.
	    Constant CD_FRAM2_Pin = 2
	    
;************ FRAM CHIP OPCODES **************************************	    
	    Constant F_WRSR = .1	;These are the opcodes set out in pg 6, data sheet.
	    Constant F_WRITE = .2
	    Constant F_READ = .3
	    Constant F_WRDI = .4
	    Constant F_RDSR = .5
	    Constant F_WREN = .6
	    Constant F_FSTRD = .11
	    
;************ MSSP Functions  **************************************	

;   Don't need to call these, just good to know where they are.
	    
	    ;Constant SDO1 = 5	    ;PORTC
	    ;Constant SDI1 = 4	    ;PORTC	    
	    ;Constant SDCK1 = 3	    ;PORTC	
	    
	    ;Constant SDO1 = 4	    ;PORTD
	    ;Constant SDI1 = 5	    ;PORTD
	    ;Constant SDCK1 = 6	    ;PORTD

	   	    
FRAM code

 
FRAM_Init  ;Clearing all configuration registers.
    clrf    SSP1CON1
    clrf    SSP1CON2
    clrf    SSP1STAT
    clrf    SSP1BUF
    
    clrf    SSP2CON1		;control register1
    clrf    SSP2CON2		;control register2
    clrf    SSP2STAT		;status register
    clrf    SSP2BUF		;buffers
    
    movlw   .25			;Allow system to setup
    call    delay_ms
    
    bcf	    TRISC, CS_FRAM1_Pin	;Chip select pin is now an output
    bsf	    PORTC, CS_FRAM1_Pin	;deselects port
    
    bcf	    TRISC, SCK1		;clock is output
    bsf	    TRISC, SDI1		;SDI is an input
    bcf	    TRISC, SDO1		;SDO is an output 
    
    bcf	    SSP1STAT, CKE		;idle to active clock state transmission.
    bsf	    SSP1STAT, SMP
    
    ;MSSP enable; CKP=1; SPI master, clock=Fosc/64 (1MHz)- check FRAM can use these settings
    movlw   (1<<SSPEN)|(1<<CKP)|(0x02)
    movwf   SSP1CON1
    return

SPI_FRAM_Write
    ;FSR1 - Address of Write Buffer
    ;FSR2 - Get Address of which to write to.
    
    bcf	    PORTC, CS_FRAM1_Pin	;selects chip.
    ;movf    SSP1BUF, W		;Reading buffer to W- Reading to clear
    clrf    SSP1BUF		;is this the same thing????
    
    movlw   F_WREN		;write enable command
    movwf   SSP1BUF, W
    btfss   SSP1STAT, BF
    bra	    $-1
    clrf    SSP1BUF
    
    bsf	    PORTC, CS_FRAM1_Pin	;Toggling CS so we can send a new opcode.
    bcf	    PORTC, CS_FRAM1_Pin
    
    movlw   F_WRITE
    movwf   SSP1BUF
    btfss   SSP1STAT, BF
    bra	    $-1
    clrf    SSP1BUF
    
    
    
;
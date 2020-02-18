#include p18f87k22.inc

global delay_ms, delay_x4us 

    
    
delay_ms			; delay given in ms in W
	movwf	cnt_ms
	call DL2
	return
DL2	movlw	.250		; 1 ms delay
	call	delay_x4us	
	decfsz	cnt_ms
	bra	DL2
	return
    
delay_x4us			; delay given in chunks of 4 microsecond in W
	movwf	cnt_l		; now need to multiply by 16
	swapf   cnt_l,F		; swap nibbles
	movlw	0x0f	   
	andwf	cnt_l,W		; move low nibble to W
	movwf	cnt_h		; then to LCD_cnt_h
	movlw	0xf0	    
	andwf	cnt_l,F		; keep high nibble in cnt_l
	call	delay
	return    
      
delay				; delay routine	4 instruction loop == 250ns	    
	movlw 	0x00		; W=0
	call DL1
	return
DL1	decf 	cnt_l,F		; no carry when 0x00 -> 0xff
	subwfb 	cnt_h,F		; no carry when 0x00 -> 0xff
	bc 	DL1		; carry, then loop again
	return			; carry reset so return


    end
    
    
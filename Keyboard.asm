#include p18f87k22.inc

    global Keyboard_Setup, Keyboard_Read, Store_Decode
   
acs0    udata_acs   ; named variables in access ram
cnt_l   res 1   ; reserve 1 byte for variable cnt_l
cnt_h   res 1   ; reserve 1 byte for variable cnt_h
cnt_ms   res 1   ; reserve 1 byte for variable cnt_ms
Row_Read res 1
Col_Read res 1
Full_Read res 1

;Change_Store res 1
;Change_Bit res 1
 
Store_Decode res 1

Decode_Value res 1
    
Keyboard    code
    

Keyboard_Setup
    setf TRISE    ;rotuine to set PORTE to tri-state
    banksel PADCFG1    
    bsf PADCFG1, REPU, BANKED
    movlb 0x00
    clrf LATE
    movlw 0x0F
    movwf TRISE
    movlw .125
    call delay_x4us ;Delay of 0.5ms
    
   ;movwf .0
    ;movf Change_Bit
    
    return
    
Keyboard_Read
    ;originally set to read rows- unsure of column- diagram given in slides.
    call Keyboard_Setup
    movff PORTE, Row_Read
    movlw 0xF0
    movwf TRISE
    movlw .125
    call delay_x4us ;Delay of 0.5ms
    movff PORTE, Col_Read
    movlw .05
    call delay_ms
    movf Row_Read, W
    addwf Col_Read, W
    movwf Full_Read ;storing to one value
    movlw .05
    call delay_ms
    call Keyboard_Decode
    movlw .05
    call delay_ms
    
    call Keyboard_Write ; To conplete loop.
    return

Keyboard_Decode
	btfss Full_Read, 7
	call Check_1_Row
	btfss Full_Read, 6
	call Check_2_Row
	btfss Full_Read, 5
	call Check_3_Row
	btfss Full_Read, 4
	call Check_4_Row
	return

Check_1_Row
	btfss Full_Read, 3
	movlw '1'
	btfss Full_Read, 2
	movlw '4'
	btfss Full_Read, 1
	movlw '7'
	btfss Full_Read, 0
	movlw 'A'   ;Empty Button
	movwf Decode_Value
	return
	
Check_2_Row
	btfss Full_Read, 3
	movlw '2'
	btfss Full_Read, 2
	movlw '5'
	btfss Full_Read, 1
	movlw '8'
	btfss Full_Read, 0
	movlw '0'
	movwf Decode_Value
	return
	
Check_3_Row
	btfss Full_Read, 3
	movlw '3'
	btfss Full_Read, 2
	movlw '6'
	btfss Full_Read, 1
	movlw '9'
	btfss Full_Read, 0
	movlw 'B' ;Potential for distortion.
	movwf Decode_Value
	return
	
Check_4_Row
	btfss Full_Read, 3
	movlw 'F'   ;Multiplier
	btfss Full_Read, 2
	movlw 'E'   ;Multiplier
	btfss Full_Read, 1
	movlw 'D'   ;Multiplier
	btfss Full_Read, 0
	movlw 'C'   ;Send
	movwf Decode_Value
	return

Keyboard_Write ;Lost loop to write to successive DDRAM addresses
		; initialise address- send data, increment address
	movlw	.255
	cpfslt	Full_Read
	goto Keyboard_Read
	movff Decode_Value, Store_Decode
	
	;check is Store_Decode has changed
	;movff Decode_Value, Change_Store, ACCESS
	;movf Store_Decode, W
	;subwf Change_Store
	
	
	return
	
delay_ms		    ; delay given in ms in W
	movwf	cnt_ms
DL2	movlw	.250	    ; 1 ms delay
	call	delay_x4us	
	decfsz	cnt_ms
	bra	DL2
	return
    
delay_x4us		    ; delay given in chunks of 4 microsecond in W
	movwf	cnt_l   ; now need to multiply by 16
	swapf   cnt_l,F ; swap nibbles
	movlw	0x0f	   
	andwf	cnt_l,W ; move low nibble to W
	movwf	cnt_h   ; then to LCD_cnt_h
	movlw	0xf0	    
	andwf	cnt_l,F ; keep high nibble in cnt_l
	call	delay
	return    
    
    
    
delay	; delay routine	4 instruction loop == 250ns	    
	movlw 	0x00		; W=0
DL1	decf 	cnt_l,F	; no carry when 0x00 -> 0xff
	subwfb 	cnt_h,F	; no carry when 0x00 -> 0xff
	bc 	DL1		; carry, then loop again
	return			; carry reset so return


    end
    end
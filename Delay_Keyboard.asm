#include p18f87k22.inc		;Use PORTJ for the keyboard
    
    global Keyboard_Setup, Keyboard_Read, Store_Decode, Delay_Time, Keyboard_Initial
    extern LCD_Clear, LCD_High_Limit, LCD_Low_Limit
    extern LCD_Delay_Write
    extern Dec_to_Hex_Converter_Delay
    extern Converted_Delay_Time

acs0    udata_acs	; named variables in access ram
cnt_l   res 1		; reserve 1 byte for variable cnt_l
cnt_h   res 1		; reserve 1 byte for variable cnt_h
cnt_ms   res 1		; reserve 1 byte for variable cnt_ms
Row_Read res 1		; reserve 1 byte for Row value
Col_Read res 1		; reserve 1 byte for Column value
Full_Read res 1		; reserve 1 byte for the total value
 
Store_Decode res 1
Decode_Value res 1
 
Delay_Time res 4
temp_decode res 1
temp_counter res 1
 
temp_press res 1
temp_limit res 1


 
Delay_Keyboard    code
    
Keyboard_Setup
    setf    TRISE			    ;rotuine to set PORTJ to tri-state
    banksel PADCFG1    
    bsf	    PADCFG1, REPU, BANKED
    movlb   0x00			    
    clrf    LATE
    movlw   0x0F			    ; Sets J4-7 to output/J0-3 to input
    movwf   TRISE
    movlw   .125			    ; Delay time/4
    call    delay_x4us		    ; Delay of 0.5ms
    return
    
Keyboard_Initial
    movlw   0xEE		    ;initial value- helps to check if store decode has changed
    ;movwf   temp_decode
    movwf   Store_Decode
    
    movlw .4			    ;So we can write to 4byte Decide Value
    movwf temp_counter
    
    lfsr    FSR0, Delay_Time	    ;loads FSR to point to Delay_Time varibale
    return
    
Keyboard_Read			    ;originally set to read rows- unsure of column- diagram given in slides.
    call    Keyboard_Setup
    movlw   .155
    movff   PORTE, temp_press	    ;This checks whether a button has been pressed so we can proceed with rest of program.
    subwf   temp_press
    movlw   .0
    cpfsgt  temp_press
    goto    Keyboard_Read
    movff   PORTE, Row_Read	    
    movlw   0xF0
    movwf   TRISE
    movlw   .50
    call    delay_ms		    ;Delay of 0.5ms
    movff   PORTE, Col_Read
    movlw   .50
    call    delay_ms
    movf    Row_Read, W
    addwf   Col_Read, W
    movwf   Full_Read		    ;storing to one value
    movlw   .25
    
    call    delay_ms
    call    Keyboard_Decode
    movlw   .250	    ;This delay limits speed of press- ensures cant go back to top with same button press. This would get through the button press check. 
    call    delay_ms
    call    Keyboard_Write ; To complete loop.
    ;Can only get here with 4 valid inuts
    call    LCD_Delay_Write
    call    Dec_to_Hex_Converter_Delay
    
    call    Check_High_Limit
    
    call    Check_Low_Limit
    
    ;;;Check if value is greater than 2000 or less than 50
    ;output messsage telling them why its wrong- output- wait 5 seconds- clear bottom line of LCD
    ;Make them enter agin- call keyboard intiial, go to keyboard Read
    
    
    call    Wait_loop
    
    return
    
Wait_loop    
    btfss   PORTJ, 7
    return
    goto Wait_loop
    
    
    return
				;Check_1_row: Check rows of column 1
Keyboard_Decode			; subroutine to decode by column first - remember the keyboard follows anti-logic
	btfss	Full_Read, 7	; if column one is not set we skip. amd vice versa 
	call	Check_1_Row	; determine the value pressed in column one (1 4 7 A)
	btfss	Full_Read, 6
	call	Check_2_Row	; determine the value pressed in column two (2 5 8 0)
	btfss	Full_Read, 5
	call	Check_3_Row	; determine the value pressed in column three (3 6 9 B)
	btfss	Full_Read, 4
	call	Check_4_Row	; determine the value pressed in column four (F E D C)
	return

Check_1_Row
	btfss	Full_Read, 3	
	movlw	0x01		; numbers 0 to 9 inclusive will be the input values for the delay time
	btfss	Full_Read, 2
	movlw	0x04
	btfss	Full_Read, 1
	movlw	0x07
	btfss	Full_Read, 0	; A currently has no function in our system
	movlw	0xFF		   
	movwf	Decode_Value
	return
	
Check_2_Row
	btfss	Full_Read, 3
	movlw	0x02
	btfss	Full_Read, 2
	movlw	0x05
	btfss	Full_Read, 1
	movlw	0x08
	btfss	Full_Read, 0
	movlw	0x00
	movwf	Decode_Value
	return
	
Check_3_Row
	btfss	Full_Read, 3
	movlw	0x03
	btfss	Full_Read, 2
	movlw	0x06
	btfss	Full_Read, 1
	movlw	0x09
	btfss	Full_Read, 0
	movlw	0xFF		    ; B currently has no function in our system
	movwf	Decode_Value
	return
	
Check_4_Row
	btfss	Full_Read, 3
	movlw	0xFF		    ; F currently has no function in our system
	btfss	Full_Read, 2
	goto	LCD_Delay_Write		    ; E currently has no function in our system- become the enter button
	btfss	Full_Read, 1
	movlw	0xFF
	btfss	Full_Read, 0
	goto	Keyboard_Clear	    	    ; C will clear the input value - go to C subroutine to clear adresses in the LCD, i.e. clears the delay time 
	movwf	Decode_Value		    ;This is fucked.
	return

Keyboard_Write		    ;Lost loop to write to successive DDRAM addresses - initialise address- send data, increment address
	movff Store_Decode, temp_decode
	
	movlw	.255		;stops no input
	cpfslt	Full_Read
	goto	Keyboard_Read
	movlw	.255
	cpfslt	Decode_Value	;stops invalid answer
	goto	Keyboard_Read
	movff	Decode_Value, Store_Decode
	
	;movf	Store_Decode, W		;store_decode- wont ever be greater than ee. 
	;subwf	temp_decode		;thus subtraction will give 0 or higher
	;movlw	0x00			;Stops repeated answers
	;cpfsgt	temp_decode		    
	;goto	Keyboard_Read
	
	movff Store_Decode, POSTINC0
	
	dcfsnz temp_counter
	return
	goto Keyboard_Read
	
Check_High_Limit
	movff    Converted_Delay_Time, temp_limit	    ;Block to check if input is greater than 2000.
	movlw   0x07
	subwf   temp_limit
	btfsc	STATUS, N
	return
	movff	Converted_Delay_Time +1, temp_limit
	movlw	0xD0
	subwf	temp_limit
	btfsc	STATUS, N
	return
	btfsc	STATUS, Z
	return
	call	Limit_Reset
	return

Check_Low_Limit
	movff   Converted_Delay_Time, temp_limit	    ;Block to check if input is less than 50.	
	movlw   0x32
	subwf   temp_limit
	btfsc	STATUS, N
	return
	btfsc	STATUS, Z
	return
	call	LCD_Low_Limit
	call    Limit_Reset
	return

Limit_Reset
	call Keyboard_Initial
	goto Keyboard_Read
	

Keyboard_Clear
	call Keyboard_Initial
	call LCD_Clear
	goto Keyboard_Read
	
; ONLY DELAYS PAST THIS POINT 

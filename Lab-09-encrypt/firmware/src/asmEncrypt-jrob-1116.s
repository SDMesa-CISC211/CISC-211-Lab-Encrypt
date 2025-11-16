/*** asmEncrypt.s   ***/

#include <xc.h>

/* Declare the following to be in data memory */
.data  

/* create a string */
.global nameStr
.type nameStr,%gnu_unique_object
    
/*** STUDENTS: Change the next line to your name!  **/
nameStr: .asciz "Joseph Roberts"  
.align
 
/* initialize a global variable that C can access to print the nameStr */
.global nameStrPtr
.type nameStrPtr,%gnu_unique_object
nameStrPtr: .word nameStr   /* Assign the mem loc of nameStr to nameStrPtr */

/* Define the globals so that the C code can access them */
/* (in this lab we return the pointer, so strictly speaking, */
/* does not really need to be defined as global) */
/* .global cipherText */
.type cipherText,%gnu_unique_object

.align
 
@ NOTE: THIS .equ MUST MATCH THE #DEFINE IN main.c !!!!!
@ TODO: create a .h file that handles both C and assembly syntax for this definition
.equ CIPHER_TEXT_LEN, 200
 
/* space allocated for cipherText: 200 bytes, prefilled with 0x2A */
cipherText: .space CIPHER_TEXT_LEN,0x2A  

.align
 
.global cipherTextPtr
.type cipherTextPtr,%gnu_unique_object
cipherTextPtr: .word cipherText

/* Tell the assembler that what follows is in instruction memory     */
.text
.align

/* Tell the assembler to allow both 16b and 32b extended Thumb instructions */
.syntax unified

    
/********************************************************************
function name: asmEncrypt
function description:
     pointerToCipherText = asmEncrypt ( ptrToInputText , key )
     
where:
     input:
     ptrToInputText: location of first character in null-terminated
                     input string. Per calling convention, passed in via r0.
     key:            shift value (K). Range 0-25. Passed in via r1.
     
     output:
     pointerToCipherText: mem location (address) of first character of
                          encrypted text. Returned in r0
     
     function description: asmEncrypt reads each character of an input
                           string, uses a shifted alphabet to encrypt it,
                           and stores the new character value in memory
                           location beginning at "cipherText". After copying
                           a character to cipherText, a pointer is incremented 
                           so that the next letter is stored in the bext byte.
                           Only encrypt characters in the range [a-zA-Z].
                           Any other characters should just be copied as-is
                           without modifications
                           Stop processing the input string when a NULL (0)
                           byte is reached. Make sure to add the NULL at the
                           end of the cipherText string.
     
     notes:
        The return value will always be the mem location defined by
        the label "cipherText".
     
     
********************************************************************/    
.global asmEncrypt
.type asmEncrypt,%function
asmEncrypt:   

    /* save the caller's registers, as required by the ARM calling convention */
    push {r4-r11,LR}
    
    /* YOUR asmEncrypt CODE BELOW THIS LINE! VVVVVVVVVVVVVVVVVVVVV  */

    push {r4-r7, lr}

    /* Load the address of the cipherText buffer into r2 (destination pointer) */
    ldr r2, =cipherText

    /* Copy input text pointer (r0) to r3 so we can auto-index it */
    mov r3, r0

    /* Move the key K from r1 into r4 (we will normalize it) */
    mov r4, r1

    /* ============================== */
    /* Normalize the key into 0..25   */
    /* Handles positive and negative  */
    /* ============================== */
normalize_key:
    cmp r4, 0                   /* Is K >= 0? */
    bge .norm_positive          /* If yes, handle positive case */

.norm_add_loop:
    add r4, r4, 26              /* If K < 0, add 26 until it becomes >= 0 */
    cmp r4, 0
    blt .norm_add_loop
    b .norm_done                /* Finished adjusting negative key */

.norm_positive:
    cmp r4, 26                  /* If K < 26, it is already normalized */
    blt .norm_done
.norm_sub_loop:
    sub r4, r4, 26              /* If K >= 26, subtract 26 until in range */
    cmp r4, 26
    bge .norm_sub_loop

.norm_done:

    /* ========================================== */
    /* Main loop ? load characters and encrypt     */
    /* ========================================== */
main_loop:
    ldrb r5, [r3], 1            /* Load next input byte, auto-index pointer */
    cmp r5, 0                   /* Check if null terminator */
    beq write_null_and_return   /* If 0, copy it and finish */

    /* ------------------------------ */
    /* Check for uppercase A..Z       */
    /* ------------------------------ */
    cmp r5, 'A'                 /* If < 'A', not uppercase */
    blt check_lower
    cmp r5, 'Z'                 /* If > 'Z', not uppercase */
    bgt check_lower

    /* Uppercase encryption: convert to 0?25, add key, wrap around */
    sub r6, r5, 'A'             /* Convert ASCII to range 0..25 */
    add r6, r6, r4              /* Add K */
    cmp r6, 26                  /* Check if it wrapped */
    blt upper_done
    sub r6, r6, 26              /* Wrap around */

upper_done:
    add r5, r6, 'A'             /* Convert back to ASCII A..Z */
    b write_char                /* Store and continue */

    /* ------------------------------ */
    /* Check for lowercase a..z       */
    /* ------------------------------ */
check_lower:
    cmp r5, 'a'                 /* If < 'a', not lowercase */
    blt write_char
    cmp r5, 'z'                 /* If > 'z', not lowercase */
    bgt write_char

    /* Lowercase encryption: convert to 0?25, add key, wrap around */
    sub r6, r5, 'a'             /* Convert ASCII to 0..25 */
    add r6, r6, r4              /* Add K */
    cmp r6, 26                  /* Check if wrapped */
    blt lower_done
    sub r6, r6, 26              /* Wrap around */

lower_done:
    add r5, r6, 'a'             /* Convert back to ASCII a..z */

    /* ============================= */
    /* Write output byte and repeat  */
    /* ============================= */
write_char:
    strb r5, [r2], 1            /* Store encrypted byte, auto-index pointer */
    b main_loop                 /* Continue loop */

    /* ============================= */
    /* Write null terminator, return */
    /* ============================= */
write_null_and_return:
    strb r5, [r2], 1            /* Write terminating 0 */
    ldr r0, =cipherText         /* r0 must hold pointer to output buffer */
    pop {r4-r7, pc}             /* Restore registers and return */

    .size asmEncrypt, .-asmEncrypt

    /* YOUR asmEncrypt CODE ABOVE THIS LINE! ^^^^^^^^^^^^^^^^^^^^^  */

    /* restore the caller's registers, as required by the ARM calling convention */
    pop {r4-r11,LR}

    mov pc, lr	 /* asmEncrypt return to caller */
   

/**********************************************************************/   
.end  /* The assembler will not process anything after this directive!!! */
           





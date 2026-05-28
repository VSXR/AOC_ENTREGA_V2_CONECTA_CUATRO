; ============================================================================================
; ARCHIVO: utils.asm
; USO: Funciones auxiliares y extendidas (decoraciones, pausas, efectos).
; ============================================================================================

; ==========================================================================
; FUNCIÓN: UTIL_PintarNfichasAlternandoColores
; Pinta N fichas consecutivas CON ESPACIO, alternando entre roja y amarilla.
;
; ENTRADAS:
;   H = Fila inicial (Y)
;   L = Columna inicial (X)
;   B = Número de fichas a pintar
; ==========================================================================
UTIL_PintarNfichasAlternandoColores:
    PUSH HL: PUSH BC: PUSH DE: PUSH AF  ; Preservar todos los registros

    ; --- Cargar colores desde memoria ---
    LD A, (COLOR_CUADRADO_ROJO)
    LD D, A                            ; Guarda color rojo en D
    LD A, (COLOR_CUADRADO_AMARILLO)
    LD E, A                            ; Guarda color amarillo en E
    LD A, E                            ; Empezar con el color Amarillo (E)

UTIL_PintarNfichasAlternandoColores_Loop:
    ; Pinta la ficha de 16x16 con el color actual en A
    CALL FICHAS_PintarFicha16          

    ; --- Alternar color ---
    CP D                                ; ¿El color actual (A) es Rojo (D)?
    JR Z, .SET_YELLOW                   ; Si sí, saltar para poner Amarillo
    LD A, D                             ; Si no, poner Rojo
    JR .COLOR_LISTO

.SET_YELLOW:
    LD A, E                             ; Poner Amarillo

.COLOR_LISTO:
    ; Avanza 3 posiciones (L+3).
    ; (La ficha mide 2 (L, L+1). L+2 sería pegado. L+3 deja un carácter de espacio).
    INC L: INC L: INC L
    
    DJNZ UTIL_PintarNfichasAlternandoColores_Loop ; Decrementa B y repite si no es 0

    POP AF: POP DE: POP BC: POP HL      ; Restaurar registros
    RET

; ==========================================================================
; FUNCIÓN: UTIL_VISUAL_ERROR_FULL_COLUMN
; Realiza un efecto visual de error (borde rojo parpadeante) 
; parpadeando 2 veces lentamente que indica que la columna está llena.
; ==========================================================================
UTIL_VISUAL_ERROR_FULL_COLUMN:
    PUSH AF: PUSH BC: PUSH DE
    LD D, 2     ;Contador para parpadear 2 veces

.BLINK_LOOP:
    ; --- 1. Poner Borde ROJO ---
    LD A, 2                     ; Color Rojo
    OUT ($FE), A                ; Cambiar borde
    
    ; --- 2. Pausa Larga (Encendido) ---
    LD BC, 25000                ; Retardo para pausa larga del parpadeo
    CALL UTIL_Pausar

    ; --- 3. Restaurar Borde (BLANCO) ---
    LD A, 7                     ; Color Blanco
    OUT ($FE), A                ; Restaurar borde

    ; --- 4. Pausa Larga (Apagado) ---
    ; OJO: Aqui es importante pausar también para que se note el "apagado" antes 
    ; del siguiente parpadeo!
    LD BC, 25000                ; Mismo retardo
    CALL UTIL_Pausar

    ; --- 5. Control del Bucle ---
    DEC D                       ; Restamos 1 al contador (D)
    JR NZ, .BLINK_LOOP          ; Si D no es 0, saltamos al inicio para parpadear otra vez

    POP DE: POP BC: POP AF
    RET

; ==========================================================================
; FUNCIÓN: UTIL_Pausar
; Realiza una pausa (delay) simple. Es un "bucle loco" (busy-loop).
;
; ENTRADAS:
;   BC = Duración de la pausa (16 bits). Un valor más alto tarda más.
;        (Ej: 60000 para una pausa larga).
; ==========================================================================
UTIL_Pausar:
    PUSH BC                     ; Preservar BC (aunque sea el contador)
.Pause_Loop:
    DEC BC                      ; Decrementa el contador de 16 bits
    LD A, B                     ; Cargar byte alto
    OR C                        ; Comprobar si el byte bajo también es 0
    JR NZ, .Pause_Loop          ; Si BC no es 0, seguir en el bucle
    POP BC                      ; Restaurar BC
    RET
; ============================================================================================
; ARCHIVO: keyboard.asm
; USO: Rutinas de hardware y bucle principal de entrada (teclado) del juego.
;
; NOTA TÉCNICA: El ZX Spectrum usa LÓGICA NEGATIVA para el teclado:
;               BIT 0 = Tecla pulsada
;               BIT 1 = Tecla NO pulsada
; ============================================================================================

; ============================================================================================
; 1. UTILIDADES DE HARDWARE
; ============================================================================================
; --------------------------------------------------------------------------------------------
; COLOR_BORDE_PANTALLA
; Pone el borde de la pantalla en blanco (7). Útil para depuración.
; --------------------------------------------------------------------------------------------
COLOR_BORDE_PANTALLA:
    LD A, 7             ; 7 = Color Blanco
    OUT (254), A        ; Puerto 0xFE para el borde de la pantalla
    RET

; --------------------------------------------------------------------------------------------
; KEYBOARD_WAIT_RELEASE
; Espera (en un bucle) hasta que el usuario suelte la tecla que está pulsando.
; Esto evita la auto-repetición en menús (efecto "debounce" o "falsas pulsaciones de teclas").
; ENTRADA: BC = Puerto de la fila de teclado a comprobar (ej: $FDFE)
; --------------------------------------------------------------------------------------------
KEYBOARD_WAIT_RELEASE:
    IN A, (C)                       ; Lee el puerto de la fila de teclado
    AND $1F                         ; Enmascara los 5 bits de teclas con el fin de ignorar los bits no usados de esa fila (Solo mantienen los bits que sean '1' en ambos números, eliminan los bits irrelevantes a 0 (bits 5, 6, 7) y deja los relevantes a 1)
    CP $1F                          ; Compara con %00011111 (estado "todo suelto")
    JR NZ, KEYBOARD_WAIT_RELEASE    ; Si A no es $1F, alguna tecla sigue pulsada (0). Repetir.
    RET

; ============================================================================================
; 2. LECTURA BLOQUEANTE (PARA MENÚS)
; ============================================================================================
; --------------------------------------------------------------------------------------------
; KEYBOARD_LEER_SN
; Detiene la ejecución del programa hasta que el usuario pulsa 'S' o 'N'.
; Usa KEYBOARD_WAIT_RELEASE para asegurar una sola pulsación.
; SALIDA: A = 'S' o 'N' (carácter ASCII)
; --------------------------------------------------------------------------------------------
KEYBOARD_LEER_SN:
    PUSH BC             ; Preservamos BC

.CHECK_S:
    LD BC, $FDFE        ; Puerto/Fila para teclas A,S,D,F,G (Bit 1 = 'S')
    IN A, (C)
    BIT 1, A            ; Comprueba el bit 1 ('S')
    JR Z, .S_PRESSED    ; Si el bit es 0, la tecla está pulsada

.CHECK_N:
    LD BC, $7FFE        ; Puerto/Fila para teclas V,B,N,M,Symbol (Bit 3 = 'N')
    IN A, (C)
    BIT 3, A            ; Comprueba el bit 3 ('N')
    JR NZ, .CHECK_S     ; Si el bit es 1 (no pulsada), volver a comprobar 'S'

.N_PRESSED:
    CALL KEYBOARD_WAIT_RELEASE  ; Espera a que el usuario suelte 'N'
    LD A, 'N'
    POP BC                      ; Restauramos BC
    RET

.S_PRESSED:
    CALL KEYBOARD_WAIT_RELEASE  ; Espera a que el usuario suelte 'S'
    LD A, 'S'
    POP BC
    RET

; ============================================================================================
; 3. LECTURA NO BLOQUEANTE (POLLING PARA EL JUEGO)
; ============================================================================================
; Estas rutinas comprueban el estado de una tecla y retornan inmediatamente.
; Son esenciales para el bucle de juego, ya que no detienen el programa.

; --------------------------------------------------------------------------------------------
; KEYBOARD_POLL_PLAYER_MOVE
; Comprueba las teclas de movimiento basándose en el jugador actual.
;
; JUGADOR 1: Puerto $FBFE -> Q (Bit 0, Izquierda), W (Bit 1, Derecha)
; JUGADOR 2: Puerto $DFFE -> O (Bit 1, Izquierda), P (Bit 0, Derecha)
;
; NOTA: Se ha corregido el puerto de J2 a $DFFE. Antes estaba en $BFFE, 
;       lo que causaba conflicto con la tecla ENTER.
;
; SALIDA: A = 'Q' (si se debe mover a la izquierda), 
;             'W' (si se debe mover a la derecha),
;              0  (si no se pulsó nada)
; REGISTROS USADOS: AF, BC
; --------------------------------------------------------------------------------------------
KEYBOARD_POLL_PLAYER_MOVE:
    LD A, (GUARDAR_JUGADOR_ACTUAL)
    CP PLAYER_1
    JR Z, .CHECK_P1_KEYS

.CHECK_P2_KEYS:
    ; --- El jugador 2 está activo: Usamos Puerto P, O, I, U, Y ($DFFE) ---
    LD BC, $DFFE        
    IN A, (C)
    BIT 1, A            ; Tecla 'O' (Bit 1) -> Mover Izquierda J2
    JR Z, .RET_Q        ; Reutilizamos retorno 'Q' como señal de "Izquierda"
    BIT 0, A            ; Tecla 'P' (Bit 0) -> Mover Derecha J2
    JR Z, .RET_W        ; Reutilizamos retorno 'W' como señal de "Derecha"
    JR .RET_NONE        ; Ninguna tecla pulsada

.CHECK_P1_KEYS:
    ; --- El jugador 1 está activo: Usamos Puerto Q, W, E, R, T ($FBFE) ---
    LD BC, $FBFE        
    IN A, (C)
    BIT 0, A            ; Tecla 'Q' (Bit 0) -> Mover Izquierda J1
    JR Z, .RET_Q
    BIT 1, A            ; Tecla 'W' (Bit 1) -> Mover Derecha J1
    JR Z, .RET_W
    
.RET_NONE:
    XOR A               ; A = 0 (Ninguna tecla de movimiento pulsada)
    RET
.RET_Q:
    LD A, 'Q'           ; Retorna 'Q' para "Mover Izquierda" (Abstracto)
    RET
.RET_W:
    LD A, 'W'           ; Retorna 'W' para "Mover Derecha" (Abstracto)
    RET

; --------------------------------------------------------------------------------------------
; KEYBOARD_POLL_ENTER
; Comprueba si 'ENTER' está pulsada AHORA MISMO.
; SALIDA: A = 13 (ASCII Enter) o 0
; REGISTROS USADOS: AF, BC
; --------------------------------------------------------------------------------------------
KEYBOARD_POLL_ENTER:
    LD BC, $BFFE        ; Puerto/Fila para P,O,I,U,Y,ENTER (Bit 0='ENTER')
    IN A, (C)
    BIT 0, A
    JR NZ, .NO_ENTER
    LD A, 13
    RET
.NO_ENTER:
    XOR A
    RET

; --------------------------------------------------------------------------------------------
; KEYBOARD_POLL_F
; Comprueba si 'F' está pulsada AHORA MISMO.
; SALIDA: A = 'F' (ASCII) o 0
; REGISTROS USADOS: AF, BC
; --------------------------------------------------------------------------------------------
KEYBOARD_POLL_F:
    LD BC, $FDFE        ; Puerto/Fila para A,S,D,F,G (Bit 3='F')
    IN A, (C)
    BIT 3, A
    JR NZ, .NO_F
    LD A, 'F'
    RET
.NO_F:
    XOR A
    RET

; =========================================================================================================================
; 4. BUCLE PRINCIPAL DE ENTRADA (GAME INPUT LOOP)
; =========================================================================================================================
; Este es el corazón del juego. Se ejecuta continuamente sin HALT (llamado en este caso, "busy-loop" o "bucle loco").
; Gestiona el temporizador de 16 bits y la lógica de redibujado la ficha del jugador al moverse.

KEYBOARD_ActivarInput_Keys:
    CALL INPUT_Inicializar_Teclado      ; Prepara la primera ficha del jugador
    LD A, (CURRENT_COLUMN)
    LD (PREVIOUS_COLUMN), A             ; Sincroniza la columna previa
    
    ; Inicializar el temporizador de 16 bits (MOVE_COOLDOWN_TIMER) a 0
    LD HL, MOVE_COOLDOWN_TIMER
    XOR A
    LD (HL), A                          ; Escribe 0 en el byte bajo con el fin de permitir movimiento inmediato
    INC HL
    LD (HL), A                          ; Escribe 0 en el byte alto, con el mismo fin

.LOOP:
    ; Este bucle se ejecuta a la máxima velocidad del Z80, ya que no podemos deshabilitar las interrupciones DI 
    ; para la practica. Por lo tanto, el temporizador de 16 bits se decrementa en cada iteración del bucle.

    ; --- 1. GESTIÓN DEL TEMPORIZADOR DE COOLDOWN (16 bits) ---
    ; Carga el valor actual del temporizador (16 bits) en BC
    LD HL, MOVE_COOLDOWN_TIMER
    LD C, (HL)
    INC HL
    LD B, (HL)

    ; Comprueba si el temporizador (BC) es 0
    LD A, B
    OR C                        ; A = B | C. Si A es 0, BC es 0.
    JR Z, .SKIP_COOLDOWN_DEC    ; Si es 0, no hay nada que decrementar

    DEC BC                      ; Si no es 0, lo decrementa
    
    ; Guarda el nuevo valor (BC-1) en memoria
    LD HL, MOVE_COOLDOWN_TIMER
    LD (HL), C
    INC HL
    LD (HL), B
.SKIP_COOLDOWN_DEC:
    ; --- FIN DEL MANEJO DE COOLDOWN ---
    
    ; --- 2. SONDEO DE TECLAS (POLLING) ---
    ; Llama a la rutina de sondeo de movimiento.
    ; Esta rutina devuelve 'Q' (izquierda) o 'W' (derecha) según el jugador activo.
    CALL KEYBOARD_POLL_PLAYER_MOVE

    CP 'Q'
    JR Z, .HANDLE_Q_CONTINUOUS
    CP 'W'
    JR Z, .HANDLE_W_CONTINUOUS

    CALL KEYBOARD_POLL_ENTER
    CP 13
    JP Z, .HANDLE_ENTER_PRESS

    CALL KEYBOARD_POLL_F
    CP 'F'
    JP Z, .HANDLE_F_PRESS

    JR .LOOP                    ; Si no se pulsó nada, repetir el bucle

; --------------------------------------------------------------------------------------------
; MANEJADORES DE MOVIMIENTO (Q y W)
; --------------------------------------------------------------------------------------------
.HANDLE_Q_CONTINUOUS:
    ; Es VITAL recargar el temporizador desde la memoria, ya que la
    ; llamada a KEYBOARD_POLL_PLAYER_MOVE sobrescribe el registro BC.
    LD HL, MOVE_COOLDOWN_TIMER
    LD C, (HL)
    INC HL
    LD B, (HL)

    ; Comprobar si el temporizador (BC) ha llegado a 0
    LD A, B
    OR C
    JR NZ, .CHECK_REDRAW            ; Si no es 0 (timer activo), no mover. Saltar a redibujar.

    ; Si el temporizador es 0, SE PERMITE EL MOVIMIENTO
    LD A, (CURRENT_COLUMN)
    OR A                            ; ¿Estamos en la columna 0 (borde izq)?
    JR Z, .CHECK_REDRAW             ; Si sí, no mover.
    DEC A                           ; Mover a la izquierda
    LD (CURRENT_COLUMN), A
    
    ; Reiniciar el temporizador al valor de MOVE_DELAY_FRAMES
    LD BC, MOVE_DELAY_FRAMES
    LD HL, MOVE_COOLDOWN_TIMER
    LD (HL), C
    INC HL
    LD (HL), B
    
    JR .CHECK_REDRAW                ; Saltar a redibujar (ahora que la columna ha cambiado)

.HANDLE_W_CONTINUOUS:
    ; Recargamos el temporizador (BC fue destruido por KEYBOARD_POLL_PLAYER_MOVE)
    LD HL, MOVE_COOLDOWN_TIMER
    LD C, (HL)
    INC HL
    LD B, (HL)

    ; Comprobar si el temporizador (BC) ha llegado a 0
    LD A, B
    OR C
    JR NZ, .CHECK_REDRAW            ; Si no es 0 (timer activo), no mover.

    ; Si el temporizador es 0, SE PERMITE EL MOVIMIENTO
    LD A, (CURRENT_COLUMN)
    CP 6                            ; ¿Estamos en la columna 6 (borde der)?
    JR Z, .CHECK_REDRAW             ; Si sí, no mover.
    INC A                           ; Mover a la derecha
    LD (CURRENT_COLUMN), A
    
    ; Reiniciar el temporizador
    LD BC, MOVE_DELAY_FRAMES
    LD HL, MOVE_COOLDOWN_TIMER
    LD (HL), C
    INC HL
    LD (HL), B

    JR .CHECK_REDRAW                ; Saltar a redibujar

; --------------------------------------------------------------------------------------------
; RUTINA DE REDIBUJADO
; Compara la columna actual con la anterior para evitar redibujar si no hay cambios.
; Esta es la optimización clave para PREVENIR EL PARPADEO.
; --------------------------------------------------------------------------------------------
.CHECK_REDRAW:
    LD A, (CURRENT_COLUMN)          ; A = Columna Nueva
    LD B, A                         ; B = Columna Nueva
    LD A, (PREVIOUS_COLUMN)         ; A = Columna Antigua
    CP B                            ; ¿Es Columna Antigua == Columna Nueva?
    JR Z, .LOOP                     ; Si son iguales, no ha habido movimiento. Volver al bucle sin redibujar.
    
    ; Si son diferentes, el jugador movió la ficha, por lo que hay que redibujarla en su nueva posición:
    ; 1. Borrar la ficha de la posición ANTIGUA
    LD A, (PREVIOUS_COLUMN)         ; Cargar A (antigua) en la variable global para que ERASE_PREVIEW sepa qué borrar
    LD (CURRENT_COLUMN), A
    CALL ERASE_PREVIEW
    
    ; 2. Dibujar la ficha en la posición NUEVA
    LD A, B                         ; Recuperamos la Columna Nueva
    LD (CURRENT_COLUMN), A          ; La ponemos en la variable global
    CALL DIBUJAR_FICHA_JUGADOR

    ; 3. Actualizar la posición antigua para el próximo fotograma
    LD (PREVIOUS_COLUMN), A         ; PREVIOUS_COLUMN = CURRENT_COLUMN
    JP .LOOP

; --------------------------------------------------------------------------------------------
; MANEJADORES DE ACCIÓN (ENTER y F)
; Estas acciones deben ocurrir UNA SOLA VEZ por pulsación.
; --------------------------------------------------------------------------------------------
.HANDLE_ENTER_PRESS:
    LD BC, $BFFE                    ; Recargar puerto de ENTER
    CALL KEYBOARD_WAIT_RELEASE      ; Esperar a que el usuario SUELTE la tecla
    CALL ERASE_PREVIEW              ; Borrar la ficha flotante
    CALL COLOCAR_FICHA_EN_TABLERO   ; Lógica principal (dejar caer, comprobar victoria, etc.)
    
    ; Si el juego no ha terminado, COLOCAR_FICHA retornará aquí
    CALL DIBUJAR_FICHA_JUGADOR      ; Dibuja la ficha flotante del siguiente turno
    LD A, (CURRENT_COLUMN)          ; Resincroniza la columna previa
    LD (PREVIOUS_COLUMN), A
    JP .LOOP

.HANDLE_F_PRESS:
    LD BC, $FDFE                    ; Recargar puerto de F
    CALL KEYBOARD_WAIT_RELEASE      ; Esperar a que suelte F
    CALL GAME_End                   ; Salta a la pantalla de fin de juego
    RET
; ============================================================================================
; ARCHIVO: logic.asm
; USO: Lógica de comprobación de victoria para Conecta 4.
;
;      OJO: Se llama desde 'input.asm' después de cada turno!
; ============================================================================================

; ============================================================================================
; RUTINA PRINCIPAL: CHECK_WIN
; ============================================================================================
; USO:
;   Comprueba si la última jugada (almacenada en LAST_ROW, LAST_COL)
;   ha resultado en una victoria para el jugador actual (GUARDAR_JUGADOR_ACTUAL).
;
; ENTRADA:
;   (Implícita) (LAST_ROW), (LAST_COL) -> Coordenadas de la última ficha.
;   (Implícita) (GUARDAR_JUGADOR_ACTUAL) -> Jugador que acaba de mover.
;
; SALIDA:
;   Carry Flag (C) = 1 (SCF) SI HAY VICTORIA
;   Carry Flag (C) = 0 (OR A) SI NO HAY VICTORIA
; --------------------------------------------------------------------------------------------
CHECK_WIN:
    PUSH BC: PUSH DE: PUSH HL  ; Preservar registros

    ; 1. Comprobar HORIZONTAL
    ;    (Fila fija, Columna se mueve +/- 1)
    LD D, 0                     ; Delta Fila = 0
    LD E, 1                     ; Delta Columna = 1
    CALL CHECK_LINE
    JR C, .WIN_FOUND            ; Si Carry=1, saltar al final

    ; 2. Comprobar VERTICAL
    ;    (Fila se mueve +/- 1, Columna fija)
    LD D, 1                     ; Delta Fila = 1
    LD E, 0                     ; Delta Columna = 0
    CALL CHECK_LINE
    JR C, .WIN_FOUND

    ; 3. Comprobar DIAGONAL \
    ;    (Fila se mueve +/- 1, Columna se mueve +/- 1)
    LD D, 1                     ; Delta Fila = 1
    LD E, 1                     ; Delta Columna = 1
    CALL CHECK_LINE
    JR C, .WIN_FOUND

    ; 4. Comprobar DIAGONAL /
    ;    (Fila se mueve +/- 1, Columna se mueve -/+ 1)
    LD D, 1                     ; Delta Fila = 1
    LD E, -1                    ; Delta Columna = -1 (255 en complemento a 2)
    CALL CHECK_LINE
    JR C, .WIN_FOUND

    ; --- Sin victoria ---
    ; Si llegamos aquí, ninguna comprobación activó el Carry
    OR A                        ; Limpia el Carry Flag (CF=0) para indicar "No Victoria"
    POP HL: POP DE: POP BC
    RET

.WIN_FOUND:
    ; --- Victoria encontrada ---
    SCF                         ; Fija el Carry Flag (CF=1) para indicar "Victoria"
    POP HL: POP DE: POP BC
    RET

; ============================================================================================
; RUTINA AUXILIAR: CHECK_LINE
; ============================================================================================
; USO:
;   Comprueba una línea completa (en ambas direcciones) usando un vector (D,E).
;   Suma las fichas encontradas en la dirección (D,E) y la opuesta (-D,-E).
;
; ENTRADA:
;   D = Delta Fila
;   E = Delta Columna
;
; SALIDA:
;   Carry Flag = 1 si la suma total (dir_1 + dir_2 + ficha_central) >= 4
;   Carry Flag = 0 si no
; --------------------------------------------------------------------------------------------
CHECK_LINE:
    PUSH DE                     ; Guardamos los deltas originales (D, E)

    ; 1. Contar en la primera dirección (D, E)
    CALL COUNT_CONSECUTIVE
    LD B, A                     ; B = Número de fichas encontradas en la primera dirección

    ; 2. Invertir la dirección para comprobar el lado opuesto
    POP DE                      ; Recuperamos los deltas originales (D, E)
    LD A, D
    NEG                         ; A = -D (Invierte el delta de fila)
    LD D, A
    LD A, E
    NEG                         ; A = -E (Invierte el delta de columna)
    LD E, A
    
    ; 3. Contar en la dirección opuesta (-D, -E)
    PUSH BC                     ; Guardamos la primera cuenta (B)
    CALL COUNT_CONSECUTIVE
    POP BC                      ; Recuperamos la primera cuenta (B)

    ; 4. Sumar resultados
    ADD A, B                    ; A = (Cuenta Dir 1) + (Cuenta Dir 2)
    INC A                       ; Sumar 1 (la ficha central que acabamos de poner)
    
    ; 5. Comprobar si hay 4 o más en raya
    CP 4                        ; ¿Es el total (A) >= 4?
    JR NC, .LINE_WIN            ; Si A >= 4 (No Carry), es victoria
    
    OR A                        ; No hay victoria en esta línea, CF = 0
    RET
.LINE_WIN:
    SCF                         ; ¡Victoria en esta línea! CF = 1
    RET

; ============================================================================================
; RUTINA AUXILIAR: COUNT_CONSECUTIVE
; ============================================================================================
; USO:
;   "Camina" desde (LAST_ROW, LAST_COL) en una dirección (D,E) y cuenta
;   cuántas fichas consecutivas pertenecen al jugador actual.
;
; ENTRADA:
;   D = Delta Fila
;   E = Delta Columna
;   (Implícita) (LAST_ROW), (LAST_COL), (GUARDAR_JUGADOR_ACTUAL)
;
; SALIDA:
;   A = Número de fichas idénticas consecutivas (sin contar la inicial)
; --------------------------------------------------------------------------------------------
COUNT_CONSECUTIVE:
    PUSH BC: PUSH DE: PUSH HL
    LD B, 0                     ; B = Contador de aciertos (empieza en 0)

    ; Cargar posición inicial de la ficha que acabamos de poner
    LD A, (LAST_ROW)
    LD H, A                     ; H = Fila actual
    LD A, (LAST_COL)
    LD L, A                     ; L = Columna actual

.LOOP_COUNT:
    ; --- 1. Mover a la siguiente celda ---
    LD A, H
    ADD A, D                    ; H = H + Delta Fila
    LD H, A
    LD A, L
    ADD A, E                    ; L = L + Delta Columna
    LD L, A

    ; --- 2. VALIDAR LÍMITES DEL TABLERO ---
    ; Verificar Fila (H debe estar entre 0 y 5)
    LD A, H
    CP 6                        ; Compara H con 6
    JR NC, .END_COUNT           ; Si H >= 6 (o < 0, que es >127), está fuera de rango.

    ; Verificar Columna (L debe estar entre 0 y 6)
    LD A, L
    CP 7                        ; Compara L con 7
    JR NC, .END_COUNT           ; Si L >= 7 (o < 0), está fuera de rango.

    ; --- 3. LEER VALOR EN TABLERO (BOARD_ARRAY) ---
    ; La celda (H, L) es válida, ahora calculamos su índice en el array 1D
    ; Índice = (H * 7) + L
    PUSH HL: PUSH DE            ; Guardar H,L (coords) y D,E (deltas)
    
    LD A, H                     ; A = H (Fila)
    ADD A, A                    ; A = H * 2
    ADD A, A                    ; A = H * 4
    LD D, A                     ; D = H * 4
    
    LD A, H                     ; A = H
    ADD A, A                    ; A = H * 2
    ADD A, H                    ; A = H * 3
    
    ADD A, D                    ; A = (H * 3) + (H * 4) = H * 7
    ADD A, L                    ; A = (H * 7) + L (Índice final)
    
    LD E, A                     ; E = Índice
    LD D, 0                     ; DE = Índice (16 bits)
    LD HL, BOARD_ARRAY
    ADD HL, DE                  ; HL = Dirección de la celda (BOARD_ARRAY + Índice)
    LD A, (HL)                  ; A = Valor de la celda (0=Vacío, 1=P1, 2=P2)
    
    POP DE: POP HL              ; Recuperar H,L y D,E

    ; --- 4. COMPARAR CON JUGADOR ACTUAL ---
    LD C, A                     ; Guardamos el valor de la celda en C
    LD A, (GUARDAR_JUGADOR_ACTUAL)
    CP C                        ; ¿Es la celda (C) igual a nuestro jugador (A)?
    JR NZ, .END_COUNT           ; Si no coincide (es 0 o del otro jugador), parar de contar

    ; --- 5. COINCIDENCIA ---
    INC B                       ; Coincide! --> Incrementamos contador de aciertos
    JR .LOOP_COUNT              ; Volver al bucle para comprobar la siguiente celda

.END_COUNT:
    LD A, B                     ; Cargar el total de aciertos (B) en A para el retorno
    POP HL: POP DE: POP BC
    RET
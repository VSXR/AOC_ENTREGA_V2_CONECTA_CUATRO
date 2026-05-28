; ==========================================================================================
; ARCHIVO: portada.asm
; USO: Dibuja el gráfico de la pantalla de bienvenida (StartScreen).
;      Dibuja un "C" rojo y un "4" amarillo usando las
;      mismas rutinas de fichas (16x16) que se usan en el juego.
; ==========================================================================================

PORTADA_DibujarPortada:
    PUSH AF: PUSH BC: PUSH HL        ; Preservar registros

    ; === PASO 1: Dibujar la 'C' con fichas rojas ===
    LD A, (COLOR_CUADRADO_ROJO)     ; Cargar el color Rojo
    PUSH AF                         ; Guardar el color en la pila para las llamadas

    ; --- Parte superior de la 'C' --- (Fila H=6)
    LD H, 6: LD L, 6                ; (X)
    CALL FICHAS_PintarFicha16
    LD L, 8                         ; (X)
    CALL FICHAS_PintarFicha16
    LD L, 10                        ; (X)
    CALL FICHAS_PintarFicha16

    ; --- Parte izquierda de la 'C' (vertical) ---
    LD H, 8: LD L, 6                ; (X)
    CALL FICHAS_PintarFicha16
    LD H, 10: LD L, 6               ; (X)
    CALL FICHAS_PintarFicha16
    LD H, 12: LD L, 6               ; (X)
    CALL FICHAS_PintarFicha16

    ; --- Parte inferior de la 'C' --- (Fila H=14)
    LD H, 14: LD L, 6               ; (X)
    CALL FICHAS_PintarFicha16
    LD L, 8                         ; (X)
    CALL FICHAS_PintarFicha16
    LD L, 10                        ; (X)
    CALL FICHAS_PintarFicha16

    POP AF                          ; Limpiar el color Rojo de la pila

    ; === PASO 2: Dibujar el '4' con fichas amarillas ===
    LD A, (COLOR_CUADRADO_AMARILLO) ; Cargar el color Amarillo
    PUSH AF                         ; Guardar el color en la pila

    ; --- Palo vertical izquierdo del '4' ---
    LD H, 6: LD L, 18               ; (X)
    CALL FICHAS_PintarFicha16
    LD H, 8: LD L, 18               ; (X)
    CALL FICHAS_PintarFicha16
    LD H, 10: LD L, 18              ; (X)
    CALL FICHAS_PintarFicha16

    ; --- Línea horizontal del '4' --- (Fila H=10)
    LD H, 10: LD L, 20              ; (X)
    CALL FICHAS_PintarFicha16
    LD L, 22                        ; (X)
    CALL FICHAS_PintarFicha16

    ; --- Palo vertical derecho del '4' ---
    LD H, 6: LD L, 22               ; (X)
    CALL FICHAS_PintarFicha16
    LD H, 8: LD L, 22               ; (X)
    CALL FICHAS_PintarFicha16
    LD H, 12: LD L, 22              ; (X)
    CALL FICHAS_PintarFicha16
    LD H, 14: LD L, 22              ; (X)
    CALL FICHAS_PintarFicha16

    POP AF                          ; Limpiar el color Amarillo de la pila
    
    ; === PASO 3: Restaurar registros ===
    POP HL: POP BC: POP AF          ; Restaurar registros originales (Orden LIFO)
    RET
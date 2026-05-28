; ============================================================================================
; ARCHIVO: EndScreen.asm
; USO: Pantalla de fin de juego.
;      Se llama desde input.asm (GAME_End).
;      Muestra el resultado (quién ganó o si fue empate) y pregunta si se desea
;      jugar de nuevo.
; ============================================================================================

END_SCREEN:
    ; 1. Inicialización de la pantalla
    CALL COMMON_INIT_SCREEN    

    ; --- 2. MOSTRAR TÍTULO: "Se acabó el juego!" ---
    LD A, COLOR_ROJO_BLANCO_FLASH ; Atributo: Rojo parpadeante sobre blanco
    LD B, 1                       ; Fila (Y) = 1
    LD C, 7                       ; Columna (X) = 7
    LD IX, GAME_OVER_MESSAGE      ; Puntero al texto
    CALL PRINTAT                 

    ; --- 3. MOSTRAR RESULTADO (Ganador o Empate) ---
    ; Cargar la variable que indica por qué terminó el juego.
    ; (0 = Empate, 1 = Gana P1, 2 = Gana P2)
    LD A, (GAME_OVER_REASON)   
    OR A                        ; Comprobar si A es 0 (Empate)
    JR Z, .PRINT_EMPATE         ; Si es 0, saltar a mostrar mensaje de empate

    ; --- CASO GANADOR (A = 1 o 2) ---
    ; Convertir el número del jugador (1 o 2) en un carácter ASCII ('1' o '2')
    ADD A, '0'                 
    
    ; Sobrescribir la 'X' en el texto "El jugador X ha ganado!"
    LD (WINNER_MESSAGE + 11), A
    
    ; --- Determinar color del texto basado en el ganador ---
    LD A, (GAME_OVER_REASON)    ; Recargar A (porque lo modificamos antes para el ASCII)
    CP 1
    JR Z, .TEXTO_ROJO
    
    ; Si no es 1, es Jugador 2 (Amarillo)
    LD A, COLOR_INK_AMARILLO
    JR .SET_TEXT_ATTR
    
.TEXTO_ROJO:
    LD A, COLOR_INK_ROJO

.SET_TEXT_ATTR:
    ; Convertir solo tinta a atributo completo (Fondo Negro + Brillo), le añadimos a A el brillo
    ; Atributo = INK + PAPER(0) + BRIGHT(64)
    OR 64                       ; Añadir Brillo (Bit 6)
    
    ; Configurar coordenadas para imprimir
    LD B, 10                    ; Fila (Y) = 10
    LD C, 4                     ; Columna (X) = 4
    LD IX, WINNER_MESSAGE       ; Puntero al texto del ganador
    
    JR .DO_PRINT_RESULT         ; Saltar a imprimir

.PRINT_EMPATE:
    ; --- CASO EMPATE (A = 0) ---
    LD A, COLOR_INK_CIAN        ; Atributo: Cian (Solo Tinta, fondo negro por defecto 0)
    OR 64                       ; Añadir brillo para consistencia
    
    LD B, 10                    ; Fila (Y) = 10
    LD C, 4                     ; Columna (X) = 4
    LD IX, EMPATE_MESSAGE       ; Puntero al texto de empate

.DO_PRINT_RESULT:
    ; Rutina común que imprime el mensaje (Ganador o Empate) con el atributo en A
    CALL PRINTAT               

    ; --- 4. PREGUNTAR "¿Volver a jugar?" ---
    LD IX, EMPTY_MESSAGE            ; IX = Título superior (ninguno)
    LD IY, PLAY_AGAIN_MESSAGE_1     ; IY = Pregunta inferior ("¿Volver a jugar?")
    
    ; Esta rutina saltará a GAME_SCREEN (si 'S') o a BYE_SCREEN (si 'N').
    JP COMMON_HANDLE_PLAY_RESPONSE